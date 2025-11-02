import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { Budget } from '../model/Budget';

let db: relationalStore.RdbStore | null = null;

export class BudgetDAO {
  static async initDatabase(context: common.Context) {
    const storeConfig: relationalStore.StoreConfig = {
      name: 'harmony_expense.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    try {
      db = await relationalStore.getRdbStore(context, storeConfig);
      console.log('[BudgetDAO] 数据库已初始化');
      await BudgetDAO.createTables();
    } catch (error) {
      console.error('[BudgetDAO] 初始化数据库失败: ' + JSON.stringify(error));
      throw BudgetDAO.toError('[BudgetDAO] 初始化数据库失败', error);
    }
  }

  static async createTables() {
    const store = BudgetDAO.ensureDb();
    try {
      await store.executeSql(`
      CREATE TABLE IF NOT EXISTS budgets (
        budget_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        category_id INTEGER,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER NOT NULL,
        created_at TEXT NOT NULL
      );
    `);
    } catch (error) {
      console.error('[BudgetDAO] 创建表失败: ' + JSON.stringify(error));
      throw BudgetDAO.toError('[BudgetDAO] 创建表失败', error);
    }
  }

  private static ensureDb(): relationalStore.RdbStore {
    if (db === null) {
      throw new Error('[BudgetDAO] Database has not been initialized. Call initDatabase first.');
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

  static async insert(budget: Budget) {
    const sql = `
      INSERT INTO budgets (user_id, category_id, amount, period, start_date, end_date, is_active, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      budget.userId, budget.categoryId, budget.amount, budget.period,
      budget.startDate, budget.endDate, budget.isActive, budget.createdAt
    ];
    const store = BudgetDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[BudgetDAO] 插入失败: ' + JSON.stringify(error));
      throw BudgetDAO.toError('[BudgetDAO] 插入失败', error);
    }
  }

  static async getById(budgetId: number): Promise<Budget | null> {
    const sql = `SELECT * FROM budgets WHERE budget_id = ?`;
    const store = BudgetDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [budgetId]);
      if (!resultSet.goToNextRow()) {
        return null;
      }
      const budget = new Budget();
      budget.budgetId = resultSet.getLong(0);
      budget.userId = resultSet.getLong(1);
      budget.categoryId = resultSet.getLong(2);
      budget.amount = resultSet.getDouble(3);
      budget.period = resultSet.getString(4);
      budget.startDate = resultSet.getString(5);
      budget.endDate = resultSet.getString(6);
      budget.isActive = resultSet.getLong(7);
      budget.createdAt = resultSet.getString(8);
      return budget;
    } catch (error) {
      console.error('[BudgetDAO] 查询失败: ' + JSON.stringify(error));
      throw BudgetDAO.toError('[BudgetDAO] 查询失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async getAll(): Promise<Budget[]> {
    const sql = `SELECT * FROM budgets ORDER BY budget_id ASC`;
    const store = BudgetDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    const budgets: Budget[] = [];
    try {
      resultSet = await store.querySql(sql);
      while (resultSet.goToNextRow()) {
        const item = new Budget();
        item.budgetId = resultSet.getLong(0);
        item.userId = resultSet.getLong(1);
        item.categoryId = resultSet.getLong(2);
        item.amount = resultSet.getDouble(3);
        item.period = resultSet.getString(4);
        item.startDate = resultSet.getString(5);
        item.endDate = resultSet.getString(6);
        item.isActive = resultSet.getLong(7);
        item.createdAt = resultSet.getString(8);
        budgets.push(item);
      }
      return budgets;
    } catch (error) {
      console.error('[BudgetDAO] 查询全部失败: ' + JSON.stringify(error));
      throw BudgetDAO.toError('[BudgetDAO] 查询全部失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async update(budget: Budget) {
    const sql = `
      UPDATE budgets
      SET category_id = ?, amount = ?, period = ?, start_date = ?, end_date = ?,
          is_active = ?, created_at = ?
      WHERE budget_id = ?
    `;
    const params = [
      budget.categoryId, budget.amount, budget.period, budget.startDate, budget.endDate,
      budget.isActive, budget.createdAt, budget.budgetId
    ];
    const store = BudgetDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[BudgetDAO] 更新失败: ' + JSON.stringify(error));
      throw BudgetDAO.toError('[BudgetDAO] 更新失败', error);
    }
  }

  static async delete(budgetId: number) {
    const sql = `DELETE FROM budgets WHERE budget_id = ?`;
    const store = BudgetDAO.ensureDb();
    try {
      await store.executeSql(sql, [budgetId]);
    } catch (error) {
      console.error('[BudgetDAO] 删除失败: ' + JSON.stringify(error));
      throw BudgetDAO.toError('[BudgetDAO] 删除失败', error);
    }
  }
}
