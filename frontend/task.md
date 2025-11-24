# 任务管理模块 - 前端文档

> **返回**: [文档首页](../README.md)  
> **相关文档**: [快捷键系统](./shortcuts.md)

## 目录

- [1. 概述](#1-概述)
- [2. 页面结构](#2-页面结构)
- [3. 组件结构](#3-组件结构)
- [4. Store 说明](#4-store-说明)
- [5. API 调用规范](#5-api-调用规范)
- [6. 交互流程](#6-交互流程)
- [7. UI 规范](#7-ui-规范)
- [8. 权限控制](#8-权限控制)
- [9. 快捷键支持](#9-快捷键支持)

---

## 1. 概述

### 1.1 模块边界与目的

任务管理模块是GWEN系统的核心前端模块，负责：

- **任务展示**: 以网格和树形结构展示任务列表
- **任务操作**: 创建、编辑、删除任务
- **状态管理**: 任务状态流转（接受、提交、完成等）
- **任务树**: 支持父子任务关系的树形展示
- **实时协作**: 通过WebSocket实现任务编辑的实时同步

### 1.2 技术栈

- **框架**: Vue 3 + TypeScript
- **状态管理**: Pinia
- **UI组件**: Ant Design Vue
- **路由**: Vue Router
- **实时通信**: WebSocket (TaskEditChannel)
- **快捷键系统**: 全局快捷键管理（详见 [快捷键系统文档](./shortcuts.md)）

---

## 2. 页面结构

### 2.1 页面列表

| 页面路径 | 路由名称 | 组件路径 | 说明 |
|---------|---------|---------|------|
| `/dashboard/index` | `dashboard` | `src/views/dashboard/index.vue` | **系统首页** - 任务网格列表展示 |
| `/task/index` | `task` | `src/views/workbench/index.vue` | 任务工作台主页面 |
| `/data/task` | - | `src/views/data/task/Task.vue` | 任务管理页面（数据维护） |

### 2.1.1 首页说明

**首页** (`/dashboard/index`) 是GWEN系统的核心入口页面，主要功能：

- **任务网格展示**: 以网格卡片形式展示所有根任务
- **任务面板**: 每个任务卡片内嵌任务面板，支持查看和编辑
- **布局切换**: 支持单列/双列布局切换（快捷键：Alt+1/Alt+2）
- **实时协作**: 显示任务编辑的订阅者状态
- **会议集成**: 支持会议预约和加入
- **快捷操作**: 任务发布、删除、会议预约等操作入口

**首页组件结构**:
```
DashboardIndex.vue (首页)
└── TaskGridList.vue (任务网格列表)
    ├── TaskCard (任务卡片)
    │   └── TaskPanelIndex (任务面板)
    │       ├── TaskTreeViewMain (查看模式)
    │       ├── TaskTreeEditMain (编辑模式)
    │       ├── TaskTreeMeetingMain (会议模式)
    │       └── IssueList (议题列表)
    └── CollaborationActions (协作操作按钮)
```

### 2.2 路由配置

#### 2.2.1 首页路由

```typescript
// src/router/routes/modules/dashboard.ts
const dashboard: AppRouteModule = {
  path: '/dashboard',
  name: 'Dashboard',
  component: LAYOUT,
  redirect: '/dashboard/index',
  meta: {
    orderNo: ROUTER_ORDER_NO.DASHBOARD,
    hideChildrenInMenu: true,
    icon: 'home|svg',
    title: t('routes.dashboard.analysis'),
  },
  children: [
    {
      path: 'index',
      name: 'dashboard',
      component: () => import('/@/views/dashboard/index.vue'),
      meta: {
        title: t('routes.dashboard.analysis'),
      },
    }
  ],
};
```

#### 2.2.2 任务工作台路由

```typescript
// src/router/routes/modules/workbench.ts
const workbench: AppRouteModule = {
  path: '/task',
  name: 'task',
  component: LAYOUT,
  redirect: '/task/index',
  meta: {
    orderNo: ROUTER_ORDER_NO.TASK,
    icon: 'workbench|svg',
    hideChildrenInMenu: true,
    title: t('routes.dashboard.workbench'),
  },
  children: [
    {
      path: 'index',
      name: 'task',
      component: () => import('/@/views/workbench/index.vue'),
      meta: {
        icon: 'task|svg',
        title: t('routes.workbench.workbench'),
      },
    }
  ],
};
```

### 2.3 页面布局

#### 2.3.1 单双列布局模式

GWEN 系统支持两种布局模式，用于适应不同的屏幕尺寸和使用场景：

**布局模式枚举** (`GridMode`):
```typescript
enum GridMode {
  SINGLE_COLUMN = '1xn',   // 单列布局（1列）
  DOUBLE_COLUMN = '2xn',   // 双列布局（2列）
}
```

**单列模式** (`SINGLE_COLUMN`):
- **布局特点**: 
  - 任务卡片垂直排列，每行显示一个任务
  - 任务面板和议题列表垂直排列（上下布局）
  - 任务面板占据全宽
- **适用场景**:
  - 移动端设备
  - 窄屏显示器
  - 需要详细查看单个任务的场景
  - 未发布根任务的编辑模式（自动使用）
- **快捷键**: `Alt+1`

**双列模式** (`DOUBLE_COLUMN`):
- **布局特点**:
  - 任务卡片可多列显示（2列）
  - 任务面板和议题列表水平排列（左右布局）
  - 任务面板使用 mini 模式（预览模式）
- **适用场景**:
  - 宽屏显示器
  - 需要同时查看多个任务的场景
  - 快速浏览任务列表
- **快捷键**: `Alt+2`

**布局切换方式**:
1. **快捷键切换**: 
   - `Alt+1`: 切换到单列布局
   - `Alt+2`: 切换到双列布局
2. **用户设置切换**: 
   - 点击用户头像下拉菜单
   - 在"任务设置"区域选择布局模式
   - 设置会持久化保存

**布局模式对任务面板的影响**:
- **单列模式**: 
  - 根据根任务状态自动选择 `VIEW` 或 `EDIT` 模式
  - 未发布根任务 → `EDIT` 模式
  - 已发布根任务 → `VIEW` 模式
- **双列模式**: 
  - 统一使用 `PREVIEW` 模式（mini 模式）
  - 任务面板和议题列表并排显示

#### 2.3.2 首页布局

**首页任务展示特点**:

首页 (`/dashboard/index`) 以**树形结构**展示所有根任务及其子任务。所有任务（未发布、已发布、已关闭、会议中等）都在同一个页面中展示，通过不同的 UI 视觉元素进行区分。

```
/dashboard/index (首页)
└── TaskGridList (任务网格列表)
    ├── 网格容器 (滚动容器)
    ├── 任务卡片组 (TaskCard)
    │   ├── 任务头部
    │   │   ├── 任务标题
    │   │   ├── 协作操作按钮 (CollaborationActions)
    │   │   ├── 发布/删除/会议按钮
    │   │   └── 订阅者状态 (TaskSubscribersStatus)
    │   └── 任务内容
    │       └── TaskPanelIndex (任务面板)
    │           ├── TaskTreeViewMain (查看模式)
    │           ├── TaskTreeEditMain (编辑模式)
    │           ├── TaskTreeMeetingMain (会议模式)
    │           └── IssueList (议题列表)
    └── 布局切换快捷键 (Alt+1/Alt+2)
```

**任务状态 UI 视觉区别**:

| 任务状态 | UI 视觉特征 | 面板模式 | 操作按钮 |
|---------|------------|---------|---------|
| **未发布** | 正常样式，无特殊边框 | `EDIT` 模式（单列）或 `PREVIEW` 模式（双列） | 显示"发布"按钮 |
| **已发布（未关闭）** | 正常样式，无特殊边框 | `VIEW` 模式（单列）或 `PREVIEW` 模式（双列） | 显示"会议预约"按钮 |
| **会议中** | **绿色边框 + 阴影** (`meeting-border` 类) | `MEETING` 模式 | 显示"加入会议"按钮和会议时间 |
| **已关闭** | 正常样式，可通过设置控制是否显示 | `VIEW` 模式 | 不显示操作按钮（或显示受限） |

**详细说明**:

1. **未发布任务**:
   - 任务卡片正常显示，无特殊边框
   - 单列模式下自动使用 `EDIT` 模式，允许编辑
   - 双列模式下使用 `PREVIEW` 模式
   - 头部显示"发布"按钮（绿色）

2. **已发布任务（未关闭）**:
   - 任务卡片正常显示，无特殊边框
   - 单列模式下使用 `VIEW` 模式，只读查看
   - 双列模式下使用 `PREVIEW` 模式
   - 头部显示"会议预约"按钮（绿色）

3. **会议中的任务**:
   - **视觉特征**: 任务卡片有**绿色边框**和**阴影效果**（`meeting-border` CSS 类）
   - 边框颜色: `@success-color` (绿色)
   - 阴影效果: `0 0 6px rgba(82, 196, 26, 0.2)`
   - 面板模式: `MEETING` 模式，显示会议相关功能
   - 头部显示:
     - "加入会议"按钮（主色）
     - "取消会议"按钮（危险色，仅创建者可操作）
     - 会议开始时间

4. **已关闭任务**:
   - 任务卡片正常显示，无特殊边框
   - 可通过用户设置控制是否在列表中显示（`includeClosedTasks` 选项）
   - 面板模式: `VIEW` 模式，只读查看
   - 不显示操作按钮（或显示受限）

**任务树结构**:

- 所有任务以**树形结构**展示，支持父子任务关系
- 根任务作为卡片展示，子任务在任务面板内的树形组件中展示
- 任务树支持展开/折叠操作
- 任务状态通过**状态标签**（Tag）显示，不同状态有不同颜色：
  - 成功状态: 绿色 (`green`)
  - 失败/拒绝状态: 红色 (`red`)
  - 其他状态: 灰色 (`gray`)

#### 2.3.3 任务工作台布局

```
/task/index (工作台)
├── PageHeader (标题栏)
│   ├── 图标 + 标题
│   └── 刷新按钮
└── TaskGridList (任务网格列表)
    ├── 网格布局控制
    └── TaskPanelIndex (任务面板)
        ├── TaskTreeViewMain (查看模式)
        ├── TaskTreeEditMain (编辑模式)
        ├── TaskTreeMeetingMain (会议模式)
        └── IssueList (议题列表)
```

---

## 3. 组件结构

### 3.1 组件树

```
DashboardIndex.vue (首页)
└── TaskGridList.vue (任务网格列表)
    ├── TaskCard (任务卡片)
    │   ├── CollaborationActions.vue (协作操作按钮)
    │   ├── TaskSubscribersStatus.vue (订阅者状态)
    │   └── TaskPanelIndex.vue (任务面板索引)
    │       ├── TaskTreeViewMain.vue (查看模式)
    │       │   ├── TaskTree.vue (任务树组件)
    │       │   └── TaskCard.vue (任务卡片)
    │       ├── TaskTreeEditMain.vue (编辑模式)
    │       │   ├── TaskTree.vue
    │       │   └── TaskEditForm.vue (任务编辑表单)
    │       ├── TaskTreeMeetingMain.vue (会议模式)
    │       │   ├── TaskTree.vue
    │       │   └── MeetingNoteList.vue (会议笔记列表)
    │       └── IssueList.vue (议题列表)
    │           └── IssueCard.vue (议题卡片)
    └── TaskPanelDrawer.vue (抽屉模式，可选)
        ├── TaskPanelView.vue (查看模式)
        ├── TaskPanelEdit.vue (编辑模式)
        ├── TaskPanelPreview.vue (预览模式)
        └── TaskPanelMeeting.vue (会议模式)
```

### 3.2 核心组件说明

#### 3.2.1 DashboardIndex (首页)

**路径**: `src/views/dashboard/index.vue`

**职责**: 
- 系统首页容器
- 布局管理（响应式）
- 快捷键注册（Alt+1/Alt+2 切换布局）

**特性**:
- 全屏展示任务网格
- 支持布局切换快捷键
- 响应式设计

#### 3.2.2 TaskGridList

**路径**: `src/views/dashboard/components/TaskGridList.vue`

**职责**: 
- 任务网格布局管理
- 任务卡片渲染
- 滚动容器管理
- 任务面板显示模式控制（索引/抽屉）
- 响应式布局适配

**Props**:
```typescript
interface Props {
  rootTasks?: RootTask[]  // 根任务列表（可选，内部会获取）
  displayMode?: GridMode  // 显示模式: SINGLE_COLUMN | DOUBLE_COLUMN
  // SINGLE_COLUMN: 单列布局，任务卡片垂直排列，任务面板和议题列表上下排列
  // DOUBLE_COLUMN: 双列布局，任务卡片可多列显示，任务面板和议题列表左右排列
}
```

**Events**:
- `@task-click`: 任务点击事件
- `@task-create`: 创建任务事件
- `@refresh`: 刷新事件
- `@issue-updated`: 议题更新事件

**核心功能**:
- 网格布局渲染（单列/双列）
- 任务卡片展示
- 加载状态管理（骨架屏）
- 滚动加载（虚拟滚动）
- 任务选择和高亮
- 会议状态显示
- 订阅者状态显示

#### 3.2.3 TaskPanelIndex

**路径**: `src/components/TaskPanel/Index.vue`

**职责**:
- 根据模式动态渲染对应的任务树组件
- 管理任务树和议题列表的显示
- 处理任务刷新和议题更新事件
- **核心路由组件**：负责根据布局模式和任务状态智能选择显示模式

**Props**:
```typescript
interface Props {
  rootTask: RootTask      // 根任务对象（包含完整的任务树和issues数据）
  displayMode: GridMode   // 显示模式: SINGLE_COLUMN | DOUBLE_COLUMN
  mode?: TaskPanelMode    // 面板模式: VIEW | EDIT | MEETING | PREVIEW（可选，用于drawer模式）
  showIssues?: boolean    // 是否显示议题部分，默认为 true
}
```

**实现逻辑**:

##### 1. 模式自动选择逻辑

`TaskPanelIndex` 的核心功能是根据 `displayMode` 和 `rootTask` 状态自动选择合适的面板模式：

```typescript
// 根据传入的mode和rootTask状态动态计算实际使用的模式
const actualMode = computed((): TaskPanelMode => {
  // 1. 如果直接指定了mode（drawer模式），优先使用
  if (props.mode) {
    return props.mode;
  }
  
  // 2. 如果 displayMode 是 DOUBLE_COLUMN（双列模式），统一使用 PREVIEW（mini 模式）
  if (props.displayMode === GridMode.DOUBLE_COLUMN) {
    return TaskPanelMode.PREVIEW;
  }
  
  // 3. 如果 displayMode 是 SINGLE_COLUMN（单列模式），根据 rootTask 状态决定
  if (props.displayMode === GridMode.SINGLE_COLUMN) {
    // 检查是否为未发布的根任务
    if (isRootUnPublished(props.rootTask)) {   
      return TaskPanelMode.EDIT;  // 未发布 → 编辑模式
    }
    
    return TaskPanelMode.VIEW;  // 已发布 → 查看模式
  }
  
  // 默认返回 VIEW 模式
  return TaskPanelMode.VIEW;
});
```

**模式选择规则总结**:

| displayMode | rootTask 状态 | 选择的模式 | 说明 |
|------------|--------------|-----------|------|
| DOUBLE_COLUMN | 任意 | `PREVIEW` | 双列模式统一使用预览模式（mini） |
| SINGLE_COLUMN | 未发布 | `EDIT` | 单列模式 + 未发布 = 编辑模式 |
| SINGLE_COLUMN | 已发布 | `VIEW` | 单列模式 + 已发布 = 查看模式 |
| 任意 | 指定 mode | 使用指定的 mode | Drawer 模式可以强制指定 |

##### 2. 动态组件切换

根据计算出的 `actualMode`，动态渲染对应的任务树组件：

```typescript
// 动态计算当前应该渲染的任务组件
const currentTaskComponent = computed(() => {
  switch (actualMode.value) {
    case TaskPanelMode.EDIT:
      return TaskTreeEditMain;      // 编辑模式：未发布任务
    case TaskPanelMode.MEETING:
      return TaskTreeMeetingMain;    // 会议模式：会议中的任务
    case TaskPanelMode.VIEW:
    case TaskPanelMode.PREVIEW:
    default:
      return TaskTreeViewMain;       // 查看/预览模式：已发布任务
  }
});
```

##### 3. 布局管理

组件内部管理任务树面板和议题列表的布局：

```typescript
// 任务树面板和议题列表的布局比例
.task-tree-pane {
  flex: 5 1 0;  // 任务树占 5 份
}

.issue-pane {
  flex: 4 1 0;  // 议题列表占 4 份
  min-width: 450px;
  border-left: 1px solid #eee;
}

// mini 模式（双列布局）
&.mini {
  .task-tree-pane {
    overflow: hidden hidden;  // 隐藏滚动条
  }
  .issue-pane {
    flex: 5 1 0;
    min-width: 280px;  // 更小的最小宽度
  }
}
```

##### 4. Props 传递

组件会计算并传递合适的 props 给子组件：

```typescript
// 任务组件的 props
const taskComponentProps = computed(() => {
  return {
    mode: actualMode.value,
    rootTask: props.rootTask,
    mini: props.displayMode === GridMode.DOUBLE_COLUMN,  // 2xn 模式使用 mini
    showCollaborationActions: false,  // 在 Index.vue 中不显示协作按钮
    showPublishButton: false,         // 在 Index.vue 中不显示发布按钮
  };
});

// 议题组件的 props
const issueComponentProps = computed(() => {
  return {
    mode: actualMode.value,
    rootTaskId: rootTaskId.value,
    rootTask: props.rootTask,
    mini: props.displayMode === GridMode.DOUBLE_COLUMN,
  };
});
```

##### 5. 事件处理

组件处理子组件的事件并向上传递：

```typescript
// 处理刷新事件
async function handleRefresh() {
  emit('refresh', { 
    operation: 'task_update', 
    mode: actualMode.value 
  });
}

// 处理 issue 更新事件
function handleIssueUpdated(data: any) {
  emit('issue-updated', {
    ...data,
    mode: actualMode.value,
    displayMode: props.displayMode
  });
}
```

**使用场景**:

1. **首页任务卡片**: 
   - `displayMode`: 根据用户设置（单列/双列）
   - `mode`: 不指定，自动根据任务状态选择
   - 结果：未发布任务自动进入编辑模式，已发布任务进入查看模式

2. **Drawer 抽屉模式**:
   - `displayMode`: SINGLE_COLUMN
   - `mode`: 明确指定（VIEW/EDIT/MEETING）
   - 结果：使用指定的模式，不受任务状态影响

3. **双列布局模式**:
   - `displayMode`: DOUBLE_COLUMN
   - 结果：统一使用 PREVIEW 模式（mini），节省空间

#### 3.2.4 TaskTreeViewMain

**路径**: `src/components/TaskPanel/TaskTreeViewMain.vue`

**职责**:
- 任务树查看模式展示（用于已发布的任务）
- 任务状态标签显示
- 任务操作按钮（接受、提交、完成等）
- 支持添加子任务（悬停显示工具栏）

**Props**:
```typescript
interface Props {
  mode: TaskPanelMode              // 面板模式
  rootTask: RootTask               // 根任务对象
  mini?: boolean                   // 是否为 mini 模式（双列布局）
  showCollaborationActions?: boolean // 是否显示协作按钮
  showPublishButton?: boolean      // 是否显示发布按钮
}
```

**实现逻辑**:

1. **任务树渲染**:
   - 使用 `BasicTaskTree` 组件递归渲染任务树
   - 支持展开/折叠操作
   - 默认展开所有节点 (`defaultExpandAll: true`)

2. **任务卡片展示**:
   - 显示任务负责人头像和名称
   - 显示任务标题、描述
   - 显示任务状态标签（带颜色区分）
   - 显示金币数量（子任务）
   - 显示延期次数标签（如果有）
   - 支持 WikiTask 状态显示（代码标注、文档提交状态）

3. **交互功能**:
   - 悬停显示子任务工具栏（添加子任务按钮）
   - 点击添加子任务按钮，显示内联编辑器
   - 支持保存和取消新建子任务

4. **Mini 模式适配**:
   - 当 `mini: true` 时，使用更小的字体和图标尺寸
   - 优化空间占用，适合双列布局

#### 3.2.5 TaskTreeEditMain

**路径**: `src/components/TaskPanel/TaskTreeEditMain.vue`

**职责**:
- 任务树编辑模式（用于未发布的任务）
- 根任务和子任务的编辑表单
- 任务创建、更新、删除
- 任务发布功能
- 可视化任务树结构（带连接线）

**Props**:
```typescript
interface Props {
  rootTask?: RootTask               // 根任务数据
  preFetchedTask?: any              // 预获取的任务数据
  preFetchedOptions?: any           // 预获取的选项数据
  mode?: TaskPanelMode              // 面板模式
  showCollaborationActions?: boolean // 是否显示协作编辑按钮
  showPublishButton?: boolean       // 是否显示发布按钮
}
```

**实现逻辑**:

1. **可视化任务树结构**:
   - 使用自定义 CSS 绘制任务树连接线
   - 根任务在顶部，子任务垂直排列
   - 每个子任务有分支连接线连接到主垂直线
   - 最后一个子任务有遮罩层，隐藏多余的连接线

2. **根任务编辑**:
   - 使用 `TaskEditor` 组件编辑根任务
   - 支持编辑标题、描述、任务类型、金币、负责人等
   - 根据权限控制是否可编辑（`canEditRootTask()`）
   - 支持添加子任务和 WikiTask

3. **子任务管理**:
   - 每个子任务使用独立的 `TaskEditor` 组件
   - 支持编辑、删除子任务
   - 根据权限控制编辑权限（`canEditSubTask()`）
   - 支持设置负责人只读（`isAssigneeReadonly()`）
   - 支持设置金币只读（`isCoinsReadonly()`）

4. **保存和发布**:
   - **保存**: 保存任务树的所有变更（根任务 + 所有子任务）
   - **发布**: 发布根任务，使其进入已发布状态
   - 保存前会验证所有任务的必填字段
   - 使用批量 API 提高性能

5. **协作编辑支持**:
   - 集成 `CollaborationActions` 组件
   - 显示任务编辑锁状态
   - 支持请求编辑权限

6. **WikiTask 支持**:
   - 支持创建 WikiTask（代码百科任务）
   - 显示 WikiTask 创建对话框
   - 处理 WikiTask 创建成功回调

#### 3.2.6 TaskTreeMeetingMain

**路径**: `src/components/TaskPanel/TaskTreeMeetingMain.vue`

**职责**:
- 任务树会议模式展示（用于会议中的任务）
- 会议相关的任务操作（通过、不通过、延期等）
- 会议笔记显示
- WikiTask 投票功能

**Props**:
```typescript
interface Props {
  mode: TaskPanelMode
  rootTask: RootTask
  // ... 其他 props
}
```

**实现逻辑**:

1. **会议信息加载**:
   - 从 `meetingStore` 获取当前会议信息
   - 显示加载遮罩层，直到会议信息准备就绪
   - 加载会议关联的任务树数据

2. **任务树展示**:
   - 使用 `BasicTaskTree` 组件展示任务树
   - 显示任务状态、负责人、金币等信息
   - 支持 WikiTask 状态显示

3. **会议操作工具栏**:
   - **通过按钮**: 标记任务为已通过验收（`STATUS_CHECKED`）
   - **不通过按钮**: 标记任务为不通过验收（`STATUS_STRIKED`）
   - **延期按钮**: 为任务申请延期
   - **撤销按钮**: 撤销之前的验收操作
   - **投票按钮**: WikiTask 专用，支持投票选择获胜者
   - 根据任务状态和权限控制按钮显示

4. **会议笔记**:
   - 显示会议笔记列表
   - 支持添加、删除会议笔记
   - 笔记关联到具体的任务节点

5. **实时更新**:
   - 监听 WebSocket 消息，实时更新任务状态
   - 处理其他参与者的操作（通过、不通过、延期等）
   - 显示操作者信息

#### 3.2.7 TaskEditor

**路径**: `src/components/TaskPanel/TaskEditor.vue`

**职责**:
- 任务编辑表单组件（根任务和子任务通用）
- 表单字段验证
- 支持只读模式
- 支持 WikiTask 对编辑

**Props**:
```typescript
interface Props {
  task: Task                    // 任务对象
  userOptions: UserOption[]     // 用户选项列表
  taskTypeOptions: TaskTypeOption[] // 任务类型选项列表
  showAddSubTask?: boolean      // 是否显示添加子任务按钮
  showDelete?: boolean          // 是否显示删除按钮
  isRoot?: boolean              // 是否为根任务
  readonly?: boolean            // 是否只读
  readonlyAssignee?: boolean    // 负责人是否只读
  readonlyCoins?: boolean       // 金币是否只读
  allowDelete?: boolean         // 是否允许删除
  optionsLoading?: boolean      // 选项加载状态
}
```

**实现逻辑**:

1. **根任务和子任务的布局差异**:
   - **根任务**: 标题和责任人在同一行，描述在下方
   - **子任务**: 责任人、金币、标题在同一行，描述在下方

2. **表单字段**:
   - **标题** (`title`): 必填，带前缀图标
   - **负责人** (`assignee_id`): 必填（子任务），下拉选择
   - **金币** (`coins`): 必填（子任务），数字输入，范围 0-10000
   - **任务类型** (`task_type`): 下拉选择
   - **描述** (`description`): 文本域，必填
   - **任务时长** (`task_duration`): 只读显示（根任务）

3. **WikiTask 对支持**:
   - 当 `task.isWikiTaskPair === true` 时，显示两个负责人
   - 负责人字段宽度自动调整为 180px
   - 显示格式：`负责人1 / 负责人2`

4. **只读模式**:
   - `readonly: true`: 所有字段只读
   - `readonlyAssignee: true`: 仅负责人字段只读
   - `readonlyCoins: true`: 仅金币字段只读
   - 只读模式下，输入框显示为文本

5. **表单验证**:
   - 使用 Ant Design Vue 的 Form 组件进行验证
   - 必填字段验证
   - 数字范围验证（金币）
   - 实时验证（`validateTrigger: 'blur'`）

6. **事件**:
   - `@update:task`: 字段变更时触发，传递更新后的任务对象
   - `@addSubTask`: 添加子任务时触发
   - `@delete`: 删除任务时触发
   - `@addWikiTask`: 添加 WikiTask 时触发

7. **删除功能**:
   - 仅子任务支持删除
   - 显示删除按钮（当 `showDelete && allowDelete` 时）
   - 删除前需要确认

#### 3.2.5 TaskTree

**路径**: `src/components/TaskTree/TaskTree.vue`

**职责**:
- 递归渲染任务树
- 任务节点展开/折叠
- 任务选择和高亮

**Props**:
```typescript
interface Props {
  tasks: Task[]           // 任务列表
  selectedTaskId?: number // 选中的任务ID
  expandedKeys?: number[] // 展开的节点keys
}
```

#### 3.2.6 TaskCard

**路径**: `src/components/Task/TaskCard.vue`

**职责**:
- 任务卡片展示
- 任务基本信息显示（标题、状态、金币、负责人等）
- 任务操作入口

**Props**:
```typescript
interface Props {
  task: Task
  showActions?: boolean   // 是否显示操作按钮
}
```

---

## 4. Store 说明

### 4.1 Task Store

**路径**: `src/store/modules/task.ts`

**State 定义**:
```typescript
interface TaskState {
  tasks: Task[]                    // 任务列表
  currentTask: Task | null         // 当前选中的任务
  loading: boolean                 // 加载状态
  pagination: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
  rootTasks: RootTask[]            // 根任务列表
  taskTree: TaskTree               // 任务树结构
}
```

**Getters**:
```typescript
getters: {
  // 获取根任务
  rootTasks: (state) => state.tasks.filter(t => !t.parent_id),
  
  // 获取我的任务（作为负责人）
  myTasks: (state) => state.tasks.filter(t => t.assignee_id === currentUserId),
  
  // 按状态筛选任务
  tasksByStatus: (state) => (status: number) => {
    return state.tasks.filter(t => t.status === status)
  },
  
  // 获取任务树
  taskTree: (state) => buildTaskTree(state.tasks)
}
```

**Actions**:
```typescript
actions: {
  // 获取任务列表
  async fetchTasks(params?: TaskQueryParams) {
    this.loading = true
    try {
      const res = await TaskIndexApi(params)
      this.tasks = res.data.tasks
      this.pagination = res.data.pagination
    } finally {
      this.loading = false
    }
  },

  // 获取任务详情
  async fetchTaskDetail(id: number) {
    const res = await TaskInfoApi({ id })
    this.currentTask = res.data.task
    return this.currentTask
  },

  // 创建任务
  async createTask(data: TaskCreateParams) {
    const res = await TaskCreateApi(data)
    this.tasks.unshift(res.data.task)
    return res.data.task
  },

  // 更新任务
  async updateTask(data: TaskUpdateParams) {
    const res = await TaskUpdateApi(data)
    const index = this.tasks.findIndex(t => t.id === data.id)
    if (index !== -1) {
      this.tasks[index] = res.data.task
    }
    if (this.currentTask?.id === data.id) {
      this.currentTask = res.data.task
    }
    return res.data.task
  },

  // 更新任务状态
  async updateTaskStatus(id: number, action: string) {
    const apiMap = {
      'accept': TaskAcceptApi,
      'read': TaskReadApi,
      'submit': TaskSubmitApi,
      'succeed': TaskSucceedApi,
      'fail': TaskFailedApi,
      'abort': TaskAbortApi
    }
    const api = apiMap[action]
    if (!api) throw new Error(`Unknown action: ${action}`)
    
    const res = await api({ id })
    const index = this.tasks.findIndex(t => t.id === id)
    if (index !== -1) {
      this.tasks[index] = res.data.task
    }
    if (this.currentTask?.id === id) {
      this.currentTask = res.data.task
    }
    return res.data.task
  },

  // 获取根任务列表（带Issue）
  async fetchRootTasksWithIssues() {
    const res = await ListRootTaskWithIssueApi()
    this.rootTasks = res.data.root_tasks
    return this.rootTasks
  }
}
```

---

## 5. API 调用规范

### 5.1 API 接口列表

**文件路径**: `src/api/data/task.ts`

| API函数 | 后端接口 | 说明 | 参数类型 |
|---------|---------|------|---------|
| `TaskIndexApi` | `GET /task/index` | 获取任务列表 | `TaskQueryParams` |
| `TaskInfoApi` | `GET /task/info` | 获取任务详情 | `{ id: number }` |
| `TaskCreateApi` | `POST /task/create` | 创建任务 | `TaskCreateParams` |
| `TaskUpdateApi` | `POST /task/update` | 更新任务 | `TaskUpdateParams` |
| `TaskDeleteApi` | `POST /task/delete` | 删除任务 | `{ id: number }` |
| `TaskOptionsApi` | `GET /task/get_create_options` | 获取创建选项 | `{ parent_id?: number }` |
| `TaskAcceptApi` | `POST /task/accept` | 接受任务 | `{ id: number }` |
| `TaskReadApi` | `POST /task/read` | 标记已读 | `{ id: number }` |
| `TaskSucceedApi` | `POST /task/succeed` | 任务成功 | `{ id: number }` |
| `TaskFailedApi` | `POST /task/fail` | 任务失败 | `{ id: number }` |
| `TaskAbortApi` | `POST /task/abort` | 任务取消 | `{ id: number, reason?: string }` |
| `ListRootTaskWithIssueApi` | `GET /task/list_root_tasks_with_issues` | 获取根任务列表（带Issue） | - |

### 5.2 参数类型定义

```typescript
// 任务查询参数
interface TaskQueryParams {
  status?: number      // 任务状态筛选
  page?: number        // 页码
  per_page?: number    // 每页数量
}

// 任务创建参数
interface TaskCreateParams {
  title: string
  description: string
  task_type: number
  coins: number
  currency: number
  assignee_id: number       // 必填, 任务负责人
  parent_id?: number         // 可选, 为空则为根任务
  could_dispatch?: boolean
  scheduled_start?: string
  scheduled_deadline?: string
}

// 任务更新参数
interface TaskUpdateParams {
  id: number
  title?: string
  description?: string
  coins?: number
  scheduled_start?: string
  scheduled_deadline?: string
}

// 任务类型
interface Task {
  id: number
  title: string
  description: string
  status: number
  status_text: string
  task_type: number
  task_type_text: string
  coins: number
  currency: number
  currency_text: string
  assignee?: User
  assignor?: User
  parent_id?: number
  children?: Task[]
  scheduled_start?: string
  scheduled_deadline?: string
  created_at: string
  updated_at: string
}
```

### 5.3 API 调用示例

```typescript
import { TaskIndexApi, TaskCreateApi, TaskInfoApi } from '/@/api/data/task'

// 获取任务列表
const loadTasks = async () => {
  const res = await TaskIndexApi({
    status: 0,
    page: 1,
    per_page: 20
  })
  tasks.value = res.data.tasks
  pagination.value = res.data.pagination
}

// 创建任务
const createTask = async (formData: TaskCreateParams) => {
  const res = await TaskCreateApi(formData)
  if (res.code === 0) {
    message.success('任务创建成功')
    // 刷新列表
    await loadTasks()
  }
}

// 获取任务详情
const loadTaskDetail = async (id: number) => {
  const res = await TaskInfoApi({ id })
  currentTask.value = res.data.task
}
```

---

## 6. 交互流程

### 6.1 首页访问流程

```
1. 用户登录后自动跳转到 /dashboard/index
   ↓
2. 首页加载 TaskGridList 组件
   ↓
3. 调用 API 获取根任务列表（带Issue）
   ↓
4. 渲染任务网格卡片
   ↓
5. 用户可以通过以下方式操作：
   - 点击任务卡片查看详情
   - 使用快捷键切换布局（Alt+1/Alt+2）
   - 点击协作按钮开始编辑
   - 点击会议按钮预约/加入会议
```

### 6.2 任务创建流程

```
1. 用户点击"创建任务"按钮
   ↓
2. 打开任务创建Modal
   ↓
3. 调用 TaskOptionsApi 获取选项数据
   - 任务类型列表
   - 可选负责人列表
   - 可用金币数量
   ↓
4. 用户填写表单
   - 任务标题（必填）
   - 任务描述（必填）
   - 任务类型
   - 金币数量
   - 货币类型
   - 负责人（必填）
   ↓
5. 前端表单验证
   - 标题不能为空
   - 描述不能为空
   - 金币数量 >= 0
   ↓
6. 调用 TaskCreateApi 创建任务
   ↓
7. 成功后：
   - 显示成功提示
   - 关闭Modal
   - 刷新任务列表
   - 如果是在任务树中创建子任务，刷新任务树
```

### 6.3 任务状态流转流程

```
任务状态流转按钮显示规则：

1. 接受任务按钮
   显示条件: status === OPEN || status === READ
   操作: 调用 TaskAcceptApi
   
2. 提交任务按钮
   显示条件: status === ACCEPTED
   操作: 调用 TaskSubmitApi
   
3. 任务成功按钮
   显示条件: status === CHECKED || status === ACCOMPLISHED
   权限: 需要关闭任务权限
   操作: 调用 TaskSucceedApi
   
4. 任务失败按钮
   显示条件: status === CHECKED || status === ACCOMPLISHED
   权限: 需要关闭任务权限
   操作: 调用 TaskFailedApi
   
5. 任务取消按钮
   显示条件: 所有状态（除已关闭状态）
   权限: 需要关闭任务权限
   操作: 调用 TaskAbortApi（需要输入取消原因）
```

### 6.4 任务编辑流程

```
1. 用户点击任务卡片或任务树节点
   ↓
2. 打开任务详情面板（Drawer或Index模式）
   ↓
3. 切换到编辑模式（TaskTreeEditMain）
   ↓
4. 用户修改任务信息
   - 标题
   - 描述
   - 金币
   - 时间
   ↓
5. 调用 TaskUpdateApi 更新任务
   ↓
6. 成功后刷新任务树和任务列表
```

### 6.5 布局切换流程

```
1. 用户在首页使用快捷键
   - Alt+1: 切换到单列布局
   - Alt+2: 切换到双列布局
   ↓
2. 快捷键事件被 DashboardIndex 捕获
   ↓
3. 调用 pageStateStore.setTaskGridMode() 更新布局模式
   ↓
4. TaskGridList 响应式更新布局
   ↓
5. 任务卡片重新排列
```

**注意**: 更多任务管理快捷键请参考 [快捷键系统文档](./shortcuts.md#32-任务管理快捷键)

### 6.7 弹窗和提示

| 操作 | 弹窗类型 | 说明 |
|------|---------|------|
| 创建任务 | Modal | 全屏Modal，包含完整表单 |
| 编辑任务 | Drawer/Index | 根据显示模式选择 |
| 任务详情 | Drawer/Index | 查看模式，只读 |
| 删除任务 | Modal确认 | 二次确认删除 |
| 任务取消 | Modal | 需要输入取消原因 |
| 出价 | Modal | 输入出价金额 |
| 成功提示 | Message | 操作成功提示 |
| 错误提示 | Message/Modal | 根据错误类型选择 |

---

## 7. UI 规范

### 7.1 视觉一致性

- **颜色规范**:
  - 任务状态标签使用 Ant Design 的 Tag 组件
  - 灰币: `#8c8c8c`
  - 红币: `#ff4d4f`
  - 蓝币: `#1890ff`

- **间距规范**:
  - 卡片间距: `16px`
  - 内容内边距: `16px`
  - 组件间距: `8px`

- **字体规范**:
  - 标题: `16px`, `font-weight: 500`
  - 正文: `14px`, `font-weight: 400`
  - 辅助文字: `12px`, `color: #8c8c8c`

### 7.2 Ant Design Vue 风格

- **按钮**: 使用 `Button` 组件，主要操作使用 `type="primary"`
- **表单**: 使用 `Form` + `FormItem` 组件
- **表格**: 使用 `Table` 组件（数据维护页面）
- **树形**: 使用 `Tree` 组件展示任务树
- **卡片**: 使用 `Card` 组件展示任务卡片
- **标签**: 使用 `Tag` 组件展示状态和类型
- **抽屉**: 使用 `Drawer` 组件展示任务详情

### 7.3 响应式设计

#### 7.3.1 布局模式

- **单列模式** (`SINGLE_COLUMN`): 
  - 任务卡片垂直排列（每行一个任务）
  - 任务树和议题列表垂直排列（上下布局）
  - 任务面板占据全宽
  - 适合移动端和窄屏
  - 适合需要详细查看单个任务的场景
- **双列模式** (`DOUBLE_COLUMN`): 
  - 任务卡片可多列显示（2列）
  - 任务树和议题列表水平排列（左右布局）
  - 任务面板使用 mini 模式（预览模式）
  - 适合宽屏显示
  - 适合需要同时查看多个任务的场景

#### 7.3.2 布局切换

- **快捷键切换**: 
  - `Alt+1`: 切换到单列布局
  - `Alt+2`: 切换到双列布局
- **用户设置切换**: 
  - 通过用户头像下拉菜单中的"任务设置"切换
  - 设置会持久化保存到本地存储
- **移动端适配**: 自动切换为单列模式
- **布局状态管理**: 使用 `pageStateStore` 管理布局模式状态

### 7.4 加载状态

- **列表加载**: 使用 `Skeleton` 组件显示骨架屏
- **按钮加载**: 使用 `loading` 属性
- **页面加载**: 使用 `PageWrapper` 的 `loading` 属性

---

## 8. 权限控制

### 8.1 按钮显示规则

#### 8.1.1 任务创建按钮

```typescript
// 显示条件：用户有创建任务权限
const canCreateTask = computed(() => {
  return userStore.hasPermission('task:create')
})
```

#### 8.1.2 任务编辑按钮

```typescript
// 显示条件：
// 1. 用户是任务分配人（assignor）
// 2. 用户有编辑任务权限
const canEditTask = computed(() => {
  const task = props.task
  const currentUser = userStore.getUserInfo
  return task.assignor_id === currentUser.id || 
         userStore.hasPermission('task:edit')
})
```

#### 8.1.3 任务删除按钮

```typescript
// 显示条件：
// 1. 用户是任务分配人
// 2. 任务状态允许删除（未关闭状态）
const canDeleteTask = computed(() => {
  const task = props.task
  const currentUser = userStore.getUserInfo
  const deletableStatuses = [
    TaskStatus.OPEN,
    TaskStatus.READ,
    TaskStatus.ACCEPTED
  ]
  return task.assignor_id === currentUser.id && 
         deletableStatuses.includes(task.status)
})
```

#### 8.1.4 任务状态操作按钮

```typescript
// 接受任务按钮
const canAccept = computed(() => {
  const task = props.task
  const currentUser = userStore.getUserInfo
  return task.assignee_id === currentUser.id &&
         (task.status === TaskStatus.OPEN || task.status === TaskStatus.READ)
})

// 提交任务按钮
const canSubmit = computed(() => {
  const task = props.task
  const currentUser = userStore.getUserInfo
  return task.assignee_id === currentUser.id &&
         task.status === TaskStatus.ACCEPTED
})

// 任务成功/失败按钮
const canCloseTask = computed(() => {
  const task = props.task
  const currentUser = userStore.getUserInfo
  // 需要关闭任务权限
  return userStore.hasPermission('task:close') &&
         (task.status === TaskStatus.CHECKED || 
          task.status === TaskStatus.ACCOMPLISHED)
})
```

### 8.2 按钮禁用规则

```typescript
// 编辑按钮禁用条件
const editDisabled = computed(() => {
  const task = props.task
  // 任务已关闭，禁用编辑
  const closedStatuses = [
    TaskStatus.SUCCEEDED,
    TaskStatus.FAILED,
    TaskStatus.ABORTED
  ]
  return closedStatuses.includes(task.status)
})

// 删除按钮禁用条件
const deleteDisabled = computed(() => {
  const task = props.task
  // 任务有子任务，禁用删除
  return task.children_count > 0
})
```

### 8.3 字段显示控制

```typescript
// 金币字段显示
const showCoins = computed(() => {
  return task.coins > 0
})

// 负责人字段显示
const showAssignee = computed(() => {
  return task.assignee_id !== null
})

```

---

## 9. WebSocket 通知处理

### 9.1 通知机制概述

任务模块通过 WebSocket 实时接收后端推送的任务状态变更通知。前端通过 `notificationStore` 订阅 `WebNotificationChannel` 并处理各种任务相关的通知事件。

### 9.2 通知订阅

**文件路径**: `src/store/modules/notification.ts`

```typescript
export const useNotificationStore = defineStore('notification', () => {
  const socketStore = useSocketStore();
  
  // 初始化通知系统
  const initNotification = () => {
    if (!isSubscribed.value) {
      if (socketStore.isConnected && socketStore.isReady) {
        // 订阅 WebNotificationChannel
        socketStore.subscribeNotifyChannel();
        isSubscribed.value = true;
      }
    }
  };
  
  // 监听 WebSocket 消息
  watch(
    () => socketStore.message,
    (newMessage) => {
      if (newMessage && newMessage.act && newMessage.type === 'notification') {
        const { act: action, data } = newMessage;
        handleWebSocketMessage({ act: action, data });
      }
    },
    { deep: true }
  );
});
```

### 9.3 任务通知类型

前端支持以下任务通知类型：

| 通知类型 | Action 值 | 处理逻辑 | 显示内容 |
|---------|-----------|---------|---------|
| 任务创建 | `task_create` | 刷新任务列表 | "任务创建" - "有新的任务被创建" |
| 任务成功 | `task_succeed` | 刷新任务列表 | "任务完成" - "任务已成功完成" |
| 任务失败 | `task_fail` | 刷新任务列表 | "任务失败" - "任务执行失败" |
| 任务中止 | `task_abort` | 刷新任务列表 | "任务中止" - "任务已被中止" |

### 9.4 通知处理逻辑

**文件路径**: `src/store/modules/notification.ts`

```typescript
function handleWebSocketMessage(message: any) {
  const { act: action, data } = message;
  
  // 更新当前消息和历史记录
  currentMessage.value = { action, data };
  messageHistory.value.unshift({ action, data });
  
  // 根据不同的 action 处理
  switch (action) {
    case WsActionEnum.TASK_CREATE:
    case WsActionEnum.TASK_SUCCEED:
    case WsActionEnum.TASK_FAILED:
    case WsActionEnum.TASK_ABORT:
      // 刷新任务列表
      refreshView();
      // 显示通知
      showNotification(getNotificationTitle(action), getNotificationDesc(action), getNotificationType(action));
      break;
  }
}
```

### 9.5 在组件中使用通知

在任务相关组件中监听通知并刷新数据：

**文件路径**: `src/views/dashboard/components/TaskGridList.vue`

```typescript
import { useNotificationStore } from '/@/store/modules/notification';
import { WsActionEnum } from '/@/enums/wsActionEnum';

const notificationStore = useNotificationStore();

// 监听通知消息变化
watch(
  () => notificationStore.currentMessage,
  (newMessage) => {
    if (newMessage && newMessage.action) {
      const { action, data } = newMessage;
      
      switch (action) {
        case WsActionEnum.TASK_CREATE:
        case WsActionEnum.TASK_SUCCEED:
        case WsActionEnum.TASK_FAILED:
        case WsActionEnum.TASK_ABORT:
          // 刷新任务列表
          refreshView();
          break;
      }
    }
  }
);
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
    action: string;   // 通知类型（如 'task_create'）
    task_id: number; // 任务ID
    // ... 其他相关数据
  };
  user_id: number;    // 触发通知的用户ID
}
```

### 9.7 初始化通知系统

在应用启动时初始化通知系统：

```typescript
// 在 main.ts 或 App.vue 中
import { useNotificationStore } from '/@/store/modules/notification';

const notificationStore = useNotificationStore();

// 应用启动后初始化
onMounted(() => {
  notificationStore.initNotification();
});
```

---

## 10. 快捷键支持

### 10.1 任务管理快捷键

任务管理模块支持以下快捷键（详细说明请参考 [快捷键系统文档](./shortcuts.md)）：

| 快捷键 | 功能 | 作用域 |
|--------|------|--------|
| `Alt+N` | 创建新任务 | global |
| `Ctrl+Enter` 或 `Cmd+Enter` | 完成/发布任务 | task |
| `J` 或 `↓` | 选择下一个任务 | task |
| `K` 或 `↑` | 选择上一个任务 | task |
| `Enter` | 打开任务详情 | task |
| `Escape` | 关闭任务详情 | task |
| `[` | 展开任务树 | task |
| `]` | 收起任务树 | task |
| `Alt+1` | 切换单列布局 | task |
| `Alt+2` | 切换双列布局 | task |
| `Ctrl+M` 或 `Cmd+M` | 为选中任务创建会议 | task |
| `Ctrl+Shift+G` 或 `Cmd+Shift+G` | 进入选中任务的会议 | task |
| `Ctrl+Alt+I` 或 `Cmd+Alt+I` | 为选中任务创建 Issue | task |

### 10.2 快捷键使用

在任务相关组件中使用 `useTaskShortcuts` Hook：

```typescript
import { useTaskShortcuts } from '/@/hooks/web/useTaskShortcuts'

const taskShortcuts = useTaskShortcuts({
  onCreateTask: () => {
    // 创建任务逻辑
  },
  onNextTask: () => {
    // 下一个任务
  },
  onLayoutSingle: () => {
    // 单列布局
  },
  onLayoutDouble: () => {
    // 双列布局
  },
})
```

更多快捷键使用说明请参考 [快捷键系统文档](./shortcuts.md#52-任务管理快捷键)。

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

