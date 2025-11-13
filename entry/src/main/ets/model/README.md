# Model 层说明文档

数据模型层，定义所有业务实体。

## 文件列表

- User.ets - 用户模型
- Account.ets - 账户模型
- Category.ets - 分类模型
- Bill.ets - 账单模型
- Budget.ets - 预算模型
- Tag.ets - 标签模型
- BillTag.ets - 账单标签关联模型
- Statistics.ets - 统计模型
- Transaction.ets - 交易模型
- AggregationTypes.ets - 聚合类型定义
- DataModels.ets - 数据模型定义
- index.ets - 统一导出

## 核心模型

### User - 用户
- userId - 用户 ID
- username - 用户名
- email - 邮箱
- passwordHash - 密码哈希
- createdAt - 创建时间
- updatedAt - 更新时间
- is_deleted - 删除标记

### Account - 账户
- accountId - 账户 ID
- userId - 所属用户
- name - 账户名称
- type - 账户类型（cash/bank/credit_card/other）
- balance - 余额
- color - 颜色标识
- createdAt - 创建时间
- updatedAt - 更新时间
- is_deleted - 删除标记

### Category - 分类
- categoryId - 分类 ID
- userId - 所属用户
- name - 分类名称
- type - 类型（expense/income）
- icon - 图标
- color - 颜色
- parentCategoryId - 父分类 ID
- sortOrder - 排序
- createdAt - 创建时间
- updatedAt - 更新时间
- is_deleted - 删除标记

### Bill - 账单
- billId - 账单 ID
- userId - 所属用户
- accountId - 关联账户
- categoryId - 关联分类
- amount - 金额
- type - 类型（expense/income）
- note - 备注
- transactionDate - 交易日期
- createdAt - 创建时间
- updatedAt - 更新时间
- is_deleted - 删除标记

### Budget - 预算
- budgetId - 预算 ID
- userId - 所属用户
- categoryId - 关联分类
- amount - 预算金额
- period - 周期（monthly/yearly）
- startDate - 开始日期
- endDate - 结束日期
- isActive - 是否激活
- createdAt - 创建时间
- isDeleted - 删除标记

### Tag - 标签
- tagId - 标签 ID
- userId - 所属用户
- name - 标签名称
- color - 颜色
- usageCount - 使用次数
- createdAt - 创建时间
- updatedAt - 更新时间
- is_deleted - 删除标记

### BillTag - 账单标签关联
- billId - 账单 ID
- tagId - 标签 ID
- createdAt - 创建时间

## 统计模型

### MonthlyStatistics - 月度统计
- userId - 用户 ID
- categoryId - 分类 ID
- month - 月份
- totalExpense - 总支出
- totalIncome - 总收入
- transactionCount - 交易数量
- createdAt - 创建时间
- updatedAt - 更新时间
- is_deleted - 删除标记

### CategoryStatistics - 分类统计
- categoryId - 分类 ID
- categoryName - 分类名称
- type - 类型
- totalAmount - 总金额
- transactionCount - 交易数量
- percentage - 占比
- icon - 图标
- color - 颜色
- createdAt - 创建时间
- updatedAt - 更新时间
- is_deleted - 删除标记

## 聚合类型

### CategoryAggregation - 分类聚合
- categoryId - 分类 ID
- categoryName - 分类名称
- type - 类型
- icon - 图标
- color - 颜色
- parentCategoryId - 父分类 ID
- transactionCount - 交易数量
- totalAmount - 总金额
- avgAmount - 平均金额
- minAmount - 最小金额
- maxAmount - 最大金额

### TagAggregation - 标签聚合
- tagId - 标签 ID
- tagName - 标签名称
- color - 颜色
- billCount - 账单数量
- totalAmount - 总金额

### CategoryTreeNode - 分类树节点
- category - 分类对象
- children - 子分类列表

## 数据验证

所有模型都提供 validate 方法：
- 检查必填字段
- 验证数据格式
- 返回布尔值

## 数据转换

部分模型提供转换方法：
- fromJSON - 从 JSON 创建对象
- toJSON - 转换为 JSON
- clone - 克隆对象

## 字段命名规则

- 模型字段使用驼峰命名
- 数据库字段使用下划线命名
- DAO 层负责字段映射

## 类型约束

- 日期使用字符串格式
- 布尔值使用数字（0/1）
- 枚举使用字符串字面量类型
- 金额使用 number 类型

## 注意事项

1. 所有模型都有默认值
2. is_deleted 字段用于软删除
3. 时间字段使用 ISO 格式字符串
4. 外键字段需要在 DAO 层验证
5. 不要直接修改 ID 字段
