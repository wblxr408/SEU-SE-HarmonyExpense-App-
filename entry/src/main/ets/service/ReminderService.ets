/**
 * 提醒服务
 * 提供定期账单和预算提醒功能
 * 
 * 功能：
 * - 创建和管理提醒
 * - 计算下次提醒时间
 * - 检查到期提醒
 * - 触发提醒通知
 */
import { ReminderDAO } from '../dao/ReminderDAO';
import { BudgetDAO } from '../dao/BudgetDAO';
import { Reminder } from '../model/Reminder';
import { Budget } from '../model/Budget';
import notificationManager from '@ohos.notificationManager';
import { NotificationService } from './NotificationService';

/**
 * 提醒创建选项
 */
export class ReminderCreateOptions {
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

  constructor(
    userId: number,
    type: 'bill' | 'budget',
    title: string,
    description: string,
    frequency: 'once' | 'daily' | 'weekly' | 'monthly' | 'yearly',
    reminderDate: string,
    amount?: number,
    categoryId?: number,
    accountId?: number,
    budgetId?: number
  ) {
    this.userId = userId;
    this.type = type;
    this.title = title;
    this.description = description;
    this.frequency = frequency;
    this.reminderDate = reminderDate;
    this.amount = amount;
    this.categoryId = categoryId;
    this.accountId = accountId;
    this.budgetId = budgetId;
  }
}

/**
 * 提醒通知结果
 */
export class ReminderNotificationResult {
  reminderId: number = 0;
  success: boolean = false;
  message: string = '';

  constructor(reminderId: number, success: boolean, message: string) {
    this.reminderId = reminderId;
    this.success = success;
    this.message = message;
  }
}

/**
 * 提醒统计
 */
class ReminderStatistics {
  total: number = 0;
  active: number = 0;
  billReminders: number = 0;
  budgetReminders: number = 0;
  dueToday: number = 0;

  constructor(
    total: number,
    active: number,
    billReminders: number,
    budgetReminders: number,
    dueToday: number
  ) {
    this.total = total;
    this.active = active;
    this.billReminders = billReminders;
    this.budgetReminders = budgetReminders;
    this.dueToday = dueToday;
  }
}

/**
 * 提醒服务
 */
export class ReminderService {

  /**
   * 创建提醒
   */
  static async createReminder(options: ReminderCreateOptions): Promise<number> {
    try {
      // 计算下次提醒时间
      const nextReminderDate: string = ReminderService.calculateNextReminderDate(
        options.reminderDate,
        options.frequency
      );

      const reminder: Reminder = new Reminder(
        0,
        options.userId,
        options.type,
        options.title,
        options.description,
        options.frequency,
        options.reminderDate,
        nextReminderDate,
        1, // isActive
        '',
        '',
        0, // isDeleted
        options.amount,
        options.categoryId,
        options.accountId,
        options.budgetId
      );

      const reminderId: number = await ReminderDAO.insert(reminder);
      console.log(`[ReminderService] 创建提醒成功: ${options.title} (ID: ${reminderId})`);
      return reminderId;
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error('[ReminderService] 创建提醒失败:', error);
      throw error instanceof Error ? error : new Error(`创建提醒失败: ${errorMsg}`);
    }
  }

  /**
   * 为预算创建提醒
   */
  static async createBudgetReminder(
    userId: number,
    budgetId: number,
    reminderDate: string,
    frequency: 'once' | 'monthly' = 'monthly'
  ): Promise<number> {
    try {
      // 查找预算
      const budget: Budget | null = await BudgetDAO.getById(budgetId);
      if (!budget || budget.userId !== userId) {
        const error: Error = new Error('预算不存在');
        throw error;
      }

      const options: ReminderCreateOptions = new ReminderCreateOptions(
        userId,
        'budget',
        `预算提醒`,
        `您的预算即将到期，预算金额: ${budget.amount}`,
        frequency,
        reminderDate,
        budget.amount,
        budget.categoryId,
        undefined,
        budget.budgetId
      );

      return await ReminderService.createReminder(options);
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error('[ReminderService] 创建预算提醒失败:', error);
      const err: Error = error instanceof Error ? error : new Error(`创建预算提醒失败: ${errorMsg}`);
      throw err;
    }
  }

  /**
   * 检查并触发到期的提醒
   */
  static async checkAndTriggerDueReminders(userId: number): Promise<ReminderNotificationResult[]> {
    try {
      const currentDate: string = new Date().toISOString();
      const dueReminders: Reminder[] = await ReminderDAO.getDueReminders(userId, currentDate);

      console.log(`[ReminderService] 检查到 ${dueReminders.length} 个到期提醒`);

      const results: ReminderNotificationResult[] = [];

      for (const reminder of dueReminders) {
        try {
          // 发送通知
          await ReminderService.sendNotification(reminder);

          // 更新下次提醒时间
          if (reminder.frequency !== 'once') {
            const nextDate: string = ReminderService.calculateNextReminderDate(
              reminder.nextReminderDate,
              reminder.frequency
            );
            await ReminderDAO.updateNextReminderDate(reminder.reminderId, nextDate);
          } else {
            // 一次性提醒，停用
            await ReminderDAO.setActive(reminder.reminderId, false);
          }

          results.push(new ReminderNotificationResult(reminder.reminderId, true, '提醒已触发'));
        } catch (error) {
          const errorMsg: string = error instanceof Error ? error.message : String(error);
          console.error(`[ReminderService] 触发提醒失败 (ID: ${reminder.reminderId}):`, error);
          results.push(new ReminderNotificationResult(reminder.reminderId, false, `触发失败: ${errorMsg}`));
        }
      }

      return results;
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error('[ReminderService] 检查提醒失败:', error);
      throw error instanceof Error ? error : new Error(`检查提醒失败: ${errorMsg}`);
    }
  }

  /**
   * 发送通知
   */
  private static async sendNotification(reminder: Reminder): Promise<void> {
    try {
      // 使用NotificationService发送通知并保存历史记录
      if (reminder.type === 'bill') {
        await NotificationService.sendBillReminderNotification(
          reminder.userId,
          reminder.reminderId,
          reminder.title,
          reminder.description
        );
      } else if (reminder.type === 'budget' && reminder.budgetId) {
        await NotificationService.sendBudgetReminderNotification(
          reminder.userId,
          reminder.reminderId,
          reminder.budgetId,
          reminder.title,
          reminder.description
        );
      }
      console.log(`[ReminderService] 通知已发送: ${reminder.title}`);
    } catch (error) {
      console.error('[ReminderService] 发送通知失败:', error);
      // 通知发送失败不抛出异常，记录日志即可
    }
  }

  /**
   * 计算下次提醒时间
   */
  static calculateNextReminderDate(currentDate: string, frequency: string): string {
    const date: Date = new Date(currentDate);

    switch (frequency) {
      case 'once':
        return currentDate;
      case 'daily':
        date.setDate(date.getDate() + 1);
        break;
      case 'weekly':
        date.setDate(date.getDate() + 7);
        break;
      case 'monthly':
        date.setMonth(date.getMonth() + 1);
        break;
      case 'yearly':
        date.setFullYear(date.getFullYear() + 1);
        break;
      default:
        return currentDate;
    }

    return date.toISOString();
  }

  /**
   * 获取用户的所有活跃提醒
   */
  static async getActiveReminders(userId: number): Promise<Reminder[]> {
    try {
      return await ReminderDAO.getActiveReminders(userId);
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error('[ReminderService] 获取活跃提醒失败:', error);
      throw error instanceof Error ? error : new Error(`获取活跃提醒失败: ${errorMsg}`);
    }
  }

  /**
   * 获取即将到期的提醒（未来N天内）
   */
  static async getUpcomingReminders(userId: number, days: number = 7): Promise<Reminder[]> {
    try {
      const allReminders: Reminder[] = await ReminderDAO.getActiveReminders(userId);
      const futureDate: Date = new Date();
      futureDate.setDate(futureDate.getDate() + days);
      const futureDateStr: string = futureDate.toISOString();

      return allReminders.filter(r => r.nextReminderDate <= futureDateStr);
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error('[ReminderService] 获取即将到期提醒失败:', error);
      throw error instanceof Error ? error : new Error(`获取即将到期提醒失败: ${errorMsg}`);
    }
  }

  /**
   * 更新提醒
   */
  static async updateReminder(reminder: Reminder): Promise<void> {
    try {
      await ReminderDAO.update(reminder);
      console.log(`[ReminderService] 更新提醒成功 (ID: ${reminder.reminderId})`);
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error('[ReminderService] 更新提醒失败:', error);
      throw error instanceof Error ? error : new Error(`更新提醒失败: ${errorMsg}`);
    }
  }

  /**
   * 删除提醒
   */
  static async deleteReminder(userId: number, reminderId: number): Promise<void> {
    try {
      await ReminderDAO.softDelete(userId, reminderId);
      console.log(`[ReminderService] 删除提醒成功 (ID: ${reminderId})`);
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error('[ReminderService] 删除提醒失败:', error);
      throw error instanceof Error ? error : new Error(`删除提醒失败: ${errorMsg}`);
    }
  }

  /**
   * 激活/停用提醒
   */
  static async toggleReminder(reminderId: number, isActive: boolean): Promise<void> {
    try {
      await ReminderDAO.setActive(reminderId, isActive);
      console.log(`[ReminderService] 设置提醒状态成功 (ID: ${reminderId}, active: ${isActive})`);
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error('[ReminderService] 设置提醒状态失败:', error);
      throw error instanceof Error ? error : new Error(`设置提醒状态失败: ${errorMsg}`);
    }
  }

  /**
   * 批量创建提醒
   */
  static async createBatchReminders(options: ReminderCreateOptions[]): Promise<number[]> {
    try {
      const reminderIds: number[] = [];
      for (const option of options) {
        const id: number = await ReminderService.createReminder(option);
        reminderIds.push(id);
      }
      console.log(`[ReminderService] 批量创建提醒成功，共 ${reminderIds.length} 个`);
      return reminderIds;
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error('[ReminderService] 批量创建提醒失败:', error);
      throw error instanceof Error ? error : new Error(`批量创建提醒失败: ${errorMsg}`);
    }
  }

  /**
   * 获取提醒统计
   */
  static async getReminderStatistics(userId: number): Promise<ReminderStatistics> {
    try {
      const allReminders: Reminder[] = await ReminderDAO.getByUserId(userId);
      const activeReminders: Reminder[] = allReminders.filter(r => r.isActive === 1);
      const today: string = new Date().toISOString().split('T')[0];
      const dueToday: Reminder[] = activeReminders.filter(r => r.nextReminderDate.startsWith(today));

      return new ReminderStatistics(
        allReminders.length,
        activeReminders.length,
        allReminders.filter(r => r.type === 'bill').length,
        allReminders.filter(r => r.type === 'budget').length,
        dueToday.length
      );
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error('[ReminderService] 获取提醒统计失败:', error);
      throw error instanceof Error ? error : new Error(`获取提醒统计失败: ${errorMsg}`);
    }
  }
}
