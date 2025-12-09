import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { ReminderService, ReminderCreateOptions } from '../../../../src/main/ets/service/ReminderService';
import { DatabaseManager } from '../../../../src/main/ets/database/DatabaseManager';
import common from '@ohos.app.ability.common';

function getTestContext(): common.Context {
  return getContext() as common.Context;
}

export default function ReminderServiceTest(): void {
  describe('ReminderService Basic Tests', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should create reminder options', 0, () => {
      const options = new ReminderCreateOptions(
        1,
        'bill',
        '测试提醒',
        '这是一个测试提醒',
        'once',
        '2025-11-05T10:00:00',
        100.0,
        1,
        1
      );
      expect(options.userId).assertEqual(1);
      expect(options.type).assertEqual('bill');
      expect(options.title).assertEqual('测试提醒');
    });

    it('should handle different reminder frequencies', 0, () => {
      const frequencies: Array<'once' | 'daily' | 'weekly' | 'monthly' | 'yearly'> = 
        ['once', 'daily', 'weekly', 'monthly', 'yearly'];
      
      frequencies.forEach(freq => {
        const options = new ReminderCreateOptions(1, 'bill', '测试', '', freq, '2025-11-05T10:00:00');
        expect(options.frequency).assertEqual(freq);
      });
    });

    // 注意：实际的提醒计算和通知功能需要系统通知权限，在测试环境中可能无法完全测试
    it('should validate reminder options', 0, () => {
      const options = new ReminderCreateOptions(1, 'bill', '测试', '', 'once', '2025-11-05T10:00:00');
      expect(options.userId > 0).assertTrue();
      expect(options.title.length > 0).assertTrue();
    });
  });
}

