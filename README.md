# HarmonyOS ArkTS DAO 层使用文档

本目录提供业务的数据库访问对象（DAO）实现，所有代码 ArkTS 强类型、linter 零警告、异常友好。

---

## 目录结构
```
entry/src/main/ets/dao/
├── BillDAO.ets              // 账单数据
├── BudgetDAO.ets            // 预算数据
├── CategoryDAO.ets          // 分类
├── UserDAO.ets              // 用户
├── AccountDAO.ets           // 账户 
├── StatisticsDAO.ets        // 统计
├── README.md                // 本文档
```

---

## 各 DAO 结构与方法举例

### 1. BillDAO.ets
**对象：账单表 bills**
| 方法名       | 功能说明 |
|--------------|-----------------------------------------------------|
| initDatabase | 初始化数据库和账单表（必须先调用）                  |
| createTables | 创建账单表结构（通常由 initDatabase 调用）         |
| insert       | 插入一条账单                                        |
| getById      | 根据 billId 查询单条账单                            |
| getAll       | 查询所有账单                                        |
| update       | 更新账单内容（根据 billId）                         |
| delete       | 删除账单（根据 billId）                             |

#### 用法详例
```typescript
import { Bill } from '../model/Bill';
import { BillDAO } from './BillDAO';
import abilityFeatureAbility from '@ohos.ability.featureAbility';
const ctx = abilityFeatureAbility.getContext();

// 1. 初始化数据库（必调）
await BillDAO.initDatabase(ctx);

// 2. 创建账单表（一般不直接调）
await BillDAO.createTables();

// 3. 插入一条账单
const bill = new Bill();
bill.userId = 1;
bill.accountId = 12;
bill.categoryId = 8;
bill.amount = 100.5;
bill.type = 'expense';
bill.note = '午餐';
bill.transactionDate = '2024-06-01';
bill.createdAt = '2024-06-01T09:00:00';
bill.updatedAt = '2024-06-01T09:01:00';
await BillDAO.insert(bill);

// 4. 查询某账单
const theBill = await BillDAO.getById(1); // 返回 Bill/null

// 5. 查询全部账单
const allBills = await BillDAO.getAll(); // Bill[]

// 6. 更新账单
if (theBill) {
  theBill.note = '早午餐';
  await BillDAO.update(theBill);
}

// 7. 删除账单
await BillDAO.delete(1);
//8.按条件筛选账单
const dateRange = { start: '2025-11-01', end: '2025-11-30' };
const bills = await BillDAO.getBillsByFilters(CURRENT_USER_ID, dateRange);

const categoryId = 1;
const foodBills = await BillDAO.getBillsByFilters(CURRENT_USER_ID, dateRange, categoryId);
```

---

### 2. AccountDAO.ets
**对象：账户表 accounts**
| 方法       | 功能说明                               |
|------------|---------------------------------------|
| initDatabase | 初始化数据库和表（必须先调用）        |
| createTables | 创建账户表（通常由 initDatabase 调） |
| insert       | 插入新账户                           |
| getById      | 查单个账户                           |
| getAll       | 查所有账户                           |
| update       | 更新账户                             |
| delete       | 删除账户                             |

#### 用法详例
```typescript
import { Account } from '../model/Account';
import { AccountDAO } from './AccountDAO';
const ctx = abilityFeatureAbility.getContext();

// 1. 初始化数据库
await AccountDAO.initDatabase(ctx);

// 2. 新增账户
const acc = new Account();
acc.userId = 1;
acc.name = '交通银行卡';
acc.type = 'bank';
acc.balance = 5000;
acc.color = '#1E90FF';
acc.createdAt = '2024-06-01T08:00:00';
await AccountDAO.insert(acc);

// 3. 查单个账户
const a1 = await AccountDAO.getById(1); // Account/null

// 4. 查全部账户
const allAcc = await AccountDAO.getAll(); // Account[]

// 5. 更新账户
if (a1) {
  a1.balance = 4500;
  await AccountDAO.update(a1);
}

// 6. 删除账户
await AccountDAO.delete(1);
```

---

### 3. BudgetDAO.ets
**对象：预算表 budgets**
| 方法         | 功能说明                    |
|--------------|-----------------------------|
| initDatabase | 初始化数据库（必调）        |
| createTables | 建预算表，一般不手动调      |
| insert       | 新增预算                    |
| getById      | 查某份预算                  |
| getAll       | 查全部预算                  |
| update       | 更新预算                    |
| delete       | 删除预算                    |

#### 用法详例
```typescript
import { Budget } from '../model/Budget';
import { BudgetDAO } from './BudgetDAO';

// 1. 初始化数据库和表
await BudgetDAO.initDatabase(ctx);

// 2. 新增预算
const bud = new Budget();
bud.userId = 2; // 所属用户
bud.categoryId = 3; // 分类关联
bud.amount = 300; // 预算金额
bud.period = 'monthly'; // 'monthly' | 'yearly'
bud.startDate = '2024-06-01'; // 预算周期起始
bud.endDate = '';
bud.isActive = 1; // 激活状态
bud.createdAt = '2024-06-01T10:00:00';
await BudgetDAO.insert(bud);

// 3. 查询单条预算
const budget = await BudgetDAO.getById(1); // 根据 budget_id 查询

// 4. 查询全部预算
const allBud = await BudgetDAO.getAll(); // 返回 Budget[]

// 5. 更新预算内容
bud.amount = 280;
await BudgetDAO.update(bud);

// 6. 删除预算
await BudgetDAO.delete(1);
```

---

### 4. CategoryDAO.ets
**对象：分类表 categories**
| 方法         | 功能说明                       |
|--------------|-------------------------------|
| initDatabase | 初始化数据库表（必调）         |
| createTables | 建表，通常由 initDatabase 调  |
| insert       | 新增分类                       |
| getById      | 按ID查分类                     |
| getAll       | 全部分类列表                   |
| update       | 编辑分类                       |
| delete       | 删除分类                       |

#### 用法详例
```typescript
import { Category } from '../model/Category';
import { CategoryDAO } from './CategoryDAO';

// 1. 初始化分类数据表
await CategoryDAO.initDatabase(ctx);

// 2. 新增分类
const c = new Category();
c.userId = 1;
c.name = '三餐'; // 分类名称
c.type = 'expense'; // 类型
c.icon = '🍚'; // 图标
c.color = '#FFD700'; // 颜色
c.parentCategoryId = 0; // 顶级分类
c.createdAt = '2024-06-01T12:00:00';
await CategoryDAO.insert(c);

// 3. 查询分类
const catItem = await CategoryDAO.getById(1);

// 4. 查询全部分类
const catList = await CategoryDAO.getAll();

// 5. 修改分类
c.name = '主食';
await CategoryDAO.update(c);

// 6. 删除分类
await CategoryDAO.delete(1);
```

---
### 5. UserDAO.ets
**对象：用户表 users**
| 方法         | 功能说明           |
|--------------|-------------------|
| initDatabase | 初始化数据库      |
| createTables | 创建表            |
| insert       | 新用户            |
| getById      | 按ID查            |
| getAll       | 全部用户          |
| update       | 编辑用户          |
| delete       | 删用户            |

#### 用法详例
```typescript
import { User } from '../model/User';
import { UserDAO } from './UserDAO';

// 1. 初始化用户表
await UserDAO.initDatabase(ctx);

// 2. 新建一个用户
const u = new User();
u.username = 'zhangsan'; // 用户名
u.email = 'zhangsan@qq.com';
u.passwordHash = '12345'; // 密码哈希
u.createdAt = '2024-06-02T11:00:00';
await UserDAO.insert(u);

// 3. 按ID查用户
const u1 = await UserDAO.getById(1);

// 4. 查询所有用户
const users = await UserDAO.getAll();

// 5. 修改用户
u.email = 'zs@huawei.com';
await UserDAO.update(u);

// 6. 删除用户
await UserDAO.delete(1);
```

---
### 6. StatisticsDAO.ets
**对象：多种统计表相关
方法较多，分月统计和分类统计两套**
| 方法名                           | 功能 |
|-----------------------------------|---------|
| initDatabase                     | 初始化表 |
| createTables                     | 创建表   |
| insertMonthlyStatistics          | 新增月统计                             |
| getMonthlyStatistics             | 查月统计（userId, month）               |
| getAllMonthlyStatistics          | 全查月统计                              |
| updateMonthlyStatistics          | 改月统计                                |
| deleteMonthlyStatistics          | 删除月统计（userId,categoryId,month）   |
| insertCategoryStatistics         | 新增分类统计                            |
| getCategoryStatistics            | 查某分类统计                            |
| getAllCategoryStatistics         | 全部分类统计                            |
| updateCategoryStatistics         | 改分类统计                              |
| deleteCategoryStatistics         | 删除分类统计                            |

#### 用法详例
```typescript
import { StatisticsDAO } from './StatisticsDAO';
import { MonthlyStatistics, CategoryStatistics } from '../model/Statistics';
// 1. 初始化
await StatisticsDAO.initDatabase(ctx);
await StatisticsDAO.createTables();
// 2. 插入月统计
await StatisticsDAO.insertMonthlyStatistics({
  userId: 1, categoryId: 2, month: '2024-06', totalExpense: 900, totalIncome: 2000, transactionCount: 12
} as MonthlyStatistics);
// 3. 查询指定用户某月
const ms = await StatisticsDAO.getMonthlyStatistics(1, '2024-06');
// 4. 查全部月数据
const msAll = await StatisticsDAO.getAllMonthlyStatistics();
// 5. 更新月数据
if (ms) { ms.totalExpense += 50; await StatisticsDAO.updateMonthlyStatistics(ms); }
// 6. 删除月度统计
await StatisticsDAO.deleteMonthlyStatistics(1, 2, '2024-06');
// 7. 插入分类统计
await StatisticsDAO.insertCategoryStatistics({
  categoryId: 7, categoryName: '饮食', type:'expense', totalAmount:1012, transactionCount:24, percentage:0.45, icon:'🍜', color:'#FA0'
} as CategoryStatistics);
// 8. 查单个分类统计
const sc = await StatisticsDAO.getCategoryStatistics(7);
// 9. 查全部分类统计
const scAll = await StatisticsDAO.getAllCategoryStatistics();
// 10. 更新分类统计
if (sc) { sc.totalAmount += 100; await StatisticsDAO.updateCategoryStatistics(sc); }
// 11. 删除分类统计
await StatisticsDAO.deleteCategoryStatistics(7);
```

---

## 使用注意事项
- 所有 DB 操作必须先调用对应的 initDatabase(context)
- Model 字段变动需同步更新 DAO 层，否则类型和数据会错
- 调用前需导入本地 Ability Context (见 BillDAO 导入例)
- 所有函数异步 Promise 返回，部署中强烈建议 await/try/catch

如需扩展 DAO 层，自行仿照本风格。
