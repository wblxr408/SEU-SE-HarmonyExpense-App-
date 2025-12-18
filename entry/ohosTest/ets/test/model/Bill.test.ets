import { describe, it, expect } from '@ohos/hypium';
import { Bill, BillJSON } from '../../../../src/main/ets/model/Bill';

export default function BillTest(): void {
  describe('Bill.validate()', () => {
    it('valid bill should pass', 0, () => {
      const bill = new Bill(
        1,
        1,
        1,
        1,
        88.5,
        '午餐',
        '2025-11-05',
        'expense',
        '2025-11-05T12:00:00',
        '2025-11-05T12:00:00',
        0
      );
      expect(bill.validate()).assertTrue();
    });

    it('invalid bill should fail (negative amount)', 0, () => {
      const bill = new Bill(
        0,
        1,
        1,
        1,
        -1,
        '',
        '2025-11-05',
        'expense',
        '',
        '',
        0
      );
      expect(bill.validate()).assertFalse();
    });

    it('invalid bill should fail (empty date)', 0, () => {
      const bill = new Bill(
        0,
        1,
        1,
        1,
        10,
        '测试',
        '',
        'income',
        '',
        '',
        0
      );
      expect(bill.validate()).assertFalse();
    });

    it('invalid bill should fail (invalid type)', 0, () => {
      const invalidType: string = 'invalid';
      const bill = new Bill(
        0,
        1,
        1,
        1,
        10,
        '测试',
        '2025-11-05',
        invalidType as 'income' | 'expense',
        '',
        '',
        0
      );
      expect(bill.validate()).assertFalse();
    });

    it('valid income bill should pass', 0, () => {
      const bill = new Bill(
        2,
        1,
        2,
        2,
        5000.0,
        '工资',
        '2025-11-01',
        'income',
        '2025-11-01T09:00:00',
        '2025-11-01T09:00:00',
        0
      );
      expect(bill.validate()).assertTrue();
    });
  });

  describe('Bill.toJSON() and fromJSON()', () => {
    it('toJSON should return correct structure', 0, () => {
      const bill = new Bill(
        1,
        1,
        1,
        1,
        100.0,
        '测试',
        '2025-11-05',
        'expense',
        '2025-11-05T10:00:00',
        '2025-11-05T11:00:00',
        0
      );
      const json = bill.toJSON();
      expect(json.billId).assertEqual(1);
      expect(json.amount).assertEqual(100.0);
      expect(json.type).assertEqual('expense');
    });

    it('fromJSON should create correct Bill instance', 0, () => {
      const json: BillJSON = {
        billId: 2,
        accountId: 1,
        categoryId: 1,
        amount: 200.0,
        note: '晚餐',
        transactionDate: '2025-11-05',
        type: 'expense',
        createdAt: '2025-11-05T18:00:00',
        updatedAt: '2025-11-05T18:00:00',
        is_deleted: 0
      };
      const bill = Bill.fromJSON(json);
      expect(bill.billId).assertEqual(2);
      expect(bill.amount).assertEqual(200.0);
      expect(bill.note).assertEqual('晚餐');
    });
  });
}

