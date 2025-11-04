# 数据访问层架构设计

## 概述

本项目的数据访问层采用 **Model + DAO** 分层架构模式，为 HarmonyOS 记账应用提供完整的数据结构和持久化支持。Model 层负责数据建模，DAO 层负责数据库操作，两者协作实现数据的完整生命周期管理。

## 架构图

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   业务逻辑层     │    │   Model 层      │    │   DAO 层        │
│   (Service)     │◄──►│   (Entities)    │◄──►│ (Data Access)   │
│                 │    │                 │    │                 │
│ - 账单管理       │    │ - User 用户     │    │ - UserDAO       │
│ - 预算控制       │    │ - Account 账户  │    │ - AccountDAO    │
│ - 统计分析       │    │ - Category 分类 │    │ - CategoryDAO   │
│ - 用户认证       │    │ - Bill 账单     │    │ - BillDAO       │
│                 │    │ - Budget 预算   │    │ - BudgetDAO     │
│                 │    │ - Statistics 统计│    │ - StatisticsDAO │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                              │
                                              ▼
                                    ┌─────────────────┐
                                    │  关系型数据库    │
                                    │ (SQLite/RDB)    │
                                    │                 │
                                    │ - users         │
                                    │ - accounts      │
                                    │ - categories    │
                                    │ - bills         │
                                    │ - budgets       │
                                    │ - *_statistics  │
                                    └─────────────────┘
```

## Model 层：数据模型

### 1. User ([User.ets](User.ets))
用户核心信息模型
- **表名**: `users`
- **主要字段**: `userId`, `username`, `email`, `passwordHash`
- **功能**: 用户身份验证和基础信息管理

### 2. Account ([Account.ets](Account.ets))
账户管理模型，支持多种账户类型
- **表名**: `accounts`
- **主要字段**: `accountId`, `userId`, `name`, `type`, `balance`, `color`
- **账户类型**: `cash` | `bank` | `credit_card` | `other`
- **功能**: 余额管理和账户分类

### 3. Category ([Category.ets](Category.ets))
收支分类模型，支持多级分类结构
- **表名**: `categories`
- **主要字段**: `categoryId`, `userId`, `name`, `type`, `icon`, `color`, `parentCategoryId`
- **分类类型**: `expense` | `income`
- **功能**: 父子分类关系和自定义图标

### 4. Bill ([Bill.ets](Bill.ets))
账单记录核心模型
- **表名**: `bills`
- **主要字段**: `billId`, `accountId`, `categoryId`, `amount`, `note`, `transactionDate`, `type`
- **交易类型**: `income` | `expense`
- **关联关系**: Account → Bill ← Category

### 5. Budget ([Budget.ets](Budget.ets))
预算管理模型
- **主要字段**: `budgetId`, `userId`, `categoryId`, `amount`, `period`, `startDate`, `endDate`
- **预算周期**: `monthly` | `yearly`
- **功能**: 时间段控制和激活状态管理

### 6. Statistics ([Statistics.ets](Statistics.ets))
统计分析模型，包含两个子类

#### MonthlyStatistics
月度统计：按月统计收支数据
- **主要字段**: `userId`, `categoryId`, `month`, `totalExpense`, `totalIncome`, `transactionCount`

#### CategoryStatistics
分类统计：按分类统计收支占比
- **主要字段**: `categoryId`, `categoryName`, `type`, `totalAmount`, `transactionCount`, `percentage`

## DAO 层：数据访问对象

### DAO 设计模式特点

#### 统一架构模式
每个 DAO 类都遵循统一的设计模式：
- **数据库初始化**: `initDatabase()` - 创建数据库连接和表结构
- **CRUD 操作**: `insert()`, `getById()`, `getAll()`, `update()`, `delete()`
- **软删除支持**: `softDelete()`, `restore()`
- **批量操作**: `insertMany()`, `updateMany()`
- **事务管理**: `transaction()` - 统一事务处理
- **数据验证**: 操作前调用 Model 的 `validate()` 方法

#### 核心功能特性

**1. 数据库配置**
- 数据库名称: `harmony_expense.db`
- 安全等级: `S1`
- 自动建表和索引

**2. 外键约束验证**
- BillDAO 验证 Account 和 Category 的存在性
- 确保数据引用完整性

**3. 高级查询支持**
- AccountDAO: 余额范围查询、用户账户查询
- CategoryDAO: 按类型查询、父子分类查询
- StatisticsDAO: 复合主键查询、统计分析

**4. 错误处理机制**
- 统一错误转换和日志记录
- 事务自动回滚机制

### DAO 类详解

#### 1. UserDAO ([UserDAO.ets](../dao/UserDAO.ets))
用户数据访问，提供基础的用户管理功能
- **特色**: 邮箱唯一性约束、密码哈希存储
- **软删除**: 支持用户软删除和恢复

#### 2. AccountDAO ([AccountDAO.ets](../dao/AccountDAO.ets))
账户数据访问，支持多种查询方式
- **特色**: 余额范围查询、批量更新、软删除/恢复
- **验证**: 账户存在性检查

#### 3. CategoryDAO ([CategoryDAO.ets](../dao/CategoryDAO.ets))
分类数据访问，支持层级分类结构
- **特色**: 用户唯一性约束、索引优化、父子分类查询
- **索引**: `user_type`, `user_parent` 复合索引

#### 4. BillDAO ([BillDAO.ets](../dao/BillDAO.ets))
账单数据访问，包含外键验证
- **特色**: 外键约束验证、关联查询、交易记录管理
- **验证**: 确保 Account 和 Category 存在

#### 5. BudgetDAO ([BudgetDAO.ets](../dao/BudgetDAO.ets))
预算数据访问，支持预算周期管理
- **特色**: 激活状态管理、时间段控制、软删除支持
- **查询**: 活跃预算查询

#### 6. StatisticsDAO ([StatisticsDAO.ets](../dao/StatisticsDAO.ets))
统计数据访问，支持月度和分类统计
- **特色**: 复合主键、批量统计、数据聚合
- **表结构**: `monthly_statistics`, `category_statistics`

## 设计模式

### Model 层设计模式

#### 统一接口设计
每个模型类都实现标准方法：
- `toJSON()`: 序列化为 JSON 对象
- `fromJSON()`: 从 JSON 对象反序列化
- `validate()`: 数据完整性验证
- `clone()`: 对象克隆

#### 软删除支持
所有模型均包含 `is_deleted` 字段（0=未删除，1=已删除），支持软删除功能。

### DAO 层设计模式

#### 数据访问对象模式 (DAO)
- 封装数据库操作细节
- 提供统一的业务接口
- 支持多种数据库操作

#### 事务管理模式
- 统一事务处理方法
- 自动异常回滚
- 批量操作事务保护

#### 数据验证模式
- 操作前数据验证
- 外键约束检查
- 业务规则验证

## 数据库设计

### 表结构总览
```
users              - 用户表
accounts           - 账户表
categories         - 分类表
bills              - 账单表
budgets            - 预算表
monthly_statistics - 月度统计表
category_statistics - 分类统计表
```

### 约束和索引
- **主键**: 自增 INTEGER 主键
- **外键**: 应用层外键约束验证
- **唯一性**: 用户邮箱唯一、用户分类名唯一
- **索引**: 查询性能优化索引
- **软删除**: 统一 `is_deleted` 字段

## 版本信息
- **Model 层版本**: 1.0.0
- **Budget 模型版本**: 1.0.1（支持软删除）
- **DAO 层版本**: 1.0.0（完整 CRUD 支持）

## 导出结构

### Model 层导出
统一通过 [index.ets](index.ets) 导出所有模型类：
```typescript
export { User } from './User';
export { Account } from './Account';
export { Category } from './Category';
export { Bill } from './Bill';
export { Budget } from './Budget';
export { MonthlyStatistics, CategoryStatistics } from './Statistics';
```

### DAO 层使用
```typescript
import { UserDAO } from '../dao/UserDAO';
import { AccountDAO } from '../dao/AccountDAO';
// ... 其他 DAO 类

// 初始化数据库
await UserDAO.initDatabase(context);

// 使用 DAO 操作
const user = await UserDAO.getById(1);
await AccountDAO.insert(account);
```