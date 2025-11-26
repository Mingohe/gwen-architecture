# 任务管理模块 - 后端文档

> **返回**: [文档首页](../../README.md)

## 目录

- [1. 模块概述](#1-模块概述)
- [2. 数据模型（Model/Schema）](#2-数据模型modelschema)
- [3. API 规范（Controller/Route）](#3-api-规范controllerroute)
- [4. 业务逻辑流程（Service/UseCase）](#4-业务逻辑流程serviceusecase)
- [5. 权限与鉴权规则](#5-权限与鉴权规则)
- [6. 错误码和响应规范](#6-错误码和响应规范)
- [7. 定时任务/队列处理/事件](#7-定时任务队列处理事件)
- [8. 任务协作编辑](#8-任务协作编辑)

---

## 1. 模块概述

### 1.1 模块职责

任务管理模块是GWEN系统的核心业务模块，负责：

- **任务生命周期管理**: 从创建到完成/失败/取消的完整流程
- **任务树结构管理**: 支持父子任务关系，实现任务分解
- **任务状态机管理**: 严格的状态流转控制和验证
- **金币奖励系统**: 任务关联金币，支持多种货币类型

### 1.2 核心概念

- **根任务**: 没有父任务的任务，从奖金池分配金币
- **子任务**: 有父任务的任务，从父任务账户分配金币
- **任务状态机**: 严格的状态流转规则，确保任务流程的规范性

---

## 2. 数据模型（Model/Schema）

### 2.1 Task 模型

**文件路径**: `app/models/task.rb`

```ruby
class Task < ApplicationRecord
  # 关联关系
  belongs_to :parent, class_name: "Task", foreign_key: "parent_id", optional: true
  has_many :children, class_name: "Task", foreign_key: "parent_id"
  belongs_to :assignee, class_name: "User", foreign_key: "assignee_id", optional: true
  belongs_to :assignor, class_name: "User", foreign_key: "assignor_id", optional: true
  has_many :related_txs, class_name: "Tx", foreign_key: "direct_task_id"
  has_many :issues, class_name: "Project::Issue", foreign_key: "task_id"
  belongs_to :wiki_task, class_name: "Codepedia::WikiTask", foreign_key: "wiki_task_id", optional: true

  # 数据库字段
  # id: integer (主键, 自增)
  # parent_id: integer (父任务ID, 可为空, 索引)
  # assignee_id: integer (负责人ID, 可为空, 索引)
  # assignor_id: integer (分配人ID, 可为空, 索引)
  # title: string (任务标题, 最大255字符)
  # description: text (任务描述, 必填)
  # status: integer (任务状态, 默认0, 索引)
  # task_type: integer (任务类型, 默认5)
  # coins: integer (金币数量, 默认0)
  # currency: integer (货币类型: 0=灰币, 1=红币, 2=蓝币, 默认0)
  # could_dispatch: boolean (是否可分发, 默认false)
  # scheduled_start: datetime (计划开始时间, 可为空)
  # scheduled_deadline: datetime (计划截止时间, 可为空)
  # actual_start: datetime (实际开始时间, 可为空)
  # actual_deadline: datetime (实际截止时间, 可为空)
  # wiki_task_id: integer (关联Wiki任务ID, 可为空)
  # created_at: datetime
  # updated_at: datetime

  # 状态枚举
  STATUS_OPEN = 0                    # 新创建(未读)
  STATUS_READ = 1                    # 已读
  STATUS_ACCEPTED = 2                # 已接收
  STATUS_PUBLISHED = 3               # 已发布(仅根任务)
  STATUS_SUBMITTED = 4               # 已提交
  STATUS_CHECKED = 5                 # 会议中通过验收
  STATUS_STRIKED = 6                 # 会议中不通过验收
  STATUS_ACCOMPLISHED = 7            # 会议后完成
  STATUS_SUCCEEDED = 8               # 成功
  STATUS_FAILED = 9                 # 失败
  STATUS_ABORTED = 10                # 中止

  # 任务类型枚举
  TASK_TYPES = {
    0 => "function_design",      # 功能设计
    1 => "ui_design",            # UI设计
    2 => "daily_op",             # 日常运营
    3 => "fault_op",             # 故障运营
    4 => "consulting_service",   # 咨询服务
    5 => "dev_and_test",         # 开发测试
    6 => "manage",               # 管理
  }

  # 货币类型枚举
  CURRENCY_GRAY = 0    # 灰币
  CURRENCY_RED = 1     # 红币
  CURRENCY_BLUE = 2    # 蓝币

  # 验证规则
  validates :description, presence: true
  validate :validate_task, on: [:create]

  # 回调
  before_validation :set_default_coins, :set_default_type, :set_default_period, on: [:create]
  after_create :update_wanted_status
end
```


  # 验证规则
end
```

### 2.2 Task::Delay 模型（任务延期）

**文件路径**: `app/models/task/delay.rb`

```ruby
class Task::Delay < ApplicationRecord
  belongs_to :task
  belongs_to :meeting

  # 数据库字段
  # id: integer
  # task_id: integer (任务ID)
  # meeting_id: integer (会议ID)
  # reason: text (延期原因)
  # new_deadline: datetime (新的截止时间)
  # created_at: datetime

  # 验证规则
  validates :reason, presence: true
  validates :new_deadline, presence: true
end
```

### 2.3 数据库索引

```sql
-- tasks 表索引
CREATE INDEX idx_tasks_parent_id ON tasks(parent_id);
CREATE INDEX idx_tasks_assignee_id ON tasks(assignee_id);
CREATE INDEX idx_tasks_assignor_id ON tasks(assignor_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);

```

---

## 3. API 规范（Controller/Route）

### 3.1 路由配置

**文件路径**: `config/routes.rb`

```ruby
# 任务相关路由（使用动态路由匹配）
match 'task/:action(/:id)', to: 'task#:action', via: [:get, :post, :put, :delete]
```

### 3.2 Controller 方法

**文件路径**: `app/controllers/task_controller.rb`

#### 3.2.1 获取任务列表

```ruby
# GET /task/index
def index
  # 参数
  # status: integer (可选, 任务状态筛选)
  # page: integer (可选, 页码, 默认1)
  # per_page: integer (可选, 每页数量, 默认20)
  
  tasks = TaskHelper.get_user_tasks(current_user, params)
  render_success({
    tasks: tasks.map(&:to_json),
    pagination: pagination_info(tasks)
  })
end
```

#### 3.2.2 获取任务创建选项

```ruby
# GET /task/get_create_options
def get_create_options
  # 参数
  # parent_id: integer (可选, 父任务ID)
  
  options = TaskHelper.get_create_options(current_user, params[:parent_id])
  render_success(options)
end
```

#### 3.2.3 创建任务

```ruby
# POST /task/create
def create
  # 参数验证
  task_params = params.require(:task).permit(
    :title, :description, :task_type, :coins, :currency,
    :assignee_id, :parent_id, :could_dispatch,
    :scheduled_start, :scheduled_deadline
  )
  
  # 业务逻辑处理
  result = TaskHelper.create_task(current_user, task_params)
  
  if result[:success]
    render_success({ task: result[:task].to_json })
  else
    render_failure_json(result[:error])
  end
end
```

#### 3.2.4 任务详情

```ruby
# GET /task/info
def info
  task = Task.find(params[:id])
  
  # 权限检查
  unless TaskHelper.can_view?(task, current_user)
    render_failure_json("无权限查看此任务")
    return
  end
  
  render_success({ task: task.to_detail_json })
end
```

#### 3.2.5 更新任务

```ruby
# POST /task/update
def update
  task = Task.find(params[:id])
  
  # 权限检查
  unless TaskHelper.can_edit?(task, current_user)
    render_failure_json("无权限编辑此任务")
    return
  end
  
  task_params = params.require(:task).permit(
    :title, :description, :coins, :scheduled_start, :scheduled_deadline
  )
  
  if task.update(task_params)
    render_success({ task: task.to_json })
  else
    render_failure_json(task.errors.full_messages.join(', '))
  end
end
```

#### 3.2.6 任务状态流转

```ruby
# POST /task/read
def read
  task = Task.find(params[:id])
  TaskHelper.update_status_read(task, current_user)
  render_success({ task: task.reload.to_json })
rescue ApiHelper::Error => e
  render_failure_json(e.message)
end

# POST /task/accept
def accept
  task = Task.find(params[:id])
  TaskHelper.update_status_accepted(task, current_user)
  render_success({ task: task.reload.to_json })
rescue ApiHelper::Error => e
  render_failure_json(e.message)
end

# POST /task/submit
def submit
  task = Task.find(params[:id])
  TaskHelper.update_status_submitted(task, current_user)
  render_success({ task: task.reload.to_json })
rescue ApiHelper::Error => e
  render_failure_json(e.message)
end

# POST /task/check
def check
  task = Task.find(params[:id])
  TaskHelper.update_status_checked(task, current_user)
  render_success({ task: task.reload.to_json })
rescue ApiHelper::Error => e
  render_failure_json(e.message)
end

# POST /task/succeed
def succeed
  task = Task.find(params[:id])
  TaskHelper.update_status_succeeded(task, current_user)
  render_success({ task: task.reload.to_json })
rescue ApiHelper::Error => e
  render_failure_json(e.message)
end

# POST /task/fail
def fail
  task = Task.find(params[:id])
  TaskHelper.update_status_failed(task, current_user)
  render_success({ task: task.reload.to_json })
rescue ApiHelper::Error => e
  render_failure_json(e.message)
end

# POST /task/abort
def abort
  task = Task.find(params[:id])
  reason = params[:reason]
  TaskHelper.update_status_aborted(task, current_user, reason)
  render_success({ task: task.reload.to_json })
rescue ApiHelper::Error => e
  render_failure_json(e.message)
end
```


---

## 4. 业务逻辑流程（Service/UseCase）

### 4.1 任务创建流程

**文件路径**: `app/helpers/task_helper.rb`

```ruby
def self.create_task(user, params)
  ActiveRecord::Base.transaction do
    # 1. 验证参数
    validate_create_params(params)
    
    # 2. 如果是子任务，验证父任务
    if params[:parent_id].present?
      parent_task = Task.find(params[:parent_id])
      validate_parent_task(parent_task, params)
    end
    
    # 3. 验证金币
    validate_coins(user, params)
    
    # 4. 创建任务
    task = Task.new(params)
    task.assignor_id = user.id
    task.save!
    
    # 6. 处理金币分配
    if task.parent_id.nil?
      # 根任务：从奖金池扣除
      BonusPool.deduct_coins(task.coins, task.currency)
    else
      # 子任务：从父任务账户扣除
      parent_task.deduct_coins_for_child(task.coins, task.currency)
    end
    
    # 7. 发送通知
    NotificationHelper.send_task_create_notification(task)
    
    { success: true, task: task }
  rescue StandardError => e
    { success: false, error: e.message }
  end
end
```

### 4.2 任务状态流转流程

```ruby
def self.update_status_read(task, user)
  ActiveRecord::Base.transaction do
    # 验证权限
    unless can_read?(task, user)
      raise ApiHelper::Error.new("无权限标记已读", ApiHelper::ERROR_PERMISSION_DENIED)
    end
    
    # 更新状态
    task.update_status_read
    
    # 发送通知
    NotificationHelper.send_task_read_notification(task, user)
  end
end

def self.update_status_accepted(task, user)
  ActiveRecord::Base.transaction do
    # 验证权限：必须是任务负责人
    unless task.assignee_id == user.id
      raise ApiHelper::Error.new("只有任务负责人可以接受任务", ApiHelper::ERROR_PERMISSION_DENIED)
    end
    
    # 验证状态
    unless [Task::STATUS_OPEN, Task::STATUS_READ].include?(task.status)
      raise ApiHelper::Error.new("任务状态不允许接受", ApiHelper::ERROR_INVALID_PARAM)
    end
    
    # 更新状态
    task.update_status_accepted
    task.update(actual_start: Time.current)
    
    # 发送通知
    NotificationHelper.send_task_accepted_notification(task, user)
  end
end
```

### 4.3 任务完成流程

```ruby
def self.update_status_succeeded(task, user)
  ActiveRecord::Base.transaction do
    # 验证权限
    unless can_close_task?(task, user)
      raise ApiHelper::Error.new("无权限关闭任务", ApiHelper::ERROR_PERMISSION_DENIED)
    end
    
    # 验证状态
    unless [Task::STATUS_CHECKED, Task::STATUS_ACCOMPLISHED].include?(task.status)
      raise ApiHelper::Error.new("任务状态不允许完成", ApiHelper::ERROR_INVALID_PARAM)
    end
    
    # 更新状态
    task.update_status_succeeded
    task.update(actual_deadline: Time.current)
    
    # 结算金币
    TaskHelper.settle_task_coins(task)
    
    # 如果所有子任务都完成，检查父任务是否可以完成
    if task.parent_id
      check_parent_task_completion(task.parent)
    end
    
    # 发送通知
    NotificationHelper.send_task_succeeded_notification(task, user)
  end
end

def self.settle_task_coins(task)
  # 分配金币给负责人
  if task.assignee_id
    Tx.create!(
      user_id: task.assignee_id,
      direct_task_id: task.id,
      amount: task.coins,
      currency: task.currency,
      tx_type: Tx::TYPE_TASK_REWARD
    )
  end
  
  # 如果有父任务，父任务的账户也需要结算
  if task.parent_id
    # 父任务的账户逻辑
  end
end
```


---

## 5. 权限与鉴权规则

### 5.1 权限检查方法

**文件路径**: `app/helpers/task_helper.rb`

```ruby
# 检查是否可以查看任务
def self.can_view?(task, user)
  return false unless user
  
  # 任务负责人可以查看
  return true if task.assignee_id == user.id
  
  # 任务分配人可以查看
  return true if task.assignor_id == user.id
  
  # 有查看任务权限的用户可以查看
  user.has_permission?('task:view')
end

# 检查是否可以编辑任务
def self.can_edit?(task, user)
  return false unless user
  
  # 任务分配人可以编辑
  return true if task.assignor_id == user.id
  
  # 有编辑任务权限的用户可以编辑
  user.has_permission?('task:edit')
end

# 检查是否可以删除任务
def self.can_delete?(task, user)
  return false unless user
  
  # 只有任务分配人可以删除
  return false unless task.assignor_id == user.id
  
  # 任务状态必须允许删除
  deletable_statuses = [
    Task::STATUS_OPEN,
    Task::STATUS_READ,
    Task::STATUS_ACCEPTED
  ]
  return false unless deletable_statuses.include?(task.status)
  
  # 不能有子任务
  return false if task.children.exists?
  
  true
end

# 检查是否可以关闭任务（成功/失败/取消）
def self.can_close_task?(task, user)
  return false unless user
  
  # 需要关闭任务权限
  return false unless user.has_permission?('task:close')
  
  # 任务状态必须允许关闭
  closable_statuses = [
    Task::STATUS_CHECKED,
    Task::STATUS_ACCOMPLISHED
  ]
  closable_statuses.include?(task.status)
end
```

### 5.2 权限枚举

```ruby
# 任务相关权限
TASK_PERMISSIONS = {
  'task:view' => '查看任务',
  'task:create' => '创建任务',
  'task:edit' => '编辑任务',
  'task:delete' => '删除任务',
  'task:close' => '关闭任务',
  'task:accept' => '接受任务',
  'task:submit' => '提交任务',
  'task:check' => '验收任务'
}
```

---

## 6. 错误码和响应规范

### 6.1 错误码定义

```ruby
# app/helpers/api_helper.rb
module ApiHelper
  ERROR_SUCCESS = 0
  ERROR_INVALID_PARAM = 400
  ERROR_UNAUTHORIZED = 401
  ERROR_PERMISSION_DENIED = 403
  ERROR_NOT_FOUND = 404
  ERROR_INTERNAL_SERVER = 500
end
```

### 6.2 响应格式

#### 6.2.1 成功响应

```ruby
# 标准成功响应
{
  "code": 0,
  "data": {
    "task": {
      "id": 1,
      "title": "任务标题",
      ...
    }
  }
}

# 带分页的成功响应
{
  "code": 0,
  "data": {
    "tasks": [...],
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
# 参数错误
{
  "code": 400,
  "message": "任务描述不能为空"
}

# 权限不足
{
  "code": 403,
  "message": "无权限编辑此任务"
}

# 资源不存在
{
  "code": 404,
  "message": "任务不存在"
}

# 业务逻辑错误
{
  "code": 400,
  "message": "任务状态不允许接受",
  "error_code": "TASK_STATUS_INVALID"
}
```

### 6.3 业务错误码

```ruby
# 任务相关业务错误码
TASK_ERROR_CODES = {
  'TASK_DESCRIPTION_REQUIRED' => '任务描述不能为空',
  'TASK_PARENT_NOT_DISPATCHABLE' => '父任务不可分发',
  'TASK_COINS_EXCEEDED' => '金币数量超过可用金币',
  'TASK_STATUS_INVALID' => '任务状态不允许此操作',
  'TASK_HAS_CHILDREN' => '任务有子任务，无法删除',
  'TASK_NOT_FOUND' => '任务不存在',
  'TASK_PERMISSION_DENIED' => '无权限操作此任务'
}
```

---

## 7. 定时任务/队列处理/事件

### 7.1 定时任务

**文件路径**: `config/schedule.rb` (whenever gem)

```ruby
# 清理过期的任务编辑锁
every 1.hour do
  runner "TaskLockCleanupJob.perform_now"
end

```

### 7.2 后台任务

**文件路径**: `app/jobs/task_lock_cleanup_job.rb`

```ruby
class TaskLockCleanupJob < ApplicationJob
  queue_as :default

  def perform
    # 清理过期的任务编辑锁
    TaskLock.where('expires_at < ?', Time.current)
            .where(is_locked: true)
            .update_all(
              is_locked: false,
              locked_by: nil,
              locked_at: nil,
              expires_at: nil
            )
  end
end
```

### 7.3 事件通知

#### 7.3.1 通知机制概述

任务模块通过 WebSocket 实时通知用户任务状态变更。通知流程如下：

1. **后端发送通知**: 任务状态变更时，调用 `NotificationHelper` 发送通知
2. **异步处理**: 通过 `NotificationJob` 异步处理通知，避免阻塞主流程
3. **WebSocket 推送**: `NotificationHelper` 调用 `WebNotificationChannel` 通过 WebSocket 发送给在线用户
4. **前端接收**: 前端 `notificationStore` 订阅 `WebNotificationChannel` 并处理通知

#### 7.3.2 通知发送流程

**文件路径**: `app/helpers/notification_helper.rb`

```ruby
# 推送消息入口，封装各平台的消息推送调用
def self.push_notification(users_ids, message, payload, user_id)
  users = User.where(id: users_ids)
  users.each do |user|
    # 本地化消息内容
    localized_message = I18n.t(message, **params)
    
    # 通过 WebSocket 发送通知（仅发送给在线用户）
    WebNotificationChannel.send_message([user], localized_message, payload, user_id)
    
    # 发送 APNS 推送通知（移动端）
    push_apns_notification([user.id], message, payload, user_id)
  end
end
```

**文件路径**: `app/jobs/notification_job.rb`

```ruby
class NotificationJob < ApplicationJob
  queue_as :default
  
  def perform(users_ids, message, payload, user_id)
    NotificationHelper.push_notification(users_ids, message, payload, user_id)
  end
end
```

**文件路径**: `app/channels/web_notification_channel.rb`

```ruby
class WebNotificationChannel < ApplicationCable::Channel
  def subscribed
    user = current_user
    stream_for user  # 订阅用户专属频道
    set_connection_status(user, true)
  end
  
  # 发送消息给指定用户
  def self.send_message(users, message, payload, user_id)
    users.each do |user|
      # 检查用户是否在线
      if has_websocket_connection?(user)
        broadcast_to(user, { 
          message: message, 
          payload: payload, 
          user_id: user_id 
        })
      end
    end
  end
end
```

#### 7.3.3 任务通知类型

任务模块支持以下通知类型：

| 通知类型 | Action 值 | 触发时机 | 通知对象 |
|---------|-----------|---------|---------|
| 任务创建 | `task_create` | 创建任务时 | 任务负责人 |
| 任务成功 | `task_succeed` | 任务成功完成时 | 任务相关人 |
| 任务失败 | `task_fail` | 任务失败时 | 任务相关人 |
| 任务中止 | `task_abort` | 任务中止时 | 任务相关人 |

**文件路径**: `app/helpers/notification_helper.rb`

```ruby
def self.send_task_create_notification(task)
  # 通知任务负责人（如果已指定）
  if task.assignee_id
    NotificationJob.perform_later(
      user_ids: [task.assignee_id],
      message: {
        title: ['notification.task.create.title'],
        body: ['notification.task.create.body', { task_title: task.title }]
      },
      payload: { 
        action: 'task_create',
        task_id: task.id 
      },
      user_id: task.assignor_id
    )
  end
end
```

### 7.4 WebSocket 事件

**文件路径**: `app/channels/task_edit_channel.rb`

```ruby
class TaskEditChannel < ApplicationCable::Channel
  def subscribed
    task_id = params[:task_id]
    stream_from "task_edit_#{task_id}"
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
    task = Task.find(data['task_id'])
    result = task.acquire_edit_lock(current_user)
    
    if result[:success]
      broadcast_to_task(task.id, {
        type: 'lock_acquired',
        user: current_user.to_sample_json,
        lock: result[:lock].to_json
      })
    else
      transmit({
        type: 'lock_failed',
        error: result[:error]
      })
    end
  end
end
```

---

## 8. 任务协作编辑

任务协作编辑功能支持多用户实时协作编辑任务，包括实时字段同步、临时任务管理、状态同步等功能。

**详细文档**: [任务协作编辑 - 后端文档](./task_collaboration.md)

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN后端开发团队

