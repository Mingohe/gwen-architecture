# 财务管理系统模块 - 前端文档

> **返回**: [文档首页](../../README.md)

## 目录

- [1. 概述](#1-概述)
- [2. 页面结构](#2-页面结构)
- [3. 组件结构](#3-组件结构)
- [4. Store 说明](#4-store-说明)
- [5. API 调用规范](#5-api-调用规范)
- [6. 交互流程](#6-交互流程)
- [7. UI 规范](#7-ui-规范)
- [8. 权限控制](#8-权限控制)

---

## 1. 概述

### 1.1 模块边界与目的

财务管理系统模块负责：

- **会计科目管理**: 会计科目树结构管理
- **项目合同管理**: 项目合同创建和管理
- **收支记录**: 收入支出记录管理
- **项目收支统计**: 项目收支统计和报表

### 1.2 技术栈

- **框架**: Vue 3 + TypeScript
- **状态管理**: Pinia
- **UI组件**: Ant Design Vue

---

## 2. 页面结构

### 2.1 页面列表

| 页面路径 | 路由名称 | 组件路径 | 说明 |
|---------|---------|---------|------|
| `/data/account` | - | `src/views/data/financialAccount/Account.vue` | **会计科目管理** - 会计科目树结构管理 |
| `/data/contract` | - | `src/views/data/contract/Contract.vue` | **合同管理** - 项目合同创建和管理 |
| `/data/income` | - | `src/views/data/income/Income.vue` | **收入管理** - 收入记录管理 |

### 2.2 页面布局

#### 2.2.1 会计科目管理页面布局

**页面路径**: `/data/account`

**布局结构**:

```
会计科目管理页面 (/data/account)
└── PageWrapper (页面容器)
    └── BasicTable (数据表格)
        ├── toolbar (工具栏)
        │   ├── "添加" 按钮
        │   └── "刷新" 按钮
        └── Table (表格主体)
            ├── 列: 科目代码
            ├── 列: 科目名称
            ├── 列: 科目类型
            ├── 列: 父科目
            └── 列: 操作列
                ├── "编辑" 按钮
                └── "删除" 按钮
```

**功能说明**:
- **科目树结构**: 支持层级科目结构，通过父科目字段关联
- **科目类型**: 资产、负债、收入、支出等
- **科目代码**: 唯一标识，支持层级编码

#### 2.2.2 合同管理页面布局

**页面路径**: `/data/contract`

**布局结构**:

```
合同管理页面 (/data/contract)
└── PageWrapper (页面容器)
    └── BasicTable (数据表格)
        ├── toolbar (工具栏)
        │   ├── "添加" 按钮
        │   └── "刷新" 按钮
        └── Table (表格主体)
            ├── 列: 合同名称
            ├── 列: 关联项目
            ├── 列: 合同金额
            ├── 列: 合同状态
            ├── 列: 签订日期
            └── 列: 操作列
                ├── "编辑" 按钮
                └── "删除" 按钮
```

**功能说明**:
- **项目关联**: 合同必须关联到项目
- **合同金额**: 记录合同总金额
- **合同状态**: 待签订、已签订、执行中、已完成等

#### 2.2.3 收入管理页面布局

**页面路径**: `/data/income`

**布局结构**:

```
收入管理页面 (/data/income)
└── PageWrapper (页面容器)
    └── BasicTable (数据表格)
        ├── toolbar (工具栏)
        │   ├── "添加" 按钮
        │   └── "刷新" 按钮
        └── Table (表格主体)
            ├── 列: 收入日期
            ├── 列: 收入金额
            ├── 列: 关联项目
            ├── 列: 关联合同
            ├── 列: 会计科目
            └── 列: 操作列
                ├── "编辑" 按钮
                └── "删除" 按钮
```

**功能说明**:
- **收入记录**: 记录项目收入明细
- **关联关系**: 收入关联到项目和合同
- **会计科目**: 选择对应的会计科目分类

---

## 3. 组件结构

### 3.1 组件树

```
FinancialAccount.vue (会计科目)
├── AccountTree.vue (科目树)
└── AccountForm.vue (科目表单)

Contract.vue (合同管理)
├── ContractList.vue (合同列表)
└── ContractForm.vue (合同表单)
```

---

## 4. Store 说明

### 4.1 Financial Store

**State 定义**:
```typescript
interface FinancialState {
  accounts: Account[]
  contracts: Contract[]
  documents: Document[]
}
```

---

## 5. API 调用规范

### 5.1 API 接口列表

| API函数 | 后端接口 | 说明 |
|---------|---------|------|
| `FinancialAccountsApi` | `GET /financial_accouting/accounts` | 获取会计科目 |
| `ProjectAccountingSummaryApi` | `GET /financial_accouting/project_accouting_summary` | 获取项目收支统计 |

---

## 6. 交互流程

标准CRUD流程。

---

## 7. UI 规范

- 使用 Ant Design Vue 组件
- 科目树使用Tree组件
- 合同列表使用Table组件

---

## 8. 权限控制

- 财务管理员可以管理所有财务数据
- 项目负责人可以查看项目财务数据

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

