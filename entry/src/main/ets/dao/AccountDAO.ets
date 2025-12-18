import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { Account, AccountJSON } from '../model/Account';

let db: relationalStore.RdbStore | null = null;

/**
 * 账户数据访问对象（DAO）
 * 提供对 accounts 表的CRUD
 */
export class AccountDAO {

  /**
   * 初始化数据库
   * @param context 应用上下文，用于获取数据库路径
   */
  static async initDatabase(context: common.Context) {
    // 数据库配置
    const storeConfig: relationalStore.StoreConfig = {
      name: 'harmony_expense.db',             // 数据库文件名
      securityLevel: relationalStore.SecurityLevel.S1  // 数据库安全等级
    };

    try {
      // 读取数据库实例
      db = await relationalStore.getRdbStore(context, storeConfig);
      console.log('[AccountDAO] 数据库已初始化');

      // 创建
      await AccountDAO.createTables();
    } catch (error) {
      console.error('[AccountDAO] 初始化数据库失败: ' + JSON.stringify(error));
      throw new Error('[AccountDAO] 初始化数据库失败');
    }
  }

  /**
   * 创建 accounts 表
   * 包含字段：account_id, user_id, name, type, balance, color, created_at, updated_at
   */
  static async createTables() {
    const store = AccountDAO.ensureDb(); // 确保数据库已经初始化

    const sql = `
      CREATE TABLE IF NOT EXISTS accounts (
        account_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        color TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      );
    `;

    // 执行 SQL 创建表
    await store.executeSql(sql);
    console.log('[AccountDAO] 表 accounts 已创建或存在');
  }

  /**
   * 确保数据库实例存在
   * 如果 db 为空则抛出异常
   */
  private static ensureDb(): relationalStore.RdbStore {
    if (!db) {
      throw new Error('[AccountDAO] Database not initialized');
    }
    return db;
  }

  /**
   * 将 ResultSet 的一行数据映射为 Account 对象
   * @param resultSet 查询结果集
   * @returns Account 对象
   */
  private static mapRowToAccount(resultSet: relationalStore.ResultSet): Account {
    // 构造 JSON 对象
    const row = {
      accountId: resultSet.getLong(resultSet.getColumnIndex('account_id')),
      userId: resultSet.getLong(resultSet.getColumnIndex('user_id')),
      name: resultSet.getString(resultSet.getColumnIndex('name')),
      type: resultSet.getString(resultSet.getColumnIndex('type')) as 'cash' | 'bank' | 'credit_card' | 'other',
      balance: resultSet.getDouble(resultSet.getColumnIndex('balance')),
      color: resultSet.getString(resultSet.getColumnIndex('color')),
      createdAt: resultSet.getString(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getString(resultSet.getColumnIndex('updated_at'))
    } as AccountJSON;

    // 使用 Account.fromJSON 方法生成 Account 对象
    return Account.fromJSON(row);
  }

  /**
   * 插入单条账户记录
   * @param account Account 对象
   * @returns 新插入记录的 ID
   */
  static async insert(account: Account): Promise<number> {
    // 校验数据有效性
    if (!account.validate()) {
      throw new Error('[AccountDAO] 插入失败，数据验证不通过');
    }

    // 设置创建和更新时间
    const now = new Date().toISOString();
    account.createdAt = now;
    account.updatedAt = now;

    const store = AccountDAO.ensureDb();

    // 构建 ValuesBucket 对象，表示要插入的列和值
    const valueBucket: relationalStore.ValuesBucket = {
      user_id: account.userId,
      name: account.name,
      type: account.type,
      balance: account.balance,
      color: account.color,
      created_at: account.createdAt,
      updated_at: account.updatedAt,
      is_deleted: account.is_deleted
    };

    try {
      // 执行插入操作，返回新行 ID
      const rowId = (await store.insert('accounts', valueBucket)) as number;
      console.log(`[AccountDAO] 插入成功 id=${rowId}`);
      return rowId;
    } catch (error) {
      console.error('[AccountDAO] 插入失败: ' + JSON.stringify(error));
      throw new Error('[AccountDAO] 插入失败');
    }
  }

  /**
   * 批量插入账户记录
   * 使用事务保证批量插入的原子性
   * @param accounts Account 数组
   */
  static async insertMany(accounts: Account[]): Promise<void> {
    const store = AccountDAO.ensureDb();
    try {
      await store.beginTransaction(); // 开启事务
      for (const acc of accounts) {
        await AccountDAO.insert(acc); // 逐条插入
      }
      await store.commit(); // 提交事务
      console.log('[AccountDAO] 批量插入成功');
    } catch (error) {
      await store.rollBack(); // 回滚事务
      console.error('[AccountDAO] 批量插入失败: ' + JSON.stringify(error));
      throw new Error('[AccountDAO] 批量插入失败');
    }
  }

  /**
   * 根据 ID 查询单个账户
   * @param accountId 账户 ID
   * @returns Account 对象或 null
   */
  static async getById(accountId: number): Promise<Account | null> {
    const store = AccountDAO.ensureDb();

    // 构建查询条件
    const predicates = new relationalStore.RdbPredicates('accounts');
    predicates.equalTo('account_id', accountId);

    // 执行查询
    const resultSet = await store.query(predicates);
    try {
      if (!resultSet.goToNextRow()) {
        return null; // 没有记录
      }
      return AccountDAO.mapRowToAccount(resultSet); // 映射为 Account 对象
    } finally {
      resultSet.close(); // 释放资源
    }
  }

  /**
   * 查询所有账户
   * @returns Account 数组
   */
  static async getAll(): Promise<Account[]> {
    const store = AccountDAO.ensureDb();

    // 执行原生 SQL 查询
    const resultSet = await store.querySql('SELECT * FROM accounts ORDER BY account_id ASC');
    const list: Account[] = [];
    try {
      while (resultSet.goToNextRow()) {
        list.push(AccountDAO.mapRowToAccount(resultSet)); // 每行映射为 Account
      }
      return list;
    } finally {
      resultSet.close(); // 释放资源
    }
  }

  /**
   * 更新账户信息
   * @param account Account 对象
   */
  static async update(account: Account) {
    if (!account.validate()) {
      throw new Error('[AccountDAO] 更新失败，数据验证不通过');
    }

    const store = AccountDAO.ensureDb();
    const now = new Date().toISOString();

    // 更新字段
    const valueBucket: relationalStore.ValuesBucket = {
      name: account.name,
      type: account.type,
      balance: account.balance,
      color: account.color,
      updated_at: now
    };

    // 构建更新条件
    const predicates = new relationalStore.RdbPredicates('accounts');
    predicates.equalTo('account_id', account.accountId);

    // 执行更新
    await store.update(valueBucket, predicates);
    console.log(`[AccountDAO] 更新成功 id=${account.accountId}`);
  }

  /**
   * 删除账户
   * @param accountId 账户 ID
   */
  static async delete(accountId: number) {
    const store = AccountDAO.ensureDb();

    // 构建删除条件
    const predicates = new relationalStore.RdbPredicates('accounts');
    predicates.equalTo('account_id', accountId);

    // 执行删除
    await store.delete(predicates);
    console.log(`[AccountDAO] 删除成功 id=${accountId}`);
  }

  /**
   * 根据 userId 查询某个用户的所有账户
   */
  static async getByUserId(userId: number): Promise<Account[]> {
    const store = AccountDAO.ensureDb();
    const predicates = new relationalStore.RdbPredicates('accounts');
    predicates.equalTo('user_id', userId);
    const resultSet = await store.query(predicates);
    const list: Account[] = [];
    try {
      while (resultSet.goToNextRow()) {
        list.push(AccountDAO.mapRowToAccount(resultSet));
      }
      return list;
    } finally {
      resultSet.close();
    }
  }

  /**
   * 根据余额范围查询账户
   * @param min 最小余额
   * @param max 最大余额
   */
  static async getByBalanceRange(min: number, max: number): Promise<Account[]> {
    const store = AccountDAO.ensureDb();
    const predicates = new relationalStore.RdbPredicates('accounts');
    predicates.greaterThanOrEqualTo('balance', min);
    predicates.lessThanOrEqualTo('balance', max);
    const resultSet = await store.query(predicates);
    const list: Account[] = [];
    try {
      while (resultSet.goToNextRow()) {
        list.push(AccountDAO.mapRowToAccount(resultSet));
      }
      return list;
    } finally {
      resultSet.close();
    }
  }

  /**
   * 批量更新账户的余额或颜色等字段
   * @param accounts Account 数组
   */
  static async updateMany(accounts: Account[]): Promise<void> {
    const store = AccountDAO.ensureDb();
    try {
      await store.beginTransaction();
      for (const acc of accounts) {
        await AccountDAO.update(acc);
      }
      await store.commit();
      console.log('[AccountDAO] 批量更新成功');
    } catch (error) {
      await store.rollBack();
      console.error('[AccountDAO] 批量更新失败: ' + JSON.stringify(error));
      throw new Error('[AccountDAO] 批量更新失败');
    }
  }

  /**
   * 软删除账户（标记删除，而不是物理删除）
   */
  static async softDelete(accountId: number): Promise<void> {
    const store = AccountDAO.ensureDb();
    const valueBucket: relationalStore.ValuesBucket = { is_deleted: 1 };
    const predicates = new relationalStore.RdbPredicates('accounts');
    predicates.equalTo('account_id', accountId);
    await store.update(valueBucket, predicates);
    console.log(`[AccountDAO] 软删除成功 id=${accountId}`);
  }

  /**
   * 恢复软删除账户
   */
  static async restore(accountId: number): Promise<void> {
    const store = AccountDAO.ensureDb();
    const valueBucket: relationalStore.ValuesBucket = { is_deleted: 0 };
    const predicates = new relationalStore.RdbPredicates('accounts');
    predicates.equalTo('account_id', accountId);
    await store.update(valueBucket, predicates);
    console.log(`[AccountDAO] 恢复账户成功 id=${accountId}`);
  }

  /**
   * 执行事务函数（统一事务处理）
   * @param fn 包含数据库操作的异步函数
   */
  static async transaction(fn: () => Promise<void>): Promise<void> {
    const store = AccountDAO.ensureDb();
    try {
      await store.beginTransaction();
      await fn();
      await store.commit();
    } catch (error) {
      await store.rollBack();
      console.error('[AccountDAO] 事务失败: ' + JSON.stringify(error));
      throw new Error('[AccountDAO] 事务失败');
    }
  }

  static async exists(accountId: number): Promise<boolean> {
    const sql = `SELECT 1 FROM accounts WHERE account_id = ? AND is_deleted = 0`;
    const store = AccountDAO.ensureDb();
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.querySql(sql, [accountId]);
      return rs.goToNextRow(); // 有记录返回 true
    } finally {
      if (rs) rs.close();
    }
  }

  /**
   * 更新账户余额 (原子的)
   * @param accountId 账户ID
   * @param amount 变动金额 (正数增加，负数减少)
   */
  static async updateBalance(accountId: number, amount: number) {
    const store = AccountDAO.ensureDb();
    const sql = `UPDATE accounts SET balance = balance + ? WHERE account_id = ?`;
    await store.executeSql(sql, [amount, accountId]);
    console.log(`[AccountDAO] 余额更新: accountId=${accountId}, delta=${amount}`);
  }

}
