// src/dao/UserDAO.ts
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { User } from '../model/User';
import { DAOHelper } from '../common/DAOHelper';

export class UserDAO {

  /** 插入单条用户 */
  static async insert(user: User) {
    if (!user.validate()) throw new Error('[UserDAO] 插入失败，数据验证不通过');

    const store = DatabaseManager.getDatabase();
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

  /** 批量插入 - 使用 DAOHelper 统一事务处理 */
  static async insertMany(users: User[]) {
    await DAOHelper.transaction(async () => {
      for (const u of users) await UserDAO.insert(u);
    }, '[UserDAO] 批量插入');
  }

  /** 查询单条（未删除） */
  static async getById(userId: number): Promise<User | null> {
    const store = DatabaseManager.getDatabase();
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
  /**
   * 根据用户名查询用户（用于登录验证）
   */
  static async getByUsername(username: string): Promise<User | null> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT * FROM users WHERE username = ? AND is_deleted = 0`;

    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.querySql(sql, [username]);
      if (!rs || !rs.goToNextRow()) return null;

      const u = new User();
      u.userId = rs.getLong(rs.getColumnIndex('user_id'));
      u.username = rs.getString(rs.getColumnIndex('username'));
      u.email = rs.getString(rs.getColumnIndex('email'));
      u.passwordHash = rs.getString(rs.getColumnIndex('password_hash'));
      u.createdAt = rs.getString(rs.getColumnIndex('created_at'));
      u.updatedAt = rs.getString(rs.getColumnIndex('updated_at'));
      u.is_deleted = rs.getLong(rs.getColumnIndex('is_deleted'));
      return u;
    } catch (error) {
      console.error('[UserDAO] getByUsername 失败: ' + JSON.stringify(error));
      return null;
    } finally {
      if (rs) rs.close();
    }
  }

  /** 查询全部（未删除） */
  static async getAll(): Promise<User[]> {
    const store = DatabaseManager.getDatabase();
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

    const store = DatabaseManager.getDatabase();
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
    const store = DatabaseManager.getDatabase();
    const sql = `DELETE FROM users WHERE user_id = ?`;
    await store.executeSql(sql, [userId]);
  }

  /** 软删除 - 使用 DAOHelper 统一方法 */
  static async softDelete(userId: number) {
    await DAOHelper.softDelete('users', 'user_id', userId, '[UserDAO]');
  }

  /** 恢复软删除 - 使用 DAOHelper 统一方法 */
  static async restore(userId: number) {
    await DAOHelper.restore('users', 'user_id', userId, '[UserDAO]');
  }

  /** 事务封装 - 使用 DAOHelper 统一方法 */
  static async transaction(fn: () => Promise<void>) {
    await DAOHelper.transaction(fn, '[UserDAO]');
  }

  /** 更新用户资料（昵称和头像） */
  static async updateProfile(userId: number, nickname: string, avatarPath: string): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `
      UPDATE users
      SET nickname = ?, avatar_path = ?, updated_at = ?
      WHERE user_id = ? AND is_deleted = 0
    `;
    await store.executeSql(sql, [nickname, avatarPath, now, userId]);
  }

  /** 更新用户密码 */
  static async updatePassword(userId: number, newPasswordHash: string): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `
      UPDATE users
      SET password_hash = ?, updated_at = ?
      WHERE user_id = ? AND is_deleted = 0
    `;
    await store.executeSql(sql, [newPasswordHash, now, userId]);
  }

  /** 更新用户邮箱 */
  static async updateEmail(userId: number, newEmail: string): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `
      UPDATE users
      SET email = ?, updated_at = ?
      WHERE user_id = ? AND is_deleted = 0
    `;
    await store.executeSql(sql, [newEmail, now, userId]);
  }
}