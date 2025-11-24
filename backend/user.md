# 用户与权限系统模块 - 后端文档

> **返回**: [文档首页](../README.md)

## 目录

- [1. 模块概述](#1-模块概述)
- [2. 数据模型（Model/Schema）](#2-数据模型modelschema)
- [3. API 规范（Controller/Route）](#3-api-规范controllerroute)
- [4. 业务逻辑流程（Service/UseCase）](#4-业务逻辑流程serviceusecase)
- [5. 权限与鉴权规则](#5-权限与鉴权规则)
- [6. 错误码和响应规范](#6-错误码和响应规范)
- [7. 定时任务/队列处理/事件](#7-定时任务队列处理事件)

---

## 1. 模块概述

### 1.1 模块职责

用户与权限系统模块负责：

- **用户管理**: 用户信息管理
- **角色权限管理**: 角色和权限配置
- **部门管理**: 部门层级管理
- **用户对账**: 用户对账明细统计

---

## 2. 数据模型（Model/Schema）

### 2.1 User 模型

```ruby
class User < ApplicationRecord
  has_many :assignor_tasks, class_name: 'Task', foreign_key: 'assignor_id'
  has_many :assignee_tasks, class_name: 'Task', foreign_key: 'assignee_id'
  has_many :sessions
  has_one_attached :avatar
end
```

### 2.2 Role 模型

```ruby
class Role < ApplicationRecord
  has_many :user_role_mappings
end
```

---

## 3. API 规范（Controller/Route）

### 3.1 获取当前用户信息

```ruby
# GET /user/me
def me
  render_success({ user: current_user.to_json })
end
```

### 3.2 用户对账明细

```ruby
# GET /user/account_statement
def account_statement
  statements = Tx.where(user_id: current_user.id)
                 .where(created_at: params[:start_date]..params[:end_date])
  render_success({ statements: statements.map(&:to_json) })
end
```

---

## 4. 业务逻辑流程

标准CRUD流程。

---

## 5. 权限与鉴权规则

- 用户只能查看自己的信息
- 管理员可以管理所有用户

---

## 6. 错误码和响应规范

标准响应格式。

---

## 7. 定时任务/队列处理/事件

无特殊定时任务。

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN后端开发团队

