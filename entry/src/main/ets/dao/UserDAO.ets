// src/dao/UserDAO.ts
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { User } from '../model/User';

let db: relationalStore.RdbStore | null = null;

export class UserDAO {

  /** 初始化数据库 */
  static async initDatabase(context: common.Context) {
    const storeConfig: relationalStore.StoreConfig = {
      name: 'harmony_expense.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    try {
      db = await relationalStore.getRdbStore(context, storeConfig);
      console.log('[UserDAO] 数据库已初始化');
      await UserDAO.createTables();
    } catch (error) {
      throw UserDAO.toError('[UserDAO] 初始化数据库失败', error);
    }
  }

  /** 创建表 */
  static async createTables() {
    const store = UserDAO.ensureDb();
    try {
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
      console.log('[UserDAO] 表 users 创建成功');
    } catch (error) {
      throw UserDAO.toError('[UserDAO] 创建表失败', error);
    }
  }

  private static ensureDb(): relationalStore.RdbStore {
    if (!db) throw new Error('[UserDAO] Database not initialized');
    return db;
  }

  private static toError(message: string, err: Error | string | object): Error {
    let details = '';
    try { details = typeof err === 'string' ? err : JSON.stringify(err); } catch (_) {}
    return new Error(`${message}${details ? ' -> ' + details : ''}`);
  }

  /** 插入单条用户 */
  static async insert(user: User) {
    if (!user.validate()) throw new Error('[UserDAO] 插入失败，数据验证不通过');

    const store = UserDAO.ensureDb();
    const now = new Date().toISOString();
    user.createdAt = now;
    user.updatedAt = now;
    const sql = `
      INSERT INTO users (username, email, password_hash, created_at, updated_at, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    const params = [user.username, user.email, user.passwordHash, user.createdAt, user.updatedAt, user.is_deleted];
    await store.executeSql(sql, params);
  }

  /** 批量插入 */
  static async insertMany(users: User[]) {
    const store = UserDAO.ensureDb();
    await store.beginTransaction();
    try {
      for (const u of users) await UserDAO.insert(u);
      await store.commit();
    } catch (error) {
      await store.rollBack();
      throw UserDAO.toError('[UserDAO] 批量插入失败', error);
    }
  }

  /** 查询单条（未删除） */
  static async getById(userId: number): Promise<User | null> {
    const store = UserDAO.ensureDb();
    const sql = `SELECT * FROM users WHERE user_id = ? AND is_deleted = 0`;
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.querySql(sql, [userId]);
      if (!rs.goToNextRow()) return null;
      const u = new User();
      u.userId = rs.getLong(0);
      u.username = rs.getString(1);
      u.email = rs.getString(2);
      u.passwordHash = rs.getString(3);
      u.createdAt = rs.getString(4);
      u.updatedAt = rs.getString(5);
      u.is_deleted = rs.getLong(6);
      return u;
    } finally { rs?.close(); }
  }

  /** 查询全部（未删除） */
  static async getAll(): Promise<User[]> {
    const store = UserDAO.ensureDb();
    const sql = `SELECT * FROM users WHERE is_deleted = 0 ORDER BY user_id ASC`;
    let rs: relationalStore.ResultSet | null = null;
    const users: User[] = [];
    try {
      rs = await store.querySql(sql);
      while (rs.goToNextRow()) {
        const u = new User();
        u.userId = rs.getLong(0);
        u.username = rs.getString(1);
        u.email = rs.getString(2);
        u.passwordHash = rs.getString(3);
        u.createdAt = rs.getString(4);
        u.updatedAt = rs.getString(5);
        u.is_deleted = rs.getLong(6);
        users.push(u);
      }
      return users;
    } finally { rs?.close(); }
  }

  /** 更新用户 */
  static async update(user: User) {
    if (!user.validate()) throw new Error('[UserDAO] 更新失败，数据验证不通过');

    const store = UserDAO.ensureDb();
    user.updatedAt = new Date().toISOString();
    const sql = `
      UPDATE users
      SET username = ?, email = ?, password_hash = ?, updated_at = ?
      WHERE user_id = ?
    `;
    const params = [user.username, user.email, user.passwordHash, user.updatedAt, user.userId];
    await store.executeSql(sql, params);
  }

  /** 物理删除 */
  static async delete(userId: number) {
    const store = UserDAO.ensureDb();
    const sql = `DELETE FROM users WHERE user_id = ?`;
    await store.executeSql(sql, [userId]);
  }

  /** 软删除 */
  static async softDelete(userId: number) {
    const store = UserDAO.ensureDb();
    const sql = `UPDATE users SET is_deleted = 1, updated_at = ? WHERE user_id = ?`;
    await store.executeSql(sql, [new Date().toISOString(), userId]);
  }

  /** 恢复软删除 */
  static async restore(userId: number) {
    const store = UserDAO.ensureDb();
    const sql = `UPDATE users SET is_deleted = 0, updated_at = ? WHERE user_id = ?`;
    await store.executeSql(sql, [new Date().toISOString(), userId]);
  }

  /** 事务封装 */
  static async transaction(fn: () => Promise<void>) {
    const store = UserDAO.ensureDb();
    await store.beginTransaction();
    try {
      await fn();
      await store.commit();
    } catch (error) {
      await store.rollBack();
      throw UserDAO.toError('[UserDAO] 事务失败', error);
    }
  }
}
