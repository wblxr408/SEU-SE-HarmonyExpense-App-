import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { Budget, BudgetInit } from '../model/Budget';
import { DAOHelper } from '../common/DAOHelper';

export class BudgetDAO {

  private static mapRowToBudget(resultSet: relationalStore.ResultSet): Budget {
    const periodValue = resultSet.getString(resultSet.getColumnIndex('period'));
    const row: BudgetInit = {
      budgetId: resultSet.getLong(resultSet.getColumnIndex('budget_id')),
      userId: resultSet.getLong(resultSet.getColumnIndex('user_id')),
      categoryId: resultSet.getLong(resultSet.getColumnIndex('category_id')),
      amount: resultSet.getDouble(resultSet.getColumnIndex('amount')),
      period: (periodValue === 'monthly' || periodValue === 'yearly') ? periodValue : 'monthly',
      startDate: resultSet.getString(resultSet.getColumnIndex('start_date')),
      endDate: resultSet.getString(resultSet.getColumnIndex('end_date')),
      isActive: resultSet.getLong(resultSet.getColumnIndex('is_active')),
      isDeleted: resultSet.getLong(resultSet.getColumnIndex('is_deleted')),
      createdAt: resultSet.getString(resultSet.getColumnIndex('created_at'))
    };
    return new Budget(row);
  }

  static async insert(budget: Budget): Promise<number> {
    if (!budget.validate()) {
      throw new Error('[BudgetDAO] 插入失败，数据验证不通过');
    }
    const now: string = new Date().toISOString();
    budget.createdAt = now;

    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const valueBucket: relationalStore.ValuesBucket = {
      user_id: budget.userId,
      category_id: budget.categoryId,
      amount: budget.amount,
      period: budget.period,
      start_date: budget.startDate,
      end_date: budget.endDate,
      is_active: budget.isActive,
      is_deleted: budget.isDeleted,
      created_at: budget.createdAt
    };

    try {
      const rowId: number = await store.insert('budgets', valueBucket) as number;
      console.log(`[BudgetDAO] 插入成功 id=${rowId}`);
      return rowId;
    } catch (err) {
      const error = err as Error;
      console.error('[BudgetDAO] 插入失败: ' + JSON.stringify(error));
      throw new Error('[BudgetDAO] 插入失败');
    }
  }

  static async getById(budgetId: number): Promise<Budget | null> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('budgets');
    predicates.equalTo('budget_id', budgetId);

    const resultSet: relationalStore.ResultSet = await store.query(predicates);
    try {
      if (!resultSet.goToNextRow()) return null;
      return BudgetDAO.mapRowToBudget(resultSet);
    } finally {
      resultSet.close();
    }
  }

  static async getAll(): Promise<Budget[]> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const resultSet: relationalStore.ResultSet = await store.querySql('SELECT * FROM budgets ORDER BY budget_id ASC');
    const list: Budget[] = [];
    try {
      while (resultSet.goToNextRow()) {
        list.push(BudgetDAO.mapRowToBudget(resultSet));
      }
      return list;
    } finally {
      resultSet.close();
    }
  }

  static async update(budget: Budget): Promise<void> {
    if (!budget.validate()) {
      throw new Error('[BudgetDAO] 更新失败，数据验证不通过');
    }

    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const valueBucket: relationalStore.ValuesBucket = {
      category_id: budget.categoryId,
      amount: budget.amount,
      period: budget.period,
      start_date: budget.startDate,
      end_date: budget.endDate,
      is_active: budget.isActive,
      is_deleted: budget.isDeleted,
      created_at: budget.createdAt
    };
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('budgets');
    predicates.equalTo('budget_id', budget.budgetId);
    await store.update(valueBucket, predicates);
    console.log(`[BudgetDAO] 更新成功 id=${budget.budgetId}`);
  }

  static async delete(budgetId: number): Promise<void> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('budgets');
    predicates.equalTo('budget_id', budgetId);
    await store.delete(predicates);
    console.log(`[BudgetDAO] 删除成功 id=${budgetId}`);
  }

  /**
   * 软删除预算 - 使用 DAOHelper 统一方法
   */
  static async softDelete(budgetId: number): Promise<void> {
    await DAOHelper.softDelete('budgets', 'budget_id', budgetId, '[BudgetDAO]');
  }

  static async getAllActive(): Promise<Budget[]> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const resultSet: relationalStore.ResultSet = await store.querySql(
      'SELECT * FROM budgets WHERE is_deleted = 0 ORDER BY budget_id ASC'
    );
    const list: Budget[] = [];
    try {
      while (resultSet.goToNextRow()) {
        list.push(BudgetDAO.mapRowToBudget(resultSet));
      }
      return list;
    } finally {
      resultSet.close();
    }
  }

  /**
   * 根据用户ID查询预算
   */
  static async getByUserId(userId: number): Promise<Budget[]> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const resultSet: relationalStore.ResultSet = await store.querySql(
      'SELECT * FROM budgets WHERE user_id = ? AND is_deleted = 0 ORDER BY budget_id ASC',
      [userId]
    );
    const list: Budget[] = [];
    try {
      while (resultSet.goToNextRow()) {
        list.push(BudgetDAO.mapRowToBudget(resultSet));
      }
      return list;
    } finally {
      resultSet.close();
    }
  }

  /**
   * 事务封装 - 使用 DAOHelper 统一方法
   */
  static async transaction(fn: () => Promise<void>): Promise<void> {
    await DAOHelper.transaction(fn, '[BudgetDAO]');
  }

  /**
   * 检查预算是否存在 - 使用 DAOHelper 统一方法
   */
  static async exists(budgetId: number): Promise<boolean> {
    return await DAOHelper.exists('budgets', 'budget_id', budgetId);
  }
}