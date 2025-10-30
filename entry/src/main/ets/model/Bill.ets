/**
 * 账单模型 - 1.0.0版本
 */
export class Bill {
  billId: number = 0;
  userId: number = 0;
  accountId: number = 0;
  categoryId: number = 0;
  amount: number = 0;
  type: string = 'expense'; // 'expense' | 'income'
  note: string = '';
  transactionDate: string = ''; // YYYY-MM-DD格式
  createdAt: string = '';
  updatedAt: string = '';

  constructor() {
  }
}