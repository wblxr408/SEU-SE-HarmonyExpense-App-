import { describe, it, expect } from '@ohos/hypium';
import { Transaction } from '../../../../main/ets/model/Transaction';

export default function TransactionTest(): void {
  describe('Transaction_constructor', () => {
    it('should_create_Transaction_instance_correctly', 0, () => {
      const trans = new Transaction(
        1,
        100.0,
        'expense',
        '午餐',
        '2025-11-05'
      );
      expect(trans.id).assertEqual(1);
      expect(trans.amount).assertEqual(100.0);
      expect(trans.type).assertEqual('expense');
      expect(trans.notes).assertEqual('午餐');
      expect(trans.date).assertEqual('2025-11-05');
    });

    it('should_create_income_Transaction_correctly', 0, () => {
      const trans = new Transaction(
        2,
        5000.0,
        'income',
        '工资',
        '2025-11-01'
      );
      expect(trans.id).assertEqual(2);
      expect(trans.amount).assertEqual(5000.0);
      expect(trans.type).assertEqual('income');
      expect(trans.notes).assertEqual('工资');
    });

    it('should_handle_zero_amount', 0, () => {
      const trans = new Transaction(
        3,
        0.0,
        'expense',
        '免费',
        '2025-11-05'
      );
      expect(trans.amount).assertEqual(0.0);
    });

    it('should_handle_empty_notes', 0, () => {
      const trans = new Transaction(
        4,
        50.0,
        'expense',
        '',
        '2025-11-05'
      );
      expect(trans.notes).assertEqual('');
    });
  });
}

