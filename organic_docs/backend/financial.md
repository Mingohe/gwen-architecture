# 财务管理系统模块 - 后端文档

> **返回**: [文档首页](../../README.md)

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

财务管理系统模块负责：

- **会计科目管理**: 会计科目树结构管理
- **项目合同管理**: 项目合同创建和管理
- **收支记录**: 收入支出记录管理
- **项目收支统计**: 项目收支统计和报表

---

## 2. 数据模型（Model/Schema）

### 2.1 FinancialAccounting::Account 模型

```ruby
class FinancialAccounting::Account < ApplicationRecord
  # 字段: id, code, name, parent_id, account_type, level
end
```

### 2.2 FinancialAccounting::Contract 模型

```ruby
class FinancialAccounting::Contract < ApplicationRecord
  belongs_to :project
  # 字段: id, project_id, name, amount, signed_date, status
end
```

### 2.3 FinancialAccounting::Document 模型

```ruby
class FinancialAccounting::Document < ApplicationRecord
  belongs_to :project
  belongs_to :account
  # 字段: id, project_id, account_id, document_type, amount, description, document_date
end
```

---

## 3. API 规范（Controller/Route）

### 3.1 获取会计科目

```ruby
# GET /financial_accouting/accounts
def accounts
  accounts = FinancialAccounting::Account.all
  render_success({ accounts: build_account_tree(accounts) })
end
```

### 3.2 项目收支统计

```ruby
# GET /financial_accouting/project_accouting_summary
def project_accouting_summary
  project_id = params[:project_id]
  summary = calculate_project_summary(project_id, params[:start_date], params[:end_date])
  render_success({ summary: summary })
end
```

---

## 4. 业务逻辑流程

标准CRUD和统计流程。

---

## 5. 权限与鉴权规则

- 财务管理员可以管理所有财务数据
- 项目负责人可以查看项目财务数据

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

