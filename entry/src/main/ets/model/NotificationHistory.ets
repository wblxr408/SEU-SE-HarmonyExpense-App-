/**
 * 通知历史记录模型
 * 用于记录所有发送给用户的通知
 */

export interface NotificationHistoryJSON {
  notificationId: number;
  userId: number;
  type: 'system' | 'budget' | 'sync' | 'reminder';
  title: string;
  content: string;
  isRead: number;
  relatedType?: string;
  relatedId?: number;
  actionUrl?: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

export class NotificationHistory {
  static readonly tableName: string = 'notification_history';

  notificationId: number = 0;
  userId: number = 0;
  type: 'system' | 'budget' | 'sync' | 'reminder' = 'system';
  title: string = '';
  content: string = '';
  isRead: number = 0; // 0=未读, 1=已读
  relatedType?: string; // 关联对象类型: anomaly, shared_ledger, budget_plan, cloud_sync, event, reminder
  relatedId?: number; // 关联对象ID
  actionUrl?: string; // 点击通知后跳转的页面路径
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0; // 0=未删除, 1=已删除

  constructor(
    notificationId: number = 0,
    userId: number = 0,
    type: 'system' | 'budget' | 'sync' | 'reminder' = 'system',
    title: string = '',
    content: string = '',
    isRead: number = 0,
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0,
    relatedType?: string,
    relatedId?: number,
    actionUrl?: string
  ) {
    this.notificationId = notificationId;
    this.userId = userId;
    this.type = type;
    this.title = title;
    this.content = content;
    this.isRead = isRead;
    this.relatedType = relatedType;
    this.relatedId = relatedId;
    this.actionUrl = actionUrl;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  toJSON(): NotificationHistoryJSON {
    return {
      notificationId: this.notificationId,
      userId: this.userId,
      type: this.type,
      title: this.title,
      content: this.content,
      isRead: this.isRead,
      relatedType: this.relatedType,
      relatedId: this.relatedId,
      actionUrl: this.actionUrl,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
  }

  static fromJSON(data: NotificationHistoryJSON): NotificationHistory {
    return new NotificationHistory(
      data.notificationId,
      data.userId,
      data.type,
      data.title,
      data.content,
      data.isRead,
      data.createdAt,
      data.updatedAt,
      data.isDeleted ?? 0,
      data.relatedType,
      data.relatedId,
      data.actionUrl
    );
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      this.title !== '' &&
      this.content !== '' &&
      ['system', 'budget', 'sync', 'reminder'].includes(this.type) &&
      (this.isRead === 0 || this.isRead === 1) &&
      (this.isDeleted === 0 || this.isDeleted === 1)
    );
  }

  clone(): NotificationHistory {
    return NotificationHistory.fromJSON(this.toJSON());
  }
}
