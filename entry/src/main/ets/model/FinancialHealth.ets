/**
 * 财务健康评分系统模型
 *
 * 功能：
 * 1. 多维度财务健康评估
 * 2. 个性化理财建议生成
 * 3. 财务趋势分析
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import { Bill, BillJSON } from './Bill';
import { Budget, BudgetInit } from './Budget';

// ==================== 辅助接口定义 ====================

/**
 * 月度收支数据接口
 */
export interface MonthlyIncomeExpense {
  income: number;
  expense: number;
}

// ==================== 常量定义 ====================

/**
 * 健康等级
 */
export const GRADE_EXCELLENT = 'excellent';
export const GRADE_GOOD = 'good';
export const GRADE_FAIR = 'fair';
export const GRADE_POOR = 'poor';
export const GRADE_CRITICAL = 'critical';

/**
 * 趋势方向
 */
export const TREND_IMPROVING = 'improving';
export const TREND_STABLE = 'stable';
export const TREND_DECLINING = 'declining';
export const TREND_VOLATILE = 'volatile';

/**
 * 建议优先级
 */
export const PRIORITY_URGENT = 'urgent';
export const PRIORITY_HIGH = 'high';
export const PRIORITY_MEDIUM = 'medium';
export const PRIORITY_LOW = 'low';

/**
 * 建议类别
 */
export const ADVICE_SAVINGS = 'savings';
export const ADVICE_SPENDING = 'spending';
export const ADVICE_BUDGET = 'budget';
export const ADVICE_DEBT = 'debt';
export const ADVICE_INVESTMENT = 'investment';
export const ADVICE_EMERGENCY = 'emergency';
export const ADVICE_LIFESTYLE = 'lifestyle';

// ==================== 接口定义 ====================

/**
 * 单维度评分接口
 */
export interface DimensionScore {
  name: string;
  score: number;
  weight: number;
  weightedScore: number;
  grade: string;
  actualValue: number;
  targetValue: number;
  benchmarkValue: number;
  description: string;
  improvement: string;
}

/**
 * 健康维度评分接口
 */
export interface HealthDimensions {
  savingsRate: DimensionScore;
  budgetAdherence: DimensionScore;
  expenseStability: DimensionScore;
  debtRatio: DimensionScore;
  emergencyFund: DimensionScore;
  spendingStructure: DimensionScore;
  incomeGrowth: DimensionScore;
  financialGoals: DimensionScore;
}

/**
 * 期间比较接口
 */
export interface PeriodComparison {
  current: number;
  previous: number;
  change: number;
}

/**
 * 历史分数接口
 */
export interface HistoricalScore {
  date: string;
  score: number;
}

/**
 * 预测接口
 */
export interface ScoreForecast {
  nextPeriod: number;
  confidence: number;
}

/**
 * 评分趋势接口
 */
export interface ScoreTrend {
  direction: string;
  changePercent: number;
  periodComparison: PeriodComparison;
  historicalScores: HistoricalScore[];
  forecast: ScoreForecast;
}

/**
 * 预期影响接口
 */
export interface ExpectedImpact {
  dimension: string;
  scoreIncrease: number;
}

/**
 * 理财建议接口
 */
export interface FinancialAdvice {
  adviceId: string;
  category: string;
  priority: string;
  title: string;
  description: string;
  actionSteps: string[];
  expectedImpact: ExpectedImpact;
  timeframe: string;
  difficulty: string;
  potentialSavings: number;
  relatedCategories: number[];
}

/**
 * 年龄组基准接口
 */
export interface AgeGroupBenchmark {
  range: string;
  averageScore: number;
  percentile: number;
}

/**
 * 收入水平基准接口
 */
export interface IncomeLevelBenchmark {
  range: string;
  averageScore: number;
  percentile: number;
}

/**
 * 城市等级基准接口
 */
export interface CityTierBenchmark {
  tier: string;
  averageScore: number;
  percentile: number;
}

/**
 * 基准对比接口
 */
export interface Benchmarks {
  ageGroup: AgeGroupBenchmark;
  incomeLevel: IncomeLevelBenchmark;
  cityTier: CityTierBenchmark;
  overallPercentile: number;
}

/**
 * 财务健康评分接口
 */
export interface FinancialHealthScoreJSON {
  scoreId: number;
  userId: number;
  overallScore: number;
  grade: string;
  dimensions: HealthDimensions;
  trend: ScoreTrend;
  advices: FinancialAdvice[];
  benchmarks: Benchmarks;
  assessmentDate: string;
  periodStart: string;
  periodEnd: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 财务目标接口
 */
export interface FinancialGoalJSON {
  goalId: number;
  userId: number;
  name: string;
  targetAmount: number;
  currentAmount: number;
  deadline: string;
  priority: string;
  category: string;
  monthlyContribution: number;
  progressPercent: number;
  status: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

// ==================== 类实现 ====================

/**
 * 财务健康评分类
 */
export class FinancialHealthScore {
  static readonly tableName: string = 'financial_health_scores';

  scoreId: number = 0;
  userId: number = 0;
  overallScore: number = 0;
  grade: string = GRADE_FAIR;
  dimensionsJson: string = '{}';
  trendJson: string = '{}';
  advicesJson: string = '[]';
  benchmarksJson: string = '{}';
  assessmentDate: string = '';
  periodStart: string = '';
  periodEnd: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    scoreId: number = 0,
    userId: number = 0,
    overallScore: number = 0,
    grade: string = GRADE_FAIR,
    dimensionsJson: string = '{}',
    trendJson: string = '{}',
    advicesJson: string = '[]',
    benchmarksJson: string = '{}',
    assessmentDate: string = '',
    periodStart: string = '',
    periodEnd: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.scoreId = scoreId;
    this.userId = userId;
    this.overallScore = overallScore;
    this.grade = grade;
    this.dimensionsJson = dimensionsJson;
    this.trendJson = trendJson;
    this.advicesJson = advicesJson;
    this.benchmarksJson = benchmarksJson;
    this.assessmentDate = assessmentDate;
    this.periodStart = periodStart;
    this.periodEnd = periodEnd;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  /**
   * 获取维度评分
   */
  getDimensions(): HealthDimensions {
    try {
      const parsed = JSON.parse(this.dimensionsJson) as HealthDimensions;
      return parsed;
    } catch (e) {
      return HealthScoreUtils.createDefaultDimensions();
    }
  }

  /**
   * 设置维度评分
   */
  setDimensions(dimensions: HealthDimensions): void {
    this.dimensionsJson = JSON.stringify(dimensions);
  }

  /**
   * 获取趋势数据
   */
  getTrend(): ScoreTrend {
    try {
      const parsed = JSON.parse(this.trendJson) as ScoreTrend;
      return parsed;
    } catch (e) {
      return HealthScoreUtils.createDefaultTrend();
    }
  }

  /**
   * 获取建议列表
   */
  getAdvices(): FinancialAdvice[] {
    try {
      const parsed = JSON.parse(this.advicesJson) as FinancialAdvice[];
      return parsed;
    } catch (e) {
      return [];
    }
  }

  /**
   * 获取基准数据
   */
  getBenchmarks(): Benchmarks {
    try {
      const parsed = JSON.parse(this.benchmarksJson) as Benchmarks;
      return parsed;
    } catch (e) {
      return HealthScoreUtils.createDefaultBenchmarks();
    }
  }

  toJSON(): FinancialHealthScoreJSON {
    const result: FinancialHealthScoreJSON = {
      scoreId: this.scoreId,
      userId: this.userId,
      overallScore: this.overallScore,
      grade: this.grade,
      dimensions: this.getDimensions(),
      trend: this.getTrend(),
      advices: this.getAdvices(),
      benchmarks: this.getBenchmarks(),
      assessmentDate: this.assessmentDate,
      periodStart: this.periodStart,
      periodEnd: this.periodEnd,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      this.overallScore >= 0 && this.overallScore <= 100
    );
  }

  /**
   * 获取等级对应的颜色
   */
  getGradeColor(): string {
    if (this.grade === GRADE_EXCELLENT) {
      return '#4CAF50';
    } else if (this.grade === GRADE_GOOD) {
      return '#8BC34A';
    } else if (this.grade === GRADE_FAIR) {
      return '#FF9800';
    } else if (this.grade === GRADE_POOR) {
      return '#FF5722';
    } else if (this.grade === GRADE_CRITICAL) {
      return '#F44336';
    }
    return '#9E9E9E';
  }

  /**
   * 获取等级对应的描述
   */
  getGradeDescription(): string {
    if (this.grade === GRADE_EXCELLENT) {
      return '您的财务状况非常健康，继续保持！';
    } else if (this.grade === GRADE_GOOD) {
      return '您的财务状况良好，还有提升空间。';
    } else if (this.grade === GRADE_FAIR) {
      return '您的财务状况一般，建议关注改进建议。';
    } else if (this.grade === GRADE_POOR) {
      return '您的财务状况需要改善，请认真查看建议。';
    } else if (this.grade === GRADE_CRITICAL) {
      return '您的财务状况需要紧急关注，请立即采取行动。';
    }
    return '';
  }
}

/**
 * 财务目标类
 */
export class FinancialGoal {
  static readonly tableName: string = 'financial_goals';

  goalId: number = 0;
  userId: number = 0;
  name: string = '';
  targetAmount: number = 0;
  currentAmount: number = 0;
  deadline: string = '';
  priority: string = PRIORITY_MEDIUM;
  category: string = 'savings';
  monthlyContribution: number = 0;
  progressPercent: number = 0;
  status: string = 'on_track';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    goalId: number = 0,
    userId: number = 0,
    name: string = '',
    targetAmount: number = 0,
    currentAmount: number = 0,
    deadline: string = '',
    priority: string = PRIORITY_MEDIUM,
    category: string = 'savings',
    monthlyContribution: number = 0,
    progressPercent: number = 0,
    status: string = 'on_track',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.goalId = goalId;
    this.userId = userId;
    this.name = name;
    this.targetAmount = targetAmount;
    this.currentAmount = currentAmount;
    this.deadline = deadline;
    this.priority = priority;
    this.category = category;
    this.monthlyContribution = monthlyContribution;
    this.progressPercent = progressPercent;
    this.status = status;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  /**
   * 计算进度百分比
   */
  calculateProgress(): number {
    if (this.targetAmount <= 0) {
      return 0;
    }
    this.progressPercent = Math.min(100, (this.currentAmount / this.targetAmount) * 100);
    return this.progressPercent;
  }

  /**
   * 计算需要的月供
   */
  calculateRequiredMonthlyContribution(): number {
    const remaining = this.targetAmount - this.currentAmount;
    if (remaining <= 0) {
      return 0;
    }

    const deadline = new Date(this.deadline);
    const now = new Date();
    const monthsRemaining = Math.max(1,
      (deadline.getFullYear() - now.getFullYear()) * 12 +
      (deadline.getMonth() - now.getMonth())
    );

    return Math.ceil(remaining / monthsRemaining);
  }

  /**
   * 更新状态
   */
  updateStatus(): void {
    this.calculateProgress();

    if (this.progressPercent >= 100) {
      this.status = 'completed';
      return;
    }

    const requiredMonthly = this.calculateRequiredMonthlyContribution();
    if (this.monthlyContribution >= requiredMonthly * 1.1) {
      this.status = 'ahead';
    } else if (this.monthlyContribution >= requiredMonthly * 0.9) {
      this.status = 'on_track';
    } else {
      this.status = 'behind';
    }
  }

  toJSON(): FinancialGoalJSON {
    const result: FinancialGoalJSON = {
      goalId: this.goalId,
      userId: this.userId,
      name: this.name,
      targetAmount: this.targetAmount,
      currentAmount: this.currentAmount,
      deadline: this.deadline,
      priority: this.priority,
      category: this.category,
      monthlyContribution: this.monthlyContribution,
      progressPercent: this.progressPercent,
      status: this.status,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      this.name.trim().length > 0 &&
      this.targetAmount > 0 &&
      this.currentAmount >= 0 &&
      this.deadline !== ''
    );
  }
}

/**
 * 健康评分工具类
 */
export class HealthScoreUtils {

  /**
   * 根据分数确定等级
   */
  static getGrade(score: number): string {
    if (score >= 90) {
      return GRADE_EXCELLENT;
    }
    if (score >= 75) {
      return GRADE_GOOD;
    }
    if (score >= 60) {
      return GRADE_FAIR;
    }
    if (score >= 40) {
      return GRADE_POOR;
    }
    return GRADE_CRITICAL;
  }

  /**
   * 创建默认维度评分
   */
  static createDefaultDimensions(): HealthDimensions {
    const defaultDimension: DimensionScore = {
      name: '',
      score: 0,
      weight: 0.125,
      weightedScore: 0,
      grade: GRADE_FAIR,
      actualValue: 0,
      targetValue: 0,
      benchmarkValue: 0,
      description: '',
      improvement: ''
    };

    const savingsRate: DimensionScore = {
      name: '储蓄率',
      score: 0,
      weight: 0.20,
      weightedScore: 0,
      grade: GRADE_FAIR,
      actualValue: 0,
      targetValue: 0,
      benchmarkValue: 0,
      description: '',
      improvement: ''
    };

    const budgetAdherence: DimensionScore = {
      name: '预算执行',
      score: 0,
      weight: 0.15,
      weightedScore: 0,
      grade: GRADE_FAIR,
      actualValue: 0,
      targetValue: 0,
      benchmarkValue: 0,
      description: '',
      improvement: ''
    };

    const expenseStability: DimensionScore = {
      name: '支出稳定性',
      score: 0,
      weight: 0.10,
      weightedScore: 0,
      grade: GRADE_FAIR,
      actualValue: 0,
      targetValue: 0,
      benchmarkValue: 0,
      description: '',
      improvement: ''
    };

    const debtRatio: DimensionScore = {
      name: '负债比率',
      score: 0,
      weight: 0.15,
      weightedScore: 0,
      grade: GRADE_FAIR,
      actualValue: 0,
      targetValue: 0,
      benchmarkValue: 0,
      description: '',
      improvement: ''
    };

    const emergencyFund: DimensionScore = {
      name: '应急资金',
      score: 0,
      weight: 0.15,
      weightedScore: 0,
      grade: GRADE_FAIR,
      actualValue: 0,
      targetValue: 0,
      benchmarkValue: 0,
      description: '',
      improvement: ''
    };

    const spendingStructure: DimensionScore = {
      name: '消费结构',
      score: 0,
      weight: 0.10,
      weightedScore: 0,
      grade: GRADE_FAIR,
      actualValue: 0,
      targetValue: 0,
      benchmarkValue: 0,
      description: '',
      improvement: ''
    };

    const incomeGrowth: DimensionScore = {
      name: '收入增长',
      score: 0,
      weight: 0.10,
      weightedScore: 0,
      grade: GRADE_FAIR,
      actualValue: 0,
      targetValue: 0,
      benchmarkValue: 0,
      description: '',
      improvement: ''
    };

    const financialGoals: DimensionScore = {
      name: '目标达成',
      score: 0,
      weight: 0.05,
      weightedScore: 0,
      grade: GRADE_FAIR,
      actualValue: 0,
      targetValue: 0,
      benchmarkValue: 0,
      description: '',
      improvement: ''
    };

    const dimensions: HealthDimensions = {
      savingsRate: savingsRate,
      budgetAdherence: budgetAdherence,
      expenseStability: expenseStability,
      debtRatio: debtRatio,
      emergencyFund: emergencyFund,
      spendingStructure: spendingStructure,
      incomeGrowth: incomeGrowth,
      financialGoals: financialGoals
    };

    return dimensions;
  }

  /**
   * 创建默认趋势
   */
  static createDefaultTrend(): ScoreTrend {
    const periodComparison: PeriodComparison = {
      current: 0,
      previous: 0,
      change: 0
    };

    const forecast: ScoreForecast = {
      nextPeriod: 0,
      confidence: 0
    };

    const trend: ScoreTrend = {
      direction: TREND_STABLE,
      changePercent: 0,
      periodComparison: periodComparison,
      historicalScores: [],
      forecast: forecast
    };

    return trend;
  }

  /**
   * 创建默认基准
   */
  static createDefaultBenchmarks(): Benchmarks {
    const ageGroup: AgeGroupBenchmark = {
      range: '',
      averageScore: 0,
      percentile: 0
    };

    const incomeLevel: IncomeLevelBenchmark = {
      range: '',
      averageScore: 0,
      percentile: 0
    };

    const cityTier: CityTierBenchmark = {
      tier: '',
      averageScore: 0,
      percentile: 0
    };

    const benchmarks: Benchmarks = {
      ageGroup: ageGroup,
      incomeLevel: incomeLevel,
      cityTier: cityTier,
      overallPercentile: 0
    };

    return benchmarks;
  }

  /**
   * 计算储蓄率评分
   */
  static calculateSavingsRateScore(income: number, expense: number): DimensionScore {
    const actualRate = income > 0 ? ((income - expense) / income) * 100 : 0;
    const targetRate = 20;
    const benchmarkRate = 15;

    let score: number;
    if (actualRate >= 30) {
      score = 100;
    } else if (actualRate >= 20) {
      score = 80 + (actualRate - 20) * 2;
    } else if (actualRate >= 10) {
      score = 60 + (actualRate - 10) * 2;
    } else if (actualRate >= 0) {
      score = 40 + actualRate * 2;
    } else {
      score = Math.max(0, 40 + actualRate * 2);
    }

    const roundedScore = Math.round(score);
    const description = '您的储蓄率为' + actualRate.toFixed(1) + '%，' +
      (actualRate >= targetRate ? '达到' : '未达到') + '目标值' + targetRate + '%';

    const improvement = actualRate < targetRate ?
      '建议减少非必要支出，争取将储蓄率提升至' + targetRate + '%' :
      '继续保持良好的储蓄习惯';

    const result: DimensionScore = {
      name: '储蓄率',
      score: roundedScore,
      weight: 0.20,
      weightedScore: Math.round(roundedScore * 0.20),
      grade: HealthScoreUtils.getGrade(roundedScore),
      actualValue: Math.round(actualRate * 100) / 100,
      targetValue: targetRate,
      benchmarkValue: benchmarkRate,
      description: description,
      improvement: improvement
    };

    return result;
  }

  /**
   * 计算预算执行评分
   */
  static calculateBudgetAdherenceScore(budgeted: number, actual: number): DimensionScore {
    if (budgeted <= 0) {
      const result: DimensionScore = {
        name: '预算执行',
        score: 50,
        weight: 0.15,
        weightedScore: 8,
        grade: GRADE_FAIR,
        actualValue: 0,
        targetValue: 100,
        benchmarkValue: 95,
        description: '您尚未设置预算',
        improvement: '建议设置月度预算，便于控制支出'
      };
      return result;
    }

    const executionRate = (actual / budgeted) * 100;
    let score: number;

    if (executionRate <= 80) {
      score = 70 + (80 - executionRate) * 0.375;
    } else if (executionRate <= 95) {
      score = 90 + (95 - executionRate) / 3;
    } else if (executionRate <= 100) {
      score = 80 + (100 - executionRate) * 2;
    } else if (executionRate <= 110) {
      score = 60 - (executionRate - 100) * 2;
    } else {
      score = Math.max(0, 40 - (executionRate - 110));
    }

    const roundedScore = Math.round(score);
    const description = '预算执行率' + executionRate.toFixed(1) + '%，' +
      (executionRate <= 100 ? '在预算范围内' : '已超出预算');

    let improvement: string;
    if (executionRate > 100) {
      improvement = '建议审视超支原因，调整消费习惯';
    } else if (executionRate < 80) {
      improvement = '预算利用率较低，可考虑增加投资或储蓄';
    } else {
      improvement = '继续保持良好的预算执行';
    }

    const result: DimensionScore = {
      name: '预算执行',
      score: roundedScore,
      weight: 0.15,
      weightedScore: Math.round(roundedScore * 0.15),
      grade: HealthScoreUtils.getGrade(roundedScore),
      actualValue: Math.round(executionRate * 100) / 100,
      targetValue: 95,
      benchmarkValue: 95,
      description: description,
      improvement: improvement
    };

    return result;
  }

  /**
   * 计算支出稳定性评分
   */
  static calculateExpenseStabilityScore(monthlyExpenses: number[]): DimensionScore {
    if (monthlyExpenses.length < 3) {
      const result: DimensionScore = {
        name: '支出稳定性',
        score: 50,
        weight: 0.10,
        weightedScore: 5,
        grade: GRADE_FAIR,
        actualValue: 0,
        targetValue: 0.2,
        benchmarkValue: 0.3,
        description: '数据不足，无法评估',
        improvement: '请继续记录账单，积累更多数据'
      };
      return result;
    }

    // 计算均值
    let sum = 0;
    for (let i = 0; i < monthlyExpenses.length; i++) {
      sum += monthlyExpenses[i];
    }
    const mean = sum / monthlyExpenses.length;

    // 计算标准差
    let varianceSum = 0;
    for (let i = 0; i < monthlyExpenses.length; i++) {
      varianceSum += Math.pow(monthlyExpenses[i] - mean, 2);
    }
    const variance = varianceSum / monthlyExpenses.length;
    const stdDev = Math.sqrt(variance);
    const cv = mean > 0 ? stdDev / mean : 0;

    let score: number;
    if (cv <= 0.1) {
      score = 100;
    } else if (cv <= 0.2) {
      score = 80 + (0.2 - cv) * 200;
    } else if (cv <= 0.3) {
      score = 60 + (0.3 - cv) * 200;
    } else if (cv <= 0.5) {
      score = 40 + (0.5 - cv) * 100;
    } else {
      score = Math.max(0, 40 - (cv - 0.5) * 80);
    }

    const roundedScore = Math.round(score);
    const description = '支出变异系数' + (cv * 100).toFixed(1) + '%，' +
      (cv <= 0.3 ? '相对稳定' : '波动较大');

    const improvement = cv > 0.3 ?
      '建议制定固定的月度支出计划，减少冲动消费' :
      '支出稳定性良好，继续保持';

    const result: DimensionScore = {
      name: '支出稳定性',
      score: roundedScore,
      weight: 0.10,
      weightedScore: Math.round(roundedScore * 0.10),
      grade: HealthScoreUtils.getGrade(roundedScore),
      actualValue: Math.round(cv * 100) / 100,
      targetValue: 0.2,
      benchmarkValue: 0.3,
      description: description,
      improvement: improvement
    };

    return result;
  }

  /**
   * 计算消费结构评分
   */
  static calculateSpendingStructureScore(essentialExpense: number, totalExpense: number): DimensionScore {
    if (totalExpense <= 0) {
      const result: DimensionScore = {
        name: '消费结构',
        score: 50,
        weight: 0.10,
        weightedScore: 5,
        grade: GRADE_FAIR,
        actualValue: 0,
        targetValue: 60,
        benchmarkValue: 65,
        description: '无支出数据',
        improvement: '请记录您的日常支出'
      };
      return result;
    }

    const essentialRatio = (essentialExpense / totalExpense) * 100;

    let score: number;
    if (essentialRatio >= 40 && essentialRatio <= 60) {
      score = 90 + (10 - Math.abs(50 - essentialRatio));
    } else if (essentialRatio < 40) {
      score = 60 + essentialRatio;
    } else {
      score = Math.max(30, 90 - (essentialRatio - 60) * 1.5);
    }

    const roundedScore = Math.round(score);
    const description = '必要支出占比' + essentialRatio.toFixed(1) + '%';

    let improvement: string;
    if (essentialRatio > 70) {
      improvement = '必要支出占比较高，建议优化生活成本';
    } else if (essentialRatio < 30) {
      improvement = '请确保基本生活需求得到满足';
    } else {
      improvement = '消费结构较为合理';
    }

    const result: DimensionScore = {
      name: '消费结构',
      score: roundedScore,
      weight: 0.10,
      weightedScore: Math.round(roundedScore * 0.10),
      grade: HealthScoreUtils.getGrade(roundedScore),
      actualValue: Math.round(essentialRatio * 100) / 100,
      targetValue: 50,
      benchmarkValue: 55,
      description: description,
      improvement: improvement
    };

    return result;
  }

  /**
   * 计算综合评分
   */
  static calculateOverallScore(dimensions: HealthDimensions): number {
    const scores: DimensionScore[] = [
      dimensions.savingsRate,
      dimensions.budgetAdherence,
      dimensions.expenseStability,
      dimensions.debtRatio,
      dimensions.emergencyFund,
      dimensions.spendingStructure,
      dimensions.incomeGrowth,
      dimensions.financialGoals
    ];

    let totalWeightedScore = 0;
    let totalWeight = 0;

    for (let i = 0; i < scores.length; i++) {
      totalWeightedScore += scores[i].score * scores[i].weight;
      totalWeight += scores[i].weight;
    }

    if (totalWeight === 0) {
      return 0;
    }
    return Math.round(totalWeightedScore / totalWeight);
  }

  // ==================== Bill/Budget 集成方法 ====================

  /**
   * 从账单列表计算月度收支数据
   * @param bills 账单列表
   * @param userId 用户ID
   */
  static calculateMonthlyIncomeExpense(
    bills: Bill[],
    userId: number
  ): Map<string, MonthlyIncomeExpense> {
    const monthlyData: Map<string, MonthlyIncomeExpense> = new Map();

    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.userId === userId && bill.isDeleted === 0) {
        const month = bill.transactionDate.substring(0, 7);
        let data = monthlyData.get(month);
        if (!data) {
          const newData: MonthlyIncomeExpense = { income: 0, expense: 0 };
          monthlyData.set(month, newData);
          data = newData;
        }

        if (bill.type === 'income') {
          data.income += bill.amount;
        } else {
          data.expense += bill.amount;
        }
      }
    }

    return monthlyData;
  }

  /**
   * 从账单计算储蓄率评分
   * @param bills 账单列表
   * @param userId 用户ID
   * @param month 指定月份（YYYY-MM格式），为空则使用所有数据
   */
  static calculateSavingsRateFromBills(
    bills: Bill[],
    userId: number,
    month: string = ''
  ): DimensionScore {
    let totalIncome = 0;
    let totalExpense = 0;

    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.userId === userId && bill.isDeleted === 0) {
        if (month === '' || bill.transactionDate.startsWith(month)) {
          if (bill.type === 'income') {
            totalIncome += bill.amount;
          } else {
            totalExpense += bill.amount;
          }
        }
      }
    }

    return HealthScoreUtils.calculateSavingsRateScore(totalIncome, totalExpense);
  }

  /**
   * 从账单和预算计算预算执行评分
   * @param bills 账单列表
   * @param budgets 预算列表
   * @param userId 用户ID
   * @param month 指定月份（YYYY-MM格式）
   */
  static calculateBudgetAdherenceFromBills(
    bills: Bill[],
    budgets: Budget[],
    userId: number,
    month: string
  ): DimensionScore {
    // 计算总预算
    let totalBudgeted = 0;
    for (let i = 0; i < budgets.length; i++) {
      const budget = budgets[i];
      if (budget.userId === userId && budget.isDeleted === 0 && budget.isActive === 1) {
        if (budget.period === 'monthly') {
          totalBudgeted += budget.amount;
        } else if (budget.period === 'yearly') {
          totalBudgeted += budget.amount / 12;
        }
      }
    }

    // 计算实际支出
    let actualExpense = 0;
    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.userId === userId && bill.isDeleted === 0 && bill.type === 'expense') {
        if (bill.transactionDate.startsWith(month)) {
          actualExpense += bill.amount;
        }
      }
    }

    return HealthScoreUtils.calculateBudgetAdherenceScore(totalBudgeted, actualExpense);
  }

  /**
   * 从账单计算支出稳定性评分
   * @param bills 账单列表
   * @param userId 用户ID
   * @param months 要分析的月份数
   */
  static calculateExpenseStabilityFromBills(
    bills: Bill[],
    userId: number,
    months: number = 6
  ): DimensionScore {
    // 按月统计支出
    const monthlyExpenses: Map<string, number> = new Map();

    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.userId === userId && bill.isDeleted === 0 && bill.type === 'expense') {
        const month = bill.transactionDate.substring(0, 7);
        const current = monthlyExpenses.get(month);
        if (current !== undefined) {
          monthlyExpenses.set(month, current + bill.amount);
        } else {
          monthlyExpenses.set(month, bill.amount);
        }
      }
    }

    // 提取最近N个月的数据
    const allMonths: string[] = [];
    monthlyExpenses.forEach((value: number, key: string) => {
      allMonths.push(key);
    });
    allMonths.sort();

    const recentMonths: string[] = [];
    const startIndex = Math.max(0, allMonths.length - months);
    for (let i = startIndex; i < allMonths.length; i++) {
      recentMonths.push(allMonths[i]);
    }

    const expenses: number[] = [];
    for (let i = 0; i < recentMonths.length; i++) {
      const expense = monthlyExpenses.get(recentMonths[i]);
      if (expense !== undefined) {
        expenses.push(expense);
      }
    }

    return HealthScoreUtils.calculateExpenseStabilityScore(expenses);
  }

  /**
   * 从账单计算消费结构评分
   * @param bills 账单列表
   * @param userId 用户ID
   * @param essentialCategoryIds 必要消费分类ID列表
   * @param month 指定月份（YYYY-MM格式），为空则使用所有数据
   */
  static calculateSpendingStructureFromBills(
    bills: Bill[],
    userId: number,
    essentialCategoryIds: number[],
    month: string = ''
  ): DimensionScore {
    let essentialExpense = 0;
    let totalExpense = 0;

    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.userId === userId && bill.isDeleted === 0 && bill.type === 'expense') {
        if (month === '' || bill.transactionDate.startsWith(month)) {
          totalExpense += bill.amount;

          // 检查是否为必要消费
          let isEssential = false;
          for (let j = 0; j < essentialCategoryIds.length; j++) {
            if (essentialCategoryIds[j] === bill.categoryId) {
              isEssential = true;
              break;
            }
          }
          if (isEssential) {
            essentialExpense += bill.amount;
          }
        }
      }
    }

    return HealthScoreUtils.calculateSpendingStructureScore(essentialExpense, totalExpense);
  }

  /**
   * 从账单和预算生成完整的财务健康评分
   * @param bills 账单列表
   * @param budgets 预算列表
   * @param userId 用户ID
   * @param essentialCategoryIds 必要消费分类ID列表
   */
  static assessFinancialHealthFromBills(
    bills: Bill[],
    budgets: Budget[],
    userId: number,
    essentialCategoryIds: number[] = []
  ): FinancialHealthScore {
    const now = new Date();
    const currentMonth = now.toISOString().substring(0, 7);

    // 计算各维度评分
    const savingsRate = HealthScoreUtils.calculateSavingsRateFromBills(bills, userId, currentMonth);
    const budgetAdherence = HealthScoreUtils.calculateBudgetAdherenceFromBills(bills, budgets, userId, currentMonth);
    const expenseStability = HealthScoreUtils.calculateExpenseStabilityFromBills(bills, userId, 6);
    const spendingStructure = HealthScoreUtils.calculateSpendingStructureFromBills(bills, userId, essentialCategoryIds, currentMonth);

    // 获取默认维度并更新
    const dimensions = HealthScoreUtils.createDefaultDimensions();
    dimensions.savingsRate = savingsRate;
    dimensions.budgetAdherence = budgetAdherence;
    dimensions.expenseStability = expenseStability;
    dimensions.spendingStructure = spendingStructure;

    // 计算综合评分
    const overallScore = HealthScoreUtils.calculateOverallScore(dimensions);
    const grade = HealthScoreUtils.getGrade(overallScore);

    // 生成建议
    const advices = HealthScoreUtils.generateAdvicesFromDimensions(dimensions);

    // 创建评分记录
    const score = new FinancialHealthScore(
      0,
      userId,
      overallScore,
      grade,
      JSON.stringify(dimensions),
      JSON.stringify(HealthScoreUtils.createDefaultTrend()),
      JSON.stringify(advices),
      JSON.stringify(HealthScoreUtils.createDefaultBenchmarks()),
      now.toISOString(),
      currentMonth + '-01',
      now.toISOString().substring(0, 10),
      now.toISOString(),
      now.toISOString(),
      0
    );

    return score;
  }

  /**
   * 根据维度评分生成理财建议
   * @param dimensions 维度评分
   */
  static generateAdvicesFromDimensions(dimensions: HealthDimensions): FinancialAdvice[] {
    const advices: FinancialAdvice[] = [];
    let adviceIndex = 1;

    // 储蓄率建议
    if (dimensions.savingsRate.score < 60) {
      const expectedImpact: ExpectedImpact = {
        dimension: '储蓄率',
        scoreIncrease: 15
      };

      const advice: FinancialAdvice = {
        adviceId: 'ADV_' + adviceIndex,
        category: ADVICE_SAVINGS,
        priority: dimensions.savingsRate.score < 40 ? PRIORITY_URGENT : PRIORITY_HIGH,
        title: '提高储蓄率',
        description: dimensions.savingsRate.improvement,
        actionSteps: [
          '审视每月固定支出，寻找节省空间',
          '设置自动储蓄，工资到账先存一部分',
          '减少非必要的订阅服务',
          '制定明确的储蓄目标'
        ],
        expectedImpact: expectedImpact,
        timeframe: '1-3个月',
        difficulty: 'medium',
        potentialSavings: 500,
        relatedCategories: []
      };
      advices.push(advice);
      adviceIndex++;
    }

    // 预算执行建议
    if (dimensions.budgetAdherence.score < 60) {
      const expectedImpact: ExpectedImpact = {
        dimension: '预算执行',
        scoreIncrease: 10
      };

      const advice: FinancialAdvice = {
        adviceId: 'ADV_' + adviceIndex,
        category: ADVICE_BUDGET,
        priority: PRIORITY_HIGH,
        title: '改善预算执行',
        description: dimensions.budgetAdherence.improvement,
        actionSteps: [
          '每周检查预算执行情况',
          '设置预算提醒功能',
          '分析超支原因',
          '调整不合理的预算项目'
        ],
        expectedImpact: expectedImpact,
        timeframe: '1个月',
        difficulty: 'easy',
        potentialSavings: 300,
        relatedCategories: []
      };
      advices.push(advice);
      adviceIndex++;
    }

    // 支出稳定性建议
    if (dimensions.expenseStability.score < 60) {
      const expectedImpact: ExpectedImpact = {
        dimension: '支出稳定性',
        scoreIncrease: 8
      };

      const advice: FinancialAdvice = {
        adviceId: 'ADV_' + adviceIndex,
        category: ADVICE_SPENDING,
        priority: PRIORITY_MEDIUM,
        title: '稳定月度支出',
        description: dimensions.expenseStability.improvement,
        actionSteps: [
          '制定月度消费计划',
          '大额消费提前规划',
          '建立消费冷静期制度',
          '区分必要和非必要支出'
        ],
        expectedImpact: expectedImpact,
        timeframe: '2-3个月',
        difficulty: 'medium',
        potentialSavings: 200,
        relatedCategories: []
      };
      advices.push(advice);
      adviceIndex++;
    }

    // 消费结构建议
    if (dimensions.spendingStructure.score < 60) {
      const expectedImpact: ExpectedImpact = {
        dimension: '消费结构',
        scoreIncrease: 5
      };

      const advice: FinancialAdvice = {
        adviceId: 'ADV_' + adviceIndex,
        category: ADVICE_LIFESTYLE,
        priority: PRIORITY_MEDIUM,
        title: '优化消费结构',
        description: dimensions.spendingStructure.improvement,
        actionSteps: [
          '分析各类支出占比',
          '适当增加/减少娱乐支出',
          '关注生活必需品性价比',
          '建立合理的消费观念'
        ],
        expectedImpact: expectedImpact,
        timeframe: '1-2个月',
        difficulty: 'easy',
        potentialSavings: 150,
        relatedCategories: []
      };
      advices.push(advice);
      adviceIndex++;
    }

    return advices;
  }

  /**
   * 计算分类支出统计
   * @param bills 账单列表
   * @param userId 用户ID
   * @param month 指定月份
   */
  static calculateCategoryExpenses(
    bills: Bill[],
    userId: number,
    month: string = ''
  ): Map<number, number> {
    const categoryExpenses: Map<number, number> = new Map();

    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.userId === userId && bill.isDeleted === 0 && bill.type === 'expense') {
        if (month === '' || bill.transactionDate.startsWith(month)) {
          const current = categoryExpenses.get(bill.categoryId);
          if (current !== undefined) {
            categoryExpenses.set(bill.categoryId, current + bill.amount);
          } else {
            categoryExpenses.set(bill.categoryId, bill.amount);
          }
        }
      }
    }

    return categoryExpenses;
  }

  /**
   * 计算预算使用情况
   * @param bills 账单列表
   * @param budgets 预算列表
   * @param userId 用户ID
   * @param month 指定月份
   */
  static calculateBudgetUsage(
    bills: Bill[],
    budgets: Budget[],
    userId: number,
    month: string
  ): BudgetUsageResult[] {
    const categoryExpenses = HealthScoreUtils.calculateCategoryExpenses(bills, userId, month);
    const results: BudgetUsageResult[] = [];

    for (let i = 0; i < budgets.length; i++) {
      const budget = budgets[i];
      if (budget.userId === userId && budget.isDeleted === 0 && budget.isActive === 1) {
        let budgetAmount = budget.amount;
        if (budget.period === 'yearly') {
          budgetAmount = budget.amount / 12;
        }

        const spent = categoryExpenses.get(budget.categoryId);
        const actualSpent = spent !== undefined ? spent : 0;
        const remaining = budgetAmount - actualSpent;
        const usagePercent = budgetAmount > 0 ? (actualSpent / budgetAmount) * 100 : 0;

        let status = 'normal';
        if (usagePercent >= 100) {
          status = 'exceeded';
        } else if (usagePercent >= 80) {
          status = 'warning';
        }

        const result: BudgetUsageResult = {
          categoryId: budget.categoryId,
          budgetAmount: budgetAmount,
          spent: actualSpent,
          remaining: remaining,
          usagePercent: Math.round(usagePercent * 100) / 100,
          status: status
        };
        results.push(result);
      }
    }

    return results;
  }
}

/**
 * 预算使用结果接口
 */
export interface BudgetUsageResult {
  categoryId: number;
  budgetAmount: number;
  spent: number;
  remaining: number;
  usagePercent: number;
  status: string;
}
