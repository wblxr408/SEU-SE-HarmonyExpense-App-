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
      throw StatisticsDAO.toError('[StatisticsDAO] 初始化数据库失败', error);
    }
  }

  static async createTables() {
    const store = StatisticsDAO.ensureDb();
    try {
      await store.executeSql(`
      CREATE TABLE IF NOT EXISTS monthly_statistics (
        user_id INTEGER,
        category_id INTEGER,
        month TEXT,
        total_expense REAL,
        total_income REAL,
        transaction_count INTEGER,
        PRIMARY KEY (user_id, category_id, month)
      );
    `);
      await store.executeSql(`
      CREATE TABLE IF NOT EXISTS category_statistics (
        category_id INTEGER,
        category_name TEXT,
        type TEXT,
        total_amount REAL,
        transaction_count INTEGER,
        percentage REAL,
        icon TEXT,
        color TEXT,
        PRIMARY KEY (category_id)
      );
    `);
    } catch (error) {
      console.error('[StatisticsDAO] 创建表失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 创建表失败', error);
    }
  }

  private static ensureDb(): relationalStore.RdbStore {
    if (db === null) {
      throw new Error('[StatisticsDAO] Database has not been initialized. Call initDatabase first.');
    }
    return db;
  }

  private static toError(message: string, err: Error | string | object): Error {
    let details: string = '';
    try {
      details = typeof err === 'string' ? err : JSON.stringify(err);
    } catch (_) {
      details = '';
    }
    return new Error(`${message}${details ? ' -> ' + details : ''}`);
  }

  static async insertMonthlyStatistics(statistics: MonthlyStatistics) {
    const sql = `
      INSERT INTO monthly_statistics (user_id, category_id, month, total_expense, total_income, transaction_count)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    const params = [
      statistics.userId, statistics.categoryId, statistics.month,
      statistics.totalExpense, statistics.totalIncome, statistics.transactionCount
    ];
    const store = StatisticsDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[StatisticsDAO] 插入月度统计失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 插入月度统计失败', error);
    }
  }

  static async getMonthlyStatistics(userId: number, month: string): Promise<MonthlyStatistics | null> {
    const sql = `SELECT * FROM monthly_statistics WHERE user_id = ? AND month = ?`;
    const store = StatisticsDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId, month]);
      if (!resultSet.goToNextRow()) {
        return null;
      }
      const stat = new MonthlyStatistics();
      stat.userId = resultSet.getLong(0);
      stat.categoryId = resultSet.getLong(1);
      stat.month = resultSet.getString(2);
      stat.totalExpense = resultSet.getDouble(3);
      stat.totalIncome = resultSet.getDouble(4);
      stat.transactionCount = resultSet.getLong(5);
      return stat;
    } catch (error) {
      console.error('[StatisticsDAO] 查询月度统计失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 查询月度统计失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async getAllMonthlyStatistics(): Promise<MonthlyStatistics[]> {
    const sql = `SELECT * FROM monthly_statistics ORDER BY month ASC`;
    const store = StatisticsDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    const statisticsList: MonthlyStatistics[] = [];
    try {
      resultSet = await store.querySql(sql);
      while (resultSet.goToNextRow()) {
        const stat = new MonthlyStatistics();
        stat.userId = resultSet.getLong(0);
        stat.categoryId = resultSet.getLong(1);
        stat.month = resultSet.getString(2);
        stat.totalExpense = resultSet.getDouble(3);
        stat.totalIncome = resultSet.getDouble(4);
        stat.transactionCount = resultSet.getLong(5);
        statisticsList.push(stat);
      }
      return statisticsList;
    } catch (error) {
      console.error('[StatisticsDAO] 查询所有月度统计失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 查询所有月度统计失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async updateMonthlyStatistics(statistics: MonthlyStatistics) {
    const sql = `
      UPDATE monthly_statistics
      SET total_expense = ?, total_income = ?, transaction_count = ?
      WHERE user_id = ? AND category_id = ? AND month = ?
    `;
    const params = [
      statistics.totalExpense, statistics.totalIncome, statistics.transactionCount,
      statistics.userId, statistics.categoryId, statistics.month
    ];
    const store = StatisticsDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[StatisticsDAO] 更新月度统计失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 更新月度统计失败', error);
    }
  }

  static async deleteMonthlyStatistics(userId: number, categoryId: number, month: string) {
    const sql = `DELETE FROM monthly_statistics WHERE user_id = ? AND category_id = ? AND month = ?`;
    const store = StatisticsDAO.ensureDb();
    try {
      await store.executeSql(sql, [userId, categoryId, month]);
    } catch (error) {
      console.error('[StatisticsDAO] 删除月度统计失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 删除月度统计失败', error);
    }
  }

  static async insertCategoryStatistics(statistics: CategoryStatistics) {
    const sql = `
      INSERT INTO category_statistics (category_id, category_name, type, total_amount, transaction_count, percentage, icon, color)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      statistics.categoryId, statistics.categoryName, statistics.type, statistics.totalAmount,
      statistics.transactionCount, statistics.percentage, statistics.icon, statistics.color
    ];
    const store = StatisticsDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[StatisticsDAO] 插入分类统计失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 插入分类统计失败', error);
    }
  }

  static async getCategoryStatistics(categoryId: number): Promise<CategoryStatistics | null> {
    const sql = `SELECT * FROM category_statistics WHERE category_id = ?`;
    const store = StatisticsDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [categoryId]);
      if (!resultSet.goToNextRow()) {
        return null;
      }
      const stat = new CategoryStatistics();
      stat.categoryId = resultSet.getLong(0);
      stat.categoryName = resultSet.getString(1);
      stat.type = resultSet.getString(2);
      stat.totalAmount = resultSet.getDouble(3);
      stat.transactionCount = resultSet.getLong(4);
      stat.percentage = resultSet.getDouble(5);
      stat.icon = resultSet.getString(6);
      stat.color = resultSet.getString(7);
      return stat;
    } catch (error) {
      console.error('[StatisticsDAO] 查询分类统计失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 查询分类统计失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async getAllCategoryStatistics(): Promise<CategoryStatistics[]> {
    const sql = `SELECT * FROM category_statistics ORDER BY category_id ASC`;
    const store = StatisticsDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    const statisticsList: CategoryStatistics[] = [];
    try {
      resultSet = await store.querySql(sql);
      while (resultSet.goToNextRow()) {
        const stat = new CategoryStatistics();
        stat.categoryId = resultSet.getLong(0);
        stat.categoryName = resultSet.getString(1);
        stat.type = resultSet.getString(2);
        stat.totalAmount = resultSet.getDouble(3);
        stat.transactionCount = resultSet.getLong(4);
        stat.percentage = resultSet.getDouble(5);
        stat.icon = resultSet.getString(6);
        stat.color = resultSet.getString(7);
        statisticsList.push(stat);
      }
      return statisticsList;
    } catch (error) {
      console.error('[StatisticsDAO] 查询全部分类统计失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 查询全部分类统计失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async updateCategoryStatistics(statistics: CategoryStatistics) {
    const sql = `
      UPDATE category_statistics
      SET total_amount = ?, transaction_count = ?, percentage = ?, icon = ?, color = ?
      WHERE category_id = ?
    `;
    const params = [
      statistics.totalAmount, statistics.transactionCount, statistics.percentage,
      statistics.icon, statistics.color, statistics.categoryId
    ];
    const store = StatisticsDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[StatisticsDAO] 更新分类统计失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 更新分类统计失败', error);
    }
  }

  static async deleteCategoryStatistics(categoryId: number) {
    const sql = `DELETE FROM category_statistics WHERE category_id = ?`;
    const store = StatisticsDAO.ensureDb();
    try {
      await store.executeSql(sql, [categoryId]);
    } catch (error) {
      console.error('[StatisticsDAO] 删除分类统计失败: ' + JSON.stringify(error));
      throw StatisticsDAO.toError('[StatisticsDAO] 删除分类统计失败', error);
    }
  }
}