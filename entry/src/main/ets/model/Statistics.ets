/**
 * 月度统计模型
 */
export interface MonthlyStatisticsJSON {
  userId: number;
  categoryId: number;
  month: string; // YYYY-MM
  totalExpense: number;
  totalIncome: number;
  transactionCount: number;
  createdAt: string;
  updatedAt: string;
  is_deleted?: number;
}

export class MonthlyStatistics {
  userId: number = 0;
  categoryId: number = 0;
  month: string = '';
  totalExpense: number = 0;
  totalIncome: number = 0;
  transactionCount: number = 0;
  createdAt: string = '';
  updatedAt: string = '';
  is_deleted: number = 0;

  constructor(init?: Partial<MonthlyStatistics>) {
    if (init) {
      if (init.userId !== undefined) this.userId = init.userId;
      if (init.categoryId !== undefined) this.categoryId = init.categoryId;
      if (init.month !== undefined) this.month = init.month;
      if (init.totalExpense !== undefined) this.totalExpense = init.totalExpense;
      if (init.totalIncome !== undefined) this.totalIncome = init.totalIncome;
      if (init.transactionCount !== undefined) this.transactionCount = init.transactionCount;
      if (init.createdAt !== undefined) this.createdAt = init.createdAt;
      if (init.updatedAt !== undefined) this.updatedAt = init.updatedAt;
      if (init.is_deleted !== undefined) this.is_deleted = init.is_deleted;
    }
  }

  validate(): boolean {
    return (
      this.userId >= 0 &&
        this.categoryId >= 0 &&
        this.month !== '' &&
        this.totalExpense >= 0 &&
        this.totalIncome >= 0 &&
        this.transactionCount >= 0 &&
        (this.is_deleted === 0 || this.is_deleted === 1)
    );
  }

  toJSON(): MonthlyStatisticsJSON {
    return {
      userId: this.userId,
      categoryId: this.categoryId,
      month: this.month,
      totalExpense: this.totalExpense,
      totalIncome: this.totalIncome,
      transactionCount: this.transactionCount,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      is_deleted: this.is_deleted
    };
  }

  static fromJSON(data: MonthlyStatisticsJSON): MonthlyStatistics {
    const stats = new MonthlyStatistics();
    stats.userId = data.userId;
    stats.categoryId = data.categoryId;
    stats.month = data.month;
    stats.totalExpense = data.totalExpense;
    stats.totalIncome = data.totalIncome;
    stats.transactionCount = data.transactionCount;
    stats.createdAt = data.createdAt;
    stats.updatedAt = data.updatedAt;
    stats.is_deleted = data.is_deleted ?? 0;
    return stats;
  }

  clone(): MonthlyStatistics {
    return MonthlyStatistics.fromJSON(this.toJSON());
  }
}

/**
 * 分类统计模型
 */
export interface CategoryStatisticsJSON {
  categoryId: number;
  categoryName: string;
  type: 'expense' | 'income';
  totalAmount: number;
  transactionCount: number;
  percentage: number;
  icon: string;
  color: string;
  createdAt: string;
  updatedAt: string;
  is_deleted?: number;
}

export class CategoryStatistics {
  categoryId: number = 0;
  categoryName: string = '';
  type: 'expense' | 'income' = 'expense';
  totalAmount: number = 0;
  transactionCount: number = 0;
  percentage: number = 0;
  icon: string = '📦';
  color: string = '#1890FF';
  createdAt: string = '';
  updatedAt: string = '';
  is_deleted: number = 0;

  constructor(init?: Partial<CategoryStatistics>) {
    if (init) {
      if (init.categoryId !== undefined) this.categoryId = init.categoryId;
      if (init.categoryName !== undefined) this.categoryName = init.categoryName;
      if (init.type !== undefined) this.type = init.type;
      if (init.totalAmount !== undefined) this.totalAmount = init.totalAmount;
      if (init.transactionCount !== undefined) this.transactionCount = init.transactionCount;
      if (init.percentage !== undefined) this.percentage = init.percentage;
      if (init.icon !== undefined) this.icon = init.icon;
      if (init.color !== undefined) this.color = init.color;
      if (init.createdAt !== undefined) this.createdAt = init.createdAt;
      if (init.updatedAt !== undefined) this.updatedAt = init.updatedAt;
      if (init.is_deleted !== undefined) this.is_deleted = init.is_deleted;
    }
  }

  validate(): boolean {
    return (
      this.categoryId >= 0 &&
        this.categoryName !== '' &&
      ['expense', 'income'].includes(this.type) &&
        this.totalAmount >= 0 &&
        this.transactionCount >= 0 &&
        this.percentage >= 0 &&
        (this.is_deleted === 0 || this.is_deleted === 1)
    );
  }

  toJSON(): CategoryStatisticsJSON {
    return {
      categoryId: this.categoryId,
      categoryName: this.categoryName,
      type: this.type,
      totalAmount: this.totalAmount,
      transactionCount: this.transactionCount,
      percentage: this.percentage,
      icon: this.icon,
      color: this.color,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      is_deleted: this.is_deleted
    };
  }

  static fromJSON(data: CategoryStatisticsJSON): CategoryStatistics {
    const stats = new CategoryStatistics();
    stats.categoryId = data.categoryId;
    stats.categoryName = data.categoryName;
    stats.type = data.type;
    stats.totalAmount = data.totalAmount;
    stats.transactionCount = data.transactionCount;
    stats.percentage = data.percentage;
    stats.icon = data.icon;
    stats.color = data.color;
    stats.createdAt = data.createdAt;
    stats.updatedAt = data.updatedAt;
    stats.is_deleted = data.is_deleted ?? 0;
    return stats;
  }

  clone(): CategoryStatistics {
    return CategoryStatistics.fromJSON(this.toJSON());
  }
}
