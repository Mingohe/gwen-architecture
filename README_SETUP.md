# Gwen Project

一个现代化的全栈 Web 应用，使用 Vue.js 前端和 Rails 后端，支持 Docker 容器化部署。

## 🏗️ 项目结构

```
gwen-architecture/
├── src/                    # 源代码目录（通过 make pull 下载）
│   ├── frontend/          # Vue.js 前端应用
│   └── backend/           # Rails 后端 API
├── docker-compose.yml      # Docker 编排配置
├── Makefile               # 开发命令工具
├── .env                   # 环境变量配置（可选）
├── organic_docs/          # 项目文档（业务概述、前端、后端文档）
└── README.md             # 项目说明文档
```

## 🚀 开发环境设置

### 前置要求

- **Docker & Docker Compose** - 容器化运行环境
  - macOS: `brew install --cask docker`
  - Windows: 下载 [Docker Desktop](https://www.docker.com/products/docker-desktop/)
  - Linux: `sudo apt install docker-ce docker-compose-plugin`
  - **注意**: Makefile 自动兼容新旧版本的 Docker Compose 命令（`docker compose` 和 `docker-compose`）

- **Git** - 版本控制工具
  - macOS: `brew install git`
  - Windows: 下载 [Git for Windows](https://git-scm.com/download/win)
  - Linux: `sudo apt install git`

- **Make** (推荐) - 提供便捷的开发命令
  - macOS: `brew install make`
  - Windows: `choco install make`
  - Linux: `sudo apt install make`

### 1. 获取项目代码

```bash
# 方法一：使用 Makefile 自动克隆（推荐）
make pull

# 方法二：手动克隆
# 创建 src 目录
mkdir -p src

# 克隆后端项目
git clone http://10.99.100.1/gwen/gwen-backend.git src/backend

# 克隆前端项目
git clone http://10.99.100.1/gwen/gwen-frontend.git src/frontend
```

### 2. 启动开发环境

```bash
# 使用 Makefile 启动开发环境 (推荐)
make dev

# 或直接使用 Docker Compose (自动兼容 docker compose 和 docker-compose)
docker compose up -d
# 或
docker-compose up -d
```

### 3. 访问应用

- **前端**: http://localhost:3201
- **后端 API**: http://localhost:3200
- **Sidekiq Web UI**: http://localhost:3200/sidekiq (需在 Rails routes.rb 中配置)
- **数据库**: MariaDB (端口 13306)
- **Redis**: 端口 6380

## 📋 项目功能

详见 [README.md](./README.md) 中的模块说明。


## 🛠️ 开发命令

### 服务管理

```bash
make dev        # 开发模式启动（热重载 + 自动重建）
make stop       # 停止所有服务
make restart    # 重启服务
make build      # 重新构建容器
make clean      # 清理容器和卷
```

### 监控和测试

```bash
make health     # 检查服务健康状态
make test       # 运行连接测试
make logs       # 查看所有服务日志
make ports      # 显示服务端口
make env        # 显示环境变量
```

### 日志查看

```bash
make frontend-logs    # 前端日志
make backend-logs     # 后端日志
make dev-logs         # 所有开发日志
```

## ⚙️ 配置说明

### 端口配置

所有端口配置都在 `docker-compose.yml` 中统一管理：

| 服务 | 宿主机端口 | 容器端口 | 访问地址 | 说明 |
|------|------------|----------|----------|------|
| 前端 | 3201 | 3201 | http://localhost:3201 | Vue3 + Vite 开发服务器 |
| 后端 (Rails) | 3200 | 3200 | http://localhost:3200 | Rails API 服务器 |
| Sidekiq Web UI | - | - | http://localhost:3200/sidekiq | 通过 Rails 路由访问 |
| MariaDB | 13306 | 3306 | localhost:13306 | 数据库服务 |
| Redis | 6380 | 6379 | localhost:6380 | 缓存和会话存储 |

### 环境变量

- `VITE_BACKEND_URL`: 前端连接的后端 URL
- `VITE_PORT`: 前端服务端口 (默认: 3201)
- `PORT`: 后端服务端口 (默认: 3200)
- `RAILS_ENV`: Rails 环境 (development)
- `LOG_LEVEL`: 日志级别
- `REDIS_URL`: Redis 连接地址
- `DB_HOST`: 数据库主机地址

## 🐳 Docker 配置

### 服务说明

- **frontend**: Vue.js 开发服务器，支持热重载
- **backend**: Rails API 服务器（包含 MariaDB、Redis、Rails、Sidekiq，使用 supervisord 管理）
  - Rails 服务器运行在端口 3200
  - Sidekiq 后台任务处理器
  - MariaDB 数据库（端口 13306 外部访问）
  - Redis 缓存服务（端口 6380 外部访问）

## 🗄️ 数据库设置

```bash
# 创建数据库
make db-setup

# 或手动执行 (自动兼容 docker compose 和 docker-compose)
docker compose exec backend bundle exec rails db:create
docker compose exec backend bundle exec rails db:migrate
docker compose exec backend bundle exec rails db:seed
```

## 🔧 开发环境

### 热重载

开发模式下，代码修改会自动重载：
- **前端**: Vue 热重载
- **后端**: Rails 自动重载

## 📊 监控和调试

### 健康检查

```bash
make health
```

### 查看日志

```bash
# 所有服务日志
make logs

# 特定服务日志
make frontend-logs
make backend-logs

# Backend 容器内各服务日志（MariaDB、Redis、Rails、Sidekiq）
make backend-logs-mariadb   # MariaDB 日志
make backend-logs-redis     # Redis 日志
make backend-logs-rails      # Rails 日志
make backend-logs-sidekiq    # Sidekiq 日志
make backend-logs-all        # 所有 backend 服务日志
```

### 连接测试

```bash
make test
```

## 🔧 Sidekiq Web UI 配置

Sidekiq Web UI 可以通过两种方式访问：

### 方式 1：通过 Rails 路由（推荐）

在 Rails 的 `config/routes.rb` 中添加：

```ruby
require 'sidekiq/web'

Rails.application.routes.draw do
  # ... 其他路由
  
  # Sidekiq Web UI（需要管理员权限）
  mount Sidekiq::Web => '/sidekiq'
end
```

然后访问：`http://localhost:3200/sidekiq`

**优点**：
- ✅ 更安全（可以通过 Rails 的认证系统保护）
- ✅ 不需要额外端口
- ✅ 统一管理更方便

### 方式 2：独立端口（如果需要）

如果需要单独暴露 Sidekiq Web UI 端口（4567），可以：

1. 在 `docker-compose.yml` 中添加端口映射：
   ```yaml
   ports:
     - "4567:4567"   # Sidekiq Web UI
   ```

2. 在 `src/backend/docker/supervisord.conf` 中添加 Sidekiq Web 服务器：
   ```ini
   [program:sidekiq-web]
   command=bash -c "cd /rails && bundle exec sidekiq-web -p 4567"
   ```

3. 访问：`http://localhost:4567`

**当前实现**：使用方式 1（通过 Rails 路由）

## 🚨 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   lsof -i :3200
   lsof -i :3201
   lsof -i :3307
   lsof -i :6380
   
   # 修改 docker-compose.yml 中的端口映射
   ```

2. **容器启动失败**
   ```bash
   # 查看详细日志
   make logs
   
   # 重新构建容器
   make build
   ```

3. **数据库连接问题**
   ```bash
   # 检查数据库服务 (自动兼容 docker compose 和 docker-compose)
   docker compose ps
   
   # 重启 backend 服务（包含所有服务）
   docker compose restart backend
   
   # 查看 backend 容器内各服务日志
   make backend-logs-mariadb
   make backend-logs-redis
   ```

4. **服务健康检查**
   ```bash
   # 检查所有服务状态
   make health
   
   # 运行连接测试
   make test
   
   # 查看端口配置
   make ports
   ```

### 清理和重置

```bash
# 完全清理
make clean

# 重新构建和启动
make rebuild
```

## 🚀 开发工作流程

### 1. 环境准备

```bash
# 1. 克隆项目代码
make pull

# 2. 启动开发环境
make dev

# 3. 验证环境
make health
make test
```

### 2. 创建开发分支

**重要**: 开发前请先创建自己的开发分支，避免直接在主分支上开发：

```bash
# 进入后端项目目录
cd src/backend

# 创建并切换到新分支
git checkout -b feature/your-feature-name

# 或进入前端目录
cd ../frontend
git checkout -b feature/your-feature-name
```

### 3. 选择开发任务

根据需求文档选择要开发的功能：

```bash
# 查看所有需求文档
ls src/backend/docs/
```

### 4. 测试账户

开发环境搭建完毕后，系统默认提供以下测试账户：

| 用户名 | 密码 | 角色 | 用途 |
|--------|------|------|------|
| `admin` | `1234abcd` | 管理员 | 测试管理员功能 |
| `testuser1` | `1234abcd` | 普通用户 | 测试用户功能 |

**登录地址**: http://localhost:3201

### 5. 开发流程

#### 前端开发
```bash
# 启动前端开发模式
make frontend-dev

# 查看前端日志
make frontend-logs

# 前端代码结构
src/frontend/src/
├── components/     # 可复用组件
├── views/         # 页面组件
├── plugins/       # 插件 (如 YjsCollaborationPlugin)
└── utils/         # 工具函数
```

#### 后端开发
```bash
# 启动后端开发模式
make backend-dev

# 查看后端日志
make backend-logs

# 数据库操作
make db-setup

# 后端代码结构
src/backend/app/
├── controllers/   # API 控制器
├── models/        # 数据模型
├── channels/      # WebSocket 频道
└── services/      # 业务逻辑
```

### 6. 测试和调试

```bash
# 运行连接测试
make test

# 检查服务健康状态
make health

# 查看所有服务日志
make logs

# 查看特定服务日志
make frontend-logs
make backend-logs
```

### 7. 代码质量

```bash
# 后端代码检查
cd src/backend
bundle exec rubocop

# 前端代码检查
cd src/frontend
npm run lint
```

## 📝 开发指南

### 代码结构

- **前端**: Vue 3 + TypeScript + Vite
- **后端**: Rails 7 + Ruby 3.2.2
- **数据库**: MySQL (开发和生产)
- **实时通信**: ActionCable + WebSocket

### 添加新功能

1. 后端 API 开发
   ```bash
   # 在 src/backend 中创建新的 controller (自动兼容 docker compose 和 docker-compose)
   docker compose exec backend bundle exec rails generate controller Api::V1::NewFeature
   ```

2. 前端组件开发
   ```bash
   # 在 gwen-frontend/src 中创建新组件
   # 支持 TypeScript 和 Vue 3 Composition API
   ```

3. WebSocket 频道开发
   ```bash
   # 创建新的 ActionCable 频道
   docker compose exec backend bundle exec rails generate channel NewChannel
   ```

### 开发最佳实践

1. **容器化开发**: 所有开发都在 Docker 容器中进行
2. **热重载**: 前端和后端都支持热重载
3. **实时通信**: 使用 ActionCable 进行实时通信
4. **权限控制**: 所有 API 都要进行权限验证
5. **错误处理**: 完善的错误处理和日志记录

**Happy Coding! 🎉**
