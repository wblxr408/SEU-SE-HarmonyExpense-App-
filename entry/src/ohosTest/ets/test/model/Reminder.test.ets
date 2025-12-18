import { describe, it, expect } from '@ohos/hypium';
import { Reminder, ReminderJSON } from '../../../../main/ets/model/Reminder';

export default function ReminderTest(): void {
  describe('Reminder.validate()', () => {
    it('valid_reminder_should_pass', 0, () => {
      const reminder = new Reminder(
        1,
        1,
        'bill',
        '测试提醒',
        '这是一个测试提醒',
        'once',
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        1,
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        0,
        100.0,
        1,
        1
      );
      expect(reminder.validate()).assertTrue();
    });

    it('invalid_reminder_should_fail_(zero_userId)', 0, () => {
      const reminder = new Reminder(
        0,
        0,
        'bill',
        '测试',
        '',
        'once',
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        1,
        '',
        '',
        0
      );
      expect(reminder.validate()).assertFalse();
    });

    it('invalid_reminder_should_fail_(empty_title)', 0, () => {
      const reminder = new Reminder(
        0,
        1,
        'bill',
        '',
        '',
        'once',
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        1,
        '',
        '',
        0
      );
      expect(reminder.validate()).assertFalse();
    });

    it('invalid_reminder_should_fail_(invalid_type)', 0, () => {
      const reminder = new Reminder();
      reminder.userId = 1;
      reminder.title = '测试';
      reminder.reminderDate = '2025-11-05T10:00:00';
      // 通过Object类型来测试无效值
      const invalidValue: Object = 'invalid';
      reminder.type = invalidValue as 'bill' | 'budget';
      expect(reminder.validate()).assertFalse();
    });

    it('invalid_reminder_should_fail_(invalid_frequency)', 0, () => {
      const reminder = new Reminder();
      reminder.userId = 1;
      reminder.title = '测试';
      reminder.reminderDate = '2025-11-05T10:00:00';
      // 通过Object类型来测试无效值
      const invalidValue: Object = 'invalid';
      reminder.frequency = invalidValue as 'once' | 'daily' | 'weekly' | 'monthly' | 'yearly';
      expect(reminder.validate()).assertFalse();
    });

    it('invalid_reminder_should_fail_(empty_reminderDate)', 0, () => {
      const reminder = new Reminder();
      reminder.userId = 1;
      reminder.title = '测试';
      reminder.reminderDate = '';
      expect(reminder.validate()).assertFalse();
    });

    it('invalid_reminder_should_fail_(invalid_isActive)', 0, () => {
      const reminder = new Reminder();
      reminder.userId = 1;
      reminder.title = '测试';
      reminder.reminderDate = '2025-11-05T10:00:00';
      reminder.isActive = 2;
      expect(reminder.validate()).assertFalse();
    });
  });

  describe('Reminder.toJSON()_and_fromJSON()', () => {
    it('toJSON_should_return_correct_structure', 0, () => {
      const reminder = new Reminder(
        1,
        1,
        'budget',
        '预算提醒',
        '预算即将超支',
        'monthly',
        '2025-11-05T10:00:00',
        '2025-12-05T10:00:00',
        1,
        '2025-11-05T10:00:00',
        '2025-11-05T11:00:00',
        0,
        500.0,
        undefined,
        undefined,
        1
      );
      const json = reminder.toJSON();
      expect(json.reminderId).assertEqual(1);
      expect(json.userId).assertEqual(1);
      expect(json.type).assertEqual('budget');
      expect(json.title).assertEqual('预算提醒');
      expect(json.frequency).assertEqual('monthly');
      expect(json.amount).assertEqual(500.0);
      expect(json.budgetId).assertEqual(1);
    });

    it('fromJSON_should_create_correct_instance', 0, () => {
      const json: ReminderJSON = {
        reminderId: 2,
        userId: 1,
        type: 'bill',
        title: '账单提醒',
        description: '记得支付账单',
        frequency: 'weekly',
        reminderDate: '2025-11-05T10:00:00',
        nextReminderDate: '2025-11-12T10:00:00',
        isActive: 1,
        createdAt: '2025-11-05T10:00:00',
        updatedAt: '2025-11-05T11:00:00',
        isDeleted: 0,
        amount: 200.0,
        categoryId: 1,
        accountId: 1
      };
      const reminder = Reminder.fromJSON(json);
      expect(reminder.reminderId).assertEqual(2);
      expect(reminder.type).assertEqual('bill');
      expect(reminder.amount).assertEqual(200.0);
      expect(reminder.categoryId).assertEqual(1);
    });

    it('should_handle_optional_fields', 0, () => {
      const json: ReminderJSON = {
        reminderId: 3,
        userId: 1,
        type: 'bill',
        title: '简单提醒',
        description: '',
        frequency: 'once',
        reminderDate: '2025-11-05T10:00:00',
        nextReminderDate: '2025-11-05T10:00:00',
        isActive: 1,
        createdAt: '2025-11-05T10:00:00',
        updatedAt: '2025-11-05T10:00:00',
        isDeleted: 0
      };
      const reminder = Reminder.fromJSON(json);
      expect(reminder.amount === undefined).assertTrue();
      expect(reminder.categoryId === undefined).assertTrue();
    });
  });

  describe('Reminder.clone()', () => {
    it('clone_should_create_independent_copy', 0, () => {
      const original = new Reminder(
        1,
        1,
        'bill',
        '原始提醒',
        '描述',
        'daily',
        '2025-11-05T10:00:00',
        '2025-11-06T10:00:00',
        1,
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        0,
        100.0
      );
      const cloned = original.clone();
      
      expect(cloned.reminderId).assertEqual(original.reminderId);
      expect(cloned.title).assertEqual(original.title);
      
      cloned.title = '修改后的提醒';
      expect(original.title).assertEqual('原始提醒');
    });
  });
}

