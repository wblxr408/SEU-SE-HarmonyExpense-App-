/**
 * 数据库管理器 - 统一管理数据库初始化和连接
 * 解决多个 DAO 重复初始化数据库的问题
 */
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

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
      
      // 按顺序创建所有表
      await DatabaseManager.createAllTables();
      
      DatabaseManager.isInitialized = true;
      console.log('[DatabaseManager] 数据库初始化完成');
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
          account_id INTEGER NOT NULL,
          category_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          note TEXT,
          transaction_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0,
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

      console.log('[DatabaseManager] 所有数据表创建完成');
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
