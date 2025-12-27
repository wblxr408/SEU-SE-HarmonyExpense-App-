# Model 层说明文档

数据模型层，定义所有业务实体。

## 文件列表

### 核心模型
- **User.ets** - 用户模型
- **Account.ets** - 账户模型
- **Category.ets** - 分类模型（支持多级分类）
- **Bill.ets** - 账单模型
- **Budget.ets** - 预算模型
- **Tag.ets** - 标签模型
- **BillTag.ets** - 账单标签关联模型
- **Statistics.ets** - 统计模型（月度统计、分类统计）
- **Transaction.ets** - 交易模型
- **AggregationTypes.ets** - 聚合类型定义

### 高级功能模型
- **Reminder.ets** - 提醒模型
- **CloudSyncRecord.ets** - 云同步记录模型
- **Notification.ets** - 通知模型
- **ChartData.ets** - 图表数据模型

### 智能功能模型（v2.0.0新增）
- **SmartCategory.ets** - 智能分类引擎（关键词匹配、用户习惯学习）
- **AnomalyDetection.ets** - 异常消费检测（金额异常、频率异常、模式识别）
- **SmartBudgetPlan.ets** - 智能预算规划（6种预测算法）
- **FinancialHealth.ets** - 财务健康评分系统（8维度评分）
- **SharedLedger.ets** - 共享账本/协作记账系统
- **OCRRecognition.ets** - OCR票据识别模型
- **EventSourcing.ets** - 事件溯源架构（CQRS模式）

### 其他
- **DataModels.ets** - 通用数据模型定义
- **index.ets** - 统一导出

---

## 核心模型详情

### User - 用户
| 字段 | 类型 | 说明 |
|------|------|------|
| userId | number | 用户 ID |
| username | string | 用户名 |
| email | string | 邮箱 |
| passwordHash | string | 密码哈希（SHA-256） |
| createdAt | string | 创建时间 |
| updatedAt | string | 更新时间 |
| is_deleted | number | 删除标记 |

### Account - 账户
| 字段 | 类型 | 说明 |
|------|------|------|
| accountId | number | 账户 ID |
| userId | number | 所属用户 |
| name | string | 账户名称 |
| type | string | 账户类型（cash/bank/credit_card/other） |
| balance | number | 余额 |
| color | string | 颜色标识 |
| createdAt | string | 创建时间 |
| updatedAt | string | 更新时间 |
| is_deleted | number | 删除标记 |

### Category - 分类
| 字段 | 类型 | 说明 |
|------|------|------|
| categoryId | number | 分类 ID |
| userId | number | 所属用户 |
| name | string | 分类名称 |
| type | string | 类型（expense/income） |
| icon | string | 图标 |
| color | string | 颜色 |
| parentCategoryId | number | 父分类 ID（支持多级分类） |
| sortOrder | number | 排序 |
| createdAt | string | 创建时间 |
| updatedAt | string | 更新时间 |
| is_deleted | number | 删除标记 |

### Bill - 账单
| 字段 | 类型 | 说明 |
|------|------|------|
| billId | number | 账单 ID |
| userId | number | 所属用户 |
| accountId | number | 关联账户 |
| categoryId | number | 关联分类 |
| amount | number | 金额 |
| type | string | 类型（expense/income） |
| note | string | 备注 |
| transactionDate | string | 交易日期 |
| createdAt | string | 创建时间 |
| updatedAt | string | 更新时间 |
| is_deleted | number | 删除标记 |

### Budget - 预算
| 字段 | 类型 | 说明 |
|------|------|------|
| budgetId | number | 预算 ID |
| userId | number | 所属用户 |
| categoryId | number | 关联分类 |
| amount | number | 预算金额 |
| period | string | 周期（monthly/yearly） |
| startDate | string | 开始日期 |
| endDate | string | 结束日期 |
| isActive | number | 是否激活 |
| createdAt | string | 创建时间 |
| isDeleted | number | 删除标记 |

### Tag - 标签
| 字段 | 类型 | 说明 |
|------|------|------|
| tagId | number | 标签 ID |
| userId | number | 所属用户 |
| name | string | 标签名称 |
| color | string | 颜色 |
| usageCount | number | 使用次数 |
| createdAt | string | 创建时间 |
| updatedAt | string | 更新时间 |
| is_deleted | number | 删除标记 |

### BillTag - 账单标签关联
| 字段 | 类型 | 说明 |
|------|------|------|
| billId | number | 账单 ID |
| tagId | number | 标签 ID |
| createdAt | string | 创建时间 |

### Reminder - 提醒
| 字段 | 类型 | 说明 |
|------|------|------|
| reminderId | number | 提醒 ID |
| userId | number | 所属用户 |
| type | string | 提醒类型（budget/daily/custom） |
| title | string | 提醒标题 |
| budgetId | number | 关联预算 ID |
| frequency | string | 频率（once/daily/weekly/monthly/yearly） |
| reminderDate | string | 提醒日期 |
| nextReminderDate | string | 下次提醒日期 |
| isActive | number | 是否激活 |

---

## 智能功能模型

### SmartCategory - 智能分类
- **CategoryKeyword**：分类关键词映射
- **UserCategoryHabit**：用户分类习惯
- **SmartCategoryResult**：分类推荐结果
- **SmartCategoryUtils**：智能分类工具函数

### AnomalyDetection - 异常检测
- **AnomalyRecord**：异常记录
- **UserSpendingBaseline**：用户消费基准线
- **AnomalyDetectionUtils**：异常检测工具函数
- 支持6种异常类型：高额支出、低额异常、频率激增、异常时间、异常分类、模式突变
- 支持5种检测算法：3σ法则、Z-Score、IQR、移动平均、集成算法

### SmartBudgetPlan - 智能预算
- **BudgetForecastUtils**：预算预测工具
- 支持6种预测算法：
  - 简单移动平均（SMA）
  - 加权移动平均（WMA）
  - 指数平滑（ETS）
  - Holt-Winters双参数平滑
  - 线性回归
  - 集成预测（Ensemble）

### FinancialHealth - 财务健康
- **FinancialHealthScore**：健康评分模型
- **FinancialGoal**：财务目标
- **HealthScoreUtils**：评分计算工具
- 8维度评分：储蓄率、预算执行、支出稳定性、负债比率、应急资金、消费结构、收入增长、目标达成
- 5级评估：Excellent/Good/Fair/Poor/Critical

### SharedLedger - 共享账本
- **SharedLedger**：共享账本
- **LedgerMember**：账本成员
- **LedgerInvitation**：邀请记录
- **SharedBill**：共享账单
- **ApprovalRecord**：审批记录
- **MemberActivity**：成员活动日志
- 6种账本类型：个人/家庭/情侣/室友/团队/项目

### OCRRecognition - OCR识别
- **OCRTask**：OCR任务
- **OCRResult**：识别结果
- **StructuredReceiptData**：结构化票据数据
- **SuggestedBillData**：建议账单数据
- 支持10种票据类型

### EventSourcing - 事件溯源
- **DomainEvent**：领域事件
- **Command**：命令
- **AggregateSnapshot**：聚合快照
- **ReadModel**：读模型
- CQRS架构支持

---

## 统计模型

### MonthlyStatistics - 月度统计
| 字段 | 类型 | 说明 |
|------|------|------|
| userId | number | 用户 ID |
| categoryId | number | 分类 ID |
| month | string | 月份 |
| totalExpense | number | 总支出 |
| totalIncome | number | 总收入 |
| transactionCount | number | 交易数量 |

### CategoryStatistics - 分类统计
| 字段 | 类型 | 说明 |
|------|------|------|
| categoryId | number | 分类 ID |
| categoryName | string | 分类名称 |
| type | string | 类型 |
| totalAmount | number | 总金额 |
| transactionCount | number | 交易数量 |
| percentage | number | 占比 |

---

## 聚合类型

### CategoryAggregation - 分类聚合
用于统计分析，包含交易数量、总金额、平均/最小/最大金额等

### TagAggregation - 标签聚合
用于标签统计，包含账单数量、总金额等

### CategoryTreeNode - 分类树节点
用于多级分类的树形结构展示

---

## 注意事项

1. 所有模型都有默认值
2. `is_deleted` 字段用于软删除
3. 时间字段使用 ISO 格式字符串
4. 外键字段需要在 DAO 层验证
5. 金额使用 number 类型
6. 日期使用字符串格式
7. 布尔值使用数字（0/1）
8. 枚举使用字符串字面量类型

---

*文档最后更新：2025年12月27日*
