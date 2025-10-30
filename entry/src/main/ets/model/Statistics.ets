/**
 * 统计模型 - 1.0.0版本
 */

/**
 * 月度统计
 */
export class MonthlyStatistics {
  userId: number = 0;
  categoryId: number = 0;
  month: string = ''; // YYYY-MM格式
  totalExpense: number = 0;
  totalIncome: number = 0;
  transactionCount: number = 0;

  constructor() {
  }
}

/**
 * 分类统计
 */
export class CategoryStatistics {
  categoryId: number = 0;
  categoryName: string = '';
  type: string = 'expense'; // 'expense' | 'income'
  totalAmount: number = 0;
  transactionCount: number = 0;
  percentage: number = 0;
  icon: string = '📦';
  color: string = '#1890FF';

  constructor() {
  }
}