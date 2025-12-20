/**
 * 服务层统一导出 - v2.0.0
 */

// 用户会话服务
export { UserSessionService } from './UserSessionService';
export { SessionInfo } from './UserSessionService';
export { LoginResult } from './UserSessionService';

// 提醒服务
export { ReminderService } from './ReminderService';
export { ReminderCreateOptions } from './ReminderService';
export { ReminderNotificationResult } from './ReminderService';

// 云端同步服务
export { CloudSyncService } from './CloudSyncService';
export { SyncOptions } from './CloudSyncService';
export { SyncResult } from './CloudSyncService';
export { ConflictInfo } from './CloudSyncService';
export type { SyncStatistics } from './CloudSyncService';

// 导出备份服务
export { ExportService } from './export/ExportService';
export { ImportService } from './export/ImportService';
export { EncryptionModule } from './export/EncryptionModule';

// 异常检测服务 (v2.0.0新增)
export { AnomalyDetectionService } from './AnomalyDetectionService';
export type { AnomalyDetectionResult } from './AnomalyDetectionService';

// 事件溯源服务 (v2.0.0新增)
export { EventSourcingService } from './EventSourcingService';
export type {
  EventPublishResult,
  CommandExecutionResult,
  AggregateState
} from './EventSourcingService';

// 共享账本服务 (v2.0.0新增)
export { SharedLedgerService } from './SharedLedgerService';
export type {
  CreateLedgerParams,
  SplitResult,
  SettlementResult
} from './SharedLedgerService';

// 智能分类服务 (v2.0.0新增)
export { SmartCategoryService } from './SmartCategoryService';
export type {
  CategoryRecommendation,
  LearningResult
} from './SmartCategoryService';

// OCR识别服务 (v2.0.0新增)
export { OCRRecognitionService } from './OCRRecognitionService';
export type {
  OCRRecognitionParams,
  OCRRecognitionResult,
  SuggestedBillData
} from './OCRRecognitionService';
