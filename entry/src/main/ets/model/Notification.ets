/**
 * 通知模型
 * 用于存储系统通知、预算提醒、同步状态等消息
 */

/**
 * 通知类型枚举
 */
export enum NotificationType {
  SYSTEM = 'SYSTEM',           // 系统通知
  BUDGET_ALERT = 'BUDGET_ALERT', // 预算警报
  SYNC_STATUS = 'SYNC_STATUS',   // 同步状态
  REMINDER = 'REMINDER'          // 提醒
}

/**
 * 通知 JSON 接口
 */
export interface NotificationJSON {
  notificationId: number;
  userId: number;
  type: string;
  title: string;
  content: string;
  isRead: number;
  createdAt: string;
}

/**
 * 通知类
 */
export class Notification {
  static readonly tableName: string = 'notifications';

  notificationId: number = 0;
  userId: number = 0;
  type: NotificationType = NotificationType.SYSTEM;
  title: string = '';
  content: string = '';
  isRead: number = 0; // 0=未读, 1=已读
  createdAt: string = '';

  constructor(
    notificationId: number = 0,
    userId: number = 0,
    type: NotificationType = NotificationType.SYSTEM,
    title: string = '',
    content: string = '',
    isRead: number = 0,
    createdAt: string = ''
  ) {
    this.notificationId = notificationId;
    this.userId = userId;
    this.type = type;
    this.title = title;
    this.content = content;
    this.isRead = isRead;
    this.createdAt = createdAt;
  }

  toJSON(): NotificationJSON {
    return {
      notificationId: this.notificationId,
      userId: this.userId,
      type: this.type,
      title: this.title,
      content: this.content,
      isRead: this.isRead,
      createdAt: this.createdAt
    };
  }

  static fromJSON(data: NotificationJSON): Notification {
    return new Notification(
      data.notificationId,
      data.userId,
      data.type as NotificationType,
      data.title,
      data.content,
      data.isRead,
      data.createdAt
    );
  }
}
