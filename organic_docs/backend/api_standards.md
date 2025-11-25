# REST API 接口规范

> **返回**: [文档首页](../../README.md)

## 目录

- [1. 概述](#1-概述)
- [2. 标准响应格式](#2-标准响应格式)
- [3. 响应方法规范](#3-响应方法规范)
- [4. 错误码规范](#4-错误码规范)
- [5. 请求规范](#5-请求规范)
- [6. 示例](#6-示例)

---

## 1. 概述

所有 REST API 接口必须遵循统一的响应格式和错误处理规范，确保前后端交互的一致性和可维护性。

### 1.1 核心原则

- ✅ **统一响应格式**：所有接口必须使用 `render_success` 和 `render_failure_json` 方法
- ✅ **标准字段不可覆盖**：`status`、`error_code`、`error_msg` 为保留字段，不能覆盖
- ✅ **错误码规范**：使用预定义的错误码常量，不使用魔法数字
- ✅ **异常处理**：使用 `ApiHelper::Error` 和 `ApiHelper::Warning` 处理业务异常

---

## 2. 标准响应格式

### 2.1 成功响应格式

所有成功响应必须包含以下标准字段：

```json
{
  "status": 0,
  "error_code": 0,
  "error_msg": "",
  // ... 业务数据字段
}
```

**字段说明**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `status` | Integer | ✅ | 状态码，0 表示成功，1 表示失败 |
| `error_code` | Integer | ✅ | 错误代码，成功时为 0 |
| `error_msg` | String | ✅ | 错误消息，成功时为空字符串 |
| 其他字段 | Any | - | 业务数据字段 |

### 2.2 失败响应格式

所有失败响应必须包含以下标准字段：

```json
{
  "status": 1,
  "error_code": 0x80000002,
  "error_msg": "参数错误：xxx",
  // ... 可选的附加数据字段
}
```

**字段说明**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `status` | Integer | ✅ | 状态码，固定为 1 |
| `error_code` | Integer | ✅ | 错误代码，使用 `ApiHelper` 中定义的常量 |
| `error_msg` | String | ✅ | 错误消息，描述具体的错误原因 |
| 其他字段 | Any | - | 可选的附加数据（如 `attachment`） |

---

## 3. 响应方法规范

### 3.1 必须使用的方法

所有 Controller 方法**必须**使用以下方法返回响应：

#### 3.1.1 `render_success`

用于返回成功响应。

**方法签名**：
```ruby
def render_success(res = {}, error_msg = "")
```

**参数说明**：
- `res` (Hash): 业务数据，会被合并到响应中
- `error_msg` (String): 可选的错误消息（通常为空字符串）

**实现**：
```ruby
def render_success(res = {}, error_msg = "")
  ret = { status: STATUS_SUCCEED, error_msg: error_msg.to_s, error_code: 0 }
  render json: (ret.merge res)
end
```

**使用示例**：
```ruby
# 简单成功响应
render_success({ message: "操作成功" })

# 返回业务数据
render_success({ task: task.to_json })

# 返回列表数据
render_success({ tasks: tasks.map(&:to_json), total: total })
```

#### 3.1.2 `render_failure_json`

用于返回失败响应（推荐使用）。

**方法签名**：
```ruby
def render_failure_json(errmsg, params = {}, exception = nil)
```

**参数说明**：
- `errmsg` (String): 错误消息
- `params` (Hash): 可选的附加数据
- `exception` (Exception): 可选的异常对象

**使用示例**：
```ruby
# 简单错误响应
render_failure_json("无权限访问此资源")

# 带错误码的错误响应
render_failure_json("参数错误", { error_code: ApiHelper::ERROR_INVALID_PARAM })

# 从异常获取错误消息
render_failure_json(task.errors.full_messages.join(', '))
```

#### 3.1.3 `render_failure`

用于返回失败响应（带错误码）。

**方法签名**：
```ruby
def render_failure(res = {}, error_code = ERROR_UNKNOWN, error_msg = "")
```

**参数说明**：
- `res` (Hash): 可选的附加数据
- `error_code` (Integer): 错误代码，使用 `ApiHelper` 中定义的常量
- `error_msg` (String): 错误消息

**使用示例**：
```ruby
render_failure({}, ApiHelper::ERROR_PERMISSION_DENIED, "无权限执行此操作")
```

### 3.2 禁止使用的方法

以下方法**禁止**在 Controller 中使用：

- ❌ `render json: { ... }` - 直接渲染 JSON（会覆盖标准字段）
- ❌ `render plain: ...` - 直接渲染文本
- ❌ 自定义响应格式 - 必须使用标准方法

### 3.3 标准字段保护

**重要**：以下字段为保留字段，**不能**在业务数据中覆盖：

- `status` - 响应状态
- `error_code` - 错误代码
- `error_msg` - 错误消息

**错误示例**：
```ruby
# ❌ 错误：覆盖了标准字段
render_success({ status: 200, error_code: 0, data: {...} })

# ✅ 正确：只包含业务数据
render_success({ data: {...} })
```

---

## 4. 错误码规范

### 4.1 错误码定义

所有错误码定义在 `ApiHelper` 模块中：

```ruby
module ApiHelper
  STATUS_SUCCEED = 0
  STATUS_FAILED = 1
  
  # 通用错误码
  ERROR_UNKNOWN = 0x80000000
  ERROR_NOT_IMPLEMENTED = 0x80000001
  ERROR_INVALID_PARAM = 0x80000002
  ERROR_INVALID_INVITATION_KEY = 0x80000003
  ERROR_INVALID_VERIFICATION = 0x80000004
  ERROR_INVALID_MOBILE = 0x80000005
  ERROR_INVALID_TIMING = 0x80000006
  ERROR_PERMISSION_DENIED = 0x80000007
  ERROR_INVALID_USER_ID = 0x80000008
  ERROR_INSUFFICIENT_BALANCE = 0x80000009
  ERROR_CONFIRM_PAYMENT = 0x80000010
  
  # 业务错误码
  ERROR_PROJ_ISSUE_NO_REL_PROJ = 0x80000011
  ERROR_INVALID_PROJECT_NAME = 0x80000012
  ERROR_MEETING_TASK_MUTI_DELAY = 0x80000013
  ERROR_NO_THIRDPARTY_AUTH = 0x80000014
  ERROR_TASK_CAN_SUCCEED = 0x80000015
  ERROR_TASK_CANNOT_BE_SETTLED = 0x80000016
  ERROR_TASK_CANNOT_SUCCEED = 0x80000017
  ERROR_TASK_ISNOT_ROOT = 0x80000018
  ERROR_TASK_NOT_FOUND = 0x80000019
  ERROR_TASK_CANNT_SUCCEED = 0x80000020
  ERROR_EMIAL_NOT_INVITED = 0x80000021
  ERROR_DUPLICATE_RECORD = 0x80000022
  ERROR_REGISTRY_NOT_APPROVED = 0x80000023
  ERROR_SCAN_LOGIN_QR_EXPIRED = 0x80000024
  ERROR_USER_PENDING = 0x80000025
  ERROR_USER_REJECT = 0x80000026
  ERROR_UNAUTHORIZED = 0x80000027
  ERROR_NO_PROJECT = 0x80000028
end
```

### 4.2 错误码使用规范

1. **必须使用常量**：使用 `ApiHelper::ERROR_XXX`，不使用魔法数字
2. **错误消息清晰**：`error_msg` 必须清晰描述错误原因
3. **错误码分类**：
   - `0x80000000 - 0x80000010`: 通用错误
   - `0x80000011 - 0x80000028`: 业务错误
   - 新增错误码需要遵循此分类

### 4.3 异常处理

使用 `ApiHelper::Error` 和 `ApiHelper::Warning` 处理业务异常：

```ruby
# 抛出业务异常
raise ApiHelper::Error.new("任务不存在", ApiHelper::ERROR_TASK_NOT_FOUND)

# 在 Controller 中捕获
rescue ApiHelper::Error => e
  render_failure_json(e.message)
end
```

---

## 5. 请求规范

### 5.1 认证

所有需要认证的接口必须在请求头中包含 `Authorization`：

```
Authorization: <token>
```

### 5.2 HTTP 方法

- **GET**: 查询操作
- **POST**: 创建、更新、删除操作（根据业务需求）
- **PUT**: 更新操作（可选）
- **DELETE**: 删除操作（可选）

### 5.3 请求参数

- **查询参数**：使用 `params` 获取
- **请求体**：使用 `params.require(:key).permit(...)` 进行参数验证

---

## 6. 示例

### 6.1 成功响应示例

```ruby
# Controller 代码
def index
  tasks = TaskHelper.get_user_tasks(current_user, params)
  render_success({
    tasks: tasks.map(&:to_json),
    pagination: pagination_info(tasks)
  })
end

# 响应 JSON
{
  "status": 0,
  "error_code": 0,
  "error_msg": "",
  "tasks": [...],
  "pagination": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 5,
    "total_count": 100
  }
}
```

### 6.2 失败响应示例

```ruby
# Controller 代码
def create
  task_params = params.require(:task).permit(:title, :description)
  result = TaskHelper.create_task(current_user, task_params)
  
  if result[:success]
    render_success({ task: result[:task].to_json })
  else
    render_failure_json(result[:error])
  end
end

# 响应 JSON（成功）
{
  "status": 0,
  "error_code": 0,
  "error_msg": "",
  "task": {...}
}

# 响应 JSON（失败）
{
  "status": 1,
  "error_code": 0x80000002,
  "error_msg": "参数错误：标题不能为空"
}
```

### 6.3 权限检查示例

```ruby
def update
  task = Task.find(params[:id])
  
  unless TaskHelper.can_edit?(task, current_user)
    render_failure_json("无权限编辑此任务")
    return
  end
  
  task_params = params.require(:task).permit(:title, :description)
  
  if task.update(task_params)
    render_success({ task: task.to_json })
  else
    render_failure_json(task.errors.full_messages.join(', '))
  end
end
```

### 6.4 异常处理示例

```ruby
def submit
  task = Task.find(params[:id])
  TaskHelper.update_status_submitted(task, current_user)
  render_success({ task: task.reload.to_json })
rescue ApiHelper::Error => e
  render_failure_json(e.message)
end
```

---

## 7. 检查清单

在编写 Controller 方法时，请确保：

- [ ] 使用 `render_success` 返回成功响应
- [ ] 使用 `render_failure_json` 或 `render_failure` 返回失败响应
- [ ] 不在业务数据中覆盖 `status`、`error_code`、`error_msg` 字段
- [ ] 使用 `ApiHelper::ERROR_XXX` 常量，不使用魔法数字
- [ ] 错误消息清晰明确
- [ ] 正确处理异常（使用 `rescue ApiHelper::Error`）

---

**文档版本**: v1.0  
**最后更新**: 2025-11-25  
**维护者**: GWEN后端开发团队

