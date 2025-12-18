import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { BudgetDAO } from '../../../../main/ets/dao/BudgetDAO';
import { Budget } from '../../../../main/ets/model/Budget';
import { DatabaseManager } from '../../../../main/ets/database/DatabaseManager';
import common from '@ohos.app.ability.common';

// 在测试环境中获取 Context 的辅助函数
function getTestContext(): common.Context {
  // 在 stageMode 中，getContext 是全局函数
  return getContext() as common.Context;
}

export default function BudgetDAOTest(): void {
  describe('BudgetDAO_CRUD', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should_insert_and_get_budget', 0, async () => {
      const bud = new Budget({
        budgetId: 0,
        userId: 1,
        categoryId: 1,
        amount: 3000.0,
        period: 'monthly',
        startDate: '2025-11-01',
        endDate: '',
        isActive: 1,
        isDeleted: 0,
        createdAt: new Date().toISOString()
      });
      await BudgetDAO.insert(bud);
      const retrieved = await BudgetDAO.getById(1);
      expect(retrieved !== null).assertTrue();
      if (retrieved) {
        expect(retrieved.amount).assertEqual(3000.0);
        expect(retrieved.period).assertEqual('monthly');
      }
    });

    it('should_get_all_budgets', 0, async () => {
      const budgets = await BudgetDAO.getAll();
      expect(Array.isArray(budgets)).assertTrue();
      expect(budgets.length >= 1).assertTrue();
    });

    it('should_get_active_budgets', 0, async () => {
      const activeBudgets = await BudgetDAO.getAllActive();
      expect(Array.isArray(activeBudgets)).assertTrue();
    });

    it('should_update_budget', 0, async () => {
      const bud = await BudgetDAO.getById(1);
      if (bud) {
        bud.amount = 3500.0;
        await BudgetDAO.update(bud);
        const updated = await BudgetDAO.getById(1);
        expect(updated !== null).assertTrue();
        if (updated) {
          expect(updated.amount).assertEqual(3500.0);
        }
      }
    });
  });
}
