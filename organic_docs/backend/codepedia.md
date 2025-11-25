# 代码文档系统模块 - 后端文档

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

代码文档系统（Codepedia）模块负责：

- **代码文档管理**: 代码文档创建和管理
- **需求提交流程**: Wiki任务需求提交
- **投票机制**: 代码文档投票
- **Wiki任务关联**: 与任务系统关联

---

## 2. 数据模型（Model/Schema）

### 2.1 Codepedia::CodeDocument 模型

```ruby
class Codepedia::CodeDocument < ApplicationRecord
  belongs_to :wiki_task
  
  # 字段: id, wiki_task_id, file_path, content
end
```

### 2.2 Codepedia::Vote 模型

```ruby
class Codepedia::Vote < ApplicationRecord
  belongs_to :user
  belongs_to :wiki_task
  
  # 字段: id, user_id, wiki_task_id, vote_type
end
```

---

## 3. API 规范（Controller/Route）

### 3.1 创建/更新代码文档

```ruby
# POST /codepedia/create_or_update_code_document
def create_or_update_code_document
  doc_params = params.permit(:wiki_task_id, :file_path, :content)
  document = Codepedia::CodeDocument.find_or_initialize_by(
    wiki_task_id: doc_params[:wiki_task_id],
    file_path: doc_params[:file_path]
  )
  document.update!(doc_params)
  render_success({ document: document.to_json })
end
```

### 3.2 投票

```ruby
# POST /codepedia/vote
def vote
  vote_params = params.permit(:wiki_task_id, :vote_type)
  vote = Codepedia::Vote.find_or_initialize_by(
    user_id: current_user.id,
    wiki_task_id: vote_params[:wiki_task_id]
  )
  vote.update!(vote_type: vote_params[:vote_type])
  render_success({ vote: vote.to_json })
end
```

---

## 4. 业务逻辑流程

标准CRUD和投票流程。

---

## 5. 权限与鉴权规则

- 所有用户可以查看和投票
- 开发者可以创建和编辑文档

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

