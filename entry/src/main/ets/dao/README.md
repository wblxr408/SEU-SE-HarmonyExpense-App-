# DAO 层说明文档

数据访问对象层，负责所有数据库操作。

## 文件列表

- AccountDAO.ets - 账户数据访问
- BillDAO.ets - 账单数据访问
- BudgetDAO.ets - 预算数据访问
- CategoryDAO.ets - 分类数据访问
- StatisticsDAO.ets - 统计数据访问
- TagDAO.ets - 标签数据访问
- UserDAO.ets - 用户数据访问
- index.ets - 统一导出

## 核心功能

### 1. 基础 CRUD 操作
所有 DAO 都提供标准的增删改查方法：
- insert - 插入单条记录
- getById - 根据 ID 查询
- getAll - 查询所有记录
- update - 更新记录
- delete - 删除记录

### 2. 批量操作
支持批量数据处理，提升性能：
- bulkInsert - 批量插入
- bulkUpdate - 批量更新
- bulkSoftDelete - 批量软删除

### 3. 软删除机制
使用 is_deleted 字段标记删除，不物理删除数据：
- softDelete - 标记为已删除
- restore - 恢复已删除数据
- hardDelete - 物理删除（慎用）

### 4. 事务支持
所有批量操作都使用事务保证数据一致性：
- transaction - 事务封装方法
- 自动回滚失败操作

### 5. 数据验证
插入和更新前自动验证数据：
- validate - 数据完整性检查
- validateForeignKeys - 外键约束检查

### 6. 统一错误处理
使用 DAOHelper 统一处理错误：
- toError - 错误信息格式化
- 详细的错误日志

## 特殊功能

### BillDAO
- 日期范围查询
- 分页查询
- 统计查询（总计、月度）
- 按分类筛选

### CategoryDAO
- 分类树结构
- 按类型查询（支出/收入）
- 子分类查询
- 分类聚合统计
- 缓存支持

### TagDAO
- 标签关联管理
- 热门标签查询
- 标签聚合统计
- 批量设置标签

### StatisticsDAO
- 月度统计
- 分类统计
- 双表管理

## 使用 DAOHelper

所有 DAO 统一使用 DAOHelper 提供的通用方法：
- DAOHelper.transaction - 事务处理
- DAOHelper.toError - 错误转换
- DAOHelper.softDelete - 软删除
- DAOHelper.restore - 恢复
- DAOHelper.exists - 检查存在

## 数据安全

所有涉及用户数据的操作都会验证 userId，确保数据隔离：
- getById 需要 userId 参数
- delete 需要 userId 参数
- restore 需要 userId 参数

## 性能优化

- 使用索引优化查询
- 批量操作减少数据库往返
- 缓存热点数据
- 事务批处理

## 注意事项

1. 所有异步方法都需要 await
2. 批量操作会自动分批处理
3. 软删除的数据不会出现在查询结果中
4. 外键约束会在插入前验证
5. 所有错误都会抛出 Error 对象
