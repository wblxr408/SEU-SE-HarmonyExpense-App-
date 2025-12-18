import { describe, it, expect } from '@ohos/hypium';
import { Account, AccountJSON } from '../../../../main/ets/model/Account';
export default function AccountTest(): void {
  console.info('✅ AccountTest loaded');
  describe('Account.validate()', () => {
    it('valid_account_should_pass', 0, () => {
      const acc = new Account(
        1,
        1,
        '交通银行卡',
        'bank',
        5000.0,
        '#1E90FF',
        '2025-11-05T10:00:00',
        0
      );
      expect(acc.validate()).assertTrue();
    });

    it('invalid_account_should_fail_(empty_name)', 0, () => {
      const acc = new Account(
        0,
        1,
        '',
        'bank',
        5000.0,
        '#1E90FF',
        '',
        0
      );
      expect(acc.validate()).assertFalse();
    });

    it('invalid_account_should_fail_(negative_balance)', 0, () => {
      const acc = new Account(
        0,
        1,
        '测试账户',
        'cash',
        -100.0,
        '#1E90FF',
        '',
        0
      );
      expect(acc.validate()).assertFalse();
    });

    it('invalid_account_should_fail_(invalid_type)', 0, () => {
      // 使用类型断言绕过类型检查，测试运行时验证
      const invalidType: string = 'invalid_type';
      const acc = new Account(
        0,
        1,
        '测试账户',
        invalidType as 'cash' | 'bank' | 'credit_card' | 'other',
        100.0,
        '#1E90FF',
        '',
        0
      );
      expect(acc.validate()).assertFalse();
    });

    it('valid_account_with_zero_balance_should_pass', 0, () => {
      const acc = new Account(
        1,
        1,
        '空账户',
        'cash',
        0.0,
        '#1E90FF',
        '2025-11-05T10:00:00',
        0
      );
      expect(acc.validate()).assertTrue();
    });

    it('valid_account_with_different_types_should_pass', 0, () => {
      const types: Array<'cash' | 'bank' | 'credit_card' | 'other'> = ['cash', 'bank', 'credit_card', 'other'];
      for (let i = 0; i < types.length; i++) {
        const acc = new Account(
          i + 1,
          1,
          `测试账户${i + 1}`,
          types[i],
          100.0,
          '#1E90FF',
          '2025-11-05T10:00:00',
          0
        );
        expect(acc.validate()).assertTrue();
      }
    });

    it('invalid_account_should_fail_(invalid_is_deleted)', 0, () => {
      const acc = new Account(
        1,
        1,
        '测试账户',
        'bank',
        100.0,
        '#1E90FF',
        '2025-11-05T10:00:00',
        2 // 无效值，只能是 0 或 1
      );
      expect(acc.validate()).assertFalse();
    });
  });

  describe('Account.toJSON()_and_fromJSON()', () => {
    it('toJSON_should_return_correct_structure', 0, () => {
      const acc = new Account(
        1,
        1,
        '测试账户',
        'bank',
        5000.0,
        '#1E90FF',
        '2025-11-05T10:00:00',
        0
      );
      acc.updatedAt = '2025-11-05T11:00:00';
      const json = acc.toJSON();
      expect(json.accountId).assertEqual(1);
      expect(json.userId).assertEqual(1);
      expect(json.name).assertEqual('测试账户');
      expect(json.type).assertEqual('bank');
      expect(json.balance).assertEqual(5000.0);
      expect(json.is_deleted).assertEqual(0);
    });

    it('fromJSON_should_create_correct_Account_instance', 0, () => {
      const json: AccountJSON = {
        accountId: 2,
        userId: 1,
        name: '信用卡',
        type: 'credit_card',
        balance: 3000.0,
        color: '#FF6B6B',
        createdAt: '2025-11-05T10:00:00',
        updatedAt: '2025-11-05T11:00:00',
        is_deleted: 0
      };
      const acc = Account.fromJSON(json);
      expect(acc.accountId).assertEqual(2);
      expect(acc.name).assertEqual('信用卡');
      expect(acc.type).assertEqual('credit_card');
      expect(acc.balance).assertEqual(3000.0);
    });
  });
}
