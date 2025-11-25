# 笔记系统模块 - 前端文档

> **返回**: [文档首页](../../README.md)

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

笔记系统模块是GWEN系统的个人知识管理模块，负责：

- **笔记管理**: 创建、编辑、删除个人笔记
- **笔记分类**: 通过标签（任务、灵感、其他）组织笔记
- **协作编辑**: 支持多人实时协作编辑，通过编辑锁机制防止冲突
- **笔记分享**: 支持将笔记分享给其他用户，设置只读/可编辑权限
- **实时同步**: 通过WebSocket实现笔记编辑的实时同步

### 1.2 技术栈

- **框架**: Vue 3 + TypeScript
- **状态管理**: Pinia
- **UI组件**: Ant Design Vue
- **编辑器**: ByteMD (Markdown编辑器)
- **实时通信**: WebSocket (NoteEditChannel)

---

## 2. 页面结构

### 2.1 页面列表

| 页面路径 | 路由名称 | 组件路径 | 说明 |
|---------|---------|---------|------|
| 全局Modal | - | `src/components/QuickNote/src/QuickNoteModal.vue` | **笔记编辑Modal（全局）** - 全屏笔记编辑界面 |
| 侧边栏 | - | `src/components/QuickNote/src/QuickNoteSidebar.vue` | **笔记列表侧边栏** - 笔记列表和筛选 |

**注意**: 笔记功能主要通过全局Modal和快捷键访问，没有独立的路由页面。

### 2.2 访问方式

- **快捷键**: `Cmd/Ctrl + K` 打开QuickNote
- **全局按钮**: 顶部导航栏的笔记图标
- **组件调用**: 通过 `useQuickNoteStore` 控制显示

### 2.3 页面布局

#### 2.3.1 QuickNote Modal 布局

**组件**: `QuickNoteModal.vue`

**布局结构**:

```
QuickNoteModal (全屏Modal, z-index: 1200)
└── flex 布局 (左右分栏)
    ├── 左侧边栏 (宽度: 300px, 固定)
    │   └── QuickNoteSidebar
    │       ├── 标签筛选器
    │       │   ├── "任务" 标签按钮
    │       │   ├── "灵感" 标签按钮
    │       │   └── "其他" 标签按钮
    │       ├── 搜索框
    │       │   └── Input (搜索笔记内容)
    │       ├── "新建笔记" 按钮
    │       └── 笔记列表
    │           └── NoteListItem (笔记项)
    │               ├── 标签图标和名称
    │               ├── 笔记标题（内容预览）
    │               ├── 创建时间
    │               └── 分享状态图标
    └── 右侧编辑器 (flex-1, 自适应)
        └── ByteMdNative (Markdown编辑器)
            ├── NoteEditorToolbar (工具栏)
            │   ├── 模式切换按钮 (Write/Preview)
            │   ├── 锁状态显示
            │   ├── 订阅者信息
            │   └── 编辑控制按钮
            └── 编辑器主体
                ├── Write模式: Markdown编辑区
                └── Preview模式: Markdown预览区
```

**布局特点**:

1. **左侧边栏** (300px 固定宽度):
   - **标签筛选器**: 三个标签按钮（任务、灵感、其他），点击筛选对应标签的笔记
   - **搜索框**: 实时搜索笔记内容
   - **新建笔记按钮**: 创建新笔记，弹出标签选择
   - **笔记列表**: 
     - 显示当前筛选条件下的笔记
     - 每个笔记项显示：标签、内容预览、时间、分享状态
     - 点击笔记项，右侧显示编辑器

2. **右侧编辑器** (自适应宽度):
   - **工具栏**:
     - 模式切换：Write（编辑）/ Preview（预览）
     - 锁状态：显示当前编辑锁状态（已锁定/未锁定）
     - 订阅者：显示当前查看/编辑笔记的其他用户
     - 编辑控制：开始编辑/停止编辑按钮
   - **编辑器主体**:
     - Write模式：Markdown编辑区，支持实时编辑
     - Preview模式：Markdown渲染预览，只读显示

**功能说明**:

| 功能区域 | 功能说明 |
|---------|---------|
| **标签筛选** | 按标签（任务/灵感/其他）筛选笔记 |
| **内容搜索** | 实时搜索笔记内容，支持关键词匹配 |
| **笔记列表** | 显示笔记列表，支持选择、创建、删除 |
| **Markdown编辑** | 支持Markdown语法编辑，实时预览 |
| **编辑锁** | 防止多人同时编辑冲突 |
| **协作编辑** | 显示其他订阅者，支持实时同步 |
| **笔记分享** | 分享笔记给其他用户，设置权限 |

---

## 3. 组件结构

### 3.1 组件树

```
QuickNoteModal.vue (全局Modal)
├── QuickNoteSidebar.vue (侧边栏)
│   ├── 标签筛选器
│   ├── 搜索框
│   └── 笔记列表
│       └── NoteListItem.vue (笔记列表项)
└── ByteMdNative.vue (Markdown编辑器)
    └── NoteEditorToolbar.vue (编辑器工具栏)
        ├── 模式切换按钮 (Write/Preview)
        ├── 锁状态显示
        ├── 订阅者信息
        └── 编辑控制按钮
```

### 3.2 核心组件说明

#### 3.2.1 QuickNoteModal

**路径**: `src/components/QuickNote/src/QuickNoteModal.vue`

**职责**: 
- 全局笔记编辑Modal容器
- 管理笔记的显示和编辑状态
- 处理笔记的创建、编辑、删除操作

**Props**:
```typescript
interface Props {
  open: boolean        // Modal显示状态
  noteId?: number      // 可选, 要编辑的笔记ID
}
```

**Events**:
- `@close`: 关闭Modal事件

#### 3.2.2 QuickNoteSidebar

**路径**: `src/components/QuickNote/src/QuickNoteSidebar.vue`

**职责**:
- 笔记列表展示
- 标签筛选
- 内容搜索
- 笔记选择

**Props**:
```typescript
interface Props {
  selectedNoteId?: number  // 当前选中的笔记ID
}
```

**Events**:
- `@note-select`: 笔记选择事件
- `@note-create`: 创建笔记事件

#### 3.2.3 NoteEditorToolbar

**路径**: `src/components/QuickNote/src/NoteEditorToolbar.vue`

**职责**:
- 编辑器模式切换（Write/Preview）
- 编辑锁状态显示
- 订阅者信息显示
- 编辑控制（开始/停止编辑）

**Props**:
```typescript
interface Props {
  note: NoteItem
  mode: 'write' | 'preview'
  canEdit: boolean
  lockStatus: NoteEditStatus | null
  subscribers: User[]
}
```

**Events**:
- `@mode-change`: 模式切换事件
- `@start-edit`: 开始编辑事件
- `@stop-edit`: 停止编辑事件

#### 3.2.4 ByteMdNative

**路径**: `src/components/Markdown/src/ByteMdNative.vue`

**职责**:
- Markdown内容编辑和预览
- 内容变更监听
- 编辑器配置

**Props**:
```typescript
interface Props {
  value: string           // 笔记内容
  mode: 'write' | 'preview'  // 编辑模式
  disabled: boolean       // 是否禁用编辑
}
```

**Events**:
- `@change`: 内容变更事件

---

## 4. Store 说明

### 4.1 QuickNote Store

**路径**: `src/store/modules/quickNote.ts`

**State 定义**:
```typescript
interface QuickNoteState {
  isVisible: boolean        // Modal显示状态
  currentNoteId: number | null  // 当前编辑的笔记ID
}
```

**Actions**:
```typescript
actions: {
  openQuickNote(noteId?: number) {
    this.isVisible = true
    this.currentNoteId = noteId || null
  },
  
  closeQuickNote() {
    this.isVisible = false
    this.currentNoteId = null
  }
}
```

### 4.2 NoteEdit Store

**路径**: `src/store/modules/noteEdit.ts`

**State 定义**:
```typescript
interface NoteEditState {
  // 按笔记ID分组的锁状态
  noteLockStatuses: Map<number, NoteEditStatus>
  
  // 按笔记ID分组的订阅者信息
  noteSubscribers: Map<number, User[]>
  
  // 订阅的笔记ID集合
  subscribedNotes: Set<number>
  
  // 笔记数据
  notes: NoteWithEdit[]
  loading: boolean
  notifications: NoteNotification[]
  
  // 当前活跃笔记ID（向后兼容）
  currentNoteId: number | null
}
```

**Getters**:
```typescript
getters: {
  // 当前笔记锁状态
  currentLockStatus: (state) => {
    return state.currentNoteId 
      ? state.noteLockStatuses.get(state.currentNoteId) || null 
      : null
  },
  
  // 当前笔记订阅者
  currentSubscribers: (state) => {
    return state.currentNoteId
      ? state.noteSubscribers.get(state.currentNoteId) || []
      : []
  },
  
  // 是否已订阅
  isSubscribed: (state) => (noteId: number) => {
    return state.subscribedNotes.has(noteId)
  }
}
```

**Actions**:
```typescript
actions: {
  // 订阅笔记编辑频道
  subscribeNoteEditChannel(noteId: number) {
    if (this.subscribedNotes.has(noteId)) {
      return
    }
    
    const socketStore = useSocketStore()
    socketStore.subscribe('NoteEditChannel', { note_id: noteId })
    this.subscribedNotes.add(noteId)
  },
  
  // 取消订阅
  unsubscribeNoteEditChannel(noteId: number) {
    const socketStore = useSocketStore()
    socketStore.unsubscribe('NoteEditChannel', { note_id: noteId })
    this.subscribedNotes.delete(noteId)
  },
  
  // 获取编辑锁
  async requestLock(noteId: number) {
    const res = await acquireNoteLock({ id: noteId })
    if (res.code === 0) {
      // 开始心跳
      this.startHeartbeat(noteId)
      return true
    }
    return false
  },
  
  // 释放编辑锁
  async releaseLock(noteId: number) {
    await releaseNoteLock({ id: noteId })
    this.stopHeartbeat(noteId)
  },
  
  // 开始心跳（每30秒）
  startHeartbeat(noteId: number) {
    const interval = setInterval(() => {
      const socketStore = useSocketStore()
      socketStore.send('NoteEditChannel', {
        action: 'heartbeat',
        note_id: noteId
      })
    }, 30000)
    
    this.heartbeatIntervals.set(noteId, interval)
  },
  
  // 停止心跳
  stopHeartbeat(noteId: number) {
    const interval = this.heartbeatIntervals.get(noteId)
    if (interval) {
      clearInterval(interval)
      this.heartbeatIntervals.delete(noteId)
    }
  },
  
  // 处理锁状态更新
  handleLockStatusUpdate(noteId: number, lock: any) {
    this.noteLockStatuses.set(noteId, {
      note_lock: lock,
      can_edit: this.canEditNote(noteId)
    })
  },
  
  // 处理内容更新
  handleContentUpdate(noteId: number, data: any) {
    const note = this.notes.find(n => n.id === noteId)
    if (note && !data.is_current_user_operation) {
      note.content = data.content
    }
  },
  
  // 处理订阅者变化
  handleSubscriberChange(noteId: number, data: any) {
    if (data.action === 'subscribe') {
      const subscribers = this.noteSubscribers.get(noteId) || []
      if (!subscribers.find(u => u.id === data.user.id)) {
        subscribers.push(data.user)
        this.noteSubscribers.set(noteId, subscribers)
      }
    } else if (data.action === 'unsubscribe') {
      const subscribers = this.noteSubscribers.get(noteId) || []
      this.noteSubscribers.set(noteId, 
        subscribers.filter(u => u.id !== data.user.id)
      )
    }
  }
}
```

---

## 5. API 调用规范

### 5.1 API 接口列表

**文件路径**: `src/api/data/note.ts`

| API函数 | 后端接口 | 说明 | 参数类型 |
|---------|---------|------|---------|
| `NoteIndexApi` | `POST /notes/index` | 获取笔记列表 | `NoteQueryParams` |
| `NoteShowApi` | `POST /notes/show` | 获取笔记详情 | `{ id: number }` |
| `NoteCreateApi` | `POST /notes/create` | 创建笔记 | `NoteCreateParams` |
| `NoteUpdateApi` | `POST /notes/update` | 更新笔记 | `NoteUpdateParams & { id: number }` |
| `NoteDestroyApi` | `POST /notes/destroy` | 删除笔记 | `{ id: number }` |
| `NoteTagOptionsApi` | `POST /notes/tag_options` | 获取标签选项 | - |
| `NoteShareApi` | `POST /notes/share` | 分享笔记 | `NoteShareParams & { id: number }` |
| `NoteUnshareApi` | `POST /notes/unshare` | 取消分享 | `NoteUnshareParams & { id: number }` |
| `NoteSharedWithMeApi` | `POST /notes/shared_with_me` | 获取分享给我的笔记 | `NoteQueryParams` |

### 5.2 参数类型定义

```typescript
// 笔记查询参数
interface NoteQueryParams {
  tag?: string           // 标签筛选: 'task' | 'inspiration' | 'other'
  search?: string        // 内容搜索关键词
  include_shared?: boolean  // 是否包含被分享的笔记
  page?: number          // 页码
  per_page?: number      // 每页数量
}

// 笔记创建参数
interface NoteCreateParams {
  tag: string            // 标签: 'task' | 'inspiration' | 'other'
  content: string        // 笔记内容（可选）
}

// 笔记更新参数
interface NoteUpdateParams {
  tag?: string           // 标签（可选）
  content?: string       // 笔记内容（可选）
}

// 笔记分享参数
interface NoteShareParams {
  user_ids: number[]     // 要分享的用户ID列表
  permissions: ('readonly' | 'editable')[]  // 对应的权限列表
}

// 笔记类型
interface NoteItem {
  id: number
  user_id: number
  user_name: string
  tag: string
  tag_display_name: string
  content: string
  content_empty: boolean
  share_opt: any
  shared_users?: SharedUser[]
  edit_lock?: {
    id: number
    note_id: number
    locked_by: number
    locked_at: string
    is_locked: boolean
    auto_release_at: string
  }
  current_editor?: {
    id: number
    account: string
    name?: string
  }
  created_at: string
  updated_at: string
}
```

### 5.3 API 调用示例

```typescript
import { 
  NoteIndexApi, 
  NoteCreateApi, 
  NoteUpdateApi,
  NoteShareApi 
} from '/@/api/data/note'

// 获取笔记列表
const loadNotes = async () => {
  const res = await NoteIndexApi({
    tag: 'task',
    search: '关键词',
    include_shared: true,
    page: 1,
    per_page: 20
  })
  notes.value = res.data.notes
  pagination.value = res.data.pagination
}

// 创建笔记
const createNote = async (tag: string, content?: string) => {
  const res = await NoteCreateApi({ tag, content: content || '' })
  if (res.code === 0) {
    notes.value.unshift(res.data.note)
    return res.data.note
  }
}

// 更新笔记
const updateNote = async (id: number, content: string) => {
  const res = await NoteUpdateApi({ id, content })
  if (res.code === 0) {
    const index = notes.value.findIndex(n => n.id === id)
    if (index !== -1) {
      notes.value[index] = res.data.note
    }
  }
}

// 分享笔记
const shareNote = async (id: number, userIds: number[], permissions: string[]) => {
  const res = await NoteShareApi({ id, user_ids: userIds, permissions })
  if (res.code === 0) {
    message.success('笔记已分享')
  }
}
```

---

## 6. 交互流程

### 6.1 笔记创建流程

```
1. 用户按快捷键 Cmd/Ctrl + K 或点击笔记图标
   ↓
2. 打开 QuickNoteModal
   ↓
3. 用户点击"新建笔记"按钮
   ↓
4. 选择标签（任务/灵感/其他）
   ↓
5. 调用 NoteCreateApi 创建笔记
   ↓
6. 成功后：
   - 笔记列表添加新笔记
   - 自动选中新笔记
   - 切换到编辑模式
   - 获取编辑锁
```

### 6.2 笔记编辑流程

```
1. 用户选择笔记
   ↓
2. 订阅 NoteEditChannel
   ↓
3. 用户切换到 Write 模式
   ↓
4. 调用 acquire_lock API 获取编辑锁
   ↓
5. 如果成功：
   - 开始心跳（每30秒）
   - 启用编辑器
   - 显示锁状态
   ↓
6. 用户编辑内容
   ↓
7. 内容变更时调用 NoteUpdateApi
   ↓
8. 后端广播内容更新给其他订阅者
   ↓
9. 用户切换到 Preview 模式
   ↓
10. 调用 release_lock API 释放编辑锁
    ↓
11. 停止心跳
```

### 6.3 笔记分享流程

```
1. 用户点击"分享"按钮
   ↓
2. 打开分享Modal
   ↓
3. 选择要分享的用户
   ↓
4. 选择权限（只读/可编辑）
   ↓
5. 调用 NoteShareApi 分享笔记
   ↓
6. 成功后：
   - 显示成功提示
   - 更新笔记的 shared_users 列表
   - 被分享用户收到WebSocket通知
```

### 6.4 编辑锁冲突处理

```
1. 用户尝试获取编辑锁
   ↓
2. 如果锁被其他人持有：
   - 显示锁状态提示
   - 显示当前编辑者信息
   - 显示剩余时间
   - 禁用编辑器
   ↓
3. 如果锁已过期：
   - 自动释放过期锁
   - 重新获取锁
   ↓
4. 如果锁被自己持有：
   - 更新最后活动时间
   - 延长自动释放时间
```

### 6.5 弹窗和提示

| 操作 | 弹窗类型 | 说明 |
|------|---------|------|
| 笔记编辑 | Modal | 全屏Modal，包含侧边栏和编辑器 |
| 分享笔记 | Modal | 用户选择和权限设置 |
| 删除笔记 | Modal确认 | 二次确认删除 |
| 锁冲突提示 | Message | 显示当前编辑者信息 |
| 成功提示 | Message | 操作成功提示 |
| 错误提示 | Message | 操作失败提示 |

### 6.6 已知问题和修复

#### 6.6.1 分享弹窗 z-index 层级问题

**问题现象**:
- 打开笔记弹窗（QuickNoteModal）
- 选中笔记，点击分享按钮
- 分享弹窗（ShareModal）弹出，但无法操作
- 原因是分享弹窗的 z-index 比笔记弹窗低，被遮挡

**问题原因**:
- 笔记弹窗（QuickNoteModal）的 z-index 设置为 1200
- 分享弹窗（ShareModal）未设置 z-index，使用默认值 1000
- 因为 1000 < 1200，分享弹窗被笔记弹窗遮挡

**解决方案**:
- 在 `ShareModal.vue` 中为 `BasicModal` 组件添加 `:z-index="1300"` 属性
- 确保分享弹窗的 z-index (1300) 高于笔记弹窗的 z-index (1200)

**修复代码**:
```vue
<BasicModal
  :open="open"
  :width="800"
  :title="t('common.share_note')"
  :z-index="1300"
  @register="register"
  @cancel="handleClose"
  @ok="handleConfirm"
  :ok-text="t('common.save_changes')"
  :cancel-text="t('common.cancel')"
>
```

**z-index 层级规范**:
- 笔记弹窗（QuickNoteModal）: 1200
- 分享弹窗（ShareModal）: 1300
- Popover/Popconfirm: 1400
- Select Dropdown: 1500

---

## 7. UI 规范

### 7.1 视觉一致性

- **颜色规范**:
  - 标签颜色:
    - 任务: `#1890ff` (蓝色)
    - 灵感: `#52c41a` (绿色)
    - 其他: `#8c8c8c` (灰色)
  - 锁状态:
    - 已锁定: `#ff4d4f` (红色)
    - 未锁定: `#52c41a` (绿色)

- **间距规范**:
  - Modal内边距: `24px`
  - 侧边栏宽度: `300px`
  - 编辑器内边距: `16px`
  - 组件间距: `8px`

- **字体规范**:
  - 笔记标题: `14px`, `font-weight: 500`
  - 笔记内容: `14px`, `font-weight: 400`
  - 辅助文字: `12px`, `color: #8c8c8c`

### 7.2 Ant Design Vue 风格

- **Modal**: 使用 `Modal` 组件，全屏显示
- **列表**: 使用 `List` + `ListItem` 组件
- **标签**: 使用 `Tag` 组件展示标签
- **按钮**: 使用 `Button` 组件
- **输入框**: 使用 `Input` 组件（搜索）
- **选择器**: 使用 `Select` 组件（标签选择）

### 7.3 编辑器样式

- **编辑器**: ByteMD，支持Markdown语法
- **工具栏**: 自定义工具栏，隐藏原生工具栏
- **预览模式**: 只读显示，支持Markdown渲染
- **编辑模式**: 可编辑，实时预览

### 7.4 加载状态

- **列表加载**: 使用 `Skeleton` 组件
- **编辑器加载**: 使用 `Spin` 组件
- **按钮加载**: 使用 `loading` 属性

### 7.5 z-index 层级规范

为了确保弹窗和下拉菜单的正确显示顺序，需要遵循以下 z-index 层级规范：

| 组件 | z-index | 说明 |
|------|---------|------|
| 笔记弹窗（QuickNoteModal） | 1200 | 主弹窗层级 |
| 分享弹窗（ShareModal） | 1300 | 需要在笔记弹窗之上 |
| Popover/Popconfirm | 1400 | 提示类组件 |
| Select Dropdown | 1500 | 下拉选择器 |

**注意事项**:
- 嵌套弹窗时，子弹窗的 z-index 必须高于父弹窗
- 使用 `BasicModal` 组件时，通过 `:z-index` 属性设置层级
- 避免使用过高的 z-index 值，保持层级清晰

---

## 8. 权限控制

### 8.1 按钮显示规则

#### 8.1.1 编辑按钮

```typescript
// 显示条件：
// 1. 用户是笔记作者
// 2. 用户是可编辑协作者
const canEdit = computed(() => {
  const note = props.note
  const currentUser = userStore.getUserInfo
  
  // 是作者
  if (note.user_id === currentUser.id) {
    return true
  }
  
  // 是可编辑协作者
  const sharedUser = note.shared_users?.find(
    su => su.user_id === currentUser.id && su.permission === 'editable'
  )
  return !!sharedUser
})
```

#### 8.1.2 分享按钮

```typescript
// 显示条件：用户是笔记作者
const canShare = computed(() => {
  const note = props.note
  const currentUser = userStore.getUserInfo
  return note.user_id === currentUser.id
})
```

#### 8.1.3 删除按钮

```typescript
// 显示条件：用户是笔记作者
const canDelete = computed(() => {
  const note = props.note
  const currentUser = userStore.getUserInfo
  return note.user_id === currentUser.id
})
```

### 8.2 编辑器禁用规则

```typescript
// 编辑器禁用条件
const editorDisabled = computed(() => {
  const note = props.note
  const lockStatus = noteEditStore.noteLockStatuses.get(note.id)
  
  // 1. 无编辑权限
  if (!canEdit.value) {
    return true
  }
  
  // 2. 笔记被其他人锁定
  if (lockStatus?.note_lock?.is_locked && 
      lockStatus.note_lock.locked_by !== currentUser.id) {
    return true
  }
  
  // 3. 当前是预览模式
  if (editorMode.value === 'preview') {
    return true
  }
  
  return false
})
```

### 8.3 字段显示控制

```typescript
// 分享用户列表显示
const showSharedUsers = computed(() => {
  return note.shared_users && note.shared_users.length > 0
})

// 锁状态显示
const showLockStatus = computed(() => {
  return note.edit_lock && note.edit_lock.is_locked
})

// 当前编辑者显示
const showCurrentEditor = computed(() => {
  return note.current_editor && note.current_editor.id !== currentUser.id
})
```

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

