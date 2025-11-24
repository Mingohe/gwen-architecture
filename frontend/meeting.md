# 会议系统模块 - 前端文档

> **返回**: [文档首页](../README.md)

## 目录

- [1. 概述](#1-概述)
- [2. 页面结构](#2-页面结构)
- [3. 组件结构](#3-组件结构)
- [4. Store 说明](#4-store-说明)
- [5. API 调用规范](#5-api-调用规范)
- [6. 交互流程](#6-交互流程)
- [7. UI 规范](#7-ui-规范)
- [8. 权限控制](#8-权限控制)

---

## 1. 概述

### 1.1 模块边界与目的

会议系统模块负责：

- **会议预约**: 创建和管理会议
- **参与者管理**: 邀请和管理会议参与者
- **会议笔记**: 实时协作编辑会议笔记
- **会议摘要**: 生成和确认会议摘要
- **实时协作**: 通过WebSocket实现实时通信

### 1.2 技术栈

- **框架**: Vue 3 + TypeScript
- **状态管理**: Pinia
- **UI组件**: Ant Design Vue
- **实时通信**: WebSocket (MeetingChannel)

---

## 2. 页面结构

### 2.1 页面列表

| 页面路径 | 路由名称 | 组件路径 | 说明 |
|---------|---------|---------|------|
| `/meeting/index` | `meeting` | `src/views/meeting/index.vue` | **会议列表页面** - 查看和管理所有会议 |

### 2.2 页面布局

#### 2.2.1 会议列表页面布局

**页面路径**: `/meeting/index`

**布局结构**:

```
会议列表页面 (/meeting/index)
├── PageHeader (页面头部)
│   ├── 图标 + 标题: "会议列表"
│   └── 额外操作区域 (预留)
└── ScrollContainer (滚动容器)
    └── Collapse (折叠面板)
        ├── CollapsePanel 1: "进行中的会议"
        │   └── List (会议列表)
        │       └── ListItem (会议项)
        │           ├── ListItemMeta (会议信息)
        │           │   ├── 任务标题
        │           │   ├── 会议状态标签
        │           │   ├── 参与者头像列表
        │           │   └── 会议时间
        │           └── actions (操作按钮)
        │               └── MeetingStatusTag (会议状态操作)
        └── CollapsePanel 2: "已完成的会议"
            └── List (会议列表)
                └── ListItem (会议项)
                    ├── 会议主题 + 任务标题
                    └── MeetingStatusTag (会议状态操作)
```

**布局特点**:

1. **页面头部区域**:
   - 显示页面标题和图标
   - 预留额外操作区域（可扩展）

2. **折叠面板区域**:
   - **进行中的会议** (CollapsePanel 1):
     - 显示未完成的会议（状态：CREATED、GOING、CONFIRMING）
     - 每个会议项显示：任务标题、状态标签、参与者、时间
     - 提供操作按钮（开始、取消、进入、查看详情）
   - **已完成的会议** (CollapsePanel 2):
     - 显示已完成的会议（状态：FINISHED）
     - 每个会议项显示：会议主题、任务标题、状态标签

3. **会议项信息展示**:
   - **任务标题**: 关联的任务名称
   - **会议状态标签**: 显示当前会议状态（预约中、进行中、确认中、已完成）
   - **参与者列表**: 显示参与者头像（最多显示部分）
   - **会议时间**: 显示会议更新时间，包含时区信息

**功能说明**:

| 功能区域 | 功能说明 |
|---------|---------|
| **会议列表** | 按状态分组显示会议（进行中/已完成） |
| **会议状态标签** | 根据会议状态显示不同操作按钮 |
| **会议操作** | 支持开始、取消、进入、查看详情等操作 |
| **参与者显示** | 显示会议参与者头像，便于快速识别 |
| **时间显示** | 显示会议更新时间，包含时区信息 |

#### 2.2.2 会议详情页面布局

会议详情通过 **Drawer（抽屉）** 或 **Modal（弹窗）** 展示：

**Drawer 模式** (`MeetingDrawer.vue`):
- 从右侧滑出，占据大部分屏幕
- 显示完整的会议信息：
  - 会议头部（标题、状态、时间）
  - 任务树（完整的任务树结构）
  - 会议笔记列表
  - 参与者列表
  - 会议操作按钮

**Modal 模式** (`MeetingModal.vue`):
- 居中弹窗，宽度 500px
- 显示会议摘要信息：
  - 会议基本信息
  - 会议摘要内容
  - 确认/编辑操作

### 2.3 路由配置

```typescript
// src/router/routes/modules/meeting.ts
const meeting: AppRouteModule = {
  path: '/meeting',
  name: 'meeting',
  component: LAYOUT,
  redirect: '/meeting/index',
  meta: {
    orderNo: ROUTER_ORDER_NO.MEETING,
    icon: 'meeting|svg',
    title: t('routes.meeting.meeting'),
  },
  children: [
    {
      path: 'index',
      name: 'meeting',
      component: () => import('/@/views/meeting/index.vue'),
    }
  ],
};
```

---

## 3. 组件结构

### 3.1 组件树

```
MeetingIndex.vue (会议列表)
├── MeetingCalendar.vue (日历视图)
│   └── MeetingCard.vue (会议卡片)
├── MeetingList.vue (列表视图)
│   └── MeetingCard.vue
└── MeetingDetailModal.vue (会议详情Modal)
    ├── MeetingHeader.vue (会议头部)
    ├── MeetingNotes.vue (会议笔记)
    └── MeetingParticipants.vue (参与者列表)
```

---

## 4. Store 说明

### 4.1 Meeting Store

**State 定义**:
```typescript
interface MeetingState {
  meetings: Meeting[]
  currentMeeting: Meeting | null
  loading: boolean
}
```

**Actions**:
```typescript
actions: {
  async fetchMeetings(params?: MeetingQueryParams) {
    const res = await MeetingListApi(params)
    this.meetings = res.data.meetings
  },
  
  async reserveMeeting(data: MeetingReserveParams) {
    const res = await MeetingReserveApi(data)
    this.meetings.push(res.data.meeting)
    return res.data.meeting
  }
}
```

---

## 5. API 调用规范

### 5.1 API 接口列表

| API函数 | 后端接口 | 说明 |
|---------|---------|------|
| `MeetingListApi` | `GET /meeting/list` | 获取会议列表 |
| `MeetingReserveApi` | `POST /meeting/reserve` | 预约会议 |
| `MeetingInfoApi` | `GET /meeting/info` | 获取会议详情 |

---

## 6. 交互流程

### 6.1 会议预约流程

```
1. 用户在任务卡片或首页点击"会议预约"按钮
   ↓
2. 打开 MeetingReserveModal（预约会议弹窗）
   ↓
3. 填写会议信息：
   - 会议主题（可选）
   - 开始时间（默认当前时间）
   - 结束时间
   - 参与者列表（自动包含任务负责人）
   - 审计人列表（可选）
   ↓
4. 选择"立即开始"或"预约"
   ↓
5. 调用 MeetingReserveApi 创建会议
   ↓
6. 成功后：
   - 显示成功提示
   - 关闭Modal
   - 刷新会议列表
   - 更新任务会议状态（显示绿色边框）
```

### 6.2 进入会议流程

```
1. 用户在任务卡片点击"加入会议"按钮
   或
   在会议列表点击"进入"按钮
   ↓
2. 打开 MeetingDrawer（会议抽屉）
   ↓
3. 加载会议信息：
   - 会议基本信息
   - 关联的任务树
   - 会议笔记
   - 参与者列表
   ↓
4. 切换到会议模式（TaskTreeMeetingMain）
   ↓
5. 显示会议操作工具栏：
   - 通过/不通过按钮
   - 延期按钮
   - 撤销按钮
   - 投票按钮（WikiTask）
```

### 6.3 会议操作流程

#### 6.3.1 开始会议

```
1. 会议创建者点击"开始会议"按钮
   ↓
2. 调用 MeetingStartApi
   ↓
3. 会议状态更新为 GOING（进行中）
   ↓
4. 通知所有参与者会议已开始
   ↓
5. 刷新会议列表
```

#### 6.3.2 取消会议

```
1. 会议创建者点击"取消会议"按钮
   ↓
2. 确认取消操作
   ↓
3. 调用 MeetingCancelApi
   ↓
4. 会议状态更新为 CANCELED（已取消）
   ↓
5. 通知所有参与者会议已取消
   ↓
6. 刷新会议列表
```

#### 6.3.3 关闭会议

```
1. 会议进行中，创建者点击"关闭会议"按钮
   ↓
2. 生成会议摘要（如果未生成）
   ↓
3. 调用 MeetingCloseApi
   ↓
4. 会议状态更新为 FINISHED（已完成）
   ↓
5. 通知所有参与者会议已关闭
   ↓
6. 刷新会议列表
   ↓
7. 更新任务会议状态（移除绿色边框）
```

---

## 7. UI 规范

### 7.1 视觉设计

- **页面布局**: 使用 `PageWrapper` + `ScrollContainer` 实现全屏滚动
- **折叠面板**: 使用 `Collapse` 组件分组显示会议
- **列表展示**: 使用 `List` + `ListItem` 展示会议列表
- **状态标签**: 使用 `MeetingStatusTag` 组件显示会议状态和操作

### 7.2 组件使用

- **PageHeader**: 页面头部，显示标题和图标
- **Collapse**: 折叠面板，分组显示进行中和已完成的会议
- **List**: 会议列表容器
- **ListItem**: 单个会议项
- **Avatar**: 参与者头像
- **DateFormatter**: 时间格式化显示
- **MeetingStatusTag**: 会议状态标签和操作按钮

### 7.3 交互反馈

- **加载状态**: 使用 `v-loading` 显示加载中
- **空状态**: 显示友好的空状态提示
- **操作反馈**: 使用 `message` 提示操作结果
- **状态更新**: 实时更新会议状态和列表

---

## 8. 权限控制

- 会议创建者可以编辑和取消会议
- 参与者可以查看会议详情和笔记

---

## 9. WebSocket 通知处理

### 9.1 通知机制概述

会议模块通过 WebSocket 实时接收后端推送的会议状态变更通知。前端通过 `notificationStore` 订阅 `WebNotificationChannel` 并处理各种会议相关的通知事件。

### 9.2 会议通知类型

前端支持以下会议通知类型：

| 通知类型 | Action 值 | 处理逻辑 | 显示内容 |
|---------|-----------|---------|---------|
| 会议预约 | `meeting_reserve` | 刷新会议列表，更新任务会议状态 | "会议预约" - "会议已预约" |
| 会议开始 | `meeting_start` | 刷新会议列表，更新任务会议状态 | "会议开始" - "会议已开始" |
| 会议取消 | `meeting_cancel` | 刷新会议列表，更新任务会议状态 | "会议取消" - "会议已被取消" |
| 会议关闭 | `meeting_close` | 刷新会议列表，更新任务会议状态，处理会议关闭逻辑 | "会议关闭" - "会议已关闭" |

### 9.3 通知处理逻辑

**文件路径**: `src/store/modules/notification.ts`

```typescript
function handleWebSocketMessage(message: any) {
  const { act: action, data } = message;
  
  switch (action) {
    case MeetingActionEnum.START:
      showNotification('会议开始', '会议已开始', 'info');
      // 刷新会议列表
      refreshView();
      // 更新任务会议状态
      if (data.task_id) {
        updateTaskMeetingStatus(data.task_id, true, data.meeting_id);
      }
      break;
      
    case MeetingActionEnum.RESERVE:
      showNotification('会议预约', '会议已预约', 'info');
      // 刷新会议列表
      refreshView();
      // 更新任务会议状态
      if (data.task_id) {
        updateTaskMeetingStatus(data.task_id, true, data.meeting_id);
      }
      break;
      
    case MeetingActionEnum.CANCEL:
      showNotification('会议取消', '会议已被取消', 'warning');
      // 刷新会议列表
      refreshView();
      // 更新任务会议状态
      if (data.task_id) {
        updateTaskMeetingStatus(data.task_id, false);
      }
      break;
      
    case WsActionEnum.MEETING_CLOSE:
      handleMeetingClose(data);
      break;
  }
}

// 处理会议关闭通知
function handleMeetingClose(data: any) {
  showNotification('会议关闭', '会议已关闭', 'info');
  
  // 通知 meetingStore 处理会议关闭
  if (meetingStore.currentMeetingId) {
    meetingStore.handleMeetingCloseUpdated(data);
  }
  
  // 更新任务会议状态
  if (data.task_id) {
    updateTaskMeetingStatus(data.task_id, false);
  }
  
  // 刷新会议列表
  refreshView();
}
```

### 9.4 在组件中使用通知

在会议相关组件中监听通知并刷新数据：

**文件路径**: `src/views/dashboard/components/TaskGridList.vue`

```typescript
import { useNotificationStore } from '/@/store/modules/notification';
import { MeetingActionEnum, WsActionEnum } from '/@/enums/wsActionEnum';

const notificationStore = useNotificationStore();

// 监听通知消息变化
watch(
  () => notificationStore.currentMessage,
  (newMessage) => {
    if (newMessage && newMessage.action) {
      const { action, data } = newMessage;
      
      switch (action) {
        case MeetingActionEnum.START:
        case MeetingActionEnum.RESERVE:
          if (data.task_id) {
            updateTaskMeetingStatus(data.task_id, true, data.meeting_id);
          }
          refreshView();
          break;
          
        case MeetingActionEnum.CANCEL:
        case WsActionEnum.MEETING_CLOSE:
          if (data.task_id) {
            updateTaskMeetingStatus(data.task_id, false);
          }
          refreshView();
          break;
      }
    }
  }
);
```

### 9.5 会议 Store 中的通知处理

**文件路径**: `src/store/modules/meeting.ts`

```typescript
export const useMeetingStore = defineStore('meeting', () => {
  // 处理会议关闭更新
  function handleMeetingCloseUpdated(data: any) {
    // 如果当前正在查看该会议，需要处理关闭逻辑
    if (meetingInfo.value?.id === data.meeting_id) {
      // 更新会议状态
      meetingInfo.value.status = MeetingStatus.FINISHED;
      
      // 执行其他清理逻辑
      // ...
    }
  }
  
  // 处理任务状态更新（会议中任务状态变更）
  function handleTaskStatusUpdate(data: any) {
    const task = data.task;
    
    // 更新 taskList 中的任务
    const targetTask = taskList.value.find((t) => t.id === task.id);
    if (targetTask) {
      targetTask.status = task.status;
    }
    
    // 更新 meetingInfo.task 中的任务（递归查找）
    function updateTaskInTree(treeTask: MeetingTask): boolean {
      if (treeTask.id === task.id) {
        treeTask.status = task.status;
        return true;
      }
      if (treeTask.sub_tasks) {
        for (const subTask of treeTask.sub_tasks) {
          if (updateTaskInTree(subTask)) {
            return true;
          }
        }
      }
      return false;
    }
    
    if (meetingInfo.value?.task) {
      updateTaskInTree(meetingInfo.value.task);
    }
  }
});
```

### 9.6 通知消息格式

WebSocket 通知消息格式：

```typescript
interface NotificationMessage {
  message: {
    title: string;    // 通知标题（已本地化）
    body: string;     // 通知内容（已本地化）
  };
  payload: {
    action: string;      // 通知类型（如 'meeting_start'）
    id: number;          // 会议ID
    meeting_id: number;  // 会议ID
    task_id: number;     // 关联的任务ID
    // ... 其他相关数据
  };
  user_id: number;    // 触发通知的用户ID
}
```

### 9.7 初始化通知系统

会议模块使用与任务模块相同的通知系统。详细说明请参考 [任务模块文档 - 9. WebSocket 通知处理](./task.md#9-websocket-通知处理)。

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

