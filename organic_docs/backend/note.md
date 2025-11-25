# 笔记系统模块 - 后端文档

> **返回**: [文档首页](../../README.md)

## 目录

- [1. 模块概述](#1-模块概述)
- [2. 数据模型（Model/Schema）](#2-数据模型modelschema)
- [3. API 规范（Controller/Route）](#3-api-规范controllerroute)
- [4. 业务逻辑流程（Service/UseCase）](#4-业务逻辑流程serviceusecase)
- [5. 权限与鉴权规则](#5-权限与鉴权规则)
- [6. 错误码和响应规范](#6-错误码和响应规范)
- [7. 定时任务/队列处理/事件](#7-定时任务队列处理事件)

---

## 1. 模块概述

### 1.1 模块职责

笔记系统模块负责：

- **笔记生命周期管理**: 从创建到删除的完整流程
- **编辑锁管理**: 防止多人同时编辑造成冲突
- **权限控制**: 作者、可编辑协作者、只读协作者三级权限
- **分享管理**: 支持笔记分享和权限管理
- **实时协作**: 通过WebSocket实现实时同步

### 1.2 核心概念

- **编辑锁**: 互斥编辑机制，同一时间只能有一个用户编辑
- **心跳机制**: 每30秒发送心跳维持编辑锁
- **自动释放**: 15分钟绝对超时或3分钟无活动自动释放锁
- **协作编辑**: 支持多用户协作模式（通过Yjs处理冲突）

---

## 2. 数据模型（Model/Schema）

### 2.1 Note 模型

**文件路径**: `app/models/note.rb`

```ruby
class Note < ApplicationRecord
  belongs_to :user
  has_one :note_edit_lock, dependent: :destroy
  has_many :note_shared_users, dependent: :destroy
  has_many :shared_users, through: :note_shared_users, source: :user

  # 数据库字段
  # id: integer (主键, 自增)
  # user_id: integer (作者ID, 索引)
  # tag: integer (标签: 0=任务, 1=灵感, 2=其他, 默认0, 索引)
  # content: text (笔记内容, 最大1000000字符)
  # share_opt: text (分享选项, JSON格式)
  # created_at: datetime (索引)
  # updated_at: datetime

  # 标签枚举
  enum tag: {
    task: 0,        # 任务
    inspiration: 1, # 灵感
    other: 2        # 其他
  }, _prefix: true

  # 验证规则
  validates :user_id, presence: true
  validates :tag, presence: true
  validates :content, length: { maximum: 1000000 }, allow_blank: true

  # 默认排序
  default_scope { order(created_at: :desc) }

  # 搜索功能
  scope :by_tag, ->(tag) { where(tag: tag) if tag.present? }
  scope :by_user, ->(user_id) { where(user_id: user_id) if user_id.present? }
  scope :search_content, ->(query) { where('content LIKE ?', "%#{query}%") if query.present? }

  # 权限检查方法
  def can_edit?(user)
    return false unless user
    return true if user.id == user_id  # 作者权限
    
    # 检查共享编辑权限
    note_shared_users.active.find_by(user: user)&.editable?
  end

  def can_view?(user)
    return false unless user
    return true if user.id == user_id  # 作者权限
    
    # 检查共享查看权限
    note_shared_users.active.exists?(user: user)
  end

  def can_share?(user)
    user && user.id == user_id
  end

  def can_delete?(user)
    user && user.id == user_id
  end

  # 编辑锁管理
  def acquire_edit_lock(user)
    return { success: false, error: "No edit permission" } unless can_edit?(user)
    
    ActiveRecord::Base.transaction do
      lock = note_edit_lock || build_note_edit_lock
      
      if lock.new_record?
        lock.save!
      else
        lock.reload
      end
      
      if lock.locked_by.nil?
        # 锁可用，获取成功
        lock.update!(
          locked_by: user.id,
          locked_at: Time.current,
          is_locked: true,
          auto_release_at: Time.current + 15.minutes,
          last_update_at: Time.current
        )
        { success: true, lock: lock }
      elsif lock.locked_by == user.id
        # 自己已经持有锁，更新最后活动时间
        lock.update!(
          last_update_at: Time.current,
          auto_release_at: Time.current + 15.minutes
        )
        { success: true, message: "Already locked by you" }
      else
        # 锁被其他人持有
        if lock.expired?
          # 强制释放过期锁
          lock.update!(
            locked_by: nil,
            locked_at: nil,
            is_locked: false,
            auto_release_at: nil
          )
          
          # 重新获取锁
          lock.update!(
            locked_by: user.id,
            locked_at: Time.current,
            is_locked: true,
            auto_release_at: Time.current + 15.minutes,
            last_update_at: Time.current
          )
          { success: true, lock: lock }
        else
          # 锁有效，返回冲突信息
          locked_by_user = User.find(lock.locked_by)
          {
            success: false,
            error: "Note is being edited by #{locked_by_user.account}",
            locked_by: locked_by_user.to_sample_json,
            remaining_time: lock.remaining_time
          }
        end
      end
    end
  rescue StandardError => e
    { success: false, error: "Failed to acquire lock: #{e.message}" }
  end

  def release_edit_lock(user)
    return { success: false, error: "No edit permission" } unless can_edit?(user)
    
    lock = note_edit_lock
    return { success: false, error: "No active lock" } unless lock&.locked?
    
    unless lock.locked_by == user.id
      return { success: false, error: "You don't hold the lock" }
    end
    
    lock.update!(
      locked_by: nil,
      locked_at: nil,
      last_update_at: nil,
      is_locked: false,
      auto_release_at: nil
    )
    
    { success: true, message: "Lock released successfully" }
  rescue StandardError => e
    { success: false, error: "Failed to release lock: #{e.message}" }
  end

  # 共享用户管理
  def add_shared_user(user_id, permission: 'readonly')
    return false if user_id == self.user_id
    
    shared_user = NoteSharedUser.find_by(note_id: self.id, user_id: user_id)
    
    if shared_user
      shared_user.update!(
        permission: permission,
        shared_at: Time.current,
        is_active: true,
        unshared_at: nil
      )
    else
      shared_user = NoteSharedUser.create!(
        note_id: self.id,
        user_id: user_id,
        permission: permission,
        shared_at: Time.current,
        is_active: true
      )
    end
    
    shared_user
  end

  def remove_shared_user(user_id)
    shared_user = note_shared_users.find_by(user_id: user_id)
    shared_user&.deactivate!
  end
end
```

### 2.2 NoteEditLock 模型

**文件路径**: `app/models/note_edit_lock.rb`

```ruby
class NoteEditLock < ApplicationRecord
  belongs_to :note
  belongs_to :locked_by_user, class_name: 'User', foreign_key: 'locked_by', optional: true

  # 数据库字段
  # id: integer
  # note_id: integer (笔记ID, 唯一, 索引)
  # locked_by: integer (锁定用户ID, 索引)
  # locked_at: datetime (锁定时间)
  # last_update_at: datetime (最后更新时间)
  # is_locked: boolean (是否锁定, 默认false)
  # lock_timeout: integer (锁超时时间, 秒, 默认900)
  # update_timeout: integer (更新超时时间, 秒, 默认180)
  # auto_release_at: datetime (自动释放时间)
  # lock_reason: string (锁定原因)

  validates :note_id, presence: true, uniqueness: true
  validates :lock_timeout, presence: true, numericality: { greater_than: 0 }
  validates :update_timeout, presence: true, numericality: { greater_than: 0 }

  def locked?
    is_locked && locked_by.present?
  end

  def expired?
    return false unless auto_release_at
    Time.current >= auto_release_at
  end

  def remaining_time
    return 0 unless auto_release_at
    remaining = auto_release_at - Time.current
    [remaining.to_i, 0].max
  end

  def update_expired?
    return false unless last_update_at
    Time.current - last_update_at > update_timeout.seconds
  end

  def update_content!
    return false unless locked?
    update!(last_update_at: Time.current)
    true
  end
end
```

### 2.3 NoteSharedUser 模型

**文件路径**: `app/models/note_shared_user.rb`

```ruby
class NoteSharedUser < ApplicationRecord
  belongs_to :note
  belongs_to :user

  # 数据库字段
  # id: integer
  # note_id: integer (笔记ID, 索引)
  # user_id: integer (被分享用户ID, 索引)
  # permission: string (权限: readonly/editable, 默认readonly)
  # shared_at: datetime (分享时间)
  # unshared_at: datetime (取消分享时间, 可为空)
  # is_active: boolean (是否激活, 默认true)

  PERMISSIONS = %w[readonly editable].freeze

  validates :note_id, presence: true
  validates :user_id, presence: true
  validates :permission, presence: true, inclusion: { in: PERMISSIONS }
  validates :shared_at, presence: true
  validates :user_id, uniqueness: { scope: :note_id }

  scope :active, -> { where(is_active: true) }
  scope :editable, -> { where(permission: 'editable') }

  def editable?
    permission == 'editable'
  end

  def active?
    is_active && unshared_at.nil?
  end

  def deactivate!
    update!(is_active: false, unshared_at: Time.current)
  end
end
```

### 2.4 数据库索引

```sql
-- notes 表索引
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_tag ON notes(tag);
CREATE INDEX idx_notes_created_at ON notes(created_at);

-- note_edit_locks 表索引
CREATE UNIQUE INDEX idx_note_edit_locks_note_id ON note_edit_locks(note_id);
CREATE INDEX idx_note_edit_locks_locked_by ON note_edit_locks(locked_by);

-- note_shared_users 表索引
CREATE INDEX idx_note_shared_users_note_id ON note_shared_users(note_id);
CREATE INDEX idx_note_shared_users_user_id ON note_shared_users(user_id);
CREATE UNIQUE INDEX idx_note_shared_users_note_user ON note_shared_users(note_id, user_id);
```

---

## 3. API 规范（Controller/Route）

### 3.1 路由配置

**文件路径**: `config/routes.rb`

```ruby
# 笔记相关路由（使用动态路由匹配）
match 'notes/:action(/:id)', to: 'notes#:action', via: [:get, :post, :put, :delete]
```

### 3.2 Controller 方法

**文件路径**: `app/controllers/notes_controller.rb`

#### 3.2.1 获取笔记列表

```ruby
# POST /notes/index
def index
  # 参数
  # tag: string (可选, 标签过滤)
  # search: string (可选, 内容搜索)
  # include_shared: boolean (可选, 是否包含被分享的笔记, 默认false)
  # page: integer (可选, 页码, 默认1)
  # per_page: integer (可选, 每页数量, 默认20)
  
  notes = if ['true', true].include?(params[:include_shared])
    # 获取用户自己的笔记和被分享的笔记
    accessible_notes_query
  else
    # 只获取用户自己的笔记
    Note.by_user(current_user.id)
  end
  
  # 应用过滤和分页
  render_notes_with_pagination(notes)
end
```

#### 3.2.2 创建笔记

```ruby
# POST /notes/create
def create
  note_params = params.permit(:tag, :content)
  note = Note.new(note_params)
  note.user_id = current_user.id
  
  if note.save
    render_success({ 
      note: note.to_json,
      message: note.content.blank? ? I18n.t('notes.hints.empty_content_hint') : nil
    })
  else
    render_failure_json(note.errors.full_messages.join(', '))
  end
end
```

#### 3.2.3 更新笔记

```ruby
# POST /notes/update
def update
  unless @note.can_edit?(current_user)
    render_failure_json(I18n.t('notes.messages.no_permission_edit'))
    return
  end
  
  note_params = params.permit(:tag, :content)
  
  if @note.update(note_params)
    # 更新编辑锁的内容更新时间
    @note.note_edit_lock&.update_content!
    
    render_success({ note: @note.to_json })
  else
    render_failure_json(@note.errors.full_messages.join(', '))
  end
end
```

#### 3.2.4 分享笔记

```ruby
# POST /notes/share
def share
  unless @note.can_share?(current_user)
    render_failure_json(I18n.t('notes.messages.no_permission_share'))
    return
  end
  
  user_ids = Array(params[:user_ids]).map(&:to_i)
  permissions = Array(params[:permissions])
  
  # 验证用户是否存在
  users = User.where(id: user_ids)
  if users.count != user_ids.count
    render_failure_json(I18n.t('notes.messages.user_not_found'))
    return
  end
  
  # 添加分享用户
  user_ids.each_with_index do |user_id, index|
    permission = permissions[index] || 'readonly'
    @note.add_shared_user(user_id, permission: permission)
  end
  
  # 发送分享通知
  send_share_notification(user_ids)
  
  render_success({ 
    message: I18n.t('notes.messages.shared'),
    note: @note.to_json.except(:content) 
  })
end
```

#### 3.2.5 编辑锁管理

```ruby
# POST /notes/acquire_lock
def acquire_lock
  unless @note.can_edit?(current_user)
    render_failure_json(I18n.t('notes.messages.no_permission_edit'))
    return
  end
  
  result = @note.acquire_edit_lock(current_user)
  
  if result[:success]
    # 广播锁状态更新
    broadcast_lock_status(@note.id, result[:lock])
    render_success({ 
      message: "Edit lock acquired successfully",
      lock: result[:lock].to_json
    })
  else
    render_failure_json(result[:error])
  end
end

# POST /notes/release_lock
def release_lock
  result = @note.release_edit_lock(current_user)
  
  if result[:success]
    # 广播锁状态更新
    broadcast_lock_status(@note.id, nil)
    render_success({ message: "Edit lock released successfully" })
  else
    render_failure_json(result[:error])
  end
end
```

---

## 4. 业务逻辑流程（Service/UseCase）

### 4.1 笔记创建流程

```ruby
def self.create_note(user, params)
  ActiveRecord::Base.transaction do
    # 1. 验证参数
    validate_note_params(params)
    
    # 2. 创建笔记
    note = Note.new(params)
    note.user_id = user.id
    note.save!
    
    # 3. 创建编辑锁记录（延迟创建）
    # NoteEditLock 会在首次获取锁时创建
    
    { success: true, note: note }
  rescue StandardError => e
    { success: false, error: e.message }
  end
end
```

### 4.2 编辑锁获取流程

```ruby
def acquire_edit_lock(user)
  # 1. 权限检查
  return { success: false, error: "No edit permission" } unless can_edit?(user)
  
  ActiveRecord::Base.transaction do
    # 2. 获取或创建锁记录
    lock = note_edit_lock || build_note_edit_lock
    
    # 3. 检查锁状态
    if lock.locked_by.nil?
      # 锁可用，获取成功
      lock.update!(
        locked_by: user.id,
        locked_at: Time.current,
        is_locked: true,
        auto_release_at: Time.current + 15.minutes,
        last_update_at: Time.current
      )
      { success: true, lock: lock }
    elsif lock.locked_by == user.id
      # 自己已经持有锁，更新活动时间
      lock.update!(
        last_update_at: Time.current,
        auto_release_at: Time.current + 15.minutes
      )
      { success: true, message: "Already locked by you" }
    else
      # 锁被其他人持有
      if lock.expired?
        # 强制释放过期锁并重新获取
        force_release_and_acquire(lock, user)
      else
        # 返回冲突信息
        { success: false, error: "Locked by other user", ... }
      end
    end
  end
end
```

### 4.3 笔记分享流程

```ruby
def add_shared_user(user_id, permission: 'readonly')
  # 1. 验证不能分享给自己
  return false if user_id == self.user_id
  
  # 2. 查找或创建共享用户记录
  shared_user = NoteSharedUser.find_or_initialize_by(
    note_id: self.id,
    user_id: user_id
  )
  
  # 3. 更新权限和状态
  shared_user.update!(
    permission: permission,
    shared_at: Time.current,
    is_active: true,
    unshared_at: nil
  )
  
  # 4. 发送通知
  NotificationHelper.send_note_share_notification(self, user_id)
  
  shared_user
end
```

### 4.4 内容更新流程

```ruby
def update_content(user, content)
  # 1. 权限检查
  unless can_edit?(user)
    raise ApiHelper::Error.new("No edit permission", ApiHelper::ERROR_PERMISSION_DENIED)
  end
  
  # 2. 更新内容（协作模式：不检查锁）
  update!(content: content)
  
  # 3. 更新编辑锁的活动时间
  note_edit_lock&.update_content!
  
  # 4. 广播内容更新
  broadcast_content_update(self.id, content, user)
  
  { success: true, note: self }
end
```

---

## 5. 权限与鉴权规则

### 5.1 权限检查方法

```ruby
# 检查是否可以查看笔记
def can_view?(user)
  return false unless user
  
  # 笔记作者可以查看
  return true if user.id == user_id
  
  # 检查共享查看权限
  note_shared_users.active.exists?(user: user)
end

# 检查是否可以编辑笔记
def can_edit?(user)
  return false unless user
  
  # 笔记作者可以编辑
  return true if user.id == user_id
  
  # 检查共享编辑权限
  note_shared_users.active.find_by(user: user)&.editable?
end

# 检查是否可以分享笔记
def can_share?(user)
  user && user.id == user_id
end

# 检查是否可以删除笔记
def can_delete?(user)
  user && user.id == user_id
end
```

### 5.2 权限枚举

```ruby
# 笔记相关权限
NOTE_PERMISSIONS = {
  'note:view' => '查看笔记',
  'note:create' => '创建笔记',
  'note:edit' => '编辑笔记',
  'note:delete' => '删除笔记',
  'note:share' => '分享笔记'
}
```

---

## 6. 错误码和响应规范

### 6.1 业务错误码

```ruby
NOTE_ERROR_CODES = {
  'NOTE_NOT_FOUND' => '笔记不存在',
  'NOTE_PERMISSION_DENIED' => '无权限操作此笔记',
  'NOTE_LOCKED' => '笔记正在被其他人编辑',
  'NOTE_LOCK_EXPIRED' => '编辑锁已过期',
  'NOTE_CONTENT_TOO_LONG' => '笔记内容过长',
  'NOTE_SHARE_FAILED' => '分享失败',
  'NOTE_USER_NOT_FOUND' => '用户不存在'
}
```

### 6.2 响应格式

#### 6.2.1 成功响应

```ruby
# 标准成功响应
{
  "code": 0,
  "data": {
    "note": {
      "id": 1,
      "user_id": 1,
      "tag": "task",
      "content": "笔记内容",
      "shared_users": [...],
      "edit_lock": {...},
      "current_editor": {...}
    }
  }
}

# 带分页的成功响应
{
  "code": 0,
  "data": {
    "notes": [...],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total_pages": 5,
      "total_count": 100
    }
  }
}
```

#### 6.2.2 错误响应

```ruby
# 权限不足
{
  "code": 403,
  "message": "无权限编辑此笔记"
}

# 锁冲突
{
  "code": 400,
  "message": "笔记正在被 user@example.com 编辑",
  "error_code": "NOTE_LOCKED",
  "locked_by": {
    "id": 2,
    "account": "user@example.com"
  },
  "remaining_time": 900
}
```

---

## 7. 定时任务/队列处理/事件

### 7.1 定时任务

**文件路径**: `config/schedule.rb`

```ruby
# 清理过期的笔记编辑锁
every 1.hour do
  runner "NoteEditLockCleanupJob.perform_now"
end
```

### 7.2 后台任务

**文件路径**: `app/jobs/note_edit_lock_cleanup_job.rb`

```ruby
class NoteEditLockCleanupJob < ApplicationJob
  queue_as :default

  def perform
    # 清理过期的编辑锁
    NoteEditLock.where('auto_release_at < ?', Time.current)
                .where(is_locked: true)
                .update_all(
                  is_locked: false,
                  locked_by: nil,
                  locked_at: nil,
                  auto_release_at: nil,
                  last_update_at: nil
                )
    
    # 清理长时间无活动的编辑锁（3分钟无更新）
    NoteEditLock.where('last_update_at < ?', 3.minutes.ago)
                .where(is_locked: true)
                .update_all(
                  is_locked: false,
                  locked_by: nil,
                  locked_at: nil,
                  auto_release_at: nil,
                  last_update_at: nil
                )
  end
end
```

### 7.3 事件通知

**文件路径**: `app/helpers/notification_helper.rb`

```ruby
def self.send_note_share_notification(note, user_id)
  alert = {
    title: ['notes.messages.shared_title', {}],
    body: ['notes.messages.shared_body', { 
      note_title: note.content.truncate(50),
      operator_name: current_user.account
    }]
  }
  
  payload = {
    action: 'note_shared',
    note_id: note.id,
    note_title: note.content.truncate(50),
    operator_id: current_user.id,
    operator_name: current_user.account
  }
  
  NotificationHelper.push_websocket_notification([user_id], alert, payload, current_user.id)
end
```

### 7.4 WebSocket 事件

**文件路径**: `app/channels/note_edit_channel.rb`

```ruby
class NoteEditChannel < ApplicationCable::Channel
  def subscribed
    note_id = params[:note_id]
    stream_from "note_edit_#{note_id}"
    
    # 通知其他订阅者有新用户加入
    broadcast_subscriber_change(note_id, 'subscribe', current_user)
  end

  def unsubscribed
    note_id = params[:note_id]
    # 通知其他订阅者有用户离开
    broadcast_subscriber_change(note_id, 'unsubscribe', current_user)
  end

  def receive(data)
    case data['action']
    when 'lock_request'
      handle_lock_request(data)
    when 'content_update'
      handle_content_update(data)
    when 'heartbeat'
      handle_heartbeat(data)
    end
  end

  private

  def handle_lock_request(data)
    note = Note.find(data['note_id'])
    result = note.acquire_edit_lock(current_user)
    
    if result[:success]
      broadcast_to_note(note.id, {
        type: 'lock_status_update',
        lock: result[:lock].to_json,
        user: current_user.to_sample_json
      })
    else
      transmit({
        type: 'lock_failed',
        error: result[:error]
      })
    end
  end

  def handle_content_update(data)
    note = Note.find(data['note_id'])
    # 内容更新由HTTP API处理，这里只负责广播
    broadcast_to_note(note.id, {
      type: 'content_update',
      content: data['content'],
      updated_by: current_user.id,
      is_current_user_operation: false
    })
  end

  def handle_heartbeat(data)
    note = Note.find(data['note_id'])
    lock = note.note_edit_lock
    
    if lock&.locked_by == current_user.id
      lock.update!(last_update_at: Time.current)
      transmit({
        type: 'heartbeat_response',
        timestamp: Time.current.to_i
      })
    end
  end

  def broadcast_to_note(note_id, data)
    ActionCable.server.broadcast("note_edit_#{note_id}", data)
  end

  def broadcast_subscriber_change(note_id, action, user)
    broadcast_to_note(note_id, {
      type: 'subscriber_change',
      action: action,
      user: user.to_sample_json
    })
  end
end
```

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN后端开发团队

