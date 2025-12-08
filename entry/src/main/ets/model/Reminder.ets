/**
 * 提醒记录模型
 * 用于定期账单和预算提醒功能
 */

export interface ReminderJSON {
  reminderId: number;
  userId: number;
  type: 'bill' | 'budget';
  title: string;
  description: string;
  amount?: number;
  categoryId?: number;
  accountId?: number;
  budgetId?: number;
  frequency: 'once' | 'daily' | 'weekly' | 'monthly' | 'yearly';
  reminderDate: string;
  nextReminderDate: string;
  isActive: number;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

export class Reminder {
  static readonly tableName: string = 'reminders';

  reminderId: number = 0;
  userId: number = 0;
  type: 'bill' | 'budget' = 'bill';
  title: string = '';
  description: string = '';
  amount?: number;
  categoryId?: number;
  accountId?: number;
  budgetId?: number;
  frequency: 'once' | 'daily' | 'weekly' | 'monthly' | 'yearly' = 'once';
  reminderDate: string = '';
  nextReminderDate: string = '';
  isActive: number = 1;
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    reminderId: number = 0,
    userId: number = 0,
    type: 'bill' | 'budget' = 'bill',
    title: string = '',
    description: string = '',
    frequency: 'once' | 'daily' | 'weekly' | 'monthly' | 'yearly' = 'once',
    reminderDate: string = '',
    nextReminderDate: string = '',
    isActive: number = 1,
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0,
    amount?: number,
    categoryId?: number,
    accountId?: number,
    budgetId?: number
  ) {
    this.reminderId = reminderId;
    this.userId = userId;
    this.type = type;
    this.title = title;
    this.description = description;
    this.amount = amount;
    this.categoryId = categoryId;
    this.accountId = accountId;
    this.budgetId = budgetId;
    this.frequency = frequency;
    this.reminderDate = reminderDate;
    this.nextReminderDate = nextReminderDate;
    this.isActive = isActive;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  toJSON(): ReminderJSON {
    return {
      reminderId: this.reminderId,
      userId: this.userId,
      type: this.type,
      title: this.title,
      description: this.description,
      amount: this.amount,
      categoryId: this.categoryId,
      accountId: this.accountId,
      budgetId: this.budgetId,
      frequency: this.frequency,
      reminderDate: this.reminderDate,
      nextReminderDate: this.nextReminderDate,
      isActive: this.isActive,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
  }

  static fromJSON(data: ReminderJSON): Reminder {
    return new Reminder(
      data.reminderId,
      data.userId,
      data.type,
      data.title,
      data.description,
      data.frequency,
      data.reminderDate,
      data.nextReminderDate,
      data.isActive,
      data.createdAt,
      data.updatedAt,
      data.isDeleted ?? 0,
      data.amount,
      data.categoryId,
      data.accountId,
      data.budgetId
    );
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      this.title !== '' &&
      ['bill', 'budget'].includes(this.type) &&
      ['once', 'daily', 'weekly', 'monthly', 'yearly'].includes(this.frequency) &&
      this.reminderDate !== '' &&
      (this.isActive === 0 || this.isActive === 1) &&
      (this.isDeleted === 0 || this.isDeleted === 1)
    );
  }

  clone(): Reminder {
    return Reminder.fromJSON(this.toJSON());
  }
}
