# 支付与钱包系统模块 - 后端文档

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

支付与钱包系统模块负责：

- **Stripe Connect集成**: Stripe Connect账户管理
- **USDC钱包管理**: USDC钱包创建和管理
- **支付处理**: Stripe支付处理
- **交易记录**: 交易历史记录

---

## 2. 数据模型（Model/Schema）

### 2.1 Stripe::Wallet 模型

```ruby
class Stripe::Wallet < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"
  has_many :transactions, class_name: "Stripe::Transaction"
  
  # 字段: id, owner_id, stripe_account_id, wallet_address, balance_usdc, status
end
```

### 2.2 Stripe::Transaction 模型

```ruby
class Stripe::Transaction < ApplicationRecord
  belongs_to :wallet
  
  # 字段: id, wallet_id, stripe_payment_intent_id, transaction_type, amount, currency, status
end
```

---

## 3. API 规范（Controller/Route）

### 3.1 钱包管理

```ruby
# GET /stripe/wallets
def index
  wallet = Stripe::Wallet.find_or_create_by(owner_id: current_user.id)
  render_success({ wallet: wallet.to_json })
end

# POST /stripe/wallets/:id/update_balance
def update_balance
  wallet = Stripe::Wallet.find(params[:id])
  wallet.update!(balance_usdc: params[:balance_usdc])
  render_success({ wallet: wallet.to_json })
end
```

### 3.2 支付处理

```ruby
# POST /stripe/payments/:id/create_intent
def create_intent
  payment_intent = Stripe::PaymentIntent.create({
    amount: params[:amount],
    currency: params[:currency]
  })
  render_success({ payment_intent: payment_intent })
end
```

### 3.3 Webhook处理

```ruby
# POST /stripe/webhooks
def create
  event = Stripe::Webhook.construct_event(request.body, request.headers['Stripe-Signature'])
  
  case event.type
  when 'payment_intent.succeeded'
    handle_payment_succeeded(event.data.object)
  when 'payment_intent.payment_failed'
    handle_payment_failed(event.data.object)
  end
  
  render_success({ received: true })
end
```

---

## 4. 业务逻辑流程

### 4.1 钱包初始化流程

```ruby
def self.initialize_wallet(user)
  wallet = Stripe::Wallet.find_or_initialize_by(owner_id: user.id)
  
  if wallet.new_record?
    # 创建Stripe Connect账户
    account = Stripe::Account.create({ type: 'express' })
    wallet.stripe_account_id = account.id
    wallet.save!
  end
  
  { success: true, wallet: wallet }
end
```

---

## 5. 权限与鉴权规则

- 用户只能查看和管理自己的钱包
- 管理员可以查看所有钱包

---

## 6. 错误码和响应规范

标准响应格式。

---

## 7. 定时任务/队列处理/事件

### 7.1 Webhook事件处理

处理Stripe Webhook事件，更新钱包余额和交易记录。

---

**文档版本**: v1.0  
**最后更新**: 2025-11-19  
**维护者**: GWEN后端开发团队

