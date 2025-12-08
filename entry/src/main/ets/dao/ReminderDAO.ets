/**
 * 提醒数据访问对象（DAO）
 * 提供对 reminders 表的CRUD操作
 */
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { Reminder, ReminderJSON } from '../model/Reminder';
import { DAOHelper } from '../common/DAOHelper';

export class ReminderDAO {

  /**
   * 将 ResultSet 的一行数据映射为 Reminder 对象
   */
  private static mapRowToReminder(resultSet: relationalStore.ResultSet): Reminder {
    try {
      const row: ReminderJSON = {
        reminderId: DAOHelper.getLong(resultSet, 'reminder_id'),
        userId: DAOHelper.getLong(resultSet, 'user_id'),
        type: DAOHelper.getString(resultSet, 'type') as 'bill' | 'budget',
        title: DAOHelper.getString(resultSet, 'title'),
        description: DAOHelper.getString(resultSet, 'description'),
        frequency: DAOHelper.getString(resultSet, 'frequency') as 'once' | 'daily' | 'weekly' | 'monthly' | 'yearly',
        reminderDate: DAOHelper.getString(resultSet, 'reminder_date'),
        nextReminderDate: DAOHelper.getString(resultSet, 'next_reminder_date'),
        isActive: DAOHelper.getLong(resultSet, 'is_active'),
        createdAt: DAOHelper.getString(resultSet, 'created_at'),
        updatedAt: DAOHelper.getString(resultSet, 'updated_at'),
        isDeleted: DAOHelper.getLong(resultSet, 'is_deleted')
      };

      // 可选字段
      const amountIndex = resultSet.getColumnIndex('amount');
      if (amountIndex >= 0 && !resultSet.isColumnNull(amountIndex)) {
        row.amount = resultSet.getDouble(amountIndex);
      }

      const categoryIdIndex = resultSet.getColumnIndex('category_id');
      if (categoryIdIndex >= 0 && !resultSet.isColumnNull(categoryIdIndex)) {
        row.categoryId = resultSet.getLong(categoryIdIndex);
      }

      const accountIdIndex = resultSet.getColumnIndex('account_id');
      if (accountIdIndex >= 0 && !resultSet.isColumnNull(accountIdIndex)) {
        row.accountId = resultSet.getLong(accountIdIndex);
      }

      const budgetIdIndex = resultSet.getColumnIndex('budget_id');
      if (budgetIdIndex >= 0 && !resultSet.isColumnNull(budgetIdIndex)) {
        row.budgetId = resultSet.getLong(budgetIdIndex);
      }

      return Reminder.fromJSON(row);
    } catch (error) {
      throw DAOHelper.toError('[ReminderDAO] 映射数据失败', error);
    }
  }

  /**
   * 插入提醒记录
   */
  static async insert(reminder: Reminder): Promise<number> {
    if (!reminder.validate()) {
      throw new Error('[ReminderDAO] 插入失败，数据验证不通过');
    }

    const now = DAOHelper.now();
    reminder.createdAt = now;
    reminder.updatedAt = now;

    const store = DatabaseManager.getDatabase();
    const valueBucket: relationalStore.ValuesBucket = {
      user_id: reminder.userId,
      type: reminder.type,
      title: reminder.title,
      description: reminder.description,
      frequency: reminder.frequency,
      reminder_date: reminder.reminderDate,
      next_reminder_date: reminder.nextReminderDate,
      is_active: reminder.isActive,
      created_at: reminder.createdAt,
      updated_at: reminder.updatedAt,
      is_deleted: reminder.isDeleted
    };

    // 可选字段
    if (reminder.amount !== undefined) valueBucket.amount = reminder.amount;
    if (reminder.categoryId !== undefined) valueBucket.category_id = reminder.categoryId;
    if (reminder.accountId !== undefined) valueBucket.account_id = reminder.accountId;
    if (reminder.budgetId !== undefined) valueBucket.budget_id = reminder.budgetId;

    try {
      const rowId = await store.insert(Reminder.tableName, valueBucket) as number;
      console.log(`[ReminderDAO] 插入成功 id=${rowId}`);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[ReminderDAO] 插入失败', error);
    }
  }

  /**
   * 根据ID查询提醒
   */
  static async getById(userId: number, reminderId: number): Promise<Reminder | null> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT * FROM ${Reminder.tableName} WHERE user_id = ? AND reminder_id = ? AND is_deleted = 0`;
    let rs: relationalStore.ResultSet | null = null;

    try {
      rs = await store.querySql(sql, [userId, reminderId]);
      if (!rs.goToNextRow()) {
        return null;
      }
      return ReminderDAO.mapRowToReminder(rs);
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 查询用户的所有提醒
   */
  static async getByUserId(userId: number): Promise<Reminder[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT * FROM ${Reminder.tableName} WHERE user_id = ? AND is_deleted = 0 ORDER BY next_reminder_date ASC`;
    let rs: relationalStore.ResultSet | null = null;
    const list: Reminder[] = [];

    try {
      rs = await store.querySql(sql, [userId]);
      while (rs.goToNextRow()) {
        list.push(ReminderDAO.mapRowToReminder(rs));
      }
      return list;
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 查询活跃的提醒
   */
  static async getActiveReminders(userId: number): Promise<Reminder[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT * FROM ${Reminder.tableName} 
                 WHERE user_id = ? AND is_active = 1 AND is_deleted = 0 
                 ORDER BY next_reminder_date ASC`;
    let rs: relationalStore.ResultSet | null = null;
    const list: Reminder[] = [];

    try {
      rs = await store.querySql(sql, [userId]);
      while (rs.goToNextRow()) {
        list.push(ReminderDAO.mapRowToReminder(rs));
      }
      return list;
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 查询到期的提醒（需要触发的）
   */
  static async getDueReminders(userId: number, currentDate: string): Promise<Reminder[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT * FROM ${Reminder.tableName} 
                 WHERE user_id = ? AND is_active = 1 AND is_deleted = 0 
                 AND next_reminder_date <= ? 
                 ORDER BY next_reminder_date ASC`;
    let rs: relationalStore.ResultSet | null = null;
    const list: Reminder[] = [];

    try {
      rs = await store.querySql(sql, [userId, currentDate]);
      while (rs.goToNextRow()) {
        list.push(ReminderDAO.mapRowToReminder(rs));
      }
      return list;
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 按类型查询提醒
   */
  static async getByType(userId: number, type: 'bill' | 'budget'): Promise<Reminder[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT * FROM ${Reminder.tableName} 
                 WHERE user_id = ? AND type = ? AND is_deleted = 0 
                 ORDER BY next_reminder_date ASC`;
    let rs: relationalStore.ResultSet | null = null;
    const list: Reminder[] = [];

    try {
      rs = await store.querySql(sql, [userId, type]);
      while (rs.goToNextRow()) {
        list.push(ReminderDAO.mapRowToReminder(rs));
      }
      return list;
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 更新提醒
   */
  static async update(reminder: Reminder): Promise<void> {
    if (!reminder.validate()) {
      throw new Error('[ReminderDAO] 更新失败，数据验证不通过');
    }

    const store = DatabaseManager.getDatabase();
    reminder.updatedAt = DAOHelper.now();

    const valueBucket: relationalStore.ValuesBucket = {
      type: reminder.type,
      title: reminder.title,
      description: reminder.description,
      frequency: reminder.frequency,
      reminder_date: reminder.reminderDate,
      next_reminder_date: reminder.nextReminderDate,
      is_active: reminder.isActive,
      updated_at: reminder.updatedAt
    };

    // 可选字段
    if (reminder.amount !== undefined) valueBucket.amount = reminder.amount;
    if (reminder.categoryId !== undefined) valueBucket.category_id = reminder.categoryId;
    if (reminder.accountId !== undefined) valueBucket.account_id = reminder.accountId;
    if (reminder.budgetId !== undefined) valueBucket.budget_id = reminder.budgetId;

    const predicates = new relationalStore.RdbPredicates(Reminder.tableName);
    predicates.equalTo('reminder_id', reminder.reminderId);

    try {
      await store.update(valueBucket, predicates);
      console.log(`[ReminderDAO] 更新成功 id=${reminder.reminderId}`);
    } catch (error) {
      throw DAOHelper.toError('[ReminderDAO] 更新失败', error);
    }
  }

  /**
   * 更新下次提醒时间
   */
  static async updateNextReminderDate(reminderId: number, nextDate: string): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `UPDATE ${Reminder.tableName} 
                 SET next_reminder_date = ?, updated_at = ? 
                 WHERE reminder_id = ?`;

    try {
      await store.executeSql(sql, [nextDate, DAOHelper.now(), reminderId]);
      console.log(`[ReminderDAO] 更新下次提醒时间成功 id=${reminderId}`);
    } catch (error) {
      throw DAOHelper.toError('[ReminderDAO] 更新下次提醒时间失败', error);
    }
  }

  /**
   * 激活/停用提醒
   */
  static async setActive(reminderId: number, isActive: boolean): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `UPDATE ${Reminder.tableName} 
                 SET is_active = ?, updated_at = ? 
                 WHERE reminder_id = ?`;

    try {
      await store.executeSql(sql, [isActive ? 1 : 0, DAOHelper.now(), reminderId]);
      console.log(`[ReminderDAO] 设置提醒状态成功 id=${reminderId}, active=${isActive}`);
    } catch (error) {
      throw DAOHelper.toError('[ReminderDAO] 设置提醒状态失败', error);
    }
  }

  /**
   * 软删除提醒
   */
  static async softDelete(userId: number, reminderId: number): Promise<void> {
    await DAOHelper.softDelete(Reminder.tableName, 'reminder_id', reminderId, '[ReminderDAO]');
  }

  /**
   * 恢复软删除的提醒
   */
  static async restore(userId: number, reminderId: number): Promise<void> {
    await DAOHelper.restore(Reminder.tableName, 'reminder_id', reminderId, '[ReminderDAO]');
  }

  /**
   * 批量插入提醒
   */
  static async insertMany(reminders: Reminder[]): Promise<void> {
    await DAOHelper.transaction(async () => {
      for (const reminder of reminders) {
        await ReminderDAO.insert(reminder);
      }
    }, '[ReminderDAO] 批量插入');
  }

  /**
   * 检查提醒是否存在
   */
  static async exists(reminderId: number): Promise<boolean> {
    return await DAOHelper.exists(Reminder.tableName, 'reminder_id', reminderId);
  }
}
