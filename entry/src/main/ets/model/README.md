# HarmonyExpense Model Layer - 1.0.0版本

## 文件结构

```
model/
├── index.ets              # 统一导出
├── User.ets               # 用户模型
├── Account.ets            # 账户模型
├── Category.ets           # 分类模型
├── Bill.ets               # 账单模型
├── Budget.ets             # 预算模型
└── Statistics.ets         # 统计模型
```

## 使用方法

### 1. 导入模型

```typescript
import { User, Account, Category, Bill, Budget } from '../model';
```

### 2. 创建对象

```typescript
// 创建用户
let user = new User();
user.userId = 1;
user.username = 'zhangsan';
user.email = 'zhangsan@example.com';
user.passwordHash = 'hashed_password';
user.createdAt = '2025-10-29 10:00:00';

// 创建账户
let account = new Account();
account.accountId = 1;
account.userId = 1;
account.name = '中国银行储蓄卡';
account.type = 'bank';
account.balance = 5000.00;
account.color = '#1890FF';
account.createdAt = '2025-10-29 10:00:00';

// 创建分类
let category = new Category();
category.categoryId = 1;
category.userId = 1;
category.name = '餐饮';
category.type = 'expense';
category.icon = '🍽️';
category.color = '#FF6B6B';
category.parentCategoryId = 0; // 0表示一级分类

// 创建账单
let bill = new Bill();
bill.billId = 1;
bill.userId = 1;
bill.accountId = 1;
bill.categoryId = 1;
bill.amount = 50.00;
bill.type = 'expense';
bill.note = '午餐';
bill.transactionDate = '2025-10-29';
bill.createdAt = '2025-10-29 12:30:00';
bill.updatedAt = '2025-10-29 12:30:00';

// 创建预算
let budget = new Budget();
budget.budgetId = 1;
budget.userId = 1;
budget.categoryId = 1;
budget.amount = 3000.00;
budget.period = 'monthly';
budget.startDate = '2025-10-01';
budget.endDate = ''; // 空字符串表示持续有效
budget.isActive = 1;
budget.createdAt = '2025-10-29 10:00:00';
```

## 字段说明

### User（用户）
- `userId`: 用户ID
- `username`: 用户名
- `email`: 邮箱
- `passwordHash`: 密码哈希
- `createdAt`: 创建时间（字符串格式）

### Account（账户）
- `accountId`: 账户ID
- `userId`: 所属用户ID
- `name`: 账户名称
- `type`: 账户类型（'cash' | 'bank' | 'credit_card' | 'other'）
- `balance`: 余额
- `color`: 颜色代码
- `createdAt`: 创建时间

### Category（分类）
- `categoryId`: 分类ID
- `userId`: 所属用户ID
- `name`: 分类名称
- `type`: 交易类型（'expense' | 'income'）
- `icon`: 图标
- `color`: 颜色代码
- `parentCategoryId`: 父分类ID（0表示一级分类）

### Bill（账单）
- `billId`: 账单ID
- `userId`: 所属用户ID
- `accountId`: 关联账户ID
- `categoryId`: 关联分类ID
- `amount`: 金额
- `type`: 交易类型（'expense' | 'income'）
- `note`: 备注
- `transactionDate`: 交易日期（YYYY-MM-DD格式）
- `createdAt`: 创建时间
- `updatedAt`: 更新时间

### Budget（预算）
- `budgetId`: 预算ID
- `userId`: 所属用户ID
- `categoryId`: 关联分类ID
- `amount`: 预算金额
- `period`: 周期（'monthly' | 'yearly'）
- `startDate`: 开始日期（YYYY-MM-DD格式）
- `endDate`: 结束日期（空字符串表示持续有效）
- `isActive`: 是否激活（1=激活，0=未激活）
- `createdAt`: 创建时间

## 注意事项

1. **所有日期使用字符串格式**，避免Date对象的兼容性问题
2. **布尔值使用数字**（1=true, 0=false），符合SQLite习惯
3. **枚举值使用字符串**，不使用enum类型
4. **所有字段都有默认值**，避免undefined问题
5. **不使用复杂的泛型和类型推断**

## 数据库字段映射

| Model字段 | 数据库字段 |
|----------|-----------|
| userId | user_id |
| accountId | account_id |
| categoryId | category_id |
| billId | bill_id |
| budgetId | budget_id |
| createdAt | created_at |
| updatedAt | updated_at |
| transactionDate | transaction_date |
| passwordHash | password_hash |
| parentCategoryId | parent_category_id |
| isActive | is_active |
| startDate | start_date |
| endDate | end_date |

## 预设分类数据

### 支出分类
```typescript
const expenseCategories = [
  { name: '餐饮', icon: '🍽️', color: '#FF6B6B' },
  { name: '交通', icon: '🚗', color: '#4ECDC4' },
  { name: '购物', icon: '🛍️', color: '#95E1D3' },
  { name: '娱乐', icon: '🎮', color: '#F38181' },
  { name: '医疗', icon: '💊', color: '#AA96DA' },
  { name: '住房', icon: '🏠', color: '#FCBAD3' },
  { name: '教育', icon: '📚', color: '#A8D8EA' },
  { name: '其他', icon: '📦', color: '#A0A0A0' }
];
```

### 收入分类
```typescript
const incomeCategories = [
  { name: '工资', icon: '💰', color: '#52C41A' },
  { name: '奖金', icon: '🎁', color: '#1890FF' },
  { name: '投资', icon: '📈', color: '#722ED1' },
  { name: '其他', icon: '💵', color: '#13C2C2' }
];
```