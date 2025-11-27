# 任务协作编辑 - 前端文档

> **返回**: [文档首页](../../README.md)  
> **相关文档**: [任务管理模块 - 前端文档](./task.md) | [任务管理模块 - 后端文档](../backend/task.md) | [任务协作编辑 - 后端文档](../backend/task_collaboration.md)

## 功能概述

前端实现了任务协作编辑的实时同步功能，支持：

1. **实时字段同步**：监听并处理任务字段的实时更新（包括根任务和子任务）
2. **临时任务管理**：处理临时任务的添加、更新、删除和保存（转换为持久化任务）
3. **状态同步**：重连后自动请求并同步最新状态
4. **防抖处理**：字段更新使用防抖机制，避免频繁发送消息

## 核心模块

### 1. TaskEditStore

**位置**：`src/store/modules/taskEdit.ts`

**职责**：
- 管理 WebSocket 连接和订阅
- 处理 WebSocket 消息的发送和接收
- 管理任务锁状态
- 管理订阅者列表
- 提供任务编辑相关的 API 方法

**主要方法**：

#### 1.1 订阅管理

- `subscribeTaskEditChannel(taskId)`: 订阅任务编辑频道
- `unsubscribeTaskEditChannel(taskId)`: 退订任务编辑频道
- `isTaskSubscribed(taskId)`: 检查任务是否已订阅
- `resubscribeAllTaskEditChannels()`: 重连后重新订阅所有频道

#### 1.2 消息发送

- `updateTaskField(rootTaskId, subTaskId, isTemp, tempId, changedFields)`: 发送任务字段更新消息
- `addTempTask(rootTaskId, tempId, taskData)`: 发送临时任务添加消息
- `deleteTempTask(rootTaskId, tempId)`: 发送临时任务删除消息
- `notifyTempTaskSaved(rootTaskId, tempId, savedTaskId)`: 通知临时任务已保存
- `notifyTaskDeleted(rootTaskId, deletedTaskId)`: 通知任务已删除
- `requestTempTasks(rootTaskId)`: 请求临时任务列表
- `requestTempTasksAndSync(rootTaskId)`: 请求临时任务列表并同步

#### 1.3 状态管理

- `getTaskLockStatus(taskId)`: 获取任务锁状态
- `getSubscribers(taskId)`: 获取订阅者列表

#### 1.4 消息处理

- `handleTaskEditMessage(message)`: 处理接收到的 WebSocket 消息
  - `task_field_updated`: 任务字段更新
  - `task_temp_added`: 临时任务添加
  - `task_temp_deleted`: 临时任务删除
  - `task_temp_saved`: 临时任务保存
  - `task_deleted`: 任务删除
  - `status_refresh_request`: 状态刷新请求
  - `user_subscribed`: 用户订阅
  - `user_unsubscribed`: 用户退订

### 2. TaskTreeEditMain 组件

**位置**：`src/components/TaskPanel/TaskTreeEditMain.vue`

**职责**：
- 渲染任务树编辑界面
- 处理用户编辑操作
- 监听 WebSocket 事件并更新 UI
- 实现防抖机制

**主要功能**：

#### 2.1 根任务编辑

- `updateRootTask(updated)`: 更新根任务，支持实时同步
  - 计算变更字段
  - 防抖处理（500ms）
  - 发送 `updateTaskField` 消息

#### 2.2 子任务编辑

- `updateSubTaskById(taskId, updated)`: 更新子任务，支持实时同步
  - 计算变更字段
  - 防抖处理（500ms）
  - 发送 `updateTaskField` 消息

#### 2.3 临时任务管理

- `addSubTask()`: 添加临时子任务
  - 生成 `_stableId`
  - 添加到本地列表
  - 发送 `addTempTask` 消息

- `deleteSubTaskById(taskId)`: 删除子任务
  - 如果是临时任务，发送 `deleteTempTask` 消息
  - 如果是已保存任务，调用 REST API 删除，成功后发送 `notifyTaskDeleted` 消息

#### 2.4 任务保存

- `saveAllTasks()`: 保存所有任务
  - 临时任务：调用 REST API 创建，成功后发送 `notifyTempTaskSaved` 消息
  - 已保存任务：调用 REST API 更新

#### 2.5 事件监听

- `handleTaskFieldUpdated`: 处理任务字段更新事件
- `handleTempTaskAdded`: 处理临时任务添加事件
- `handleTempTaskDeleted`: 处理临时任务删除事件
- `handleTempTaskSaved`: 处理临时任务保存事件
- `handleTempTasksSynced`: 处理临时任务同步事件

### 3. UUID 工具

**位置**：`src/utils/uuid.ts`

**功能**：生成 `_stableId`

**方法**：

- `buildStableTaskId(prefix, taskId?)`: 生成稳定的任务 ID
  - `prefix`: `'new'` 或 `'saved'`
  - `taskId`: 已保存任务的 ID（可选）

## 关键概念

### `_stableId`

`_stableId` 是前端用于追踪任务的稳定标识符，用于解决 Vue 组件 ref 映射和列表渲染的稳定性问题。

#### 生成规则

使用 `buildStableTaskId()` 函数生成，该函数基于 `buildUUID()` 实现，确保唯一性和规范性。

1. **临时任务（`isNew=true`）**：
   ```typescript
   import { buildStableTaskId } from '/@/utils/uuid';
   const stableId = buildStableTaskId('new');
   ```
   - 格式：`new_{uuid}`
   - 示例：`new_a1b2c3d4e5f6789012345678901234567890`
   - 特点：
     - 使用标准 UUID（32位十六进制）确保唯一性
     - 前缀 `new_` 标识为临时任务
     - 基于 `buildUUID()` 实现，规范可靠

2. **已保存任务（从后端加载）**：
   ```typescript
   import { buildStableTaskId } from '/@/utils/uuid';
   _stableId: buildStableTaskId('saved', subTask.id)
   ```
   - 格式：`saved_{task_id}_{uuid}`
   - 示例：`saved_123_a1b2c3d4e5f6789012345678901234567890`
   - 特点：
     - 使用任务 ID 作为主要标识
     - 添加 UUID 确保唯一性（即使同一任务多次加载）
     - 前缀 `saved_` 标识为已保存任务
     - 基于 `buildUUID()` 实现，规范可靠

#### 使用场景

- **Vue 组件 ref 映射**：使用 `_stableId` 作为 Map 的 key，确保即使任务 ID 变化，ref 映射仍然有效
- **列表渲染 key**：使用 `_stableId` 作为 `v-for` 的 key，确保组件稳定性
- **临时任务追踪**：临时任务保存后，保留 `_stableId` 用于 merge 操作

#### 注意事项

- `_stableId` 是前端本地生成的，不同用户之间不共享
- 临时任务的 `_stableId` 在创建时生成，保存后保留用于 merge
- 已保存任务的 `_stableId` 在加载时生成，每次加载可能不同（但同一任务在同一会话中应保持一致）

## 实现机制

### 1. 实时字段同步机制

#### 1.1 根任务字段更新

**流程**：
1. 用户编辑根任务字段（title、description等）
2. `updateRootTask` 被调用
3. 计算变更字段（对比原始值和更新值）
4. 防抖处理（500ms）
5. 调用 `taskEditStore.updateTaskField` 发送消息
6. 后端广播消息给其他观察者
7. 其他观察者收到消息后更新 UI

**代码示例**：
```typescript
function updateRootTask(updated: Task) {
  const originalTask = { ...rootTask };
  Object.assign(rootTask, updated);
  
  if (canEditForSync && taskEditStore.isTaskSubscribed(rootTask.id)) {
    const changedFields: any = {};
    Object.keys(updated).forEach(field => {
      if (updated[field] !== originalTask[field]) {
        changedFields[field] = updated[field];
      }
    });
    
    if (Object.keys(changedFields).length > 0) {
      const debounceKey = `root_${rootTask.id}_${Object.keys(changedFields).join('_')}`;
      if (fieldChangeDebounce.value.has(debounceKey)) {
        clearTimeout(fieldChangeDebounce.value.get(debounceKey)!);
      }
      
      const timeout = setTimeout(() => {
        taskEditStore.updateTaskField(
          rootTask.id,
          rootTask.id,
          false,
          null,
          changedFields
        ).catch(error => {
          console.error('根任务字段更新同步失败:', error);
        });
        fieldChangeDebounce.value.delete(debounceKey);
      }, 500);
      
      fieldChangeDebounce.value.set(debounceKey, timeout);
    }
  }
}
```

#### 1.2 子任务字段更新

**流程**：
1. 用户编辑子任务字段
2. `updateSubTaskById` 被调用
3. 计算变更字段
4. 防抖处理（500ms）
5. 调用 `taskEditStore.updateTaskField` 发送消息
6. 后端广播消息给其他观察者
7. 其他观察者收到消息后更新 UI

**代码示例**：
```typescript
function updateSubTaskById(taskId: number, updated: Partial<Task>) {
  const taskIndex = subTasks.value.findIndex(t => t.id === taskId);
  if (taskIndex === -1) return;
  
  const originalTask = { ...subTasks.value[taskIndex] };
  Object.assign(subTasks.value[taskIndex], updated);
  
  if (canEditForSync && taskEditStore.isTaskSubscribed(rootTask.id)) {
    const changedFields: any = {};
    Object.keys(updated).forEach(field => {
      if (updated[field] !== originalTask[field]) {
        changedFields[field] = updated[field];
      }
    });
    
    if (Object.keys(changedFields).length > 0) {
      const isTemp = subTasks.value[taskIndex].isNew;
      const subTaskId = isTemp ? null : subTasks.value[taskIndex].id;
      const tempId = isTemp ? subTasks.value[taskIndex]._stableId : null;
      
      const debounceKey = `${subTaskId || tempId}_${Object.keys(changedFields).join('_')}`;
      if (fieldChangeDebounce.value.has(debounceKey)) {
        clearTimeout(fieldChangeDebounce.value.get(debounceKey)!);
      }
      
      const timeout = setTimeout(() => {
        taskEditStore.updateTaskField(
          rootTask.id,
          subTaskId,
          isTemp,
          tempId,
          changedFields
        ).catch(error => {
          console.error('子任务字段更新同步失败:', error);
        });
        fieldChangeDebounce.value.delete(debounceKey);
      }, 500);
      
      fieldChangeDebounce.value.set(debounceKey, timeout);
    }
  }
}
```

### 2. 临时任务管理机制

#### 2.1 临时任务添加

**流程**：
1. 用户点击"添加子任务"
2. `addSubTask` 被调用
3. 生成 `_stableId`（`buildStableTaskId('new')`）
4. 创建临时任务对象（`isNew: true`）
5. 添加到本地列表
6. 调用 `taskEditStore.addTempTask` 发送消息
7. 后端存储到 Redis 并广播消息
8. 其他观察者收到消息后添加临时任务到列表

**代码示例**：
```typescript
function addSubTask() {
  const newTask: Task = {
    _stableId: buildStableTaskId('new'),
    isNew: true,
    title: '',
    description: '',
    // ... 其他字段
  };
  
  subTasks.value.unshift(newTask);
  
  if (canEditForSync && taskEditStore.isTaskSubscribed(rootTask.id)) {
    taskEditStore.addTempTask(
      rootTask.id,
      newTask._stableId,
      {
        title: newTask.title,
        description: newTask.description,
        assignee_id: newTask.assignee_id,
        coins: newTask.coins,
        task_type: newTask.task_type,
        parent_id: rootTask.id
      }
    ).catch(error => {
      console.error('实时同步临时任务添加失败:', error);
    });
  }
}
```

#### 2.2 临时任务更新

临时任务字段更新使用与已保存任务相同的机制（`updateTaskField`），通过 `is_temp: true` 标识。

#### 2.3 临时任务删除

**流程**：
1. 用户删除临时任务
2. `deleteSubTaskById` 被调用
3. 从本地列表移除
4. 调用 `taskEditStore.deleteTempTask` 发送消息
5. 后端从 Redis 删除并广播消息
6. 其他观察者收到消息后从列表移除

#### 2.4 临时任务保存

**流程**：
1. 用户点击"保存"
2. `saveAllTasks` 被调用
3. 对于临时任务，调用 REST API `TaskCreateApi` 创建任务
4. 收到成功响应后，更新本地任务（`isNew: false`, `id: createdTask.id`）
5. 调用 `taskEditStore.notifyTempTaskSaved` 发送消息
6. 后端从 Redis 删除临时任务并广播消息
7. 其他观察者收到消息后，将临时任务转换为已保存任务（更新 `id` 和 `isNew`）

**代码示例**：
```typescript
async function saveAllTasks() {
  for (const subTask of subTasks.value) {
    if (subTask.isNew) {
      const tempId = subTask._stableId;
      const createdTask = await taskPanelStore.createSubTask({
        parentId: rootTaskData.id,
        task: { ...subTask }
      });
      
      // 更新本地数据
      const taskIndex = subTasks.value.findIndex(t => t._stableId === tempId);
      if (taskIndex !== -1) {
        Object.assign(subTasks.value[taskIndex], {
          ...createdTask,
          isNew: false,
          id: createdTask.id,
          _stableId: tempId // 保留 _stableId
        });
      }
      
      // 发送保存通知
      if (taskEditStore.isTaskSubscribed(rootTaskData.id)) {
        taskEditStore.notifyTempTaskSaved(rootTaskData.id, tempId, createdTask.id)
          .catch(error => {
            console.error('临时任务保存通知发送失败:', error);
          });
      }
    }
  }
}
```

### 3. 状态同步机制

#### 3.1 重连后同步

**流程**：
1. WebSocket 重连成功
2. `resubscribeAllTaskEditChannels` 被调用
3. 重新订阅所有任务编辑频道
4. 延迟 500ms 后调用 `requestTempTasksAndSync`
5. 发送 `temp_tasks_request` 消息
6. 收到响应后，触发 `tempTasksSynced` 事件
7. `TaskTreeEditMain` 监听事件并同步临时任务列表

**代码示例**：
```typescript
// taskEdit.ts
const requestTempTasksAndSync = async (rootTaskId: number) => {
  try {
    const response = await requestTempTasks(rootTaskId);
    if (response.data?.temp_tasks) {
      const event = new CustomEvent('tempTasksSynced', {
        detail: {
          taskId: rootTaskId,
          tempTasks: response.data.temp_tasks,
          replace: false
        }
      });
      window.dispatchEvent(event);
    }
  } catch (error) {
    console.error('请求临时任务列表失败:', error);
  }
};

// TaskTreeEditMain.vue
const handleTempTasksSynced = (event: CustomEvent) => {
  const { taskId, tempTasks, replace } = event.detail;
  if (taskId !== rootTask.id) return;
  
  if (replace) {
    // 完全替换模式（编辑者退订时）
    subTasks.value = subTasks.value.filter(t => !t.isNew);
    tempTasks.forEach((tempTask: any) => {
      // 添加临时任务
    });
  } else {
    // 合并模式（重连同步时）
    tempTasks.forEach((tempTask: any) => {
      const existingIndex = subTasks.value.findIndex(t => t._stableId === tempTask.temp_id);
      if (existingIndex === -1) {
        // 添加新临时任务
      }
    });
  }
};
```

#### 3.2 状态刷新请求处理

**流程**：
1. 编辑者退订时，后端广播 `status_refresh_request` 消息
2. 前端收到消息后，触发 `tempTasksSynced` 事件（`replace: true`）
3. `TaskTreeEditMain` 监听事件并完全替换临时任务列表

### 4. 事件处理机制

#### 4.1 任务字段更新事件

**事件名**：`taskFieldUpdated`

**触发时机**：收到 `task_field_updated` 广播消息

**处理逻辑**：
1. 检查是否为根任务更新
2. 如果是根任务，更新 `rootTask`
3. 如果是子任务，查找并更新对应的子任务
4. 如果是临时任务，更新临时任务的字段
5. 如果是 `assignee_id` 变更，需要查找并设置 `assignee` 对象

**代码示例**：
```typescript
const handleTaskFieldUpdated = (event: CustomEvent) => {
  const { taskId, rootTaskId, isTemp, tempId, changedFields } = event.detail;
  if (rootTaskId !== rootTask.id) return;
  
  // 处理根任务更新
  if (taskId === rootTask.id) {
    Object.keys(changedFields).forEach(field => {
      rootTask[field] = changedFields[field];
    });
    return;
  }
  
  // 处理子任务更新
  const taskIndex = subTasks.value.findIndex(t => 
    isTemp ? t._stableId === tempId : t.id === taskId
  );
  
  if (taskIndex !== -1) {
    const task = subTasks.value[taskIndex];
    Object.keys(changedFields).forEach(field => {
      task[field] = changedFields[field];
    });
    
    // 处理 assignee_id 变更
    if (changedFields.assignee_id !== undefined) {
      const assigneeId = changedFields.assignee_id;
      if (assigneeId && fetchedOptions.value?.assignees) {
        const assignee = fetchedOptions.value.assignees.find((a: any) => a.id === assigneeId);
        if (assignee) {
          task.assignee = assignee;
        }
      } else {
        task.assignee = null;
      }
    }
  }
};
```

#### 4.2 临时任务添加事件

**事件名**：`tempTaskAdded`

**触发时机**：收到 `task_temp_added` 广播消息

**处理逻辑**：
1. 检查是否为当前用户自己创建的任务（通过 `createdBy.id` 判断）
2. 如果是自己创建的，跳过（避免重复添加）
3. 检查是否已存在（通过 `tempId` 判断）
4. 如果不存在，添加临时任务到列表
5. 根据 `assignee_id` 查找并设置 `assignee` 对象

#### 4.3 临时任务删除事件

**事件名**：`tempTaskDeleted`

**触发时机**：收到 `task_temp_deleted` 广播消息

**处理逻辑**：
1. 查找临时任务（通过 `tempId`）
2. 从列表中移除

#### 4.4 临时任务保存事件

**事件名**：`tempTaskSaved`

**触发时机**：收到 `task_temp_saved` 广播消息

**处理逻辑**：
1. 查找临时任务（通过 `tempId`）
2. 更新任务：`id = taskId`, `isNew = false`
3. 保留 `_stableId` 用于 ref 映射

#### 4.5 任务删除事件

**事件名**：`taskDeleted`

**触发时机**：收到 `task_deleted` 广播消息

**处理逻辑**：
1. 查找任务（通过 `deletedTaskId`）
2. 从列表中移除

## 防抖机制

### 实现原理

使用 `Map<string, NodeJS.Timeout>` 存储防抖定时器，key 为 `${taskId || tempId}_${field1}_${field2}_...`。

### 防抖时间

- **默认防抖时间**：500ms
- **防抖 key 格式**：
  - 根任务：`root_{rootTaskId}_{field1}_{field2}_...`
  - 子任务：`{taskId || tempId}_{field1}_{field2}_...`

### 代码示例

```typescript
const fieldChangeDebounce = ref<Map<string, NodeJS.Timeout>>(new Map());

function updateTaskField(task: Task, changedFields: any) {
  const debounceKey = `${task.id || task._stableId}_${Object.keys(changedFields).join('_')}`;
  
  // 清除之前的定时器
  if (fieldChangeDebounce.value.has(debounceKey)) {
    clearTimeout(fieldChangeDebounce.value.get(debounceKey)!);
  }
  
  // 设置新的定时器
  const timeout = setTimeout(() => {
    taskEditStore.updateTaskField(...);
    fieldChangeDebounce.value.delete(debounceKey);
  }, 500);
  
  fieldChangeDebounce.value.set(debounceKey, timeout);
}
```

## 使用示例

### 1. 订阅任务编辑频道

```typescript
import { useTaskEditStore } from '@/store/modules/taskEdit';

const taskEditStore = useTaskEditStore();

// 订阅任务编辑频道
taskEditStore.subscribeTaskEditChannel(taskId);
```

### 2. 更新任务字段

```typescript
// 更新根任务字段
updateRootTask({
  title: '新标题',
  description: '新描述'
});

// 更新子任务字段
updateSubTaskById(taskId, {
  title: '新标题',
  coins: 100
});
```

### 3. 添加临时任务

```typescript
addSubTask();
```

### 4. 保存临时任务

```typescript
async function saveTask() {
  const createdTask = await taskPanelStore.createSubTask({
    parentId: rootTask.id,
    task: tempTask
  });
  
  // 发送保存通知
  taskEditStore.notifyTempTaskSaved(rootTask.id, tempTask._stableId, createdTask.id);
}
```

### 5. 删除任务

```typescript
async function deleteTask(taskId: number) {
  await taskPanelStore.deleteTask({
    taskId: taskId,
    parentId: rootTask.id
  });
  
  // 发送删除通知
  taskEditStore.notifyTaskDeleted(rootTask.id, taskId);
}
```

## 注意事项

1. **防抖处理**：字段更新使用 500ms 防抖，避免频繁发送消息
2. **权限检查**：发送消息前需要检查用户是否有编辑权限
3. **去重处理**：接收消息时检查是否已存在，避免重复添加
4. **错误处理**：网络错误时不影响本地编辑体验
5. **`_stableId` 规则**：
   - 临时任务：`new_{uuid}`（使用 `buildStableTaskId('new')` 生成）
   - 已保存任务：`saved_{task_id}_{uuid}`（使用 `buildStableTaskId('saved', taskId)` 生成）
   - 基于标准 UUID（32位十六进制）确保唯一性
   - 不同用户之间不共享，仅用于前端本地追踪
6. **临时任务保存后保留 `_stableId`**：用于 Vue 组件 ref 映射和列表渲染稳定性

