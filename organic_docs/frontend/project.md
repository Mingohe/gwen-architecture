# 项目管理模块 - 前端文档

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

项目管理模块负责：

- **项目创建和管理**: 创建、编辑、删除项目
- **项目成员管理**: 添加、移除项目成员
- **Issue管理**: 创建、跟踪、关闭Issue
- **第三方平台集成**: GitHub、GitLab、Jira集成
- **项目财务关联**: 关联项目合同和收支

### 1.2 技术栈

- **框架**: Vue 3 + TypeScript
- **状态管理**: Pinia
- **UI组件**: Ant Design Vue

---

## 2. 页面结构

### 2.1 页面列表

| 页面路径 | 路由名称 | 组件路径 | 说明 |
|---------|---------|---------|------|
| `/data/project` | - | `src/views/data/project/Project.vue` | **项目管理页面** - 项目数据维护和管理 |

### 2.2 页面布局

#### 2.2.1 项目管理页面布局

**页面路径**: `/data/project`

**布局结构**:

```
项目管理页面 (/data/project)
└── PageWrapper (页面容器)
    └── BasicTable (数据表格)
        ├── toolbar (工具栏)
        │   ├── "添加" 按钮
        │   └── "刷新" 按钮
        └── Table (表格主体)
            ├── 列: 项目名称
            ├── 列: 项目描述
            ├── 列: 项目状态
            ├── 列: 创建时间
            └── 列: 操作列
                ├── "添加合同" 按钮
                ├── "编辑" 按钮
                └── "删除" 按钮
```

**布局特点**:

1. **工具栏区域**:
   - **添加按钮**: 创建新项目
   - **刷新按钮**: 重新加载项目列表

2. **表格区域**:
   - 使用 `BasicTable` 组件展示项目列表
   - 支持列宽调整（`canResize: true`）
   - 支持列拖拽排序（`canColDrag: true`）
   - 支持分页（默认每页 50 条）
   - 支持表格设置（显示/隐藏列）

3. **操作列**:
   - **添加合同**: 为项目添加合同
   - **编辑**: 编辑项目信息
   - **删除**: 删除项目（需确认）

**功能说明**:

| 功能区域 | 功能说明 |
|---------|---------|
| **项目列表** | 以表格形式展示所有项目，支持排序、筛选 |
| **项目创建** | 通过 Modal 创建新项目 |
| **项目编辑** | 通过 Modal 编辑项目信息 |
| **项目删除** | 删除项目（需二次确认） |
| **合同管理** | 为项目添加合同，关联财务系统 |
| **列自定义** | 支持调整列宽、拖拽排序、显示/隐藏列 |

#### 2.2.2 项目创建/编辑 Modal 布局

**组件**: `ProjectModal.vue`

**布局结构**:

```
ProjectModal (项目创建/编辑弹窗)
└── Form (表单)
    ├── 项目名称 (必填)
    ├── 项目描述
    ├── 项目状态
    ├── 第三方平台集成
    │   ├── GitHub
    │   ├── GitLab
    │   └── Jira
    └── 操作按钮
        ├── "取消" 按钮
        └── "确定" 按钮
```

---

## 3. 组件结构

### 3.1 组件树

```
Project.vue (项目管理)
├── ProjectList.vue (项目列表)
├── ProjectDetail.vue (项目详情)
│   ├── IssueList.vue (Issue列表)
│   └── ProjectMembers.vue (项目成员)
└── ProjectModal.vue (项目创建/编辑Modal)
```

---

## 4. Store 说明

### 4.1 Project Store

**State 定义**:
```typescript
interface ProjectState {
  projects: Project[]
  currentProject: Project | null
  loading: boolean
}
```

**Actions**:
```typescript
actions: {
  async fetchProjects() {
    const res = await ProjectListApi()
    this.projects = res.data.projects
  },
  
  async createProject(data: ProjectCreateParams) {
    const res = await ProjectCreateApi(data)
    this.projects.push(res.data.project)
    return res.data.project
  }
}
```

---

## 5. API 调用规范

### 5.1 API 接口列表

| API函数 | 后端接口 | 说明 |
|---------|---------|------|
| `ProjectListApi` | `GET /project/list` | 获取项目列表 |
| `ProjectCreateApi` | `POST /project/create` | 创建项目 |
| `ProjectCreateIssueApi` | `POST /project/create_issue` | 创建Issue |
| `ProjectListIssuesApi` | `GET /project/list_issues` | 获取Issue列表 |

---

## 6. 交互流程

### 6.1 项目创建流程

```
1. 用户点击工具栏的"添加"按钮
   ↓
2. 打开 ProjectModal（项目创建弹窗）
   ↓
3. 填写项目信息：
   - 项目名称（必填）
   - 项目描述
   - 项目状态
   - 第三方平台集成配置（可选）
     - GitHub 仓库
     - GitLab 仓库
     - Jira 项目
   ↓
4. 前端表单验证
   ↓
5. 调用 ProjectCreateApi 创建项目
   ↓
6. 成功后：
   - 显示成功提示
   - 关闭Modal
   - 刷新项目列表
```

### 6.2 项目编辑流程

```
1. 用户点击项目行的"编辑"按钮
   ↓
2. 打开 ProjectModal（项目编辑弹窗）
   - 预填充项目信息
   ↓
3. 修改项目信息
   ↓
4. 调用 ProjectUpdateApi 更新项目
   ↓
5. 成功后刷新列表
```

### 6.3 项目删除流程

```
1. 用户点击项目行的"删除"按钮
   ↓
2. 显示确认弹窗
   ↓
3. 用户确认删除
   ↓
4. 调用 ProjectDeleteApi 删除项目
   ↓
5. 成功后刷新列表
```

### 6.4 添加合同流程

```
1. 用户点击项目行的"添加合同"按钮
   ↓
2. 打开 ContractModal（合同创建弹窗）
   - 自动关联当前项目
   ↓
3. 填写合同信息
   ↓
4. 调用 ContractAddApi 创建合同
   ↓
5. 成功后：
   - 显示成功提示
   - 关闭Modal
   - 合同自动关联到项目
```

---

## 7. UI 规范

### 7.1 视觉设计

- **页面布局**: 使用 `PageWrapper` 实现全屏布局
- **表格展示**: 使用 `BasicTable` 组件，支持丰富的表格功能
- **弹窗交互**: 使用 `Modal` 组件进行创建和编辑操作

### 7.2 组件使用

- **BasicTable**: 数据表格，支持排序、筛选、分页、列自定义
- **TableAction**: 操作按钮组，统一的操作按钮样式
- **Modal**: 弹窗组件，用于项目创建和编辑
- **Form**: 表单组件，用于项目信息输入

### 7.3 交互反馈

- **加载状态**: 表格显示加载状态
- **操作确认**: 删除操作需要二次确认
- **成功提示**: 操作成功后显示提示消息
- **错误处理**: 操作失败时显示错误提示

---

## 8. 权限控制

- 项目负责人可以编辑和删除项目
- 项目成员可以创建和查看Issue

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

