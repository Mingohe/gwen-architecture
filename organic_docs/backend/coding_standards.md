# 后端代码规范

> **返回**: [文档首页](../../README.md)

## 目录

- [1. 概述](#1-概述)
- [2. Ruby 代码规范](#2-ruby-代码规范)
- [3. Rails 代码规范](#3-rails-代码规范)
- [4. 命名规范](#4-命名规范)
- [5. 文件组织规范](#5-文件组织规范)
- [6. 注释规范](#6-注释规范)
- [7. 测试规范](#7-测试规范)

---

## 1. 概述

本文档定义了 GWEN 项目后端的代码规范，确保代码质量和团队协作效率。

### 1.1 核心原则

- ✅ **一致性**：保持代码风格一致
- ✅ **可读性**：代码应该易于理解和维护
- ✅ **可维护性**：遵循 Rails 最佳实践
- ✅ **安全性**：注意安全漏洞和性能问题

---

## 2. Ruby 代码规范

### 2.1 基本规范

#### 2.1.1 缩进和空格

- 使用 **2 个空格**进行缩进，不使用 Tab
- 方法之间空一行
- 类/模块之间空两行

```ruby
# ✅ 正确
class UserController < ApplicationController
  def index
    users = User.all
    render_success({ users: users.map(&:to_json) })
  end

  def show
    user = User.find(params[:id])
    render_success({ user: user.to_json })
  end
end

# ❌ 错误：使用 Tab 缩进
class UserController < ApplicationController
	def index
		users = User.all
	end
end
```

#### 2.1.2 字符串

- 优先使用单引号（除非需要字符串插值）
- 使用双引号进行字符串插值

```ruby
# ✅ 正确
name = 'John'
message = "Hello, #{name}!"

# ❌ 错误
name = "John"
message = 'Hello, ' + name + '!'
```

#### 2.1.3 方法定义

- 方法名使用 `snake_case`
- 方法参数使用 `snake_case`
- 方法末尾不需要分号

```ruby
# ✅ 正确
def get_user_tasks(user, params = {})
  # ...
end

# ❌ 错误
def getUserTasks(user, params = {})
  # ...
end
```

### 2.2 代码组织

#### 2.2.1 方法顺序

1. `public` 方法
2. `protected` 方法
3. `private` 方法

```ruby
class TaskController < ApplicationController
  # Public methods
  def index
  end

  def create
  end

  protected

  def can_edit?
  end

  private

  def task_params
  end
end
```

#### 2.2.2 条件语句

- 优先使用 `unless` 而不是 `if !`
- 使用 `&&` 和 `||` 而不是 `and` 和 `or`
- 复杂条件使用括号

```ruby
# ✅ 正确
return unless user.present?
return if user.nil? || user.inactive?

if (user.admin? || user.moderator?) && user.active?
  # ...
end

# ❌ 错误
return if !user.present?
return if user.nil? or user.inactive?
```

---

## 3. Rails 代码规范

### 3.1 Controller 规范

#### 3.1.1 方法职责

- 每个方法只做一件事
- 业务逻辑放在 Helper 或 Service 中
- Controller 只负责参数验证、权限检查和响应渲染

```ruby
# ✅ 正确
def create
  task_params = params.require(:task).permit(:title, :description)
  result = TaskHelper.create_task(current_user, task_params)
  
  if result[:success]
    render_success({ task: result[:task].to_json })
  else
    render_failure_json(result[:error])
  end
end

# ❌ 错误：业务逻辑在 Controller 中
def create
  task = Task.new(params[:task])
  if task.save
    # 复杂的业务逻辑...
    task.update_status!
    task.send_notification!
    # ...
  end
end
```

#### 3.1.2 参数验证

- 使用 `params.require().permit()` 进行强参数验证
- 验证失败时返回明确的错误消息

```ruby
# ✅ 正确
def create
  task_params = params.require(:task).permit(
    :title, :description, :task_type, :coins
  )
  # ...
end

# ❌ 错误：没有参数验证
def create
  task = Task.new(params[:task])
  # ...
end
```

#### 3.1.3 权限检查

- 在方法开始处进行权限检查
- 权限检查失败时立即返回

```ruby
# ✅ 正确
def update
  task = Task.find(params[:id])
  
  unless TaskHelper.can_edit?(task, current_user)
    render_failure_json("无权限编辑此任务")
    return
  end
  
  # 继续处理...
end
```

### 3.2 Model 规范

#### 3.2.1 关联定义

- 关联定义放在文件顶部
- 使用 `dependent: :destroy` 或 `dependent: :nullify` 明确依赖关系

```ruby
# ✅ 正确
class Task < ApplicationRecord
  belongs_to :assignee, class_name: 'User'
  belongs_to :assignor, class_name: 'User'
  has_many :children, class_name: 'Task', foreign_key: 'parent_id'
  has_many :checkpoints, dependent: :destroy
end
```

#### 3.2.2 验证

- 验证放在关联定义之后
- 使用 Rails 内置验证器

```ruby
# ✅ 正确
class Task < ApplicationRecord
  validates :title, presence: true
  validates :status, inclusion: { in: %w[open accepted published] }
  validates :coins, numericality: { greater_than_or_equal_to: 0 }
end
```

#### 3.2.3 回调

- 回调方法使用 `private` 或 `protected`
- 回调方法名清晰表达意图

```ruby
# ✅ 正确
class Task < ApplicationRecord
  before_save :set_default_status
  after_create :send_notification

  private

  def set_default_status
    self.status ||= 'open'
  end

  def send_notification
    NotificationService.send_task_created(self)
  end
end
```

### 3.3 Helper 规范

#### 3.3.1 职责

- Helper 包含业务逻辑
- Helper 方法应该是纯函数（尽可能）
- Helper 方法名清晰表达意图

```ruby
# ✅ 正确
module TaskHelper
  def self.create_task(user, params)
    # 业务逻辑
  end

  def self.can_edit?(task, user)
    # 权限检查逻辑
  end
end
```

---

## 4. 命名规范

### 4.1 文件命名

- 文件名使用 `snake_case`
- Controller 文件：`task_controller.rb`
- Model 文件：`task.rb`
- Helper 文件：`task_helper.rb`

### 4.2 类命名

- 类名使用 `PascalCase`
- Controller：`TaskController`
- Model：`Task`
- Helper：`TaskHelper`

### 4.3 方法命名

- 方法名使用 `snake_case`
- 布尔方法以 `?` 结尾：`can_edit?`, `is_active?`
- 危险方法以 `!` 结尾：`save!`, `update!`

### 4.4 变量命名

- 变量名使用 `snake_case`
- 常量使用 `UPPER_SNAKE_CASE`
- 实例变量使用 `@` 前缀

---

## 5. 文件组织规范

### 5.1 目录结构

```
app/
├── controllers/        # 控制器
│   ├── application_controller.rb
│   └── task_controller.rb
├── models/            # 模型
│   ├── application_record.rb
│   └── task.rb
├── helpers/           # 辅助方法
│   ├── application_helper.rb
│   ├── api_helper.rb
│   └── task_helper.rb
├── services/          # 业务服务（可选）
└── channels/          # WebSocket 频道
```

### 5.2 文件组织原则

- 每个类一个文件
- 相关功能放在同一目录
- 使用命名空间组织相关类

---

## 6. 注释规范

### 6.1 类注释

```ruby
# 任务控制器
# 
# 负责处理任务相关的 API 请求
# 
# 主要功能：
# - 任务 CRUD 操作
# - 任务状态流转
# - 任务权限管理
class TaskController < ApplicationController
end
```

### 6.2 方法注释

```ruby
# 创建任务
# 
# @param [Hash] task_params 任务参数
#   - title [String] 任务标题（必填）
#   - description [String] 任务描述
#   - task_type [String] 任务类型
# @return [Hash] 包含 success 和 task 或 error
def create
  # ...
end
```

### 6.3 复杂逻辑注释

```ruby
# 计算任务金币分配
# 
# 规则：
# 1. 根任务的金币分配给所有子任务
# 2. 子任务完成后，金币分配给执行者
# 3. 如果子任务失败，金币返回根任务
def calculate_coins
  # ...
end
```

---

## 7. 测试规范

### 7.1 测试文件组织

- 测试文件放在 `test/` 或 `spec/` 目录
- 测试文件命名：`task_controller_test.rb` 或 `task_controller_spec.rb`

### 7.2 测试命名

- 测试方法名清晰描述测试场景
- 使用 `test_` 前缀或 `it` 描述

```ruby
# ✅ 正确
test "should create task with valid params" do
  # ...
end

test "should not create task without title" do
  # ...
end
```

### 7.3 测试覆盖

- 每个 Controller 方法都应该有测试
- 测试成功和失败场景
- 测试权限检查

---

## 8. 安全检查

### 8.1 SQL 注入

- 使用参数化查询
- 使用 ActiveRecord 查询方法，避免直接 SQL

```ruby
# ✅ 正确
User.where("name = ?", params[:name])

# ❌ 错误
User.where("name = '#{params[:name]}'")
```

### 8.2 XSS 防护

- 使用 `sanitize` 方法清理用户输入
- 在视图中使用 `html_safe` 时要谨慎

### 8.3 CSRF 防护

- 确保所有 POST/PUT/DELETE 请求包含 CSRF token
- 使用 `protect_from_forgery`（Rails 默认启用）

---

## 9. 性能优化

### 9.1 数据库查询

- 使用 `includes` 避免 N+1 查询
- 使用 `select` 只查询需要的字段
- 使用索引优化查询

```ruby
# ✅ 正确：避免 N+1
tasks = Task.includes(:assignee, :assignor).all

# ❌ 错误：N+1 查询
tasks = Task.all
tasks.each { |task| task.assignee.name }
```

### 9.2 缓存

- 使用 Rails 缓存机制
- 缓存频繁查询的数据

---

## 10. 检查清单

在提交代码前，请确保：

- [ ] 代码遵循缩进和空格规范
- [ ] 方法名和变量名符合命名规范
- [ ] Controller 方法使用 `render_success` 和 `render_failure_json`
- [ ] 参数验证使用 `params.require().permit()`
- [ ] 权限检查在方法开始处
- [ ] 业务逻辑在 Helper 或 Service 中
- [ ] 代码有必要的注释
- [ ] 没有安全漏洞（SQL 注入、XSS 等）
- [ ] 没有 N+1 查询问题

---

**文档版本**: v1.0  
**最后更新**: 2025-11-25  
**维护者**: GWEN后端开发团队

