import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { Account } from '../model/Account';

// 使用显式类型避免被推断为 null
let db: relationalStore.RdbStore | null = null;

/**
 * 账户数据访问对象 - AccountDAO
 * 负责操作 accounts 表
 */
export class AccountDAO {

  // 初始化数据库
  static async initDatabase(context: common.Context) {
    const storeConfig: relationalStore.StoreConfig = {
      name: 'harmony_expense.db', // 数据库名称
      securityLevel: relationalStore.SecurityLevel.S1
    };

    // 获取数据库连接
    try {
      db = await relationalStore.getRdbStore(context, storeConfig);
      console.log('[AccountDAO] 数据库已初始化');
      await AccountDAO.createTables();
    } catch (error) {
      console.error('[AccountDAO] 初始化数据库失败: ' + JSON.stringify(error));
      throw AccountDAO.toError('[AccountDAO] 初始化数据库失败', error);
    }
  }

  // 创建表格（如果没有的话）
  static async createTables() {
    const store = AccountDAO.ensureDb();
    try {
      await store.executeSql(`
      CREATE TABLE IF NOT EXISTS accounts (
        account_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        type TEXT NOT NULL,  // 账户类型：'cash' | 'bank' | 'credit_card' | 'other'
        balance REAL NOT NULL,
        color TEXT,
        created_at TEXT NOT NULL
      );
    `);
    } catch (error) {
      console.error('[AccountDAO] 创建表失败: ' + JSON.stringify(error));
      throw AccountDAO.toError('[AccountDAO] 创建表失败', error);
    }
  }

  // 确保 db 已初始化
  private static ensureDb(): relationalStore.RdbStore {
    if (db === null) {
      throw new Error('[AccountDAO] Database has not been initialized. Call initDatabase first.');
    }
    return db;
  }

  // 将错误包装为标准 Error（避免 unknown/any）
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
   * 新增账户
   */
  static async insert(account: Account) {
    const sql = `
      INSERT INTO accounts (user_id, name, type, balance, color, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    const params = [account.userId, account.name, account.type, account.balance, account.color, account.createdAt];
    const store = AccountDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[AccountDAO] 插入失败: ' + JSON.stringify(error));
      throw AccountDAO.toError('[AccountDAO] 插入失败', error);
    }
  }

  /**
   * 根据账户ID查询账户
   */
  static async getById(accountId: number): Promise<Account | null> {
    const sql = `SELECT * FROM accounts WHERE account_id = ?`;
    const store = AccountDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [accountId]);
      if (!resultSet.goToNextRow()) {
        return null;
      }
      const account = new Account();
      account.accountId = resultSet.getLong(0);
      account.userId = resultSet.getLong(1);
      account.name = resultSet.getString(2);
      account.type = resultSet.getString(3);
      account.balance = resultSet.getDouble(4);
      account.color = resultSet.getString(5);
      account.createdAt = resultSet.getString(6);
      return account;
    } catch (error) {
      console.error('[AccountDAO] 查询失败: ' + JSON.stringify(error));
      throw AccountDAO.toError('[AccountDAO] 查询失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  /**
   * 获取所有账户
   */
  static async getAll(): Promise<Account[]> {
    const sql = `SELECT * FROM accounts ORDER BY account_id ASC`;
    const store = AccountDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    const accounts: Account[] = [];
    try {
      resultSet = await store.querySql(sql);
      while (resultSet.goToNextRow()) {
        const item = new Account();
        item.accountId = resultSet.getLong(0);
        item.userId = resultSet.getLong(1);
        item.name = resultSet.getString(2);
        item.type = resultSet.getString(3);
        item.balance = resultSet.getDouble(4);
        item.color = resultSet.getString(5);
        item.createdAt = resultSet.getString(6);
        accounts.push(item);
      }
      return accounts;
    } catch (error) {
      console.error('[AccountDAO] 查询全部失败: ' + JSON.stringify(error));
      throw AccountDAO.toError('[AccountDAO] 查询全部失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  /**
   * 更新账户信息
   */
  static async update(account: Account) {
    const sql = `
      UPDATE accounts
      SET name = ?, type = ?, balance = ?, color = ?
      WHERE account_id = ?
    `;
    const params = [account.name, account.type, account.balance, account.color, account.accountId];
    const store = AccountDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[AccountDAO] 更新失败: ' + JSON.stringify(error));
      throw AccountDAO.toError('[AccountDAO] 更新失败', error);
    }
  }

  /**
   * 删除账户
   */
  static async delete(accountId: number) {
    const sql = `DELETE FROM accounts WHERE account_id = ?`;
    const store = AccountDAO.ensureDb();
    try {
      await store.executeSql(sql, [accountId]);
    } catch (error) {
      console.error('[AccountDAO] 删除失败: ' + JSON.stringify(error));
      throw AccountDAO.toError('[AccountDAO] 删除失败', error);
    }
  }
}