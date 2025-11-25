# 项目结构迁移需求

## 需求概述

### 1. 项目定位
- **当前目录 `gwen-architecture`** 是一个 GitHub 项目
- **内容**: GWEN 系统的 Markdown 形式项目介绍文档
- **目的**: 帮助 AI 理解 GWEN 项目的功能以及实现方式，辅助 AI 进行现状理解以及后续开发

### 2. 部署文档迁移
- **来源**: `origin_docs/` 目录中的实现文件
- **目标**: 移动到根目录下
- **文件**:
  - `origin_docs/README.md` → `README.md` (覆盖)
  - `origin_docs/Makefile` → `Makefile` (覆盖)
  - `origin_docs/docker-compose.yml` → `docker-compose.yml` (覆盖)
- **目的**: 帮助小白用户一站式部署 Docker Container 开发环境

### 3. 源代码目录处理
- **`src/` 目录**: 应该清空
- **用途**: 在部署过程中，通过 `make pull` 等命令下载的代码库应当放到这个目录下
- **Git 管理**: `src/` 目录不参与根目录下的 GitHub 仓库（添加到 `.gitignore`）

## 实施步骤

1. ✅ 将 `origin_docs/` 中的文件移动到根目录
2. ✅ 清空 `src/` 目录
3. ✅ 更新 `.gitignore`，排除 `src/` 目录
4. ✅ 更新根目录 `README.md`，确保包含部署说明
5. ✅ 验证新的项目结构

## 最终目录结构

```
gwen-architecture/
├── README.md              # 项目部署说明（来自 origin_docs）
├── Makefile               # 开发命令工具（来自 origin_docs）
├── docker-compose.yml     # Docker 编排配置（来自 origin_docs）
├── .gitignore             # Git 忽略配置（排除 src/）
├── organic_docs/          # 项目文档（保留）
│   ├── backend/
│   ├── frontend/
│   └── modules/
├── origin_docs/           # 原始文档备份（可删除）
└── src/                   # 源代码目录（.gitignore，部署时下载）
    ├── frontend/          # 前端代码（通过 make pull 下载）
    └── backend/           # 后端代码（通过 make pull 下载）
```

