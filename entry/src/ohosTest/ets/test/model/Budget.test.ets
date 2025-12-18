import { describe, it, expect } from '@ohos/hypium';
import { Budget, BudgetInit } from '../../../../main/ets/model/Budget';

export default function BudgetTest(): void {
  describe('Budget.validate()', () => {
    it('valid_budget_should_pass', 0, () => {
      const bud = new Budget({
        budgetId: 1,
        userId: 1,
        categoryId: 1,
        amount: 3000.0,
        period: 'monthly',
        startDate: '2025-11-01',
        endDate: '',
        isActive: 1,
        isDeleted: 0,
        createdAt: '2025-11-05T10:00:00'
      });
      expect(bud.validate()).assertTrue();
    });

    it('invalid_budget_should_fail_(negative_amount)', 0, () => {
      const bud = new Budget({
        budgetId: 0,
        userId: 1,
        categoryId: 1,
        amount: -100.0,
        period: 'monthly',
        startDate: '2025-11-01',
        endDate: '',
        isActive: 1,
        isDeleted: 0,
        createdAt: ''
      });
      expect(bud.validate()).assertFalse();
    });

    it('invalid_budget_should_fail_(empty_startDate)', 0, () => {
      const bud = new Budget({
        budgetId: 0,
        userId: 1,
        categoryId: 1,
        amount: 3000.0,
        period: 'monthly',
        startDate: '',
        endDate: '',
        isActive: 1,
        isDeleted: 0,
        createdAt: ''
      });
      expect(bud.validate()).assertFalse();
    });

    it('invalid_budget_should_fail_(invalid_period)', 0, () => {
      const invalidPeriod: string = 'invalid';
      const bud = new Budget({
        budgetId: 0,
        userId: 1,
        categoryId: 1,
        amount: 3000.0,
        period: invalidPeriod as 'monthly' | 'yearly',
        startDate: '2025-11-01',
        endDate: '',
        isActive: 1,
        isDeleted: 0,
        createdAt: ''
      });
      expect(bud.validate()).assertFalse();
    });

    it('valid_yearly_budget_should_pass', 0, () => {
      const bud = new Budget({
        budgetId: 2,
        userId: 1,
        categoryId: 2,
        amount: 36000.0,
        period: 'yearly',
        startDate: '2025-01-01',
        endDate: '2025-12-31',
        isActive: 1,
        isDeleted: 0,
        createdAt: '2025-11-05T10:00:00'
      });
      expect(bud.validate()).assertTrue();
    });

    it('invalid_budget_should_fail_(invalid_isActive)', 0, () => {
      const bud = new Budget({
        budgetId: 1,
        userId: 1,
        categoryId: 1,
        amount: 3000.0,
        period: 'monthly',
        startDate: '2025-11-01',
        endDate: '',
        isActive: 2,
        isDeleted: 0,
        createdAt: '2025-11-05T10:00:00'
      });
      expect(bud.validate()).assertFalse();
    });
  });

  describe('Budget.toJSON()_and_fromJSON()', () => {
    it('toJSON_should_return_correct_structure', 0, () => {
      const bud = new Budget({
        budgetId: 1,
        userId: 1,
        categoryId: 1,
        amount: 3000.0,
        period: 'monthly',
        startDate: '2025-11-01',
        endDate: '',
        isActive: 1,
        isDeleted: 0,
        createdAt: '2025-11-05T10:00:00'
      });
      const json = bud.toJSON();
      expect(json.budgetId).assertEqual(1);
      expect(json.amount).assertEqual(3000.0);
      expect(json.period).assertEqual('monthly');
    });

    it('fromJSON_should_create_correct_Budget_instance', 0, () => {
      const json: BudgetInit = {
        budgetId: 2,
        userId: 1,
        categoryId: 2,
        amount: 5000.0,
        period: 'yearly',
        startDate: '2025-01-01',
        endDate: '2025-12-31',
        isActive: 1,
        isDeleted: 0,
        createdAt: '2025-11-05T10:00:00'
      };
      const bud = Budget.fromJSON(json);
      expect(bud.budgetId).assertEqual(2);
      expect(bud.amount).assertEqual(5000.0);
      expect(bud.period).assertEqual('yearly');
    });
  });
}

