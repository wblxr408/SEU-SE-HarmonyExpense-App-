@Observed
export class MonthSummary {
  totalExpense: number = 0;
  totalIncome: number = 0;
  billCount: number = 0;
}
@Observed
export class DailyChartData {
  day: string; // 日期 (例如 "01", "15")
  amount: number; // 金额
  isHighest: boolean = false; // 是否是当月最高的一天 (用于高亮显示)

  constructor(day: string, amount: number) {
    this.day = day;
    this.amount = amount;
  }
}

// 分类统计数据 (用于排行榜)
@Observed
export class CategoryStat {
  categoryId: number;
  categoryName: string;
  icon: string;
  totalAmount: number;
  percentage: number; // 0 ~ 100

  constructor(id: number, name: string, icon: string, amount: number) {
    this.categoryId = id;
    this.categoryName = name;
    this.icon = icon;
    this.totalAmount = amount;
    this.percentage = 0;
  }
}