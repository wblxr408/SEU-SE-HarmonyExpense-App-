/**
 * DAO 层统一导出 - v1.2.0
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