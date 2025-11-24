# 代码分析系统模块 - 前端文档

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

代码分析系统模块负责：

- **代码仓库管理**: Git/SVN仓库添加和管理
- **分析规则配置**: 代码分析规则配置
- **分析结果展示**: 代码分析结果查看

### 1.2 技术栈

- **框架**: Vue 3 + TypeScript
- **状态管理**: Pinia
- **UI组件**: Ant Design Vue

---

## 2. 页面结构

### 2.1 页面列表

| 页面路径 | 路由名称 | 组件路径 | 说明 |
|---------|---------|---------|------|
| `/code_analyze/repository` | - | `src/views/code_analyze/repository/index.vue` | 代码仓库管理 |

---

## 3. 组件结构

### 3.1 组件树

```
RepositoryManagement.vue (仓库管理)
├── RepositoryList.vue (仓库列表)
└── RepositoryForm.vue (仓库表单)

AnalysisResult.vue (分析结果)
└── ResultList.vue (结果列表)
```

---

## 4. Store 说明

### 4.1 CodeAnalyze Store

**State 定义**:
```typescript
interface CodeAnalyzeState {
  repositories: Repository[]
  analysisResults: AnalysisResult[]
  loading: boolean
}
```

---

## 5. API 调用规范

### 5.1 API 接口列表

| API函数 | 后端接口 | 说明 |
|---------|---------|------|
| `CodeAnalyzeAddRepoApi` | `POST /code_analyze/repository/add_repo` | 添加代码库 |
| `CodeAnalyzeAnalysisResultApi` | `GET /code_analyze/analyze/analysis_result` | 获取分析结果 |

---

## 6. 交互流程

标准CRUD流程。

---

## 7. UI 规范

- 使用 Ant Design Vue 组件
- 仓库列表使用Table组件

---

## 8. 权限控制

- 管理员可以管理代码仓库
- 开发者可以查看分析结果

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

