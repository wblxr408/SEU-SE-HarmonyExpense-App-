# Implementation Plan

- [x] 1. 创建索引管理模块





  - 创建 `entry/src/main/ets/database/IndexManager.ets` 文件
  - 实现 `createAllIndexes()` 方法作为统一入口
  - 实现 Bills 表的 3 个核心索引创建（日期索引、覆盖索引、账户日期索引）
  - 实现 Accounts 表的用户类型复合索引
  - 实现 Bill_Tags 表的双向索引
  - 在 DatabaseManager 初始化时调用索引创建
  - 添加详细的注释说明每个索引的用途和优化原理
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. 实现批量查询辅助模块


  - 创建 `entry/src/main/ets/database/BatchQueryHelper.ets` 文件
  - 实现批量插入功能 `bulkInsert()`，支持自动分批（100条/批）
  - 实现批量软删除功能 `bulkSoftDelete()`，使用 IN 子句
  - 实现事务管理逻辑（beginTransaction、commit、rollback）
  - 添加错误处理和日志输出
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

- [-] 3. 在 BillDAO 中集成批量操作

  - 在 `entry/src/main/ets/dao/BillDAO.ets` 中添加 `bulkInsert()` 方法
  - 在 `entry/src/main/ets/dao/BillDAO.ets` 中添加 `bulkSoftDelete()` 方法
  - 调用 BatchQueryHelper 的对应方法
  - 添加数据验证逻辑
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 4. 实现分页查询功能
  - 在 `entry/src/main/ets/dao/BillDAO.ets` 中添加 `getByPage()` 方法
  - 创建 `PaginatedResult` 接口定义返回结构
  - 实现总数统计查询（COUNT）
  - 实现分页数据查询（LIMIT + OFFSET）
  - 确保使用索引优化排序性能
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 5. 实现聚合统计查询
  - 在 `entry/src/main/ets/dao/BillDAO.ets` 中添加 `getTotalStats()` 方法
  - 创建 `TotalStats` 接口定义统计结果结构
  - 使用 CASE 表达式在单个查询中计算收入和支出
  - 使用覆盖索引优化查询性能
  - 在 `entry/src/main/ets/dao/BillDAO.ets` 中添加 `getMonthlyStats()` 方法
  - 创建 `MonthlyStats` 接口定义月度统计结构
  - 使用 strftime 和 GROUP BY 实现按月聚合
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 6. 实现性能监控装饰器（⭐ 企业级亮点）
  - 创建 `entry/src/main/ets/database/PerformanceMonitor.ets` 文件
  - 实现 `measureQueryTime` 装饰器函数
  - 实现时间戳记录和耗时计算逻辑
  - 实现慢查询警告（> 100ms）
  - 实现错误捕获和日志记录
  - 在 BillDAO 的关键查询方法上应用装饰器
  - 添加注释说明装饰器模式和 AOP 思想
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ]* 7. 实现内存缓存管理器（⭐ 企业级亮点 - 可选）
  - 创建 `entry/src/main/ets/database/CacheManager.ets` 文件
  - 定义 `CacheEntry` 接口（value + expireAt）
  - 实现 `get()` 方法，包含自动过期检查
  - 实现 `set()` 方法，支持自定义 TTL（默认 5 分钟）
  - 实现 `clear()` 方法，支持正则表达式模式匹配
  - 在 CategoryDAO 的 `getAll()` 方法中集成缓存
  - 在 CategoryDAO 的 `insert()` 方法中清除缓存
  - 添加注释说明 TTL 机制和缓存失效策略
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ]* 8. 实现数据库配置优化（可选）
  - 创建 `entry/src/main/ets/database/DatabaseConfigOptimizer.ets` 文件
  - 实现 `applyOptimizations()` 方法
  - 执行 PRAGMA journal_mode=WAL
  - 执行 PRAGMA cache_size=10000
  - 执行 PRAGMA synchronous=NORMAL
  - 执行 PRAGMA temp_store=MEMORY
  - 在 DatabaseManager 初始化时调用配置优化
  - 添加注释说明每个配置参数的作用
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ]* 9. 功能验证和文档完善（可选）
  - 在应用启动时观察索引创建日志
  - 测试批量插入 100 条数据，观察分批日志和耗时
  - 测试分页查询，验证返回数据结构正确
  - 测试统计查询，验证计算结果准确
  - 观察性能监控装饰器的日志输出
  - 测试缓存功能，观察缓存命中日志
  - 在代码中添加详细注释，说明技术亮点
  - 准备演示文档，突出 3 个企业级亮点
  - _Requirements: All_
