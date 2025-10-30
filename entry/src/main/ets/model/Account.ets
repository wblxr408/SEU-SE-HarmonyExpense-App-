/**
 * 账户模型 - 1.0.0版本
 */
export class Account {
  accountId: number = 0;
  userId: number = 0;
  name: string = '';
  type: string = 'cash'; // 'cash' | 'bank' | 'credit_card' | 'other'
  balance: number = 0;
  color: string = '#1890FF';
  createdAt: string = '';

  constructor() {
  }
}