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
| `/meeting/index` | `meeting` | `src/views/meeting/index.vue` | 会议列表页面 |

### 2.2 路由配置

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
1. 用户点击"预约会议"
2. 打开预约Modal
3. 填写会议信息（主题、时间、参与者）
4. 调用 MeetingReserveApi
5. 成功后刷新列表
```

---

## 7. UI 规范

- 使用 Ant Design Vue 组件
- 日历视图展示会议时间
- 会议卡片显示基本信息

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

