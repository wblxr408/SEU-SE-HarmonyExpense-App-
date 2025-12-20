/**
 * Model层统一导出 - 2.0.0版本
 */

// ==================== 核心模型 ====================
export { User, UserJSON } from './User';
export { Account } from './Account';
export { Category, CategoryJSON } from './Category';
export { Bill, BillJSON } from './Bill';
export { Budget, BudgetInit } from './Budget';
export { MonthlyStatistics, CategoryStatistics } from './Statistics';
export { Tag } from './Tag';
export { BillTag } from './BillTag';
export { CategoryTreeNode, CategoryAggregation, TagAggregation } from './AggregationTypes';

// 高级功能模型 (v1.2.0新增)
export { Reminder } from './Reminder';
export { CloudSyncRecord } from './CloudSyncRecord';

// ==================== 智能功能模型 (v2.0.0新增) ====================

// 智能分类引擎
export {
  CategoryKeyword,
  CategoryKeywordJSON,
  UserCategoryHabit,
  UserCategoryHabitJSON,
  SmartCategoryResult,
  SmartCategoryUtils,
  CategoryRecommendation,
  AmountRange
} from './SmartCategory';

// 异常消费检测
export {
  AnomalyRecord,
  AnomalyRecordJSON,
  UserSpendingBaseline,
  UserSpendingBaselineJSON,
  AnomalyDetectionUtils,
  AnomalyDetectionResult,
  AnomalyDetectionConfig,
  StatisticalSummary,
  DetectionDetails,
  ExpectedRange,
  ANOMALY_TYPE_HIGH_AMOUNT,
  ANOMALY_TYPE_LOW_AMOUNT,
  ANOMALY_TYPE_FREQUENCY_SPIKE,
  ANOMALY_TYPE_UNUSUAL_TIME,
  ANOMALY_TYPE_UNUSUAL_CATEGORY,
  ANOMALY_TYPE_PATTERN_BREAK,
  SEVERITY_LOW,
  SEVERITY_MEDIUM,
  SEVERITY_HIGH,
  SEVERITY_CRITICAL,
  ALGORITHM_SIGMA_3,
  ALGORITHM_Z_SCORE,
  ALGORITHM_IQR,
  ALGORITHM_MOVING_AVG,
  ALGORITHM_ENSEMBLE
} from './AnomalyDetection';

// 智能预算规划
export {
  BudgetForecastUtils,
  FORECAST_SIMPLE_MOVING_AVG,
  FORECAST_WEIGHTED_MOVING_AVG,
  FORECAST_EXPONENTIAL_SMOOTH,
  FORECAST_HOLT_WINTERS,
  FORECAST_LINEAR_REGRESSION,
  FORECAST_ENSEMBLE
} from './SmartBudgetPlan';

// 财务健康评分
export {
  FinancialHealthScore,
  FinancialHealthScoreJSON,
  FinancialGoal,
  FinancialGoalJSON,
  HealthScoreUtils,
  HealthDimensions,
  DimensionScore,
  ScoreTrend,
  FinancialAdvice,
  Benchmarks,
  BudgetUsageResult,
  MonthlyIncomeExpense,
  GRADE_EXCELLENT,
  GRADE_GOOD,
  GRADE_FAIR,
  GRADE_POOR,
  GRADE_CRITICAL,
  TREND_IMPROVING,
  TREND_STABLE as HEALTH_TREND_STABLE,
  TREND_DECLINING,
  TREND_VOLATILE,
  PRIORITY_URGENT,
  PRIORITY_HIGH,
  PRIORITY_MEDIUM,
  PRIORITY_LOW
} from './FinancialHealth';

// 协作记账系统
export {
  SharedLedger,
  SharedLedgerJSON,
  LedgerMember,
  LedgerMemberJSON,
  LedgerInvitation,
  LedgerInvitationJSON,
  SharedBill,
  SharedBillJSON,
  ApprovalRecord,
  ApprovalRecordJSON,
  MemberActivity,
  MemberActivityJSON,
  SharedLedgerUtils,
  LedgerSettings,
  BillSplitDetail,
  RolePermissionConfig,
  LEDGER_TYPE_PERSONAL,
  LEDGER_TYPE_FAMILY,
  LEDGER_TYPE_COUPLE,
  LEDGER_TYPE_ROOMMATE,
  LEDGER_TYPE_TEAM,
  LEDGER_TYPE_PROJECT,
  MEMBER_ROLE_OWNER,
  MEMBER_ROLE_ADMIN,
  MEMBER_ROLE_MEMBER,
  MEMBER_ROLE_VIEWER,
  APPROVAL_STATUS_PENDING,
  APPROVAL_STATUS_APPROVED,
  APPROVAL_STATUS_REJECTED,
  APPROVAL_STATUS_AUTO_APPROVED,
  ALL_PERMISSIONS,
  ALL_LEDGER_TYPES,
  ALL_MEMBER_ROLES
} from './SharedLedger';

// OCR票据识别
export {
  OCRTask,
  OCRTaskJSON,
  OCRUtils,
  OCRConfigUtils,
  OCRResult,
  OCRConfig,
  StructuredReceiptData,
  SuggestedBillData,
  NumberField,
  StringField,
  DateField,
  LineItem,
  ExtractedEntity,
  PreprocessingOptions,
  RECEIPT_TYPE_GENERAL,
  RECEIPT_TYPE_SUPERMARKET,
  RECEIPT_TYPE_RESTAURANT,
  RECEIPT_TYPE_TRANSPORT,
  RECEIPT_TYPE_FUEL,
  RECEIPT_TYPE_MEDICAL,
  RECEIPT_TYPE_HOTEL,
  RECEIPT_TYPE_ONLINE,
  RECEIPT_TYPE_BANK,
  RECEIPT_TYPE_INVOICE,
  OCR_PROVIDER_HUAWEI_ML_KIT,
  OCR_PROVIDER_BAIDU,
  OCR_PROVIDER_TENCENT,
  RECOGNITION_STATUS_PENDING,
  RECOGNITION_STATUS_PROCESSING,
  RECOGNITION_STATUS_SUCCESS,
  RECOGNITION_STATUS_FAILED,
  CONFIDENCE_LEVEL_HIGH,
  CONFIDENCE_LEVEL_MEDIUM,
  CONFIDENCE_LEVEL_LOW
} from './OCRRecognition';

// 事件溯源架构(CQRS)
export {
  DomainEvent,
  DomainEventJSON,
  Command,
  CommandJSON,
  AggregateSnapshot,
  AggregateSnapshotJSON,
  ReadModel,
  ReadModelJSON,
  EventSourcingUtils,
  EventMetadata,
  EventStoreStats,
  EventTypeStats,
  AggregateTypeStats,
  EventChange,
  BudgetExceededPayload,
  AccountBalanceChangedPayload,
  DeleteBillPayload,
  EVENT_TYPE_BILL_CREATED,
  EVENT_TYPE_BILL_UPDATED,
  EVENT_TYPE_BILL_DELETED,
  EVENT_TYPE_BILL_RESTORED,
  EVENT_TYPE_CATEGORY_CREATED,
  EVENT_TYPE_CATEGORY_UPDATED,
  EVENT_TYPE_CATEGORY_DELETED,
  EVENT_TYPE_ACCOUNT_CREATED,
  EVENT_TYPE_ACCOUNT_UPDATED,
  EVENT_TYPE_ACCOUNT_DELETED,
  EVENT_TYPE_ACCOUNT_BALANCE_CHANGED,
  EVENT_TYPE_BUDGET_CREATED,
  EVENT_TYPE_BUDGET_UPDATED,
  EVENT_TYPE_BUDGET_DELETED,
  EVENT_TYPE_BUDGET_EXCEEDED,
  EVENT_TYPE_USER_REGISTERED,
  EVENT_TYPE_USER_LOGGED_IN,
  EVENT_TYPE_USER_LOGGED_OUT,
  EVENT_TYPE_USER_UPDATED,
  EVENT_TYPE_SYNC_STARTED,
  EVENT_TYPE_SYNC_COMPLETED,
  EVENT_TYPE_SYNC_FAILED,
  EVENT_TYPE_DATA_EXPORTED,
  EVENT_TYPE_DATA_IMPORTED,
  AGGREGATE_TYPE_BILL,
  AGGREGATE_TYPE_CATEGORY,
  AGGREGATE_TYPE_ACCOUNT,
  AGGREGATE_TYPE_BUDGET,
  AGGREGATE_TYPE_USER,
  AGGREGATE_TYPE_TAG,
  AGGREGATE_TYPE_LEDGER,
  COMMAND_STATUS_PENDING,
  COMMAND_STATUS_PROCESSING,
  COMMAND_STATUS_SUCCEEDED,
  COMMAND_STATUS_FAILED,
  COMMAND_STATUS_CANCELLED,
  SNAPSHOT_FREQUENCY_NEVER,
  SNAPSHOT_FREQUENCY_EVERY_10,
  SNAPSHOT_FREQUENCY_EVERY_50,
  SNAPSHOT_FREQUENCY_EVERY_100,
  EVENT_SOURCE_APP,
  EVENT_SOURCE_API,
  EVENT_SOURCE_SYNC,
  EVENT_SOURCE_IMPORT,
  EVENT_SOURCE_SYSTEM,
  READ_MODEL_TYPE_BILL_SUMMARY,
  READ_MODEL_TYPE_CATEGORY_STATS,
  READ_MODEL_TYPE_MONTHLY_REPORT,
  READ_MODEL_TYPE_BUDGET_STATUS,
  READ_MODEL_TYPE_ACCOUNT_BALANCE,
  READ_MODEL_TYPE_USER_ACTIVITY,
  ALL_EVENT_TYPES,
  ALL_AGGREGATE_TYPES,
  ALL_COMMAND_STATUSES
} from './EventSourcing';