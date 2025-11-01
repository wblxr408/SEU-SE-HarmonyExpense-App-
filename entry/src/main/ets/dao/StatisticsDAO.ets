import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { MonthlyStatistics, CategoryStatistics } from '../model/Statistics';

let db: relationalStore.RdbStore | null = null;

export class StatisticsDAO {
  static async initDatabase(context: common.Context) {
    const storeConfig: relationalStore.StoreConfig = {
      name: 'harmony_expense.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    try {
      db = await relationalStore.getRdbStore(context, storeConfig);
      console.log('[StatisticsDAO] 数据库已初始化');
      await StatisticsDAO.createTables();
    } catch (error) {
      console.error('[StatisticsDAO] 初始化数据库失败: ' + JSON.stringify(error));
      throw new Error('[StatisticsDAO] 初始化数据库失败');
    }
  }

  static async createTables() {
    const store = StatisticsDAO.ensureDb();
    const monthlySQL = `
      CREATE TABLE IF NOT EXISTS monthly_statistics (
        user_id INTEGER,
        category_id INTEGER,
        month TEXT,
        total_expense REAL,
        total_income REAL,
        transaction_count INTEGER,
        created_at TEXT,
        updated_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        PRIMARY KEY(user_id, category_id, month)
      );
    `;
    const categorySQL = `
      CREATE TABLE IF NOT EXISTS category_statistics (
        category_id INTEGER PRIMARY KEY,
        category_name TEXT,
        type TEXT,
        total_amount REAL,
        transaction_count INTEGER,
        percentage REAL,
        icon TEXT,
        color TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_deleted INTEGER DEFAULT 0
      );
    `;
    await store.executeSql(monthlySQL);
    await store.executeSql(categorySQL);
    console.log('[StatisticsDAO] 表创建完成');
  }

  private static ensureDb(): relationalStore.RdbStore {
    if (!db) throw new Error('[StatisticsDAO] Database not initialized');
    return db;
  }

  /** ================== 月度统计 ================== */
  static async insertMonthly(stat: MonthlyStatistics) {
    if (!stat.validate()) throw new Error('[StatisticsDAO] 月度统计验证失败');

    const store = StatisticsDAO.ensureDb();
    const now = new Date().toISOString();
    stat.createdAt = now;
    stat.updatedAt = now;

    const sql = `
      INSERT INTO monthly_statistics 
      (user_id, category_id, month, total_expense, total_income, transaction_count, created_at, updated_at, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      stat.userId, stat.categoryId, stat.month,
      stat.totalExpense, stat.totalIncome, stat.transactionCount,
      stat.createdAt, stat.updatedAt, stat.is_deleted
    ];
    await store.executeSql(sql, params);
  }

  static async bulkInsertMonthly(stats: MonthlyStatistics[]) {
    const store = StatisticsDAO.ensureDb();
    await store.beginTransaction();
    try {
      for (const s of stats) await StatisticsDAO.insertMonthly(s);
      await store.commit();
    } catch (err) {
      await store.rollBack();
      throw new Error('[StatisticsDAO] 批量插入月度统计失败');
    }
  }

  static async getMonthly(userId: number, categoryId: number, month: string): Promise<MonthlyStatistics | null> {
    const store = StatisticsDAO.ensureDb();
    const sql = `
      SELECT * FROM monthly_statistics 
      WHERE user_id=? AND category_id=? AND month=? AND is_deleted=0
    `;
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.querySql(sql, [userId, categoryId, month]);
      if (!rs.goToNextRow()) return null;
      return StatisticsDAO.mapMonthlyRow(rs);
    } finally {
      rs?.close();
    }
  }

  static async getAllMonthly(): Promise<MonthlyStatistics[]> {
    const store = StatisticsDAO.ensureDb();
    const sql = `SELECT * FROM monthly_statistics WHERE is_deleted=0 ORDER BY month ASC`;
    let rs: relationalStore.ResultSet | null = null;
    const list: MonthlyStatistics[] = [];
    try {
      rs = await store.querySql(sql);
      while (rs.goToNextRow()) list.push(StatisticsDAO.mapMonthlyRow(rs));
      return list;
    } finally {
      rs?.close();
    }
  }

  static async updateMonthly(stat: MonthlyStatistics) {
    if (!stat.validate()) throw new Error('[StatisticsDAO] 月度统计验证失败');

    const store = StatisticsDAO.ensureDb();
    stat.updatedAt = new Date().toISOString();

    const sql = `
      UPDATE monthly_statistics
      SET total_expense=?, total_income=?, transaction_count=?, updated_at=?
      WHERE user_id=? AND category_id=? AND month=? AND is_deleted=0
    `;
    const params = [
      stat.totalExpense, stat.totalIncome, stat.transactionCount, stat.updatedAt,
      stat.userId, stat.categoryId, stat.month
    ];
    await store.executeSql(sql, params);
  }

  static async softDeleteMonthly(userId: number, categoryId: number, month: string) {
    const store = StatisticsDAO.ensureDb();
    const sql = `
      UPDATE monthly_statistics SET is_deleted=1, updated_at=? 
      WHERE user_id=? AND category_id=? AND month=?
    `;
    await store.executeSql(sql, [new Date().toISOString(), userId, categoryId, month]);
  }

  static async restoreMonthly(userId: number, categoryId: number, month: string) {
    const store = StatisticsDAO.ensureDb();
    const sql = `
      UPDATE monthly_statistics SET is_deleted=0, updated_at=? 
      WHERE user_id=? AND category_id=? AND month=?
    `;
    await store.executeSql(sql, [new Date().toISOString(), userId, categoryId, month]);
  }

  private static mapMonthlyRow(rs: relationalStore.ResultSet): MonthlyStatistics {
    const stats = new MonthlyStatistics();
    stats.userId = rs.getLong(0);
    stats.categoryId = rs.getLong(1);
    stats.month = rs.getString(2);
    stats.totalExpense = rs.getDouble(3);
    stats.totalIncome = rs.getDouble(4);
    stats.transactionCount = rs.getLong(5);
    stats.createdAt = rs.getString(6);
    stats.updatedAt = rs.getString(7);
    stats.is_deleted = rs.getLong(8);
    return stats;
  }

  /** ================== 分类统计 ================== */
  static async insertCategory(stat: CategoryStatistics) {
    if (!stat.validate()) throw new Error('[StatisticsDAO] 分类统计验证失败');

    const store = StatisticsDAO.ensureDb();
    const now = new Date().toISOString();
    stat.createdAt = now;
    stat.updatedAt = now;

    const sql = `
      INSERT INTO category_statistics 
      (category_id, category_name, type, total_amount, transaction_count, percentage, icon, color, created_at, updated_at, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      stat.categoryId, stat.categoryName, stat.type, stat.totalAmount,
      stat.transactionCount, stat.percentage, stat.icon, stat.color,
      stat.createdAt, stat.updatedAt, stat.is_deleted
    ];
    await store.executeSql(sql, params);
  }

  static async bulkInsertCategory(stats: CategoryStatistics[]) {
    const store = StatisticsDAO.ensureDb();
    await store.beginTransaction();
    try {
      for (const s of stats) await StatisticsDAO.insertCategory(s);
      await store.commit();
    } catch (err) {
      await store.rollBack();
      throw new Error('[StatisticsDAO] 批量插入分类统计失败');
    }
  }

  static async getCategory(categoryId: number): Promise<CategoryStatistics | null> {
    const store = StatisticsDAO.ensureDb();
    const sql = `SELECT * FROM category_statistics WHERE category_id=? AND is_deleted=0`;
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.querySql(sql, [categoryId]);
      if (!rs.goToNextRow()) return null;
      return StatisticsDAO.mapCategoryRow(rs);
    } finally {
      rs?.close();
    }
  }

  static async getAllCategory(): Promise<CategoryStatistics[]> {
    const store = StatisticsDAO.ensureDb();
    const sql = `SELECT * FROM category_statistics WHERE is_deleted=0 ORDER BY category_id ASC`;
    let rs: relationalStore.ResultSet | null = null;
    const list: CategoryStatistics[] = [];
    try {
      rs = await store.querySql(sql);
      while (rs.goToNextRow()) list.push(StatisticsDAO.mapCategoryRow(rs));
      return list;
    } finally {
      rs?.close();
    }
  }

  static async updateCategory(stat: CategoryStatistics) {
    if (!stat.validate()) throw new Error('[StatisticsDAO] 分类统计验证失败');

    const store = StatisticsDAO.ensureDb();
    stat.updatedAt = new Date().toISOString();

    const sql = `
      UPDATE category_statistics
      SET total_amount=?, transaction_count=?, percentage=?, icon=?, color=?, updated_at=?
      WHERE category_id=? AND is_deleted=0
    `;
    const params = [
      stat.totalAmount, stat.transactionCount, stat.percentage, stat.icon, stat.color,
      stat.updatedAt, stat.categoryId
    ];
    await store.executeSql(sql, params);
  }

  static async softDeleteCategory(categoryId: number) {
    const store = StatisticsDAO.ensureDb();
    const sql = `
      UPDATE category_statistics SET is_deleted=1, updated_at=? WHERE category_id=?
    `;
    await store.executeSql(sql, [new Date().toISOString(), categoryId]);
  }

  static async restoreCategory(categoryId: number) {
    const store = StatisticsDAO.ensureDb();
    const sql = `
      UPDATE category_statistics SET is_deleted=0, updated_at=? WHERE category_id=?
    `;
    await store.executeSql(sql, [new Date().toISOString(), categoryId]);
  }

  private static mapCategoryRow(rs: relationalStore.ResultSet): CategoryStatistics {
    const stats = new CategoryStatistics();
    stats.categoryId = rs.getLong(0);
    stats.categoryName = rs.getString(1);
    stats.type = rs.getString(2) as 'expense' | 'income';
    stats.totalAmount = rs.getDouble(3);
    stats.transactionCount = rs.getLong(4);
    stats.percentage = rs.getDouble(5);
    stats.icon = rs.getString(6);
    stats.color = rs.getString(7);
    stats.createdAt = rs.getString(8);
    stats.updatedAt = rs.getString(9);
    stats.is_deleted = rs.getLong(10);
    return stats;
  }

  /** ================== 事务封装 ================== */
  static async transaction(fn: () => Promise<void>): Promise<void> {
    const store = StatisticsDAO.ensureDb();
    await store.beginTransaction();
    try {
      await fn();
      await store.commit();
    } catch (err) {
      await store.rollBack();
      throw new Error('[StatisticsDAO] 事务失败');
    }
  }
}
