/**
 * DAO 层统一导出 - v2.0.0
 * 提供数据访问层的所有类
 */

export { DatabaseManager } from '../database/DatabaseManager';
export { UserDAO } from './UserDAO';
export { AccountDAO } from './AccountDAO';
export { CategoryDAO } from './CategoryDAO';
export { BillDAO } from './BillDAO';
export { BudgetDAO } from './BudgetDAO';
export { StatisticsDAO } from './StatisticsDAO';
export { TagDAO } from './TagDAO';
export { QueryHelper } from '../database/QueryHelper';

// 高级功能DAO (v1.2.0新增)
export { ReminderDAO } from './ReminderDAO';
export { CloudSyncRecordDAO } from './CloudSyncRecordDAO';
export { SyncStatisticsResult } from './CloudSyncRecordDAO';

// 异常检测DAO (v2.0.0新增)
export { AnomalyRecordDAO, UserSpendingBaselineDAO } from './AnomalyDetectionDAO';
export type { AnomalyStatistics } from './AnomalyDetectionDAO';

// 事件溯源DAO (v2.0.0新增)
export { DomainEventDAO, CommandDAO, AggregateSnapshotDAO, ReadModelDAO } from './EventSourcingDAO';
export type { EventStoreStats, CommandStats } from './EventSourcingDAO';

// 共享账本DAO (v2.0.0新增)
export {
  SharedLedgerDAO,
  LedgerMemberDAO,
  LedgerInvitationDAO,
  SharedBillDAO,
  ApprovalRecordDAO,
  MemberActivityDAO
} from './SharedLedgerDAO';
export type { SharedBillStatistics } from './SharedLedgerDAO';

// 智能分类DAO (v2.0.0新增)
export { SmartCategoryTrainingDAO, SmartCategoryRuleDAO } from './SmartCategoryDAO';
export type { TrainingStatistics, RuleStatistics } from './SmartCategoryDAO';

// OCR识别DAO (v2.0.0新增)
export { OCRRecognitionRecordDAO } from './OCRRecognitionDAO';
export type { OCRStatistics, ReceiptTypeStatistics, ProviderStatistics } from './OCRRecognitionDAO';
