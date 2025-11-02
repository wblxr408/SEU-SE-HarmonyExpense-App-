import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { Bill } from '../model/Bill';

// 显式类型，避免被推断为 null
let db: relationalStore.RdbStore | null = null;

/**
 * 账单数据访问对象 - BillDAO
 * 负责操作 bills 表
 */
export class BillDAO {

  // 初始化数据库
  static async initDatabase(context: common.Context) {
    const storeConfig: relationalStore.StoreConfig = {
      name: 'harmony_expense.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    try {
      db = await relationalStore.getRdbStore(context, storeConfig);
      console.log('[BillDAO] 数据库已初始化');
      await BillDAO.createTables();
    } catch (error) {
      console.error('[BillDAO] 初始化数据库失败: ' + JSON.stringify(error));
      throw BillDAO.toError('[BillDAO] 初始化数据库失败', error);
    }
  }

  // 创建表格（如果没有的话）
  static async createTables() {
    const store = BillDAO.ensureDb();
    try {
      await store.executeSql(`
      CREATE TABLE IF NOT EXISTS bills (
        bill_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        account_id INTEGER,
        category_id INTEGER,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    `);
    } catch (error) {
      console.error('[BillDAO] 创建表失败: ' + JSON.stringify(error));
      throw BillDAO.toError('[BillDAO] 创建表失败', error);
    }
  }

  // 私有: 确保 db 已初始化
  private static ensureDb(): relationalStore.RdbStore {
    if (db === null) {
      throw new Error('[BillDAO] Database has not been initialized. Call initDatabase first.');
    }
    return db;
  }

  // 私有: 标准 Error 打包
  private static toError(message: string, err: Error | string | object): Error {
    let details: string = '';
    try {
      details = typeof err === 'string' ? err : JSON.stringify(err);
    } catch (_) {
      details = '';
    }
    return new Error(`${message}${details ? ' -> ' + details : ''}`);
  }

  /**
   * 新增账单
   */
  static async insert(bill: Bill) {
    const sql = `
      INSERT INTO bills (user_id, account_id, category_id, amount, type, note, transaction_date, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      bill.userId, bill.accountId, bill.categoryId, bill.amount, bill.type,
      bill.note, bill.transactionDate, bill.createdAt, bill.updatedAt
    ];
    const store = BillDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[BillDAO] 插入失败: ' + JSON.stringify(error));
      throw BillDAO.toError('[BillDAO] 插入失败', error);
    }
  }

  /**
   * 根据账单ID查询账单
   */
  static async getById(billId: number): Promise<Bill | null> {
    const sql = `SELECT * FROM bills WHERE bill_id = ?`;
    const store = BillDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [billId]);
      if (!resultSet.goToNextRow()) {
        return null;
      }
      const bill = new Bill();
      bill.billId = resultSet.getLong(0);
      bill.userId = resultSet.getLong(1);
      bill.accountId = resultSet.getLong(2);
      bill.categoryId = resultSet.getLong(3);
      bill.amount = resultSet.getDouble(4);
      bill.type = resultSet.getString(5);
      bill.note = resultSet.getString(6);
      bill.transactionDate = resultSet.getString(7);
      bill.createdAt = resultSet.getString(8);
      bill.updatedAt = resultSet.getString(9);
      return bill;
    } catch (error) {
      console.error('[BillDAO] 查询失败: ' + JSON.stringify(error));
      throw BillDAO.toError('[BillDAO] 查询失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  /**
   * 获取所有账单
   */
  static async getAll(): Promise<Bill[]> {
    const sql = `SELECT * FROM bills ORDER BY bill_id ASC`;
    const store = BillDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    const bills: Bill[] = [];
    try {
      resultSet = await store.querySql(sql);
      while (resultSet.goToNextRow()) {
        const bill = new Bill();
        bill.billId = resultSet.getLong(0);
        bill.userId = resultSet.getLong(1);
        bill.accountId = resultSet.getLong(2);
        bill.categoryId = resultSet.getLong(3);
        bill.amount = resultSet.getDouble(4);
        bill.type = resultSet.getString(5);
        bill.note = resultSet.getString(6);
        bill.transactionDate = resultSet.getString(7);
        bill.createdAt = resultSet.getString(8);
        bill.updatedAt = resultSet.getString(9);
        bills.push(bill);
      }
      return bills;
    } catch (error) {
      console.error('[BillDAO] 查询全部失败: ' + JSON.stringify(error));
      throw BillDAO.toError('[BillDAO] 查询全部失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  /**
   * 更新账单信息
   */
  static async update(bill: Bill) {
    const sql = `
      UPDATE bills
      SET account_id = ?, category_id = ?, amount = ?, type = ?, note = ?,
          transaction_date = ?, updated_at = ?
      WHERE bill_id = ?
    `;
    const params = [
      bill.accountId, bill.categoryId, bill.amount, bill.type, bill.note,
      bill.transactionDate, bill.updatedAt, bill.billId
    ];
    const store = BillDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[BillDAO] 更新失败: ' + JSON.stringify(error));
      throw BillDAO.toError('[BillDAO] 更新失败', error);
    }
  }

  /**
   * 删除账单
   */
  static async delete(billId: number) {
    const sql = `DELETE FROM bills WHERE bill_id = ?`;
    const store = BillDAO.ensureDb();
    try {
      await store.executeSql(sql, [billId]);
    } catch (error) {
      console.error('[BillDAO] 删除失败: ' + JSON.stringify(error));
      throw BillDAO.toError('[BillDAO] 删除失败', error);
    }
  }
}