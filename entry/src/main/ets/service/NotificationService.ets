/**
 * 通知服务
 * 封装通知的业务逻辑
 */
import { Notification, NotificationType } from '../model/Notification';
import { NotificationDAO } from '../dao/NotificationDAO';
import { UserSessionService } from './UserSessionService';

export class NotificationService {

  /**
   * 推送新通知
   * @param type 通知类型
   * @param title 标题
   * @param content 内容
   */
  static async push(type: NotificationType, title: string, content: string): Promise<boolean> {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) {
      console.error('[NotificationService] 未登录，无法推送通知');
      return false;
    }

    try {
      const notification = new Notification(0, userId, type, title, content, 0, '');
      await NotificationDAO.insert(notification);
      console.log(`[NotificationService] 通知已推送: ${title}`);
      return true;
    } catch (error) {
      console.error('[NotificationService] 推送通知失败:', error);
      return false;
    }
  }

  /**
   * 获取当前用户的通知列表
   * @param limit 数量限制
   */
  static async getNotifications(limit: number = 50): Promise<Notification[]> {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) {
      return [];
    }
    return await NotificationDAO.getByUserId(userId, limit);
  }

  /**
   * 根据类型筛选通知
   * @param type 通知类型
   */
  static async getByType(type: NotificationType): Promise<Notification[]> {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) {
      return [];
    }
    return await NotificationDAO.getByType(userId, type);
  }

  /**
   * 标记通知为已读
   * @param notificationId 通知ID
   */
  static async markAsRead(notificationId: number): Promise<void> {
    await NotificationDAO.markAsRead(notificationId);
  }

  /**
   * 标记所有通知为已读
   */
  static async markAllAsRead(): Promise<void> {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) {
      return;
    }
    await NotificationDAO.markAllAsRead(userId);
  }

  /**
   * 获取未读通知数量
   */
  static async getUnreadCount(): Promise<number> {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) {
      return 0;
    }
    return await NotificationDAO.getUnreadCount(userId);
  }

  /**
   * 清空所有通知
   */
  static async clearAll(): Promise<void> {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) {
      return;
    }
    await NotificationDAO.clearAll(userId);
  }
}
