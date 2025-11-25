# 代码分析系统模块 - 后端文档

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

代码分析系统模块负责：

- **代码仓库管理**: Git/SVN仓库添加和管理
- **分析规则配置**: 代码分析规则配置
- **分析结果展示**: 代码分析结果查看

---

## 2. 数据模型（Model/Schema）

### 2.1 CodeAnalyze::Repository 模型

```ruby
class CodeAnalyze::Repository < ApplicationRecord
  has_many :results
  has_many :repo_users
  
  # 字段: id, name, url, repo_type, branch, status
end
```

---

## 3. API 规范（Controller/Route）

### 3.1 添加代码库

```ruby
# POST /code_analyze/repository/add_repo
def add_repo
  repo_params = params.permit(:name, :url, :repo_type, :branch)
  repository = CodeAnalyze::Repository.create!(repo_params)
  render_success({ repository: repository.to_json })
end
```

### 3.2 获取分析结果

```ruby
# GET /code_analyze/analyze/analysis_result
def analysis_result
  repository_id = params[:repository_id]
  results = CodeAnalyze::Result.where(repository_id: repository_id)
  render_success({ results: results.map(&:to_json) })
end
```

---

## 4. 业务逻辑流程

标准CRUD流程。

---

## 5. 权限与鉴权规则

- 管理员可以管理代码仓库
- 开发者可以查看分析结果

---

## 6. 错误码和响应规范

标准响应格式。

---

## 7. 定时任务/队列处理/事件

### 7.1 代码分析任务

后台任务执行代码分析，更新分析结果。

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN后端开发团队

