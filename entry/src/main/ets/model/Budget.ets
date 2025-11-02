/**
 * 预算模型 - 1.0.1版本（支持软删除）
 */

// 定义初始化参数接口
export interface BudgetInit {
  budgetId: number;
  userId: number;
  categoryId: number;
  amount: number;
  period: 'monthly' | 'yearly';
  startDate: string; // YYYY-MM-DD格式
  endDate: string;   // YYYY-MM-DD格式，空字符串表示无结束日期
  isActive: number;  // 1=激活，0=未激活
  isDeleted: number; // 0=未删除, 1=已删除
  createdAt: string;
}

// 主类定义
export class Budget {
  budgetId: number = 0;
  userId: number = 0;
  categoryId: number = 0;
  amount: number = 0;
  period: 'monthly' | 'yearly' = 'monthly';
  startDate: string = '';
  endDate: string = '';
  isActive: number = 1;
  isDeleted: number = 0; // 新增软删除字段
  createdAt: string = '';

  constructor(initData?: BudgetInit) {
    if (initData) {
      this.budgetId = initData.budgetId;
      this.userId = initData.userId;
      this.categoryId = initData.categoryId;
      this.amount = initData.amount;
      this.period = initData.period;
      this.startDate = initData.startDate;
      this.endDate = initData.endDate;
      this.isActive = initData.isActive;
      this.isDeleted = initData.isDeleted ?? 0;
      this.createdAt = initData.createdAt;
    }
  }

  // 序列化
  toJSON(): BudgetInit {
    return {
      budgetId: this.budgetId,
      userId: this.userId,
      categoryId: this.categoryId,
      amount: this.amount,
      period: this.period,
      startDate: this.startDate,
      endDate: this.endDate,
      isActive: this.isActive,
      isDeleted: this.isDeleted,
      createdAt: this.createdAt,
    };
  }

  // 反序列化
  static fromJSON(data: BudgetInit): Budget {
    return new Budget(data);
  }

  // 数据验证
  validate(): boolean {
    return (
      this.amount >= 0 &&
        (this.period === 'monthly' || this.period === 'yearly') &&
        this.startDate !== '' &&
        (this.isActive === 0 || this.isActive === 1) &&
        (this.isDeleted === 0 || this.isDeleted === 1)
    );
  }

  // 克隆
  clone(): Budget {
    return new Budget(this.toJSON());
  }
}
