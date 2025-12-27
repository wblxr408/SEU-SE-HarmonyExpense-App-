# DAO 层说明文档

数据访问对象层，负责所有数据库操作。

## 文件列表

### 核心 DAO
- **UserDAO.ets** - 用户数据访问
- **AccountDAO.ets** - 账户数据访问
- **CategoryDAO.ets** - 分类数据访问（支持树形结构）
- **BillDAO.ets** - 账单数据访问
- **BudgetDAO.ets** - 预算数据访问
- **TagDAO.ets** - 标签数据访问
- **StatisticsDAO.ets** - 统计数据访问

### 高级功能 DAO
- **ReminderDAO.ets** - 提醒数据访问
- **CloudSyncRecordDAO.ets** - 云同步记录数据访问
- **NotificationDAO.ets** - 通知数据访问

### 智能功能 DAO（v2.0.0新增）
- **SmartCategoryDAO.ets** - 智能分类数据访问
- **AnomalyDetectionDAO.ets** - 异常检测数据访问
- **SharedLedgerDAO.ets** - 共享账本数据访问
- **OCRRecognitionDAO.ets** - OCR识别数据访问
- **EventSourcingDAO.ets** - 事件溯源数据访问

### 其他
- **index.ets** - 统一导出

---

## 核心功能

### 1. BillDAO - 账单数据访问

**基础 CRUD：**
- `insert(bill)` - 插入账单
- `getById(userId, billId)` - 按 ID 查询
- `getAll(userId)` - 获取所有账单
- `getByUserId(userId)` - 按用户查询
- `update(bill)` - 更新账单
- `delete(userId, billId)` - 删除账单（软删除）

**高级查询：**
- `getBillsByFilters(userId, dateRange, categoryId)` - 筛选查询
- `getBillsByDateRange(userId, start, end)` - 日期范围查询
- `getMonthlyStats(userId, month)` - 月度统计
- `getPaginatedBills(userId, page, pageSize)` - 分页查询

### 2. CategoryDAO - 分类数据访问

**基础 CRUD：**
- `insert(category)` - 插入分类
- `getById(userId, categoryId)` - 按 ID 查询
- `getAll(userId)` - 获取所有分类
- `getByType(userId, type)` - 按类型查询
- `update(category)` - 更新分类
- `delete(userId, categoryId)` - 删除分类

**多级分类支持：**
- `getCategoryTree(userId, type)` - 获取分类树
- `getChildren(userId, parentId)` - 获取子分类
- `updateSortOrder(categoryId, sortOrder)` - 更新排序

**统计聚合：**
- `aggregateByCategory(userId, dateRange)` - 分类聚合统计
- 支持缓存加速

### 3. TagDAO - 标签数据访问

**基础 CRUD：**
- `insert(tag)` - 插入标签
- `getById(userId, tagId)` - 按 ID 查询
- `getAll(userId)` - 获取所有标签
- `update(tag)` - 更新标签
- `delete(userId, tagId)` - 删除标签

**标签关联：**
- `setTagsForBill(billId, tagIds)` - 设置账单标签
- `getTagsForBill(billId)` - 获取账单标签
- `removeTagsFromBill(billId)` - 移除账单标签

**统计功能：**
- `getHotTags(userId, limit)` - 热门标签查询
- `incrementUsageCount(tagId)` - 更新使用次数
- `aggregateByTag(userId, dateRange)` - 标签聚合统计

### 4. SmartCategoryDAO - 智能分类数据访问

- `insertKeyword(keyword)` - 插入关键词规则
- `getKeywordsByCategory(categoryId)` - 按分类获取关键词
- `getAllKeywords(userId)` - 获取所有关键词规则
- `updateHabit(habit)` - 更新用户习惯
- `getHabitsByUser(userId)` - 获取用户习惯
- `deleteKeyword(keywordId)` - 删除关键词规则

### 5. AnomalyDetectionDAO - 异常检测数据访问

- `insertAnomaly(record)` - 插入异常记录
- `getAnomalies(userId, options)` - 获取异常记录
- `getUnreadCount(userId)` - 获取未读数量
- `markAsRead(anomalyId)` - 标记已读
- `updateBaseline(baseline)` - 更新消费基准线
- `getBaseline(userId, categoryId)` - 获取消费基准线

### 6. SharedLedgerDAO - 共享账本数据访问

**账本管理：**
- `insertLedger(ledger)` - 创建账本
- `getLedgersByUser(userId)` - 获取用户账本
- `updateLedger(ledger)` - 更新账本
- `deleteLedger(ledgerId)` - 删除账本

**成员管理：**
- `addMember(member)` - 添加成员
- `getMembers(ledgerId)` - 获取成员列表
- `updateMemberRole(memberId, role)` - 更新成员角色
- `removeMember(memberId)` - 移除成员

**邀请管理：**
- `createInvitation(invitation)` - 创建邀请
- `getPendingInvitations(userId)` - 获取待处理邀请
- `acceptInvitation(invitationId)` - 接受邀请
- `declineInvitation(invitationId)` - 拒绝邀请

**共享账单：**
- `insertSharedBill(bill)` - 插入共享账单
- `getSharedBills(ledgerId)` - 获取共享账单
- `updateSharedBill(bill)` - 更新共享账单

### 7. OCRRecognitionDAO - OCR识别数据访问

- `insertTask(task)` - 创建识别任务
- `getTaskById(taskId)` - 获取任务
- `updateTask(task)` - 更新任务状态
- `getTasksByUser(userId)` - 获取用户任务历史

### 8. EventSourcingDAO - 事件溯源数据访问

**事件存储：**
- `insertEvent(event)` - 插入事件
- `getEvents(aggregateType, aggregateId)` - 获取聚合事件
- `getEventsSince(timestamp)` - 获取时间点后的事件

**快照管理：**
- `insertSnapshot(snapshot)` - 保存快照
- `getLatestSnapshot(aggregateType, aggregateId)` - 获取最新快照

**读模型：**
- `updateReadModel(model)` - 更新读模型
- `getReadModel(type, userId)` - 获取读模型

---

## 批量操作

所有 DAO 都支持批量数据处理：
- `bulkInsert(items)` - 批量插入
- `bulkUpdate(items)` - 批量更新
- `bulkSoftDelete(ids)` - 批量软删除

---

## 软删除机制

使用 `is_deleted` 字段标记删除：
- `softDelete(id)` - 标记为已删除
- `restore(id)` - 恢复已删除数据
- `hardDelete(id)` - 物理删除（慎用）

---

## 事务支持

所有批量操作都使用事务保证数据一致性：
- `transaction(callback)` - 事务封装方法
- 自动回滚失败操作

---

## 数据验证

插入和更新前自动验证数据：
- `validate(data)` - 数据完整性检查
- `validateForeignKeys(data)` - 外键约束检查

---

## 统一错误处理

使用 DAOHelper 统一处理错误：
- `toError(error)` - 错误信息格式化
- 详细的错误日志

---

## 数据安全

所有涉及用户数据的操作都会验证 `userId`，确保数据隔离：
- `getById` 需要 `userId` 参数
- `delete` 需要 `userId` 参数
- `restore` 需要 `userId` 参数

---

## 性能优化

- 使用索引优化查询
- 批量操作减少数据库往返
- 缓存热点数据（CacheManager）
- 事务批处理
- 覆盖索引避免回表查询

---

## 注意事项

1. 所有异步方法都需要 `await`
2. 批量操作会自动分批处理（每批100条）
3. 软删除的数据不会出现在查询结果中
4. 外键约束会在插入前验证
5. 所有错误都会抛出 `Error` 对象

---

*文档最后更新：2025年12月27日*
