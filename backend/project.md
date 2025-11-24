# 项目管理模块 - 后端文档

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

项目管理模块负责：

- **项目生命周期管理**: 从创建到关闭的完整流程
- **成员管理**: 添加、移除项目成员
- **Issue管理**: 创建、跟踪、关闭Issue
- **第三方平台集成**: GitHub、GitLab、Jira集成

---

## 2. 数据模型（Model/Schema）

### 2.1 Project 模型

```ruby
class Project < ApplicationRecord
  belongs_to :principal, class_name: "User"
  belongs_to :thirdparty_platform, optional: true
  has_many :participants, class_name: "Project::Participant"
  has_many :issues, class_name: "Project::Issue"
  has_many :contracts, class_name: "FinancialAccounting::Contract"
end
```

### 2.2 Project::Issue 模型

```ruby
class Project::Issue < ApplicationRecord
  belongs_to :project
  belongs_to :task, optional: true
  belongs_to :creator, class_name: "User"
  has_many :status_histories, class_name: "IssueStatusHistory"
end
```

---

## 3. API 规范（Controller/Route）

### 3.1 创建项目

```ruby
# POST /project/create
def create
  project_params = params.permit(:name, :description, :project_type, :principal_id, :currency, :base_salary)
  project = Project.create!(project_params)
  render_success({ project: project.to_json })
end
```

### 3.2 创建Issue

```ruby
# POST /project/create_issue
def create_issue
  issue_params = params.permit(:project_id, :title, :description, :priority, :task_id)
  issue = Project::Issue.create!(issue_params.merge(creator_id: current_user.id))
  render_success({ issue: issue.to_json })
end
```

---

## 4. 业务逻辑流程

### 4.1 项目创建流程

```ruby
def self.create_project(user, params)
  ActiveRecord::Base.transaction do
    project = Project.create!(params.merge(principal_id: user.id))
    { success: true, project: project }
  end
end
```

---

## 5. 权限与鉴权规则

- 项目负责人可以编辑和删除项目
- 项目成员可以创建和查看Issue

---

## 6. 错误码和响应规范

标准响应格式，参考通用规范。

---

## 7. 定时任务/队列处理/事件

无特殊定时任务。

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN后端开发团队

