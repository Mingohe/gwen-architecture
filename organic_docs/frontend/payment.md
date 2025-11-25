# 支付与钱包系统模块 - 前端文档

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

支付与钱包系统模块负责：

- **Stripe钱包管理**: Stripe Connect钱包创建和管理
- **USDC余额显示**: 实时显示USDC余额
- **支付处理**: Stripe支付集成
- **交易记录**: 交易历史记录查看

### 1.2 技术栈

- **框架**: Vue 3 + TypeScript
- **状态管理**: Pinia
- **UI组件**: Ant Design Vue
- **支付集成**: Stripe Elements

---

## 2. 页面结构

### 2.1 页面列表

| 页面路径 | 路由名称 | 组件路径 | 说明 |
|---------|---------|---------|------|
| `/stripe/wallet` | `stripe-wallet` | `src/views/stripe/wallet/index.vue` | 钱包管理 |
| `/stripe/transactions` | `stripe-transactions` | `src/views/stripe/transactions/index.vue` | 交易记录 |
| `/stripe/payment` | `stripe-payment` | `src/views/stripe/payment/index.vue` | 支付页面 |

---

## 3. 组件结构

### 3.1 组件树

```
StripeWallet.vue (钱包管理)
├── WalletCard.vue (钱包卡片)
└── WalletActions.vue (钱包操作)

StripeTransactions.vue (交易记录)
└── TransactionList.vue (交易列表)

StripePayment.vue (支付页面)
└── PaymentForm.vue (支付表单)
```

---

## 4. Store 说明

### 4.1 Stripe Store

**State 定义**:
```typescript
interface StripeState {
  wallet: Wallet | null
  transactions: Transaction[]
  loading: boolean
}
```

**Actions**:
```typescript
actions: {
  async initializeWallet() {
    const res = await StripeWalletApi()
    this.wallet = res.data.wallet
  },
  
  async createPaymentIntent(amount: number, currency: string) {
    const res = await StripeCreatePaymentIntentApi({ amount, currency })
    return res.data.payment_intent
  }
}
```

---

## 5. API 调用规范

### 5.1 API 接口列表

| API函数 | 后端接口 | 说明 |
|---------|---------|------|
| `StripeWalletApi` | `GET /stripe/wallets` | 获取钱包 |
| `StripeCreatePaymentIntentApi` | `POST /stripe/payments/:id/create_intent` | 创建支付意图 |
| `StripeTransactionsApi` | `GET /stripe/transactions` | 获取交易记录 |

---

## 6. 交互流程

### 6.1 支付流程

```
1. 用户选择支付金额
2. 调用创建支付意图API
3. 使用Stripe Elements处理支付
4. 支付成功后更新余额
```

---

## 7. UI 规范

- 使用 Ant Design Vue 组件
- 集成 Stripe Elements
- 钱包余额使用Card组件展示

---

## 8. 权限控制

- 用户只能查看和管理自己的钱包
- 管理员可以查看所有钱包

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN前端开发团队

