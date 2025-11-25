# Docker 配置冲突分析报告

## 冲突概述

`docker-compose.yml` 和 `docker/` 目录下的配置存在**架构冲突**和**配置不一致**的问题。

## 发现的冲突

### 1. 架构冲突 ⚠️ **严重**

**docker-compose.yml**:
- 使用**分离容器架构**
- `backend` 和 `frontend` 是独立的容器
- 每个容器有自己的 `Dockerfile.dev`

**docker/ 目录**:
- 使用**单容器架构**
- 使用 `supervisord` 管理多个进程（rails, vite, sidekiq）
- 使用根目录的 `Dockerfile`

**影响**: 两种架构不能同时使用，需要选择一种。

### 2. 工作目录冲突

| 配置项 | docker-compose.yml | docker/entrypoint.sh |
|--------|-------------------|---------------------|
| Backend 工作目录 | `/rails` | `/app/src/backend` |
| 工作目录结构 | `./src/backend:/rails` | `cd /app/src/backend` |

**影响**: 路径不一致会导致命令执行失败。

### 3. 端口配置冲突

| 服务 | docker-compose.yml | supervisord.conf |
|------|-------------------|-----------------|
| Backend/Rails | `3200` | `3000` |
| Frontend/Vite | `3201` | `5173` |

**影响**: 端口不一致会导致服务无法访问。

### 4. 数据库名称冲突

| 配置项 | docker-compose.yml | mysql/init.sql |
|--------|-------------------|---------------|
| 数据库名 | `gwen_dev` | `gwen_development` |

**影响**: 数据库名称不一致，可能导致连接失败。

### 5. Dockerfile 引用冲突

**docker-compose.yml**:
```yaml
backend:
  build:
    context: ./src/backend
    dockerfile: Dockerfile.dev  # ❌ 文件不存在
frontend:
  build:
    context: ./src/frontend
    dockerfile: Dockerfile.dev  # ❌ 文件不存在
```

**根目录 Dockerfile**:
- 引用 `docker/supervisord.conf` ✅
- 引用 `docker/entrypoint.sh` ✅
- 但 `docker-compose.yml` 不使用这个 Dockerfile

**影响**: `docker-compose.yml` 引用的 `Dockerfile.dev` 文件不存在，构建会失败。

## 解决方案 ✅ 已实施

### 方案 1: 使用分离容器架构（已采用，符合 docker-compose.yml）

**已实施步骤**:
1. ✅ 已删除 `docker/` 目录（与 docker-compose.yml 冲突）
2. ⚠️  需要在 `src/backend/` 和 `src/frontend/` 目录下创建各自的 `Dockerfile.dev`
3. ✅ `docker-compose.yml` 中的工作目录已正确配置为 `/rails`（backend）和 `/app`（frontend）
4. ✅ 数据库名称已统一为 `gwen_dev`
5. ✅ 端口配置已统一（3200/3201）

### 方案 2: 使用单容器架构（符合 docker/ 目录）

**步骤**:
1. 修改 `docker-compose.yml`，使用根目录的 `Dockerfile`
2. 只定义一个服务（gwen），使用 supervisord 管理所有进程
3. 更新端口映射为 3000 和 5173
4. 统一数据库名称为 `gwen_development`
5. 更新工作目录为 `/app/src/backend` 和 `/app/src/frontend`

### 方案 3: 保留两种配置（不推荐）

**步骤**:
1. 将 `docker/` 目录重命名为 `docker-single/`（单容器配置）
2. 将 `docker-compose.yml` 重命名为 `docker-compose-separate.yml`（分离容器配置）
3. 在文档中说明两种部署方式

## 推荐方案

**推荐使用方案 1（分离容器架构）**，原因：
- ✅ 更符合 Docker 最佳实践（一个容器一个进程）
- ✅ 更容易扩展和维护
- ✅ 更符合微服务架构
- ✅ `docker-compose.yml` 已经配置好了分离架构

## 需要创建的文件

如果选择方案 1，需要创建：
- `src/backend/Dockerfile.dev`
- `src/frontend/Dockerfile.dev`

