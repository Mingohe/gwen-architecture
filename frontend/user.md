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
| `/profile/index` | `profile` | `src/views/profile/index.vue` | **用户资料页面** - 个人资料和对账明细 |
| `/data/user` | - | `src/views/data/user/User.vue` | **用户管理页面** - 用户数据维护 |

### 2.2 页面布局

#### 2.2.1 用户资料页面布局

**页面路径**: `/profile/index`

**布局结构**:

```
用户资料页面 (/profile/index)
└── PageWrapper (页面容器)
    └── Tabs (标签页)
        ├── TabPane: "个人信息"
        │   └── Descriptions (描述列表)
        │       ├── 头像
        │       ├── 用户名
        │       ├── 邮箱
        │       ├── 角色
        │       └── 部门
        ├── TabPane: "对账明细"
        │   └── BasicTable (数据表格)
        │       ├── 列: 交易时间
        │       ├── 列: 交易类型
        │       ├── 列: 金额
        │       ├── 列: 货币类型
        │       └── 列: 关联任务/项目
        └── TabPane: "权限设置" (可选)
            └── 权限列表
```

**功能说明**:
- **个人信息**: 查看和编辑个人基本信息
- **对账明细**: 查看个人的所有交易记录（任务奖励、项目收入等）
- **权限设置**: 查看个人拥有的权限列表

#### 2.2.2 用户管理页面布局

**页面路径**: `/data/user`

**布局结构**:

```
用户管理页面 (/data/user)
└── PageWrapper (页面容器)
    └── BasicTable (数据表格)
        ├── toolbar (工具栏)
        │   ├── "添加" 按钮
        │   └── "刷新" 按钮
        └── Table (表格主体)
            ├── 列: 用户名
            ├── 列: 邮箱
            ├── 列: 角色
            ├── 列: 部门
            ├── 列: 状态
            └── 列: 操作列
                ├── "编辑" 按钮
                └── "删除" 按钮
```

**功能说明**:
- **用户列表**: 以表格形式展示所有用户
- **用户创建**: 创建新用户账号
- **用户编辑**: 编辑用户信息和角色
- **用户删除**: 删除用户（需确认）

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

