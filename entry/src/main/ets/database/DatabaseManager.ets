/**
 * 数据库管理器 - 统一管理数据库初始化和连接
 * 解决多个 DAO 重复初始化数据库的问题
 */
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { IndexManager } from './IndexManager';
import { DatabaseConfigOptimizer } from './DatabaseConfigOptimizer';

export class DatabaseManager {
  private static db: relationalStore.RdbStore | null = null;
  private static isInitialized: boolean = false;
  
  // 数据库配置常量
  static readonly DB_NAME: string = 'harmony_expense.db';
  static readonly DB_VERSION: number = 1;
  static readonly SECURITY_LEVEL = relationalStore.SecurityLevel.S1;

  /**
   * 初始化数据库（单例模式）
   * @param context 应用上下文
   */
  static async initDatabase(context: common.Context): Promise<void> {
    if (DatabaseManager.isInitialized && DatabaseManager.db) {
      console.log('[DatabaseManager] 数据库已初始化，跳过重复初始化');
      return;
    }

    try {
      const storeConfig: relationalStore.StoreConfig = {
        name: DatabaseManager.DB_NAME,
        securityLevel: DatabaseManager.SECURITY_LEVEL
      };
      
      DatabaseManager.db = await relationalStore.getRdbStore(context, storeConfig);
      console.log('[DatabaseManager] 数据库连接成功');
      
      // 应用数据库配置优化
      await DatabaseConfigOptimizer.applyOptimizations();
      
      // 按顺序创建所有表
      await DatabaseManager.createAllTables();
      
      // 创建优化索引
      await IndexManager.createAllIndexes();
      
      DatabaseManager.isInitialized = true;
      console.log('[DatabaseManager] 数据库初始化完成');
      
      // 打印数据库配置信息
      await DatabaseConfigOptimizer.printConfig();
    } catch (error) {
      DatabaseManager.isInitialized = false;
      throw DatabaseManager.toError('[DatabaseManager] 数据库初始化失败', error);
    }
  }

  /**
   * 获取数据库实例
   */
  static getDatabase(): relationalStore.RdbStore {
    if (!DatabaseManager.db) {
      throw new Error('[DatabaseManager] 数据库未初始化，请先调用 initDatabase()');
    }
    return DatabaseManager.db;
  }

  /**
   * 检查数据库是否已初始化
   */
  static isDbInitialized(): boolean {
    return DatabaseManager.isInitialized && DatabaseManager.db !== null;
  }

  /**
   * 创建所有数据表（按依赖顺序）
   */
  private static async createAllTables(): Promise<void> {
    const store = DatabaseManager.getDatabase();
    
    try {
      // 1. 创建用户表（独立表，无外键依赖）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS users (
          user_id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0
        );
      `);
      console.log('[DatabaseManager] 表 users 创建成功');

      // 2. 创建账户表（依赖 users）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS accounts (
          account_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          balance REAL NOT NULL DEFAULT 0,
          color TEXT NOT NULL DEFAULT '#1890FF',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users(user_id)
        );
      `);
      console.log('[DatabaseManager] 表 accounts 创建成功');

      // 3. 创建分类表（依赖 users）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS categories (
          category_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL CHECK (type IN ('expense', 'income')),
          icon TEXT NOT NULL DEFAULT '📦',
          color TEXT NOT NULL DEFAULT '#1890FF',
          parent_category_id INTEGER DEFAULT 0,
          sort_order INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          UNIQUE(user_id, name, type)
        );
      `);
      
      // 创建分类表索引
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_category_user_type 
        ON categories(user_id, type) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_category_user_parent 
        ON categories(user_id, parent_category_id) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_category_sort 
        ON categories(user_id, sort_order, category_id);
      `);
      console.log('[DatabaseManager] 表 categories 及索引创建成功');

      // 4. 创建账单表（依赖 accounts 和 categories）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS bills (
          bill_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          account_id INTEGER NOT NULL,
          category_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          note TEXT,
          transaction_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (account_id) REFERENCES accounts(account_id),
          FOREIGN KEY (category_id) REFERENCES categories(category_id)
        );
      `);
      console.log('[DatabaseManager] 表 bills 创建成功');

      // 5. 创建预算表（依赖 users 和 categories）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS budgets (
          budget_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          category_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          period TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT,
          is_active INTEGER DEFAULT 1,
          is_deleted INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (category_id) REFERENCES categories(category_id)
        );
      `);
      console.log('[DatabaseManager] 表 budgets 创建成功');

      // 6. 创建月度统计表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS monthly_statistics (
          user_id INTEGER NOT NULL,
          category_id INTEGER NOT NULL,
          month TEXT NOT NULL,
          total_expense REAL DEFAULT 0,
          total_income REAL DEFAULT 0,
          transaction_count INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0,
          PRIMARY KEY (user_id, category_id, month)
        );
      `);
      console.log('[DatabaseManager] 表 monthly_statistics 创建成功');

      // 7. 创建分类统计表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS category_statistics (
          category_id INTEGER NOT NULL,
          category_name TEXT NOT NULL,
          type TEXT NOT NULL,
          total_amount REAL DEFAULT 0,
          transaction_count INTEGER DEFAULT 0,
          percentage REAL DEFAULT 0,
          icon TEXT NOT NULL DEFAULT '📦',
          color TEXT NOT NULL DEFAULT '#1890FF',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0,
          PRIMARY KEY (category_id)
        );
      `);
      console.log('[DatabaseManager] 表 category_statistics 创建成功');

      // 8. 创建标签表（依赖 users）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS tags (
          tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          color TEXT DEFAULT '#52C41A',
          usage_count INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          UNIQUE (user_id, name)
        );
      `);
      
      // 创建标签表索引
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_tags_user 
        ON tags (user_id) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_tags_usage 
        ON tags (user_id, usage_count DESC) WHERE is_deleted = 0;
      `);
      console.log('[DatabaseManager] 表 tags 及索引创建成功');

      // 9. 创建账单标签关联表（多对多关系）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS bill_tags (
          bill_id INTEGER NOT NULL,
          tag_id INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          PRIMARY KEY (bill_id, tag_id),
          FOREIGN KEY (bill_id) REFERENCES bills(bill_id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
        );
      `);
      
      // 创建关联表索引
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_bill_tags_bill 
        ON bill_tags (bill_id);
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_bill_tags_tag 
        ON bill_tags (tag_id);
      `);
      console.log('[DatabaseManager] 表 bill_tags 及索引创建成功');

      // 10. 创建提醒表（依赖 users, categories, accounts, budgets）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS reminders (
          reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          type TEXT NOT NULL CHECK (type IN ('bill', 'budget')),
          title TEXT NOT NULL,
          description TEXT,
          amount REAL,
          category_id INTEGER,
          account_id INTEGER,
          budget_id INTEGER,
          frequency TEXT NOT NULL CHECK (frequency IN ('once', 'daily', 'weekly', 'monthly', 'yearly')),
          reminder_date TEXT NOT NULL,
          next_reminder_date TEXT NOT NULL,
          is_active INTEGER DEFAULT 1 CHECK (is_active IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (category_id) REFERENCES categories(category_id),
          FOREIGN KEY (account_id) REFERENCES accounts(account_id),
          FOREIGN KEY (budget_id) REFERENCES budgets(budget_id)
        );
      `);
      
      // 创建提醒表索引
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_reminders_user 
        ON reminders (user_id) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_reminders_next_date 
        ON reminders (user_id, next_reminder_date) WHERE is_active = 1 AND is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_reminders_type 
        ON reminders (user_id, type) WHERE is_deleted = 0;
      `);
      console.log('[DatabaseManager] 表 reminders 及索引创建成功');

      // 11. 创建云端同步记录表（依赖 users）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS cloud_sync_records (
          sync_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          sync_type TEXT NOT NULL CHECK (sync_type IN ('full', 'incremental')),
          sync_direction TEXT NOT NULL CHECK (sync_direction IN ('upload', 'download', 'bidirectional')),
          status TEXT NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
          data_types TEXT NOT NULL,
          record_count INTEGER DEFAULT 0,
          start_time TEXT NOT NULL,
          end_time TEXT,
          error_message TEXT,
          cloud_provider TEXT NOT NULL CHECK (cloud_provider IN ('huawei', 'custom')),
          last_sync_hash TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(user_id)
        );
      `);
      
      // 创建云端同步记录表索引
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_cloud_sync_user 
        ON cloud_sync_records (user_id);
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_cloud_sync_status 
        ON cloud_sync_records (user_id, status);
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_cloud_sync_time 
        ON cloud_sync_records (user_id, created_at DESC);
      `);
      console.log('[DatabaseManager] 表 cloud_sync_records 及索引创建成功');

      // ==================== 高级功能模块表创建 ====================

      // 12. 创建异常记录表（异常检测功能）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS anomaly_records (
          anomaly_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          bill_id INTEGER NOT NULL,
          anomaly_type TEXT NOT NULL CHECK (anomaly_type IN ('high_amount', 'low_amount', 'frequency_spike', 'unusual_time', 'unusual_category', 'pattern_break')),
          severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
          algorithm TEXT NOT NULL CHECK (algorithm IN ('sigma_3', 'z_score', 'iqr', 'moving_avg', 'ensemble')),
          score REAL NOT NULL DEFAULT 0,
          threshold REAL NOT NULL DEFAULT 0,
          expected_value REAL NOT NULL DEFAULT 0,
          actual_value REAL NOT NULL DEFAULT 0,
          deviation REAL NOT NULL DEFAULT 0,
          description TEXT,
          is_acknowledged INTEGER DEFAULT 0 CHECK (is_acknowledged IN (0, 1)),
          acknowledged_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (bill_id) REFERENCES bills(bill_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_anomaly_user
        ON anomaly_records (user_id) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_anomaly_bill
        ON anomaly_records (bill_id) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_anomaly_severity
        ON anomaly_records (user_id, severity) WHERE is_deleted = 0 AND is_acknowledged = 0;
      `);
      console.log('[DatabaseManager] 表 anomaly_records 及索引创建成功');

      // 13. 创建用户消费基线表（异常检测基础数据）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS user_spending_baselines (
          baseline_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          category_id INTEGER DEFAULT 0,
          period TEXT NOT NULL DEFAULT 'monthly',
          mean REAL NOT NULL DEFAULT 0,
          median REAL NOT NULL DEFAULT 0,
          std_dev REAL NOT NULL DEFAULT 0,
          variance REAL NOT NULL DEFAULT 0,
          min REAL NOT NULL DEFAULT 0,
          max REAL NOT NULL DEFAULT 0,
          q1 REAL NOT NULL DEFAULT 0,
          q3 REAL NOT NULL DEFAULT 0,
          iqr REAL NOT NULL DEFAULT 0,
          sample_size INTEGER NOT NULL DEFAULT 0,
          last_calculated_at TEXT NOT NULL,
          sample_start_date TEXT NOT NULL,
          sample_end_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          UNIQUE (user_id, category_id, period)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_baseline_user_category
        ON user_spending_baselines (user_id, category_id) WHERE is_deleted = 0;
      `);
      console.log('[DatabaseManager] 表 user_spending_baselines 及索引创建成功');

      // 14. 创建领域事件表（事件溯源功能）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS domain_events (
          event_id TEXT PRIMARY KEY,
          event_type TEXT NOT NULL,
          aggregate_type TEXT NOT NULL CHECK (aggregate_type IN ('bill', 'category', 'account', 'budget', 'user', 'tag', 'ledger')),
          aggregate_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          version INTEGER NOT NULL DEFAULT 1,
          payload_json TEXT NOT NULL DEFAULT '{}',
          metadata_json TEXT NOT NULL DEFAULT '{}',
          occurred_at TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(user_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_events_aggregate
        ON domain_events (aggregate_type, aggregate_id, version);
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_events_user
        ON domain_events (user_id, occurred_at DESC);
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_events_type
        ON domain_events (event_type, occurred_at DESC);
      `);
      console.log('[DatabaseManager] 表 domain_events 及索引创建成功');

      // 15. 创建命令表（CQRS命令侧）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS commands (
          command_id TEXT PRIMARY KEY,
          command_type TEXT NOT NULL,
          aggregate_type TEXT NOT NULL CHECK (aggregate_type IN ('bill', 'category', 'account', 'budget', 'user', 'tag', 'ledger')),
          aggregate_id INTEGER NOT NULL DEFAULT 0,
          user_id INTEGER NOT NULL,
          payload_json TEXT NOT NULL DEFAULT '{}',
          status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'succeeded', 'failed', 'cancelled')),
          metadata_json TEXT NOT NULL DEFAULT '{}',
          expected_version INTEGER NOT NULL DEFAULT 0,
          issued_at TEXT NOT NULL,
          processed_at TEXT,
          error_message TEXT,
          FOREIGN KEY (user_id) REFERENCES users(user_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_commands_status
        ON commands (status, issued_at);
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_commands_user
        ON commands (user_id, issued_at DESC);
      `);
      console.log('[DatabaseManager] 表 commands 及索引创建成功');

      // 16. 创建聚合快照表（事件溯源性能优化）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS aggregate_snapshots (
          snapshot_id INTEGER PRIMARY KEY AUTOINCREMENT,
          aggregate_type TEXT NOT NULL CHECK (aggregate_type IN ('bill', 'category', 'account', 'budget', 'user', 'tag', 'ledger')),
          aggregate_id INTEGER NOT NULL,
          version INTEGER NOT NULL,
          state_json TEXT NOT NULL DEFAULT '{}',
          created_at TEXT NOT NULL,
          UNIQUE (aggregate_type, aggregate_id, version)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_snapshots_aggregate
        ON aggregate_snapshots (aggregate_type, aggregate_id, version DESC);
      `);
      console.log('[DatabaseManager] 表 aggregate_snapshots 及索引创建成功');

      // 17. 创建读模型表（CQRS查询侧）
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS read_models (
          model_id INTEGER PRIMARY KEY AUTOINCREMENT,
          model_type TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          data_json TEXT NOT NULL DEFAULT '{}',
          last_event_version INTEGER NOT NULL DEFAULT 0,
          last_updated_at TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          UNIQUE (model_type, user_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_read_models_user_type
        ON read_models (user_id, model_type);
      `);
      console.log('[DatabaseManager] 表 read_models 及索引创建成功');

      // 18. 创建共享账本表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS shared_ledgers (
          ledger_id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          type TEXT NOT NULL CHECK (type IN ('personal', 'family', 'couple', 'roommate', 'team', 'project')),
          owner_id INTEGER NOT NULL,
          owner_name TEXT NOT NULL,
          currency TEXT NOT NULL DEFAULT 'CNY',
          icon TEXT,
          color TEXT NOT NULL DEFAULT '#2196F3',
          member_count INTEGER NOT NULL DEFAULT 1,
          settings_json TEXT NOT NULL DEFAULT '{}',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (owner_id) REFERENCES users(user_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_ledgers_owner
        ON shared_ledgers (owner_id) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_ledgers_type
        ON shared_ledgers (type) WHERE is_deleted = 0;
      `);
      console.log('[DatabaseManager] 表 shared_ledgers 及索引创建成功');

      // 19. 创建账本成员表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS ledger_members (
          member_id INTEGER PRIMARY KEY AUTOINCREMENT,
          ledger_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          username TEXT NOT NULL,
          email TEXT NOT NULL,
          avatar TEXT,
          role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
          permissions_json TEXT NOT NULL DEFAULT '[]',
          nickname TEXT,
          contribution_amount REAL NOT NULL DEFAULT 0,
          bill_count INTEGER NOT NULL DEFAULT 0,
          joined_at TEXT NOT NULL,
          last_active_at TEXT NOT NULL,
          is_active INTEGER DEFAULT 1 CHECK (is_active IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (ledger_id) REFERENCES shared_ledgers(ledger_id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          UNIQUE (ledger_id, user_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_ledger_members_ledger
        ON ledger_members (ledger_id) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_ledger_members_user
        ON ledger_members (user_id) WHERE is_deleted = 0;
      `);
      console.log('[DatabaseManager] 表 ledger_members 及索引创建成功');

      // 20. 创建账本邀请表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS ledger_invitations (
          invitation_id INTEGER PRIMARY KEY AUTOINCREMENT,
          ledger_id INTEGER NOT NULL,
          ledger_name TEXT NOT NULL,
          inviter_id INTEGER NOT NULL,
          inviter_name TEXT NOT NULL,
          invitee_email TEXT NOT NULL,
          invitee_user_id INTEGER DEFAULT 0,
          role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
          message TEXT,
          status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'declined', 'expired', 'cancelled')),
          invitation_code TEXT NOT NULL,
          expires_at TEXT NOT NULL,
          responded_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (ledger_id) REFERENCES shared_ledgers(ledger_id) ON DELETE CASCADE,
          FOREIGN KEY (inviter_id) REFERENCES users(user_id),
          UNIQUE (invitation_code)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_invitations_ledger
        ON ledger_invitations (ledger_id) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_invitations_email
        ON ledger_invitations (invitee_email, status) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_invitations_code
        ON ledger_invitations (invitation_code) WHERE is_deleted = 0;
      `);
      console.log('[DatabaseManager] 表 ledger_invitations 及索引创建成功');

      // 21. 创建共享账单表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS shared_bills (
          bill_id INTEGER PRIMARY KEY AUTOINCREMENT,
          ledger_id INTEGER NOT NULL,
          creator_id INTEGER NOT NULL,
          creator_name TEXT NOT NULL,
          account_id INTEGER NOT NULL,
          category_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          note TEXT,
          transaction_date TEXT NOT NULL,
          type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
          approval_status TEXT NOT NULL CHECK (approval_status IN ('pending', 'approved', 'rejected', 'auto_approved')),
          approved_by INTEGER DEFAULT 0,
          approved_at TEXT,
          sync_status TEXT NOT NULL CHECK (sync_status IN ('synced', 'pending', 'conflict', 'failed')),
          last_synced_at TEXT,
          version INTEGER NOT NULL DEFAULT 1,
          split_type TEXT NOT NULL CHECK (split_type IN ('equal', 'custom', 'percentage', 'none')),
          split_details_json TEXT NOT NULL DEFAULT '[]',
          attachments_json TEXT NOT NULL DEFAULT '[]',
          tags_json TEXT NOT NULL DEFAULT '[]',
          location TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (ledger_id) REFERENCES shared_ledgers(ledger_id) ON DELETE CASCADE,
          FOREIGN KEY (creator_id) REFERENCES users(user_id),
          FOREIGN KEY (account_id) REFERENCES accounts(account_id),
          FOREIGN KEY (category_id) REFERENCES categories(category_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_shared_bills_ledger
        ON shared_bills (ledger_id, transaction_date DESC) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_shared_bills_creator
        ON shared_bills (creator_id) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_shared_bills_approval
        ON shared_bills (ledger_id, approval_status) WHERE is_deleted = 0;
      `);
      console.log('[DatabaseManager] 表 shared_bills 及索引创建成功');

      // 22. 创建审批记录表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS approval_records (
          approval_id INTEGER PRIMARY KEY AUTOINCREMENT,
          ledger_id INTEGER NOT NULL,
          bill_id INTEGER NOT NULL,
          requester_id INTEGER NOT NULL,
          requester_name TEXT NOT NULL,
          approver_id INTEGER DEFAULT 0,
          approver_name TEXT,
          status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'auto_approved')),
          amount REAL NOT NULL,
          reason TEXT,
          comment TEXT,
          requested_at TEXT NOT NULL,
          processed_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (ledger_id) REFERENCES shared_ledgers(ledger_id) ON DELETE CASCADE,
          FOREIGN KEY (bill_id) REFERENCES shared_bills(bill_id) ON DELETE CASCADE,
          FOREIGN KEY (requester_id) REFERENCES users(user_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_approvals_ledger
        ON approval_records (ledger_id, status) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_approvals_bill
        ON approval_records (bill_id) WHERE is_deleted = 0;
      `);
      console.log('[DatabaseManager] 表 approval_records 及索引创建成功');

      // 23. 创建成员活动记录表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS member_activities (
          activity_id INTEGER PRIMARY KEY AUTOINCREMENT,
          ledger_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          username TEXT NOT NULL,
          action_type TEXT NOT NULL CHECK (action_type IN ('create', 'update', 'delete', 'approve', 'reject', 'join', 'leave')),
          target_type TEXT NOT NULL CHECK (target_type IN ('bill', 'category', 'budget', 'member', 'settings')),
          target_id INTEGER NOT NULL,
          description TEXT,
          metadata_json TEXT NOT NULL DEFAULT '{}',
          created_at TEXT NOT NULL,
          FOREIGN KEY (ledger_id) REFERENCES shared_ledgers(ledger_id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users(user_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_activities_ledger
        ON member_activities (ledger_id, created_at DESC);
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_activities_user
        ON member_activities (user_id, created_at DESC);
      `);
      console.log('[DatabaseManager] 表 member_activities 及索引创建成功');

      // 24. 创建智能分类训练数据表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS smart_category_training (
          training_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          bill_id INTEGER NOT NULL,
          predicted_category_id INTEGER NOT NULL,
          actual_category_id INTEGER NOT NULL,
          confidence REAL NOT NULL DEFAULT 0,
          features_json TEXT NOT NULL DEFAULT '{}',
          is_correct INTEGER DEFAULT 0 CHECK (is_correct IN (0, 1)),
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (bill_id) REFERENCES bills(bill_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_training_user
        ON smart_category_training (user_id, created_at DESC);
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_training_accuracy
        ON smart_category_training (user_id, is_correct);
      `);
      console.log('[DatabaseManager] 表 smart_category_training 及索引创建成功');

      // 25. 创建智能分类规则表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS smart_category_rules (
          rule_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          category_id INTEGER NOT NULL,
          rule_type TEXT NOT NULL CHECK (rule_type IN ('keyword', 'amount_range', 'time_pattern', 'merchant', 'combined')),
          condition_json TEXT NOT NULL DEFAULT '{}',
          priority INTEGER NOT NULL DEFAULT 0,
          confidence REAL NOT NULL DEFAULT 1.0,
          usage_count INTEGER NOT NULL DEFAULT 0,
          success_count INTEGER NOT NULL DEFAULT 0,
          is_active INTEGER DEFAULT 1 CHECK (is_active IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (category_id) REFERENCES categories(category_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_rules_user
        ON smart_category_rules (user_id, priority DESC) WHERE is_active = 1 AND is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_rules_category
        ON smart_category_rules (category_id) WHERE is_active = 1 AND is_deleted = 0;
      `);
      console.log('[DatabaseManager] 表 smart_category_rules 及索引创建成功');

      // 26. 创建OCR识别记录表
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS ocr_recognition_records (
          recognition_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          bill_id INTEGER DEFAULT 0,
          image_path TEXT NOT NULL,
          recognition_status TEXT NOT NULL CHECK (recognition_status IN ('pending', 'processing', 'completed', 'failed')),
          confidence REAL NOT NULL DEFAULT 0,
          extracted_data_json TEXT NOT NULL DEFAULT '{}',
          merchant_name TEXT,
          amount REAL DEFAULT 0,
          transaction_date TEXT,
          category_suggestion TEXT,
          error_message TEXT,
          processing_time_ms INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (bill_id) REFERENCES bills(bill_id)
        );
      `);

      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_ocr_user
        ON ocr_recognition_records (user_id, created_at DESC) WHERE is_deleted = 0;
      `);
      await store.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_ocr_status
        ON ocr_recognition_records (recognition_status) WHERE is_deleted = 0;
      `);
      console.log('[DatabaseManager] 表 ocr_recognition_records 及索引创建成功');

      console.log('[DatabaseManager] 所有数据表创建完成（共26张表）');
    } catch (error) {
      throw DatabaseManager.toError('[DatabaseManager] 创建数据表失败', error);
    }
  }

  /**
   * 关闭数据库连接
   */
  static async closeDatabase(): Promise<void> {
    if (DatabaseManager.db) {
      // HarmonyOS 的 RdbStore 没有显式的 close 方法
      // 数据库会在应用退出时自动关闭
      DatabaseManager.db = null;
      DatabaseManager.isInitialized = false;
      console.log('[DatabaseManager] 数据库连接已清理');
    }
  }

  /**
   * 统一错误处理
   */
  private static toError(message: string, err: Error | string | object): Error {
    let details = '';
    try {
      details = typeof err === 'string' ? err : JSON.stringify(err);
    } catch (_) {
      details = String(err);
    }
    return new Error(`${message}${details ? ' -> ' + details : ''}`);
  }

  /**
   * 执行事务
   * @throws
   */
  static async transaction(fn: () => Promise<void>): Promise<void> {
    const store = DatabaseManager.getDatabase();
    await store.beginTransaction();
    try {
      await fn();
      await store.commit();
    } catch (error) {
      await store.rollBack();
      throw DatabaseManager.toError('[DatabaseManager] 事务执行失败', error);
    }
  }
}
