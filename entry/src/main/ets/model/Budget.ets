/**
 * 预算模型 - 1.0.0版本
 */
export class Budget {
  budgetId: number = 0;
  userId: number = 0;
  categoryId: number = 0;
  amount: number = 0;
  period: string = 'monthly'; // 'monthly' | 'yearly'
  startDate: string = ''; // YYYY-MM-DD格式
  endDate: string = ''; // YYYY-MM-DD格式，空字符串表示无结束日期
  isActive: number = 1; // 1=激活，0=未激活
  createdAt: string = '';

  constructor() {
  }
}