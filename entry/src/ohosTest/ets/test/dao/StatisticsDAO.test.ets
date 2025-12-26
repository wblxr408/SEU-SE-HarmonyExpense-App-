import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { StatisticsDAO } from '../../../../src/main/ets/dao/StatisticsDAO';
import { MonthlyStatistics, CategoryStatistics } from '../../../../src/main/ets/model/Statistics';
import { DatabaseManager } from '../../../../src/main/ets/dao/DatabaseManager';
import common from '@ohos.app.ability.common';

// 在测试环境中获取 Context 的辅助函数
function getTestContext(): common.Context {
  // 在 stageMode 中，getContext 是全局函数
  return getContext() as common.Context;
}

export default function StatisticsDAOTest(): void {
  describe('StatisticsDAO CRUD', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should insert and get monthly statistics', 0, async () => {
      const stats = new MonthlyStatistics();
      stats.userId = 1;
      stats.categoryId = 2;
      stats.month = '2025-11';
      stats.totalExpense = 900.0;
      stats.totalIncome = 2000.0;
      stats.transactionCount = 12;
      stats.createdAt = new Date().toISOString();
      stats.updatedAt = new Date().toISOString();
      stats.is_deleted = 0;
      await StatisticsDAO.insertMonthly(stats);
      const retrieved = await StatisticsDAO.getMonthly(1, 2, '2025-11');
      expect(retrieved !== null).assertTrue();
      if (retrieved) {
        expect(retrieved.totalExpense).assertEqual(900.0);
        expect(retrieved.month).assertEqual('2025-11');
      }
    });

    it('should get all monthly statistics', 0, async () => {
      const allStats = await StatisticsDAO.getAllMonthly();
      expect(Array.isArray(allStats)).assertTrue();
      expect(allStats.length >= 1).assertTrue();
    });

    it('should insert and get category statistics', 0, async () => {
      const stats = new CategoryStatistics();
      stats.categoryId = 7;
      stats.categoryName = '饮食';
      stats.type = 'expense';
      stats.totalAmount = 1012.0;
      stats.transactionCount = 24;
      stats.percentage = 0.45;
      stats.icon = '🍜';
      stats.color = '#FA0';
      stats.createdAt = new Date().toISOString();
      stats.updatedAt = new Date().toISOString();
      stats.is_deleted = 0;
      await StatisticsDAO.insertCategory(stats);
      const retrieved = await StatisticsDAO.getCategory(7);
      expect(retrieved !== null).assertTrue();
      if (retrieved) {
        expect(retrieved.categoryName).assertEqual('饮食');
        expect(retrieved.totalAmount).assertEqual(1012.0);
      }
    });

    it('should get all category statistics', 0, async () => {
      const allStats = await StatisticsDAO.getAllCategory();
      expect(Array.isArray(allStats)).assertTrue();
      expect(allStats.length >= 1).assertTrue();
    });

    it('should update monthly statistics', 0, async () => {
      const stats = await StatisticsDAO.getMonthly(1, 2, '2025-11');
      if (stats) {
        stats.totalExpense = 1000.0;
        await StatisticsDAO.updateMonthly(stats);
        const updated = await StatisticsDAO.getMonthly(1, 2, '2025-11');
        expect(updated !== null).assertTrue();
        if (updated) {
          expect(updated.totalExpense).assertEqual(1000.0);
        }
      }
    });
  });
}

