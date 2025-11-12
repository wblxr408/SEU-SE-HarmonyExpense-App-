import { describe, it, expect } from '@ohos/hypium';
import { MonthlyStatistics, CategoryStatistics, CategoryStatisticsJSON } from '../../../../src/main/ets/model/Statistics';

export default function StatisticsTest(): void {
  describe('MonthlyStatistics.validate()', () => {
    it('valid monthly statistics should pass', 0, () => {
      const stats = new MonthlyStatistics();
      stats.userId = 1;
      stats.categoryId = 2;
      stats.month = '2025-11';
      stats.totalExpense = 900.0;
      stats.totalIncome = 2000.0;
      stats.transactionCount = 12;
      stats.createdAt = '2025-11-05T10:00:00';
      stats.updatedAt = '2025-11-05T10:00:00';
      stats.is_deleted = 0;
      expect(stats.validate()).assertTrue();
    });

    it('invalid monthly statistics should fail (negative userId)', 0, () => {
      const stats = new MonthlyStatistics();
      stats.userId = -1;
      stats.categoryId = 2;
      stats.month = '2025-11';
      stats.totalExpense = 900.0;
      stats.totalIncome = 2000.0;
      stats.transactionCount = 12;
      stats.createdAt = '';
      stats.updatedAt = '';
      stats.is_deleted = 0;
      expect(stats.validate()).assertFalse();
    });

    it('invalid monthly statistics should fail (empty month)', 0, () => {
      const stats = new MonthlyStatistics();
      stats.userId = 1;
      stats.categoryId = 2;
      stats.month = '';
      stats.totalExpense = 900.0;
      stats.totalIncome = 2000.0;
      stats.transactionCount = 12;
      stats.createdAt = '';
      stats.updatedAt = '';
      stats.is_deleted = 0;
      expect(stats.validate()).assertFalse();
    });

    it('invalid monthly statistics should fail (negative totalExpense)', 0, () => {
      const stats = new MonthlyStatistics();
      stats.userId = 1;
      stats.categoryId = 2;
      stats.month = '2025-11';
      stats.totalExpense = -100.0;
      stats.totalIncome = 2000.0;
      stats.transactionCount = 12;
      stats.createdAt = '';
      stats.updatedAt = '';
      stats.is_deleted = 0;
      expect(stats.validate()).assertFalse();
    });
  });

  describe('CategoryStatistics.validate()', () => {
    it('valid category statistics should pass', 0, () => {
      const stats = new CategoryStatistics();
      stats.categoryId = 7;
      stats.categoryName = '饮食';
      stats.type = 'expense';
      stats.totalAmount = 1012.0;
      stats.transactionCount = 24;
      stats.percentage = 0.45;
      stats.icon = '🍜';
      stats.color = '#FA0';
      stats.createdAt = '2025-11-05T10:00:00';
      stats.updatedAt = '2025-11-05T10:00:00';
      stats.is_deleted = 0;
      expect(stats.validate()).assertTrue();
    });

    it('invalid category statistics should fail (empty categoryName)', 0, () => {
      const stats = new CategoryStatistics();
      stats.categoryId = 7;
      stats.categoryName = '';
      stats.type = 'expense';
      stats.totalAmount = 1012.0;
      stats.transactionCount = 24;
      stats.percentage = 0.45;
      stats.icon = '🍜';
      stats.color = '#FA0';
      stats.createdAt = '';
      stats.updatedAt = '';
      stats.is_deleted = 0;
      expect(stats.validate()).assertFalse();
    });

    it('invalid category statistics should fail (invalid type)', 0, () => {
      const stats = new CategoryStatistics();
      stats.categoryId = 7;
      stats.categoryName = '饮食';
      stats.type = 'invalid' as 'expense' | 'income';
      stats.totalAmount = 1012.0;
      stats.transactionCount = 24;
      stats.percentage = 0.45;
      stats.icon = '🍜';
      stats.color = '#FA0';
      stats.createdAt = '';
      stats.updatedAt = '';
      stats.is_deleted = 0;
      expect(stats.validate()).assertFalse();
    });

    it('invalid category statistics should fail (negative totalAmount)', 0, () => {
      const stats = new CategoryStatistics();
      stats.categoryId = 7;
      stats.categoryName = '饮食';
      stats.type = 'expense';
      stats.totalAmount = -100.0;
      stats.transactionCount = 24;
      stats.percentage = 0.45;
      stats.icon = '🍜';
      stats.color = '#FA0';
      stats.createdAt = '';
      stats.updatedAt = '';
      stats.is_deleted = 0;
      expect(stats.validate()).assertFalse();
    });

    it('valid income category statistics should pass', 0, () => {
      const stats = new CategoryStatistics();
      stats.categoryId = 8;
      stats.categoryName = '工资';
      stats.type = 'income';
      stats.totalAmount = 5000.0;
      stats.transactionCount = 1;
      stats.percentage = 1.0;
      stats.icon = '💰';
      stats.color = '#52C41A';
      stats.createdAt = '2025-11-05T10:00:00';
      stats.updatedAt = '2025-11-05T10:00:00';
      stats.is_deleted = 0;
      expect(stats.validate()).assertTrue();
    });
  });

  describe('Statistics.toJSON() and fromJSON()', () => {
    it('MonthlyStatistics toJSON should return correct structure', 0, () => {
      const stats = new MonthlyStatistics();
      stats.userId = 1;
      stats.categoryId = 2;
      stats.month = '2025-11';
      stats.totalExpense = 900.0;
      stats.totalIncome = 2000.0;
      stats.transactionCount = 12;
      stats.createdAt = '2025-11-05T10:00:00';
      stats.updatedAt = '2025-11-05T11:00:00';
      stats.is_deleted = 0;
      const json = stats.toJSON();
      expect(json.userId).assertEqual(1);
      expect(json.month).assertEqual('2025-11');
      expect(json.totalExpense).assertEqual(900.0);
    });

    it('CategoryStatistics fromJSON should create correct instance', 0, () => {
      const json: CategoryStatisticsJSON = {
        categoryId: 7,
        categoryName: '饮食',
        type: 'expense',
        totalAmount: 1012.0,
        transactionCount: 24,
        percentage: 0.45,
        icon: '🍜',
        color: '#FA0',
        createdAt: '2025-11-05T10:00:00',
        updatedAt: '2025-11-05T11:00:00',
        is_deleted: 0
      };
      const stats = CategoryStatistics.fromJSON(json);
      expect(stats.categoryId).assertEqual(7);
      expect(stats.categoryName).assertEqual('饮食');
      expect(stats.type).assertEqual('expense');
    });
  });
}



