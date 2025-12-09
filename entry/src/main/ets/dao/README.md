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
## 这个 AccountDAO 实现了：
- 数据库管理：初始化数据库，创建表。
- 单条/批量 CRUD： 
  - 插入：insert, insertMany 
  - 查询：getById, getAll, getByUserId, getByBalanceRange, exists 
  - 更新：update, updateMany 
  - 删除：delete（物理）、softDelete（逻辑）
- 事务支持：
  - transaction 封装异步操作。
  - insertMany、updateMany 使用事务保证原子性。
- 数据映射：ResultSet → Account 对象。
- 数据完整性校验：在插入/更新前调用 validate()。

## 这个 BillDAO 实现了：
* 数据库管理：初始化数据库，创建表。
* 单条 CRUD：
    * 插入：insert
    * 查询：getById, getAll,getByUserId
    * 更新：update
    * 删除：delete（逻辑删除）
* 事务支持：transaction 封装异步操作。
* 外键验证：在插入或更新前验证 account_id 与 category_id 是否存在。
* 数据映射：ResultSet → Bill 对象。

## 这个 BudgetDAO 实现了：
* 数据库管理：初始化数据库，创建表。
* 单条 CRUD：
    * 插入：insert
    * 查询：getById, getAll, getAllActive, exists
    * 更新：update
    * 删除：delete（物理删除）、softDelete（逻辑删除）
* 事务支持：transaction 封装异步操作。
* 数据映射：ResultSet → Budget 对象。
* 数据完整性校验：在插入/更新前调用 validate()。

## 这个 CategoryDAO 实现了：
* 数据库管理：初始化数据库，创建表和索引。
* 单条/批量 CRUD：
    * 插入：insert, bulkInsert
    * 查询：getById, getAll, getByType, getChildren, exists
    * 更新：update
    * 删除：softDelete（逻辑删除）、restore（恢复）、hardDelete（物理删除）
* 事务支持：bulkInsert 可使用事务保证原子性。
* 数据映射：ResultSet → Category 对象。
* 数据完整性校验：在插入/更新前调用 validate()。
* 错误处理：统一封装 toError 进行详细错误输出。

## 这个 StatisticsDAO 实现了：
* 数据库管理：初始化数据库，创建月度统计表（monthly_statistics）和分类统计表（category_statistics）。
* 单条/批量 CRUD：
    * 插入：insertMonthly、insertCategory、bulkInsertMonthly、bulkInsertCategory
    * 查询：getMonthly、getAllMonthly、getCategory、getAllCategory
    * 更新：updateMonthly、updateCategory
    * 删除：softDeleteMonthly/restoreMonthly、softDeleteCategory/restoreCategory
* 事务支持：transaction 封装异步操作，批量插入使用事务保证原子性。
* 数据映射：ResultSet → MonthlyStatistics 或 CategoryStatistics 对象。
* 数据完整性校验：在插入/更新前调用 validate()。
* 错误处理：统一捕获并抛出明确错误信息。

## 这个 UserDAO 实现了：
* 数据库管理：初始化数据库，创建月度统计表（monthly_statistics）和分类统计表（category_statistics）。
* 单条/批量 CRUD：
    * 插入：insertMonthly、insertCategory、bulkInsertMonthly、bulkInsertCategory
    * 查询：getMonthly、getAllMonthly、getCategory、getAllCategory
    * 更新：updateMonthly、updateCategory
    * 删除：softDeleteMonthly/restoreMonthly、softDeleteCategory/restoreCategory
* 事务支持：transaction 封装异步操作，批量插入使用事务保证原子性。
* 数据映射：ResultSet → MonthlyStatistics 或 CategoryStatistics 对象。
* 数据完整性校验：在插入/更新前调用 validate()。
* 错误处理：统一捕获并抛出明确错误信息。

