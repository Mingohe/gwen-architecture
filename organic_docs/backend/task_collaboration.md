# 任务协作编辑 - 后端文档

> **返回**: [文档首页](../../README.md)  
> **相关文档**: [任务管理模块 - 后端文档](./task.md) | [任务管理模块 - 前端文档](../frontend/task.md) | [任务协作编辑 - 前端文档](../frontend/task_collaboration.md)

## 功能概述

本系统实现了任务协作编辑功能，支持多用户实时协作编辑任务，包括：

1. **实时字段同步**：支持已保存任务和临时任务的所有字段（title、description、assignee_id、coins等）的实时编辑同步
2. **临时任务管理**：支持临时任务的创建、更新、删除和保存（转换为持久化任务）
3. **状态同步**：支持用户重连后自动同步最新状态（锁状态、临时任务列表）
4. **编辑者管理**：支持编辑者退订时清理缓存并通知其他观察者

## 核心模块

### 1. TaskEditChannel

**位置**：`app/channels/task_edit_channel.rb`

**职责**：
- 处理 WebSocket 消息的接收和分发
- 验证用户权限
- 广播消息给所有订阅者
- 管理订阅者列表
- 管理临时任务在 Redis 中的存储

**主要方法**：

#### 1.1 消息处理方法

- `task_field_updated(data)`: 处理任务字段更新请求
- `task_temp_added(data)`: 处理临时任务添加请求
- `task_temp_deleted(data)`: 处理临时任务删除请求
- `task_temp_saved_notify(data)`: 处理临时任务保存通知
- `task_deleted_notify(data)`: 处理任务删除通知
- `status_request(data)`: 处理状态请求
- `temp_tasks_request(data)`: 处理临时任务列表请求

#### 1.2 广播方法

- `broadcast_task_field_updated(...)`: 广播任务字段更新
- `broadcast_task_temp_added(...)`: 广播临时任务添加
- `broadcast_task_temp_deleted(...)`: 广播临时任务删除
- `broadcast_task_temp_saved_notify(...)`: 广播临时任务保存通知
- `broadcast_task_deleted_notify(...)`: 广播任务删除通知
- `broadcast_status_refresh_request`: 广播状态刷新请求

#### 1.3 Redis 管理方法

- `get_temp_tasks_for_task(task_id)`: 获取任务的临时任务列表
- `remove_temp_task_from_redis(root_task_id, temp_id)`: 从 Redis 删除特定临时任务
- `update_temp_task_in_redis(temp_id, changed_fields)`: 更新 Redis 中的临时任务数据
- `cleanup_task_edit_redis_data(task_id)`: 清理任务的所有 Redis 数据

#### 1.4 订阅管理方法

- `subscribed`: 处理用户订阅
- `unsubscribed`: 处理用户退订
- `remove_subscriber`: 从订阅者列表移除用户

### 2. Task 模型

**位置**：`app/models/task.rb`

**关键方法**：

- `can_be_edited_by?(user)`: 判断用户是否可以编辑任务
  - 如果没有锁，作者可以编辑
  - 如果有锁，只有锁持有者或锁分配者可以编辑（根据锁状态）

### 3. TaskLock 模型

**位置**：`app/models/task_lock.rb`

**职责**：
- 管理任务的锁状态
- 存储锁的持有者信息
- 管理锁的生命周期

**锁状态**：
- `no_lock`: 无锁状态（作者可以编辑）
- `open`: 锁已打开（任何有权限的用户可以获取）
- `locked`: 锁已锁定（只有锁持有者可以编辑）

### 4. TaskController

**位置**：`app/controllers/task_controller.rb`

**职责**：
- 处理任务发布时的 Redis 清理
- 处理根任务删除时的 Redis 清理

**关键方法**：
- `publish`: 任务发布时清理 Redis 数据
- `delete`: 根任务删除时清理 Redis 数据

## 存储结构

### Redis 数据结构

#### 1. 订阅者列表

**Key 格式**：`task_edit_subscribers:{task_id}`

**数据结构**：Set

**存储内容**：
```json
{
  "id": 7,
  "account": "user_account",
  "avatar": "http://..."
}
```

**用途**：存储当前订阅该任务的用户列表（多服务器共享）

**过期时间**：24小时

**生命周期**：
- **创建**：用户订阅 `TaskEditChannel` 时
- **更新**：用户订阅/退订时
- **删除**：
  - 任务发布时
  - 根任务删除时
  - 编辑者退订时（清空所有数据）

#### 2. 临时任务列表

**Key 格式**：`task_edit_temp_tasks:{task_id}`

**数据结构**：Set

**存储内容**：
```json
{
  "temp_id": "new_a1b2c3d4e5f6789012345678901234567890",
  "task_data": {
    "title": "临时任务",
    "description": "描述",
    "assignee_id": 456,
    "coins": 100,
    "task_type": 5,
    "parent_id": 123
  },
  "created_by": {
    "id": 7,
    "account": "user_account",
    "display_name": "用户名称"
  },
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**用途**：存储临时任务数据（仅 `isNew=true` 的任务），用于重连同步

**过期时间**：24小时

**生命周期**：
- **创建**：编辑者添加临时任务时（`task_temp_added`）
- **更新**：编辑者更新临时任务字段时（`task_field_updated` with `is_temp: true`）
- **删除**：
  - 临时任务保存为持久化任务时（`task_temp_saved_notify`）
  - 编辑者删除临时任务时（`task_temp_deleted`）
  - 任务发布时
  - 根任务删除时
  - 编辑者退订时（清空所有数据）

### 数据库结构

#### TaskLock 表

**表名**：`task_locks`

**关键字段**：
- `task_id`: 任务ID
- `status`: 锁状态（no_lock/open/locked）
- `locked_by_id`: 锁持有者ID
- `assignor_id`: 锁分配者ID

**用途**：持久化存储任务的锁信息（多服务器共享）

**生命周期**：
- **创建**：任务作者分享编辑权限时
- **更新**：用户获取/释放/回收锁时
- **删除**：任务删除时（级联删除）

## 模块运作机制

### 1. 实时字段同步机制

**流程**：
1. 前端发送 `task_field_updated` 消息
2. `TaskEditChannel#task_field_updated` 接收消息
3. 验证用户权限（`@task.can_be_edited_by?(current_user)`）
4. 如果是临时任务，更新 Redis 缓存（`update_temp_task_in_redis`）
5. 广播 `task_field_updated` 消息给所有订阅者
6. 返回成功响应

**关键点**：
- 临时任务字段更新会同步到 Redis，确保重连后能看到最新数据
- 已保存任务字段更新不存储到 Redis（数据已在数据库中）

### 2. 临时任务管理机制

#### 2.1 临时任务添加

**流程**：
1. 前端发送 `task_temp_added` 消息
2. `TaskEditChannel#task_temp_added` 接收消息
3. 验证用户权限
4. 调用 `broadcast_task_temp_added`：
   - 存储临时任务到 Redis（`task_edit_temp_tasks:{task_id}`）
   - 广播 `task_temp_added` 消息给所有订阅者
5. 返回成功响应

#### 2.2 临时任务更新

**流程**：
1. 前端发送 `task_field_updated` 消息（`is_temp: true`）
2. `TaskEditChannel#task_field_updated` 接收消息
3. 验证用户权限
4. 调用 `update_temp_task_in_redis` 更新 Redis 缓存
5. 广播 `task_field_updated` 消息给所有订阅者
6. 返回成功响应

#### 2.3 临时任务删除

**流程**：
1. 前端发送 `task_temp_deleted` 消息
2. `TaskEditChannel#task_temp_deleted` 接收消息
3. 验证用户权限
4. 调用 `broadcast_task_temp_deleted`：
   - 从 Redis 删除临时任务（`remove_temp_task_from_redis`）
   - 广播 `task_temp_deleted` 消息给所有订阅者
5. 返回成功响应

#### 2.4 临时任务保存

**流程**：
1. 前端调用 REST API `TaskCreateApi` 保存任务
2. 前端收到成功响应后，发送 `task_temp_saved_notify` 消息
3. `TaskEditChannel#task_temp_saved_notify` 接收消息
4. 验证用户权限
5. 从 Redis 删除临时任务（`remove_temp_task_from_redis`）
6. 广播 `task_temp_saved` 消息给所有订阅者（包含 `temp_id` 和 `task_id`）
7. 返回成功响应

### 3. 状态同步机制

#### 3.1 临时任务列表请求

**流程**：
1. 前端发送 `temp_tasks_request` 消息
2. `TaskEditChannel#temp_tasks_request` 接收消息
3. 从 Redis 获取临时任务列表（`get_temp_tasks_for_task`）
4. 返回 `temp_tasks_request_response` 响应（包含临时任务列表）

#### 3.2 状态刷新请求（编辑者退订时）

**流程**：
1. 编辑者退订时，`unsubscribed` 被调用
2. `remove_subscriber` 判断是否为编辑者（`@task.can_be_edited_by?(current_user)`）
3. 如果是编辑者：
   - 清空 Redis 缓存（`cleanup_task_edit_redis_data`）
   - 如果还有其他订阅者，调用 `broadcast_status_refresh_request`
4. `broadcast_status_refresh_request` 从 Redis 获取临时任务列表（此时应为空）
5. 广播 `status_refresh_request` 消息给其他订阅者（包含空的临时任务列表）

### 4. 订阅管理机制

#### 4.1 用户订阅

**流程**：
1. 前端订阅 `TaskEditChannel`
2. `subscribed` 方法被调用
3. 将用户添加到 Redis 订阅者列表（`task_edit_subscribers:{task_id}`）
4. 广播 `user_subscribed` 消息给其他订阅者
5. 发送 `subscribed` 响应给当前用户（包含锁状态和订阅者列表）

#### 4.2 用户退订

**流程**：
1. 前端退订 `TaskEditChannel`
2. `unsubscribed` 方法被调用
3. `remove_subscriber` 从 Redis 订阅者列表移除用户
4. 判断是否为编辑者（`@task.can_be_edited_by?(current_user)`）
5. 如果是编辑者：
   - 清空 Redis 缓存（`cleanup_task_edit_redis_data`）
   - 如果还有其他订阅者，广播 `status_refresh_request`
6. 广播 `user_unsubscribed` 消息给其他订阅者

## 完整生命周期

### 1. 任务协作编辑生命周期

```
1. 任务作者分享编辑权限
   ↓
2. 创建 TaskLock（status: open）
   ↓
3. 用户订阅 TaskEditChannel
   ↓
4. 用户获取锁（status: locked）
   ↓
5. 用户编辑任务（实时同步）
   ↓
6. 用户添加临时任务（存储到 Redis）
   ↓
7. 用户编辑临时任务（更新 Redis）
   ↓
8. 用户保存临时任务（从 Redis 删除，转换为持久化任务）
   ↓
9. 用户释放锁（status: open）
   ↓
10. 用户退订（如果是编辑者，清空 Redis）
```

### 2. 临时任务生命周期

```
1. 编辑者添加临时任务
   ↓
2. 存储到 Redis（task_edit_temp_tasks:{task_id}）
   ↓
3. 广播给其他观察者
   ↓
4. 编辑者更新临时任务字段
   ↓
5. 更新 Redis 缓存
   ↓
6. 广播给其他观察者
   ↓
7. 编辑者保存临时任务
   ↓
8. 从 Redis 删除临时任务
   ↓
9. 广播保存通知给其他观察者（包含 temp_id 和 task_id）
```

### 3. Redis 数据生命周期

#### 订阅者列表

```
创建：用户订阅时
  ↓
更新：用户订阅/退订时
  ↓
删除：任务发布/根任务删除/编辑者退订时
```

#### 临时任务列表

```
创建：编辑者添加临时任务时
  ↓
更新：编辑者更新临时任务字段时
  ↓
删除：临时任务保存/删除/任务发布/根任务删除/编辑者退订时
```

## WebSocket API 接口

### 客户端发送消息

#### 1. task_field_updated

**功能**：更新任务字段（支持已保存任务和临时任务）

**消息格式**：
```json
{
  "action": "task_field_updated",
  "task_id": 123,  // 已保存任务ID（临时任务为 null）
  "is_temp": false,  // 是否为临时任务
  "temp_id": null,  // 临时任务ID（已保存任务为 null）
  "changed_fields": {
    "title": "新标题",
    "assignee_id": 456,
    "coins": 100
  },
  "seq": 1
}
```

**响应格式**：
```json
{
  "action": "task_field_updated_response",
  "task_id": 123,
  "status": 0,
  "timestamp": "2024-01-01T00:00:00Z",
  "seq": 1
}
```

**权限要求**：用户必须可以编辑任务（`can_be_edited_by?` 返回 true）

#### 2. task_temp_added

**功能**：添加临时任务

**消息格式**：
```json
{
  "action": "task_temp_added",
  "temp_id": "new_a1b2c3d4e5f6789012345678901234567890",
  "task_data": {
    "title": "临时任务",
    "description": "描述",
    "assignee_id": 456,
    "coins": 100,
    "task_type": 5,
    "parent_id": 123
  },
  "seq": 1
}
```

**响应格式**：
```json
{
  "action": "task_temp_added_response",
  "task_id": 123,
  "status": 0,
  "timestamp": "2024-01-01T00:00:00Z",
  "seq": 1
}
```

**权限要求**：用户必须可以编辑任务

#### 3. task_temp_deleted

**功能**：删除临时任务

**消息格式**：
```json
{
  "action": "task_temp_deleted",
  "temp_id": "new_a1b2c3d4e5f6789012345678901234567890",
  "seq": 1
}
```

**响应格式**：
```json
{
  "action": "task_temp_deleted_response",
  "task_id": 123,
  "status": 0,
  "timestamp": "2024-01-01T00:00:00Z",
  "seq": 1
}
```

**权限要求**：用户必须可以编辑任务

#### 4. task_temp_saved_notify

**功能**：通知临时任务已保存（转换为持久化任务）

**消息格式**：
```json
{
  "action": "task_temp_saved_notify",
  "temp_id": "new_a1b2c3d4e5f6789012345678901234567890",
  "task_id": 456,
  "seq": 1
}
```

**响应格式**：
```json
{
  "action": "task_temp_saved_notify_response",
  "task_id": 123,
  "status": 0,
  "timestamp": "2024-01-01T00:00:00Z",
  "seq": 1
}
```

**权限要求**：用户必须可以编辑任务

#### 5. task_deleted_notify

**功能**：通知任务已删除

**消息格式**：
```json
{
  "action": "task_deleted_notify",
  "task_id": 456,
  "seq": 1
}
```

**响应格式**：
```json
{
  "action": "task_deleted_notify_response",
  "task_id": 123,
  "status": 0,
  "timestamp": "2024-01-01T00:00:00Z",
  "seq": 1
}
```

**权限要求**：用户必须可以编辑任务

#### 6. temp_tasks_request

**功能**：请求临时任务列表

**消息格式**：
```json
{
  "action": "temp_tasks_request",
  "seq": 1
}
```

**响应格式**：
```json
{
  "action": "temp_tasks_request_response",
  "task_id": 123,
  "status": 0,
  "data": {
    "temp_tasks": [
      {
        "temp_id": "new_a1b2c3d4e5f6789012345678901234567890",
        "task_data": {
          "title": "临时任务",
          "description": "描述",
          "assignee_id": 456,
          "coins": 100
        },
        "created_by": {
          "id": 7,
          "account": "user_account",
          "display_name": "用户名称"
        },
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z"
      }
    ]
  },
  "timestamp": "2024-01-01T00:00:00Z",
  "seq": 1
}
```

### 服务器广播消息

#### 1. task_field_updated

**触发时机**：任务字段更新时

**消息格式**：
```json
{
  "action": "task_field_updated",
  "task_id": 123,
  "root_task_id": 123,
  "is_temp": false,
  "temp_id": null,
  "changed_fields": {
    "title": "新标题"
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### 2. task_temp_added

**触发时机**：临时任务添加时

**消息格式**：
```json
{
  "action": "task_temp_added",
  "root_task_id": 123,
  "temp_id": "new_a1b2c3d4e5f6789012345678901234567890",
  "task_data": {
    "title": "临时任务",
    "description": "描述",
    "assignee_id": 456,
    "coins": 100,
    "task_type": 5,
    "parent_id": 123
  },
  "created_by": {
    "id": 7,
    "account": "user_account",
    "display_name": "用户名称"
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### 3. task_temp_deleted

**触发时机**：临时任务删除时

**消息格式**：
```json
{
  "action": "task_temp_deleted",
  "root_task_id": 123,
  "temp_id": "new_a1b2c3d4e5f6789012345678901234567890",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### 4. task_temp_saved

**触发时机**：临时任务保存时

**消息格式**：
```json
{
  "action": "task_temp_saved",
  "root_task_id": 123,
  "temp_id": "new_a1b2c3d4e5f6789012345678901234567890",
  "task_id": 456,
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### 5. task_deleted

**触发时机**：任务删除时

**消息格式**：
```json
{
  "action": "task_deleted",
  "root_task_id": 123,
  "deleted_task_id": 456,
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### 6. status_refresh_request

**触发时机**：编辑者退订且还有其他订阅者时

**消息格式**：
```json
{
  "action": "status_refresh_request",
  "task_id": 123,
  "temp_tasks": [],
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### 7. user_subscribed

**触发时机**：用户订阅时

**消息格式**：
```json
{
  "action": "user_subscribed",
  "task_id": 123,
  "user": {
    "id": 7,
    "account": "user_account",
    "avatar": "http://..."
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### 8. user_unsubscribed

**触发时机**：用户退订时

**消息格式**：
```json
{
  "action": "user_unsubscribed",
  "task_id": 123,
  "user": {
    "id": 7,
    "account": "user_account",
    "avatar": "http://..."
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## REST API 接口

### 1. 分享编辑权限

**接口**：`POST /task/share_editing_permission`

**功能**：任务作者分享编辑权限，创建 TaskLock

**参考**：详见 `task_edit_api_reference.md`

### 2. 获取锁状态

**接口**：`GET /task/get_lock_status`

**功能**：获取任务的锁状态信息

**参考**：详见 `task_edit_api_reference.md`

### 3. 任务发布

**接口**：`POST /task/publish`

**功能**：发布任务，清理 Redis 协作编辑数据

**关键逻辑**：
- 调用 `cleanup_task_edit_redis_data(task.id)` 清理 Redis 数据

### 4. 任务删除

**接口**：`DELETE /task/:id`

**功能**：删除任务，如果是根任务则清理 Redis 协作编辑数据

**关键逻辑**：
- 如果是根任务，调用 `cleanup_task_edit_redis_data(ret.id)` 清理 Redis 数据

## 响应格式规范

### 成功响应

所有成功响应不包含 `error` 字段，通过 `error` 字段不存在来判断成功：

```json
{
  "action": "{action}_response",
  "task_id": 123,
  "status": 0,
  "data": { ... },
  "timestamp": "2024-01-01T00:00:00Z",
  "seq": 1
}
```

### 错误响应

所有错误响应包含 `error` 字段：

```json
{
  "action": "{action}_response",
  "status": 1,
  "error": "错误信息",
  "timestamp": "2024-01-01T00:00:00Z",
  "seq": 1
}
```

### 广播消息

广播消息使用原始 action 名称（不加 `_response` 后缀）：

```json
{
  "action": "task_field_updated",
  "task_id": 123,
  "root_task_id": 123,
  ...
  "timestamp": "2024-01-01T00:00:00Z"
}
```

