# 会议系统模块 - 后端文档

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

会议系统模块负责：

- **会议生命周期管理**: 从预约到完成的完整流程
- **参与者管理**: 邀请、确认、拒绝参与者
- **会议笔记管理**: 实时协作编辑会议笔记
- **会议摘要**: 生成和确认会议摘要

---

## 2. 数据模型（Model/Schema）

### 2.1 Meeting 模型

```ruby
class Meeting < ApplicationRecord
  belongs_to :task
  belongs_to :creator, class_name: "User"
  has_many :participants, class_name: "Meeting::Participant"
  has_many :notes, class_name: "Meeting::Note"

  # 状态枚举
  STATUS_OK = 0           # 普通状态
  STATUS_CANCELED = 1     # 取消/删除
  STATUS_ON_GOING = 2     # 正在开会
  STATUS_FINISHED = 3    # 会议完成
  STATUS_CONFIRMING = 4   # 会议正在确认摘要
end
```

---

## 3. API 规范（Controller/Route）

### 3.1 预约会议

```ruby
# POST /meeting/reserve
def reserve
  meeting_params = params.permit(:task_id, :topic, :start_time, :end_time, participants: [])
  meeting = Meeting.create!(meeting_params.merge(creator_id: current_user.id))
  render_success({ meeting: meeting.to_json })
end
```

---

## 4. 业务逻辑流程

### 4.1 会议创建流程

```ruby
def self.create_meeting(user, params)
  ActiveRecord::Base.transaction do
    meeting = Meeting.create!(params.merge(creator_id: user.id))
    # 创建参与者记录
    params[:participants].each do |user_id|
      Meeting::Participant.create!(meeting: meeting, user_id: user_id)
    end
    { success: true, meeting: meeting }
  end
end
```

---

## 5. 权限与鉴权规则

- 会议创建者可以编辑和取消会议
- 参与者可以查看会议详情

---

## 6. 错误码和响应规范

标准响应格式，参考通用规范。

---

## 7. 定时任务/队列处理/事件

### 7.1 事件通知

#### 7.1.1 通知机制概述

会议模块通过 WebSocket 实时通知用户会议状态变更。通知流程与任务模块相同：

1. **后端发送通知**: 会议状态变更时，调用 `NotificationHelper` 发送通知
2. **异步处理**: 通过 `NotificationJob` 异步处理通知
3. **WebSocket 推送**: `NotificationHelper` 调用 `WebNotificationChannel` 通过 WebSocket 发送给在线用户
4. **前端接收**: 前端 `notificationStore` 订阅 `WebNotificationChannel` 并处理通知

#### 7.1.2 会议通知类型

会议模块支持以下通知类型：

| 通知类型 | Action 值 | 触发时机 | 通知对象 |
|---------|-----------|---------|---------|
| 会议预约 | `meeting_reserve` | 预约会议时 | 所有参与者 |
| 会议开始 | `meeting_start` | 开始会议时 | 所有参与者 |
| 会议取消 | `meeting_cancel` | 取消会议时 | 所有参与者 |
| 会议关闭 | `meeting_close` | 关闭会议时 | 所有参与者 |

#### 7.1.3 通知发送示例

**文件路径**: `app/controllers/meeting_controller.rb`

```ruby
# 预约会议时发送通知
def reserve
  # ... 创建会议逻辑 ...
  
  # 通知所有参与者
  user_ids = (participants + auditors).uniq
  task = Task.find(task_id)
  project = Project.find(task.project_id)
  
  alert = {
    title: ['project_message.name', { name: project.name }],
    body: ['meeting_message.reserve', { name: task.title }],
  }
  
  NotificationJob.perform_later(
    user_ids, 
    alert, 
    { 
      action: Meeting::NOTIFY_RESERVE, 
      id: meeting_id, 
      meeting_id: meeting_id, 
      task_id: task.id 
    }, 
    current_user.id
  )
end

# 开始会议时发送通知
def start
  meeting = Meeting.find(meeting_id)
  meeting.update_status_going
  
  users_ids = meeting.participants.pluck(:user_id)
  task = Task.find(meeting.task_id)
  project = Project.find(task.project_id)
  
  alert = {
    title: ['project_message.name', { name: project.name }],
    body: ['meeting_message.start', { name: task.title }],
  }
  
  NotificationJob.perform_later(
    users_ids, 
    alert, 
    { 
      action: Meeting::NOTIFY_START, 
      id: meeting_id, 
      meeting_id: meeting_id, 
      task_id: task.id 
    }, 
    current_user.id
  )
end

# 取消会议时发送通知
def cancel
  meeting = Meeting.find(meeting_id)
  meeting.update_status_cancel
  
  users_ids = meeting.participants.pluck(:user_id)
  task = Task.find(meeting.task_id)
  project = Project.find(task.project_id)
  
  alert = {
    title: ['project_message.name', { name: project.name }],
    body: ['meeting_message.cancel', { name: task.title }],
  }
  
  NotificationJob.perform_later(
    users_ids, 
    alert, 
    { 
      action: Meeting::NOTIFY_CANCEL, 
      id: meeting_id, 
      meeting_id: meeting_id, 
      task_id: task.id 
    }, 
    current_user.id
  )
end
```

**注意**: 通知机制的具体实现请参考 [任务模块文档 - 7.3 事件通知](./task.md#73-事件通知) 中的详细说明。

### 7.2 WebSocket 事件

#### 7.2.1 会议实时协作 Channel

**文件路径**: `app/channels/meeting_channel.rb`

```ruby
class MeetingChannel < ApplicationCable::Channel
  def subscribed
    meeting_id = params[:meeting_id]
    stream_from "meeting_#{meeting_id}"
  end
  
  # 处理会议内的实时消息（如笔记更新、状态变更等）
  def receive(data)
    case data['action']
    when 'note_update'
      handle_note_update(data)
    when 'status_update'
      handle_status_update(data)
    end
  end
end
```

#### 7.2.2 会议通知 Channel

会议通知通过 `WebNotificationChannel` 发送，与任务通知使用相同的机制。详细说明请参考 [任务模块文档 - 7.3 事件通知](./task.md#73-事件通知)。

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN后端开发团队

