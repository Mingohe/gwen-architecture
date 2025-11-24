# 项目管理模块 - 前端文档

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
| `/data/project` | - | `src/views/data/project/Project.vue` | 项目管理页面 |

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
1. 用户点击"创建项目"
2. 打开项目创建Modal
3. 填写项目信息
4. 调用 ProjectCreateApi
5. 成功后刷新列表
```

---

## 7. UI 规范

- 使用 Ant Design Vue 组件
- 项目列表使用Table组件
- Issue列表使用Card组件

---

## 8. 权限控制

- 项目负责人可以编辑和删除项目
- 项目成员可以创建和查看Issue

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

