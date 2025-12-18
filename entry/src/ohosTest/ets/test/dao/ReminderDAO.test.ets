import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { ReminderDAO } from '../../../../main/ets/dao/ReminderDAO';
import { Reminder } from '../../../../main/ets/model/Reminder';
import { DatabaseManager } from '../../../../main/ets/database/DatabaseManager';
import common from '@ohos.app.ability.common';

function getTestContext(): common.Context {
  return getContext() as common.Context;
}

export default function ReminderDAOTest(): void {
  describe('ReminderDAO_CRUD', () => {
    const testUserId: number = 1;

    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should_insert_and_get_reminder', 0, async () => {
      const now = new Date().toISOString();
      const reminder = new Reminder(
        0,
        testUserId,
        'bill',
        '测试提醒',
        '这是一个测试提醒',
        'once',
        now,
        now,
        1,
        now,
        now,
        0,
        100.0,
        1,
        1
      );
      const rowId = await ReminderDAO.insert(reminder);
      expect(rowId > 0).assertTrue();
      
      const retrieved = await ReminderDAO.getById(testUserId, rowId);
      expect(retrieved !== null).assertTrue();
      if (retrieved) {
        expect(retrieved.title).assertEqual('测试提醒');
        expect(retrieved.type).assertEqual('bill');
      }
    });

    it('should_get_all_reminders_by_user', 0, async () => {
      const reminders = await ReminderDAO.getByUserId(testUserId);
      expect(Array.isArray(reminders)).assertTrue();
    });

    it('should_get_active_reminders', 0, async () => {
      const reminders = await ReminderDAO.getActiveReminders(testUserId);
      expect(Array.isArray(reminders)).assertTrue();
    });

    it('should_update_reminder', 0, async () => {
      const reminders = await ReminderDAO.getByUserId(testUserId);
      if (reminders.length > 0) {
        const reminder = reminders[0];
        reminder.title = '更新后的提醒';
        await ReminderDAO.update(reminder);
        
        const updated = await ReminderDAO.getById(testUserId, reminder.reminderId);
        expect(updated !== null).assertTrue();
        if (updated) {
          expect(updated.title).assertEqual('更新后的提醒');
        }
      }
    });

    it('should_soft_delete_reminder', 0, async () => {
      const reminders = await ReminderDAO.getByUserId(testUserId);
      if (reminders.length > 0) {
        const reminder = reminders[0];
        await ReminderDAO.softDelete(testUserId, reminder.reminderId);
        
        const deleted = await ReminderDAO.getById(testUserId, reminder.reminderId);
        expect(deleted === null).assertTrue();
      }
    });
  });
}

