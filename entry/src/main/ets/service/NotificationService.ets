/**
 * 通知服务
 * 统一管理所有类型的通知发送和历史记录
 *
 * 通知类型：
 * - system: 系统通知（异常消费检测、共享账本）
 * - budget: 预算通知（预算优化、预算超支）
 * - sync: 同步通知（云同步、事件溯源）
 * - reminder: 提醒通知（记账提醒、账单提醒）
 */
import notificationManager from '@ohos.notificationManager';
import { NotificationHistoryDAO } from '../dao/NotificationHistoryDAO';
import { NotificationHistory } from '../model/NotificationHistory';

/**
 * 通知创建选项
 */
export class NotificationOptions {
  userId: number = 0;
  type: 'system' | 'budget' | 'sync' | 'reminder' = 'system';
  title: string = '';
  content: string = '';
  relatedType?: string;
  relatedId?: number;
  actionUrl?: string;
  sendSystemNotification: boolean = true; // 是否发送系统通知

  constructor(
    userId: number,
    type: 'system' | 'budget' | 'sync' | 'reminder',
    title: string,
    content: string,
    sendSystemNotification: boolean = true,
    relatedType?: string,
    relatedId?: number,
    actionUrl?: string
  ) {
    this.userId = userId;
    this.type = type;
    this.title = title;
    this.content = content;
    this.sendSystemNotification = sendSystemNotification;
    this.relatedType = relatedType;
    this.relatedId = relatedId;
    this.actionUrl = actionUrl;
  }
}

/**
 * 通知统计
 */
export class NotificationStatistics {
  total: number = 0;
  unread: number = 0;
  systemCount: number = 0;
  budgetCount: number = 0;
  syncCount: number = 0;
  reminderCount: number = 0;

  constructor(
    total: number,
    unread: number,
    systemCount: number,
    budgetCount: number,
    syncCount: number,
    reminderCount: number
  ) {
    this.total = total;
    this.unread = unread;
    this.systemCount = systemCount;
    this.budgetCount = budgetCount;
    this.syncCount = syncCount;
    this.reminderCount = reminderCount;
  }
}

/**
 * 通知服务
 */
export class NotificationService {

  /**
   * 发送通知
   * @param options 通知选项
   * @returns 通知ID
   */
  static async sendNotification(options: NotificationOptions): Promise<number> {
    try {
      // 1. 创建通知历史记录
      const notification = new NotificationHistory(
        0,
        options.userId,
        options.type,
        options.title,
        options.content,
        0, // 未读
        '',
        '',
        0,
        options.relatedType,
        options.relatedId,
        options.actionUrl
      );

      const notificationId = await NotificationHistoryDAO.insert(notification);
      console.log(`[NotificationService] 通知记录已保存 id=${notificationId}`);

      // 2. 发送系统通知（如果启用）
      if (options.sendSystemNotification) {
        await NotificationService.sendSystemNotification(notificationId, options.title, options.content);
      }

      return notificationId;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[NotificationService] 发送通知失败:', error);
      throw error instanceof Error ? error : new Error(`发送通知失败: ${errorMsg}`);
    }
  }

  /**
   * 发送系统通知
   */
  private static async sendSystemNotification(id: number, title: string, content: string): Promise<void> {
    try {
      const notificationRequest: notificationManager.NotificationRequest = {
        id: id,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: content
          }
        }
      };

      await notificationManager.publish(notificationRequest);
      console.log(`[NotificationService] 系统通知已发送: ${title}`);
    } catch (error) {
      console.error('[NotificationService] 发送系统通知失败:', error);
      // 系统通知失败不抛出异常，因为通知历史已保存
    }
  }

  /**
   * 获取用户所有通知
   */
  static async getNotifications(userId: number): Promise<NotificationHistory[]> {
    try {
      return await NotificationHistoryDAO.getByUserId(userId);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[NotificationService] 获取通知列表失败:', error);
      throw error instanceof Error ? error : new Error(`获取通知列表失败: ${errorMsg}`);
    }
  }

  /**
   * 按类型获取通知
   */
  static async getNotificationsByType(
    userId: number,
    type: 'system' | 'budget' | 'sync' | 'reminder'
  ): Promise<NotificationHistory[]> {
    try {
      return await NotificationHistoryDAO.getByType(userId, type);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[NotificationService] 按类型获取通知失败:', error);
      throw error instanceof Error ? error : new Error(`按类型获取通知失败: ${errorMsg}`);
    }
  }

  /**
   * 获取未读通知
   */
  static async getUnreadNotifications(userId: number): Promise<NotificationHistory[]> {
    try {
      return await NotificationHistoryDAO.getUnreadNotifications(userId);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[NotificationService] 获取未读通知失败:', error);
      throw error instanceof Error ? error : new Error(`获取未读通知失败: ${errorMsg}`);
    }
  }

  /**
   * 获取未读通知数量
   */
  static async getUnreadCount(userId: number): Promise<number> {
    try {
      return await NotificationHistoryDAO.getUnreadCount(userId);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[NotificationService] 获取未读数量失败:', error);
      throw error instanceof Error ? error : new Error(`获取未读数量失败: ${errorMsg}`);
    }
  }

  /**
   * 标记通知为已读
   */
  static async markAsRead(notificationId: number): Promise<void> {
    try {
      await NotificationHistoryDAO.markAsRead(notificationId);
      console.log(`[NotificationService] 通知已标记为已读 id=${notificationId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[NotificationService] 标记已读失败:', error);
      throw error instanceof Error ? error : new Error(`标记已读失败: ${errorMsg}`);
    }
  }

  /**
   * 标记所有通知为已读
   */
  static async markAllAsRead(userId: number): Promise<void> {
    try {
      await NotificationHistoryDAO.markAllAsRead(userId);
      console.log(`[NotificationService] 所有通知已标记为已读 userId=${userId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[NotificationService] 标记所有已读失败:', error);
      throw error instanceof Error ? error : new Error(`标记所有已读失败: ${errorMsg}`);
    }
  }

  /**
   * 删除通知
   */
  static async deleteNotification(userId: number, notificationId: number): Promise<void> {
    try {
      await NotificationHistoryDAO.softDelete(userId, notificationId);
      console.log(`[NotificationService] 通知已删除 id=${notificationId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[NotificationService] 删除通知失败:', error);
      throw error instanceof Error ? error : new Error(`删除通知失败: ${errorMsg}`);
    }
  }

  /**
   * 批量删除通知
   */
  static async batchDeleteNotifications(userId: number, notificationIds: number[]): Promise<void> {
    try {
      await NotificationHistoryDAO.batchSoftDelete(userId, notificationIds);
      console.log(`[NotificationService] 批量删除通知成功 count=${notificationIds.length}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[NotificationService] 批量删除通知失败:', error);
      throw error instanceof Error ? error : new Error(`批量删除通知失败: ${errorMsg}`);
    }
  }

  /**
   * 获取通知统计
   */
  static async getStatistics(userId: number): Promise<NotificationStatistics> {
    try {
      const allNotifications = await NotificationHistoryDAO.getByUserId(userId);
      const unreadCount = await NotificationHistoryDAO.getUnreadCount(userId);

      return new NotificationStatistics(
        allNotifications.length,
        unreadCount,
        allNotifications.filter(n => n.type === 'system').length,
        allNotifications.filter(n => n.type === 'budget').length,
        allNotifications.filter(n => n.type === 'sync').length,
        allNotifications.filter(n => n.type === 'reminder').length
      );
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[NotificationService] 获取通知统计失败:', error);
      throw error instanceof Error ? error : new Error(`获取通知统计失败: ${errorMsg}`);
    }
  }

  // ==================== 系统通知类型 ====================

  /**
   * 发送异常消费检测通知
   */
  static async sendAnomalyDetectionNotification(
    userId: number,
    anomalyId: number,
    title: string,
    description: string
  ): Promise<number> {
    const options = new NotificationOptions(
      userId,
      'system',
      `异常消费提醒: ${title}`,
      description,
      true,
      'anomaly',
      anomalyId,
      'pages/AnomalyReportPage' // 未来的异常检测报告页面
    );
    return await NotificationService.sendNotification(options);
  }

  /**
   * 发送共享账本通知
   */
  static async sendSharedLedgerNotification(
    userId: number,
    ledgerId: number,
    title: string,
    content: string
  ): Promise<number> {
    const options = new NotificationOptions(
      userId,
      'system',
      `账本通知: ${title}`,
      content,
      true,
      'shared_ledger',
      ledgerId,
      'pages/SharedLedgerPage' // 未来的共享账本页面
    );
    return await NotificationService.sendNotification(options);
  }

  // ==================== 预算通知类型 ====================

  /**
   * 发送预算优化建议通知
   */
  static async sendBudgetOptimizationNotification(
    userId: number,
    budgetPlanId: number,
    title: string,
    suggestion: string
  ): Promise<number> {
    const options = new NotificationOptions(
      userId,
      'budget',
      `预算建议: ${title}`,
      suggestion,
      true,
      'budget_plan',
      budgetPlanId,
      'pages/SmartBudgetPage' // 未来的智能预算页面
    );
    return await NotificationService.sendNotification(options);
  }

  /**
   * 发送预算超支通知
   */
  static async sendBudgetOverspendNotification(
    userId: number,
    budgetId: number,
    categoryName: string,
    used: number,
    total: number,
    percentage: number
  ): Promise<number> {
    const options = new NotificationOptions(
      userId,
      'budget',
      `预算超支提醒`,
      `您的"${categoryName}"预算已使用 ${percentage.toFixed(0)}%（${used}/${total}元）`,
      true,
      'budget',
      budgetId,
      'pages/BudgetManagement'
    );
    return await NotificationService.sendNotification(options);
  }

  /**
   * 发送预算即将超支通知
   */
  static async sendBudgetWarningNotification(
    userId: number,
    budgetId: number,
    categoryName: string,
    used: number,
    total: number,
    percentage: number
  ): Promise<number> {
    const options = new NotificationOptions(
      userId,
      'budget',
      `预算预警`,
      `您的"${categoryName}"预算已使用 ${percentage.toFixed(0)}%（${used}/${total}元），请注意控制支出`,
      true,
      'budget',
      budgetId,
      'pages/BudgetManagement'
    );
    return await NotificationService.sendNotification(options);
  }

  // ==================== 同步通知类型 ====================

  /**
   * 发送云同步通知
   */
  static async sendCloudSyncNotification(
    userId: number,
    syncRecordId: number,
    success: boolean,
    message: string
  ): Promise<number> {
    const options = new NotificationOptions(
      userId,
      'sync',
      success ? '云同步成功' : '云同步失败',
      message,
      !success, // 只有失败时才发系统通知
      'cloud_sync',
      syncRecordId,
      'pages/SyncSettingsPage'
    );
    return await NotificationService.sendNotification(options);
  }

  /**
   * 发送事件溯源通知
   */
  static async sendEventSourcingNotification(
    userId: number,
    eventId: string,
    eventType: string,
    description: string
  ): Promise<number> {
    const options = new NotificationOptions(
      userId,
      'sync',
      `数据变更: ${eventType}`,
      description,
      false, // 事件溯源通知不发送系统通知
      'event',
      0,
      'pages/EventHistoryPage' // 未来的事件历史页面
    );
    return await NotificationService.sendNotification(options);
  }

  // ==================== 提醒通知类型 ====================

  /**
   * 发送记账提醒通知
   */
  static async sendBillReminderNotification(
    userId: number,
    reminderId: number,
    title: string,
    description: string
  ): Promise<number> {
    const options = new NotificationOptions(
      userId,
      'reminder',
      title,
      description,
      true,
      'reminder',
      reminderId,
      'pages/AddBill'
    );
    return await NotificationService.sendNotification(options);
  }

  /**
   * 发送预算提醒通知
   */
  static async sendBudgetReminderNotification(
    userId: number,
    reminderId: number,
    budgetId: number,
    title: string,
    description: string
  ): Promise<number> {
    const options = new NotificationOptions(
      userId,
      'reminder',
      title,
      description,
      true,
      'reminder',
      reminderId,
      'pages/BudgetManagement'
    );
    return await NotificationService.sendNotification(options);
  }
}
