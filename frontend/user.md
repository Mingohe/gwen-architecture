# 用户与权限系统模块 - 前端文档

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

用户与权限系统模块负责：

- **用户管理**: 用户信息查看和编辑
- **角色权限管理**: 角色和权限配置
- **部门管理**: 部门层级管理
- **用户对账**: 用户对账明细查看

### 1.2 技术栈

- **框架**: Vue 3 + TypeScript
- **状态管理**: Pinia
- **UI组件**: Ant Design Vue

---

## 2. 页面结构

### 2.1 页面列表

| 页面路径 | 路由名称 | 组件路径 | 说明 |
|---------|---------|---------|------|
| `/profile/index` | `profile` | `src/views/profile/index.vue` | 用户资料页面 |
| `/data/user` | - | `src/views/data/user/User.vue` | 用户管理页面 |

---

## 3. 组件结构

### 3.1 组件树

```
UserProfile.vue (用户资料)
├── UserInfo.vue (用户信息)
├── UserRoles.vue (用户角色)
└── AccountStatement.vue (对账明细)
```

---

## 4. Store 说明

### 4.1 User Store

**State 定义**:
```typescript
interface UserState {
  userInfo: User | null
  roles: Role[]
  permissions: Permission[]
}
```

**Actions**:
```typescript
actions: {
  async fetchUserInfo() {
    const res = await UserMeApi()
    this.userInfo = res.data.user
  },
  
  async fetchAccountStatement(params: AccountStatementParams) {
    const res = await UserAccountStatementApi(params)
    return res.data
  }
}
```

---

## 5. API 调用规范

### 5.1 API 接口列表

| API函数 | 后端接口 | 说明 |
|---------|---------|------|
| `UserMeApi` | `GET /user/me` | 获取当前用户信息 |
| `UserAccountStatementApi` | `GET /user/account_statement` | 获取对账明细 |

---

## 6. 交互流程

### 6.1 用户信息查看流程

```
1. 用户进入个人资料页面
2. 调用 UserMeApi 获取用户信息
3. 显示用户信息和角色
```

---

## 7. UI 规范

- 使用 Ant Design Vue 组件
- 用户信息使用Descriptions组件
- 对账明细使用Table组件

---

## 8. 权限控制

- 用户只能查看和编辑自己的信息
- 管理员可以管理所有用户

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

