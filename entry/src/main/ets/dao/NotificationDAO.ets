/**
 * 通知 DAO
 * 提供通知的增删改查操作
 */
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { Notification, NotificationType } from '../model/Notification';

export class NotificationDAO {

  /** 插入通知 */
  static async insert(notification: Notification): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    notification.createdAt = now;
    const sql = `
      INSERT INTO notifications (user_id, type, title, content, is_read, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    const params = [
      notification.userId,
      notification.type,
      notification.title,
      notification.content,
      notification.isRead,
      notification.createdAt
    ];
    await store.executeSql(sql, params);
  }

  /** 根据用户ID获取通知列表 */
  static async getByUserId(userId: number, limit: number = 50): Promise<Notification[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `
      SELECT * FROM notifications
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT ?
    `;
    let rs: relationalStore.ResultSet | null = null;
    const notifications: Notification[] = [];
    try {
      rs = await store.querySql(sql, [userId, limit]);
      while (rs.goToNextRow()) {
        const n = new Notification();
        n.notificationId = rs.getLong(rs.getColumnIndex('notification_id'));
        n.userId = rs.getLong(rs.getColumnIndex('user_id'));
        n.type = rs.getString(rs.getColumnIndex('type')) as NotificationType;
        n.title = rs.getString(rs.getColumnIndex('title'));
        n.content = rs.getString(rs.getColumnIndex('content'));
        n.isRead = rs.getLong(rs.getColumnIndex('is_read'));
        n.createdAt = rs.getString(rs.getColumnIndex('created_at'));
        notifications.push(n);
      }
      return notifications;
    } finally {
      rs?.close();
    }
  }

  /** 根据类型筛选通知 */
  static async getByType(userId: number, type: NotificationType): Promise<Notification[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `
      SELECT * FROM notifications
      WHERE user_id = ? AND type = ?
      ORDER BY created_at DESC
    `;
    let rs: relationalStore.ResultSet | null = null;
    const notifications: Notification[] = [];
    try {
      rs = await store.querySql(sql, [userId, type]);
      while (rs.goToNextRow()) {
        const n = new Notification();
        n.notificationId = rs.getLong(rs.getColumnIndex('notification_id'));
        n.userId = rs.getLong(rs.getColumnIndex('user_id'));
        n.type = rs.getString(rs.getColumnIndex('type')) as NotificationType;
        n.title = rs.getString(rs.getColumnIndex('title'));
        n.content = rs.getString(rs.getColumnIndex('content'));
        n.isRead = rs.getLong(rs.getColumnIndex('is_read'));
        n.createdAt = rs.getString(rs.getColumnIndex('created_at'));
        notifications.push(n);
      }
      return notifications;
    } finally {
      rs?.close();
    }
  }

  /** 标记单条通知为已读 */
  static async markAsRead(notificationId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `UPDATE notifications SET is_read = 1 WHERE notification_id = ?`;
    await store.executeSql(sql, [notificationId]);
  }

  /** 标记用户所有通知为已读 */
  static async markAllAsRead(userId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `UPDATE notifications SET is_read = 1 WHERE user_id = ?`;
    await store.executeSql(sql, [userId]);
  }

  /** 获取未读通知数量 */
  static async getUnreadCount(userId: number): Promise<number> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0`;
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.querySql(sql, [userId]);
      if (rs.goToNextRow()) {
        return rs.getLong(rs.getColumnIndex('count'));
      }
      return 0;
    } finally {
      rs?.close();
    }
  }

  /** 删除通知 */
  static async delete(notificationId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `DELETE FROM notifications WHERE notification_id = ?`;
    await store.executeSql(sql, [notificationId]);
  }

  /** 清空用户所有通知 */
  static async clearAll(userId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `DELETE FROM notifications WHERE user_id = ?`;
    await store.executeSql(sql, [userId]);
  }
}
