# 代码文档系统模块 - 前端文档

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

代码文档系统（Codepedia）模块负责：

- **代码文档管理**: 代码文档创建和管理
- **需求提交流程**: Wiki任务需求提交
- **投票机制**: 代码文档投票
- **Wiki任务关联**: 与任务系统关联

### 1.2 技术栈

- **框架**: Vue 3 + TypeScript
- **状态管理**: Pinia
- **UI组件**: Ant Design Vue

---

## 2. 页面结构

### 2.1 页面列表

| 页面路径 | 路由名称 | 组件路径 | 说明 |
|---------|---------|---------|------|
| `/codepedia` | `codepedia` | `src/views/codepedia/index.vue` | 代码文档首页 |

---

## 3. 组件结构

### 3.1 组件树

```
CodepediaIndex.vue (代码文档首页)
├── CodeDocumentList.vue (文档列表)
├── CodeDocumentEditor.vue (文档编辑器)
└── VotePanel.vue (投票面板)
```

---

## 4. Store 说明

### 4.1 Codepedia Store

**State 定义**:
```typescript
interface CodepediaState {
  codeDocuments: CodeDocument[]
  wikiTasks: WikiTask[]
  votes: Vote[]
}
```

---

## 5. API 调用规范

### 5.1 API 接口列表

| API函数 | 后端接口 | 说明 |
|---------|---------|------|
| `CodepediaCreateOrUpdateCodeDocumentApi` | `POST /codepedia/create_or_update_code_document` | 创建/更新代码文档 |
| `CodepediaCodeDocumentsApi` | `GET /codepedia/code_documents` | 获取代码文档列表 |
| `CodepediaVoteApi` | `POST /codepedia/vote` | 投票 |

---

## 6. 交互流程

标准CRUD和投票流程。

---

## 7. UI 规范

- 使用 Ant Design Vue 组件
- 文档列表使用List组件
- 投票使用Button组件

---

## 8. 权限控制

- 所有用户可以查看和投票
- 开发者可以创建和编辑文档

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

