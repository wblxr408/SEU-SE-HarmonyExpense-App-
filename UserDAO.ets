import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { User } from '../model/User';

let db: relationalStore.RdbStore | null = null;

export class UserDAO {
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
      console.error('[UserDAO] 初始化数据库失败: ' + JSON.stringify(error));
      throw UserDAO.toError('[UserDAO] 初始化数据库失败', error);
    }
  }

  static async createTables() {
    const store = UserDAO.ensureDb();
    try {
      await store.executeSql(`
      CREATE TABLE IF NOT EXISTS users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    `);
    } catch (error) {
      console.error('[UserDAO] 创建表失败: ' + JSON.stringify(error));
      throw UserDAO.toError('[UserDAO] 创建表失败', error);
    }
  }

  private static ensureDb(): relationalStore.RdbStore {
    if (db === null) {
      throw new Error('[UserDAO] Database has not been initialized. Call initDatabase first.');
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

  static async insert(user: User) {
    const sql = `
      INSERT INTO users (username, email, password_hash, created_at)
      VALUES (?, ?, ?, ?)
    `;
    const params = [user.username, user.email, user.passwordHash, user.createdAt];
    const store = UserDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[UserDAO] 插入失败: ' + JSON.stringify(error));
      throw UserDAO.toError('[UserDAO] 插入失败', error);
    }
  }

  static async getById(userId: number): Promise<User | null> {
    const sql = `SELECT * FROM users WHERE user_id = ?`;
    const store = UserDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId]);
      if (!resultSet.goToNextRow()) {
        return null;
      }
      const user = new User();
      user.userId = resultSet.getLong(0);
      user.username = resultSet.getString(1);
      user.email = resultSet.getString(2);
      user.passwordHash = resultSet.getString(3);
      user.createdAt = resultSet.getString(4);
      return user;
    } catch (error) {
      console.error('[UserDAO] 查询失败: ' + JSON.stringify(error));
      throw UserDAO.toError('[UserDAO] 查询失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async getAll(): Promise<User[]> {
    const sql = `SELECT * FROM users ORDER BY user_id ASC`;
    const store = UserDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    const users: User[] = [];
    try {
      resultSet = await store.querySql(sql);
      while (resultSet.goToNextRow()) {
        const user = new User();
        user.userId = resultSet.getLong(0);
        user.username = resultSet.getString(1);
        user.email = resultSet.getString(2);
        user.passwordHash = resultSet.getString(3);
        user.createdAt = resultSet.getString(4);
        users.push(user);
      }
      return users;
    } catch (error) {
      console.error('[UserDAO] 查询全部失败: ' + JSON.stringify(error));
      throw UserDAO.toError('[UserDAO] 查询全部失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async update(user: User) {
    const sql = `
      UPDATE users
      SET username = ?, email = ?, password_hash = ?
      WHERE user_id = ?
    `;
    const params = [user.username, user.email, user.passwordHash, user.userId];
    const store = UserDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[UserDAO] 更新失败: ' + JSON.stringify(error));
      throw UserDAO.toError('[UserDAO] 更新失败', error);
    }
  }

  static async delete(userId: number) {
    const sql = `DELETE FROM users WHERE user_id = ?`;
    const store = UserDAO.ensureDb();
    try {
      await store.executeSql(sql, [userId]);
    } catch (error) {
      console.error('[UserDAO] 删除失败: ' + JSON.stringify(error));
      throw UserDAO.toError('[UserDAO] 删除失败', error);
    }
  }
}