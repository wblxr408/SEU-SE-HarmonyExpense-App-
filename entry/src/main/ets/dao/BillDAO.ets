// dao/BillDAO.ts
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { Bill } from '../model/Bill';
import { AccountDAO } from './AccountDAO';
import { CategoryDAO } from './CategoryDAO';
import hilog from '@ohos.hilog';

export interface DateRangeFilter {
  start: string;
  end: string;
}
let db: relationalStore.RdbStore | null = null;

interface GeneratedTypeLiteralInterface_1 {
  start: string;
  end: string;
}

export class BillDAO {

  static async initDatabase(context: common.Context) {
    const storeConfig: relationalStore.StoreConfig = {
      name: 'harmony_expense.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    db = await relationalStore.getRdbStore(context, storeConfig);
    console.log('[BillDAO] 数据库已初始化');
    await BillDAO.createTables();
  }

  static async createTables() {
    const store = BillDAO.ensureDb();
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
        is_deleted INTEGER DEFAULT 0
      );
    `);
    await store.executeSql(`CREATE INDEX IF NOT EXISTS idx_bills_user_date ON bills (user_id, transaction_date);`);
  }

  private static ensureDb(): relationalStore.RdbStore {
    if (!db) throw new Error('[BillDAO] Database not initialized');
    return db;
  }

  private static toError(msg: string, err: Error | string | object): Error {
    let detail = '';
    try {
      detail = typeof err === 'string' ? err : JSON.stringify(err);
    } catch {}
    return new Error(`${msg}${detail ? ' -> ' + detail : ''}`);
  }


  private static mapRow(rs: relationalStore.ResultSet): Bill {
    return new Bill(
      // rs.getLong(0),
      // rs.getLong(1),
      // rs.getLong(2),
      // rs.getDouble(3),
      // rs.getString(5),
      // rs.getString(6),
      // rs.getString(4) as 'income' | 'expense',
      // rs.getString(7),
      // rs.getString(8),
      // rs.getLong(9)
      rs.getLong(rs.getColumnIndex('bill_id')),
      rs.getLong(rs.getColumnIndex('user_id')),
      rs.getLong(rs.getColumnIndex('account_id')),
      rs.getLong(rs.getColumnIndex('category_id')),
      rs.getDouble(rs.getColumnIndex('amount')),
      rs.getString(rs.getColumnIndex('note')),
      rs.getString(rs.getColumnIndex('transaction_date')),
      rs.getString(rs.getColumnIndex('type')) as 'income' | 'expense',
      rs.getString(rs.getColumnIndex('created_at')),
      rs.getString(rs.getColumnIndex('updated_at')),
      rs.getLong(rs.getColumnIndex('is_deleted'))
    );
  }

  // 插入账单
  static async insert(bill: Bill) {
    await BillDAO.validateForeignKeys(bill);
    const sql = `
      INSERT INTO bills
      (user_id,account_id, category_id, amount, type, note, transaction_date, created_at, updated_at, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?,?)
    `;
    const params = [
      bill.userId,
      bill.accountId, bill.categoryId, bill.amount, bill.type, bill.note,
      bill.transactionDate, bill.createdAt, bill.updatedAt, bill.isDeleted
    ];
    await BillDAO.ensureDb().executeSql(sql, params);
  }

  static async validateForeignKeys(bill: Bill) {
    const accountExists = await AccountDAO.exists(bill.accountId);
    const categoryExists = await CategoryDAO.exists(bill.categoryId);
    if (!accountExists) throw new Error(`[BillDAO] Account ${bill.accountId} does not exist`);
    if (!categoryExists) throw new Error(`[BillDAO] Category ${bill.categoryId} does not exist`);
  }

  static async getById(billId: number,userId:number): Promise<Bill | null> {
    const sql = `SELECT * FROM bills WHERE bill_id = ? AND is_deleted = 0`;
    const rs = await BillDAO.ensureDb().querySql(sql, [billId]);
    try {
      if (!rs.goToNextRow()) return null;
      return BillDAO.mapRow(rs);
    } finally { rs.close(); }
  }

  static async getAll(): Promise<Bill[]> {
    const sql = `SELECT * FROM bills WHERE is_deleted = 0 ORDER BY bill_id ASC`;
    const rs = await BillDAO.ensureDb().querySql(sql);
    const list: Bill[] = [];
    try {
      while (rs.goToNextRow()) list.push(BillDAO.mapRow(rs));
      return list;
    } finally { rs.close(); }
  }

  static async update(bill: Bill) {
    await BillDAO.validateForeignKeys(bill);
    const sql = `
      UPDATE bills
      SET account_id = ?, category_id = ?, amount = ?, type = ?, note = ?,
          transaction_date = ?, updated_at = ?, is_deleted = ?
      WHERE bill_id = ?
    `;
    const params = [
      bill.accountId, bill.categoryId, bill.amount, bill.type, bill.note,
      bill.transactionDate, bill.updatedAt, bill.isDeleted, bill.billId,bill.userId
    ];
    await BillDAO.ensureDb().executeSql(sql, params);
  }

  // 软删除
  static async delete(billId: number,userId:number) {
    const sql = `UPDATE bills SET is_deleted = 1 WHERE bill_id = ?`;
    await BillDAO.ensureDb().executeSql(sql, [billId,userId]);
  }

  static async restore(billId: number,userId:number) {
    const sql = `UPDATE bills SET is_deleted = 0 WHERE bill_id = ?`;
    await BillDAO.ensureDb().executeSql(sql, [billId,userId]);
  }


  static async getBillsByFilters(
    userId: number,
    dateRange:DateRangeFilter ,
    categoryId?: number
  ): Promise<Bill[]> {

    let sql = `
      SELECT * FROM bills
      WHERE user_id = ?
        AND transaction_date >= ?
        AND transaction_date <= ?
        AND is_deleted = 0
    `;
    const params: (string | number)[] = [userId, dateRange.start, dateRange.end];

    if (categoryId !== undefined && categoryId > 0) {
      sql += ` AND category_id = ?`;
      params.push(categoryId);
    }
    sql += ` ORDER BY transaction_date DESC`;

    const store = BillDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    const bills: Bill[] = [];

    try {
      resultSet = await store.querySql(sql, params);
      while (resultSet.goToNextRow()) {
        bills.push(BillDAO.mapRow(resultSet));
      }
      return bills;
    } catch (error) {
      throw BillDAO.toError('getBillsByFilters 查询失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }
  // 事务封装
  static async transaction(fn: () => Promise<void>) {
    const store = BillDAO.ensureDb();
    await store.beginTransaction();
    try {
      await fn();
      await store.commit();
    } catch (err) {
      await store.rollBack();
      throw BillDAO.toError('[BillDAO] Transaction failed', err);
    }
  }
}
