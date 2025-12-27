/**
 * 通知历史数据访问对象（DAO）
 * 提供对 notification_history 表的CRUD操作
 */
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { NotificationHistory, NotificationHistoryJSON } from '../model/NotificationHistory';
import { DAOHelper } from '../common/DAOHelper';

export class NotificationHistoryDAO {

  /**
   * 将 ResultSet 的一行数据映射为 NotificationHistory 对象
   */
  private static mapRowToNotification(resultSet: relationalStore.ResultSet): NotificationHistory {
    try {
      const row: NotificationHistoryJSON = {
        notificationId: DAOHelper.getLong(resultSet, 'notification_id'),
        userId: DAOHelper.getLong(resultSet, 'user_id'),
        type: DAOHelper.getString(resultSet, 'type') as 'system' | 'budget' | 'sync' | 'reminder',
        title: DAOHelper.getString(resultSet, 'title'),
        content: DAOHelper.getString(resultSet, 'content'),
        isRead: DAOHelper.getLong(resultSet, 'is_read'),
        createdAt: DAOHelper.getString(resultSet, 'created_at'),
        updatedAt: DAOHelper.getString(resultSet, 'updated_at'),
        isDeleted: DAOHelper.getLong(resultSet, 'is_deleted')
      };

      // 可选字段
      const relatedTypeIndex = resultSet.getColumnIndex('related_type');
      if (relatedTypeIndex >= 0 && !resultSet.isColumnNull(relatedTypeIndex)) {
        row.relatedType = resultSet.getString(relatedTypeIndex);
      }

      const relatedIdIndex = resultSet.getColumnIndex('related_id');
      if (relatedIdIndex >= 0 && !resultSet.isColumnNull(relatedIdIndex)) {
        row.relatedId = resultSet.getLong(relatedIdIndex);
      }

      const actionUrlIndex = resultSet.getColumnIndex('action_url');
      if (actionUrlIndex >= 0 && !resultSet.isColumnNull(actionUrlIndex)) {
        row.actionUrl = resultSet.getString(actionUrlIndex);
      }

      return NotificationHistory.fromJSON(row);
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 映射数据失败', error);
    }
  }

  /**
   * 插入通知记录
   */
  static async insert(notification: NotificationHistory): Promise<number> {
    if (!notification.validate()) {
      throw new Error('[NotificationHistoryDAO] 插入失败，数据验证不通过');
    }

    const now = DAOHelper.now();
    notification.createdAt = now;
    notification.updatedAt = now;

    const store = DatabaseManager.getDatabase();
    const valueBucket: relationalStore.ValuesBucket = {
      user_id: notification.userId,
      type: notification.type,
      title: notification.title,
      content: notification.content,
      is_read: notification.isRead,
      created_at: notification.createdAt,
      updated_at: notification.updatedAt,
      is_deleted: notification.isDeleted
    };

    // 可选字段
    if (notification.relatedType !== undefined) valueBucket.related_type = notification.relatedType;
    if (notification.relatedId !== undefined) valueBucket.related_id = notification.relatedId;
    if (notification.actionUrl !== undefined) valueBucket.action_url = notification.actionUrl;

    try {
      const rowId = await store.insert(NotificationHistory.tableName, valueBucket) as number;
      console.log(`[NotificationHistoryDAO] 插入通知成功 id=${rowId}`);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 插入失败', error);
    }
  }

  /**
   * 根据ID查询通知
   */
  static async getById(notificationId: number): Promise<NotificationHistory | null> {
    const store = DatabaseManager.getDatabase();
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('notification_id', notificationId);

    try {
      const resultSet = await store.query(predicates);
      if (resultSet.goToFirstRow()) {
        const notification = NotificationHistoryDAO.mapRowToNotification(resultSet);
        resultSet.close();
        return notification;
      }
      resultSet.close();
      return null;
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 查询失败', error);
    }
  }

  /**
   * 获取用户所有通知（未删除）
   */
  static async getByUserId(userId: number): Promise<NotificationHistory[]> {
    const store = DatabaseManager.getDatabase();
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('user_id', userId).and().equalTo('is_deleted', 0);
    predicates.orderByDesc('created_at');

    try {
      const resultSet = await store.query(predicates);
      const notifications: NotificationHistory[] = [];
      while (resultSet.goToNextRow()) {
        notifications.push(NotificationHistoryDAO.mapRowToNotification(resultSet));
      }
      resultSet.close();
      return notifications;
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 查询用户通知失败', error);
    }
  }

  /**
   * 按类型获取用户通知
   */
  static async getByType(userId: number, type: 'system' | 'budget' | 'sync' | 'reminder'): Promise<NotificationHistory[]> {
    const store = DatabaseManager.getDatabase();
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('user_id', userId)
      .and().equalTo('type', type)
      .and().equalTo('is_deleted', 0);
    predicates.orderByDesc('created_at');

    try {
      const resultSet = await store.query(predicates);
      const notifications: NotificationHistory[] = [];
      while (resultSet.goToNextRow()) {
        notifications.push(NotificationHistoryDAO.mapRowToNotification(resultSet));
      }
      resultSet.close();
      return notifications;
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 按类型查询通知失败', error);
    }
  }

  /**
   * 获取未读通知数量
   */
  static async getUnreadCount(userId: number): Promise<number> {
    const store = DatabaseManager.getDatabase();
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('user_id', userId)
      .and().equalTo('is_read', 0)
      .and().equalTo('is_deleted', 0);

    try {
      const resultSet = await store.query(predicates);
      const count = resultSet.rowCount;
      resultSet.close();
      return count;
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 获取未读数量失败', error);
    }
  }

  /**
   * 获取未读通知列表
   */
  static async getUnreadNotifications(userId: number): Promise<NotificationHistory[]> {
    const store = DatabaseManager.getDatabase();
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('user_id', userId)
      .and().equalTo('is_read', 0)
      .and().equalTo('is_deleted', 0);
    predicates.orderByDesc('created_at');

    try {
      const resultSet = await store.query(predicates);
      const notifications: NotificationHistory[] = [];
      while (resultSet.goToNextRow()) {
        notifications.push(NotificationHistoryDAO.mapRowToNotification(resultSet));
      }
      resultSet.close();
      return notifications;
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 查询未读通知失败', error);
    }
  }

  /**
   * 标记通知为已读
   */
  static async markAsRead(notificationId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const valueBucket: relationalStore.ValuesBucket = {
      is_read: 1,
      updated_at: DAOHelper.now()
    };
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('notification_id', notificationId);

    try {
      await store.update(valueBucket, predicates);
      console.log(`[NotificationHistoryDAO] 标记已读成功 id=${notificationId}`);
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 标记已读失败', error);
    }
  }

  /**
   * 标记所有通知为已读
   */
  static async markAllAsRead(userId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const valueBucket: relationalStore.ValuesBucket = {
      is_read: 1,
      updated_at: DAOHelper.now()
    };
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('user_id', userId).and().equalTo('is_read', 0);

    try {
      await store.update(valueBucket, predicates);
      console.log(`[NotificationHistoryDAO] 标记所有已读成功 userId=${userId}`);
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 标记所有已读失败', error);
    }
  }

  /**
   * 更新通知
   */
  static async update(notification: NotificationHistory): Promise<void> {
    if (!notification.validate()) {
      throw new Error('[NotificationHistoryDAO] 更新失败，数据验证不通过');
    }

    notification.updatedAt = DAOHelper.now();

    const store = DatabaseManager.getDatabase();
    const valueBucket: relationalStore.ValuesBucket = {
      user_id: notification.userId,
      type: notification.type,
      title: notification.title,
      content: notification.content,
      is_read: notification.isRead,
      updated_at: notification.updatedAt,
      is_deleted: notification.isDeleted
    };

    // 可选字段
    if (notification.relatedType !== undefined) valueBucket.related_type = notification.relatedType;
    if (notification.relatedId !== undefined) valueBucket.related_id = notification.relatedId;
    if (notification.actionUrl !== undefined) valueBucket.action_url = notification.actionUrl;

    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('notification_id', notification.notificationId);

    try {
      await store.update(valueBucket, predicates);
      console.log(`[NotificationHistoryDAO] 更新成功 id=${notification.notificationId}`);
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 更新失败', error);
    }
  }

  /**
   * 软删除通知
   */
  static async softDelete(userId: number, notificationId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const valueBucket: relationalStore.ValuesBucket = {
      is_deleted: 1,
      updated_at: DAOHelper.now()
    };
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('notification_id', notificationId).and().equalTo('user_id', userId);

    try {
      await store.update(valueBucket, predicates);
      console.log(`[NotificationHistoryDAO] 软删除成功 id=${notificationId}`);
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 软删除失败', error);
    }
  }

  /**
   * 批量软删除通知
   */
  static async batchSoftDelete(userId: number, notificationIds: number[]): Promise<void> {
    if (notificationIds.length === 0) return;

    const store = DatabaseManager.getDatabase();
    const valueBucket: relationalStore.ValuesBucket = {
      is_deleted: 1,
      updated_at: DAOHelper.now()
    };
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('user_id', userId).and().in('notification_id', notificationIds);

    try {
      await store.update(valueBucket, predicates);
      console.log(`[NotificationHistoryDAO] 批量软删除成功 count=${notificationIds.length}`);
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 批量软删除失败', error);
    }
  }

  /**
   * 物理删除通知
   */
  static async hardDelete(userId: number, notificationId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('notification_id', notificationId).and().equalTo('user_id', userId);

    try {
      await store.delete(predicates);
      console.log(`[NotificationHistoryDAO] 物理删除成功 id=${notificationId}`);
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 物理删除失败', error);
    }
  }

  /**
   * 清理已删除的通知（物理删除所有软删除的记录）
   */
  static async cleanupDeleted(userId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.equalTo('user_id', userId).and().equalTo('is_deleted', 1);

    try {
      const count = await store.delete(predicates);
      console.log(`[NotificationHistoryDAO] 清理已删除通知成功 count=${count}`);
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 清理已删除通知失败', error);
    }
  }

  /**
   * 获取所有通知（包括已删除，用于调试）
   */
  static async getAll(): Promise<NotificationHistory[]> {
    const store = DatabaseManager.getDatabase();
    const predicates = new relationalStore.RdbPredicates(NotificationHistory.tableName);
    predicates.orderByDesc('created_at');

    try {
      const resultSet = await store.query(predicates);
      const notifications: NotificationHistory[] = [];
      while (resultSet.goToNextRow()) {
        notifications.push(NotificationHistoryDAO.mapRowToNotification(resultSet));
      }
      resultSet.close();
      return notifications;
    } catch (error) {
      throw DAOHelper.toError('[NotificationHistoryDAO] 查询所有通知失败', error);
    }
  }
}
