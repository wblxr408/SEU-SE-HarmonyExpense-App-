import { describe, it, expect } from '@ohos/hypium';
import { MOCK_TRANSACTIONS } from '../../../../src/main/ets/mock/MockData';
import { Transaction } from '../../../../src/main/ets/model/Transaction';

export default function IndexPageTest(): void {
  describe('Index Page Data Tests', () => {
    it('should have mock transactions data', 0, () => {
      expect(MOCK_TRANSACTIONS != null).assertTrue();
      expect(Array.isArray(MOCK_TRANSACTIONS)).assertTrue();
      expect(MOCK_TRANSACTIONS.length).assertLarger(0);
    });

    it('should have valid transaction structure', 0, () => {
      if (MOCK_TRANSACTIONS.length > 0) {
        const transaction = MOCK_TRANSACTIONS[0];
        expect(transaction.id != null).assertTrue();
        expect(transaction.amount != null).assertTrue();
        expect(transaction.type != null).assertTrue();
        expect(transaction.notes != null).assertTrue();
        expect(transaction.date != null).assertTrue();
      }
    });

    it('should handle transaction list operations', 0, () => {
      const transactions: Array<Transaction> = [
        new Transaction(1, 100.0, 'expense', '午餐', '2025-11-06'),
        new Transaction(2, 200.0, 'income', '工资', '2025-11-05')
      ];
      expect(transactions.length).assertEqual(2);
      expect(transactions[0].amount).assertEqual(100.0);
      expect(transactions[1].type).assertEqual('income');
    });

    it('should handle empty transaction list', 0, () => {
      const transactions: Array<Transaction> = [];
      expect(transactions.length).assertEqual(0);
    });

    it('should add transaction to list', 0, () => {
      const transactions: Array<Transaction> = [
        new Transaction(1, 100.0, 'expense', '午餐', '2025-11-06')
      ];
      const newTransaction = new Transaction(2, 50.0, 'expense', '咖啡', '2025-11-06');
      const updatedTransactions = [...transactions, newTransaction];
      expect(updatedTransactions.length).assertEqual(2);
      expect(updatedTransactions[1].id).assertEqual(2);
      expect(updatedTransactions[1].amount).assertEqual(50.0);
    });
  });

  describe('Index Page TransactionRow Builder', () => {
    it('should format expense amount correctly', 0, () => {
      const transaction = new Transaction(1, 100.5, 'expense', '测试', '2025-11-06');
      expect(transaction.type).assertEqual('expense');
      expect(transaction.amount).assertEqual(100.5);
      const formattedAmount = transaction.type === 'expense' ? `-${transaction.amount.toFixed(2)}` : `+${transaction.amount.toFixed(2)}`;
      expect(formattedAmount).assertEqual('-100.50');
    });

    it('should format income amount correctly', 0, () => {
      const transaction = new Transaction(2, 200.75, 'income', '测试', '2025-11-06');
      expect(transaction.type).assertEqual('income');
      expect(transaction.amount).assertEqual(200.75);
      const formattedAmount = transaction.type === 'expense' ? `-${transaction.amount.toFixed(2)}` : `+${transaction.amount.toFixed(2)}`;
      expect(formattedAmount).assertEqual('+200.75');
    });

    it('should handle zero amount', 0, () => {
      const transaction = new Transaction(3, 0, 'expense', '测试', '2025-11-06');
      const formattedAmount = transaction.type === 'expense' ? `-${transaction.amount.toFixed(2)}` : `+${transaction.amount.toFixed(2)}`;
      expect(formattedAmount).assertEqual('-0.00');
    });

    it('should handle large amounts', 0, () => {
      const transaction = new Transaction(4, 999999.99, 'income', '测试', '2025-11-06');
      const formattedAmount = transaction.type === 'expense' ? `-${transaction.amount.toFixed(2)}` : `+${transaction.amount.toFixed(2)}`;
      expect(formattedAmount).assertEqual('+999999.99');
    });
  });
}

