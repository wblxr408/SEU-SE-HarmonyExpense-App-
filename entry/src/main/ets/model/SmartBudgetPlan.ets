/**
 * 智能预算规划模型
 *
 * 功能：
 * 1. 基于历史消费的预算自动规划
 * 2. 支持多种预测算法
 * 3. 季节性消费模式识别
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

// ==================== 常量定义 ====================

/**
 * 预测算法
 */
export const FORECAST_SIMPLE_MOVING_AVG = 'simple_moving_avg';
export const FORECAST_WEIGHTED_MOVING_AVG = 'weighted_moving_avg';
export const FORECAST_EXPONENTIAL_SMOOTH = 'exponential_smooth';
export const FORECAST_HOLT_WINTERS = 'holt_winters';
export const FORECAST_LINEAR_REGRESSION = 'linear_regression';
export const FORECAST_ENSEMBLE = 'ensemble';

/**
 * 预算建议类型
 */
export const ADVICE_INCREASE = 'increase';
export const ADVICE_DECREASE = 'decrease';
export const ADVICE_MAINTAIN = 'maintain';
export const ADVICE_WARNING = 'warning';
export const ADVICE_OPTIMIZATION = 'optimization';

/**
 * 季节性类型
 */
export const SEASONALITY_NONE = 'none';
export const SEASONALITY_WEEKLY = 'weekly';
export const SEASONALITY_MONTHLY = 'monthly';
export const SEASONALITY_QUARTERLY = 'quarterly';
export const SEASONALITY_YEARLY = 'yearly';

// ==================== 接口定义 ====================

/**
 * 预测结果接口
 */
export interface ForecastResult {
  period: string;
  predictedAmount: number;
  lowerBound: number;
  upperBound: number;
  confidence: number;
  algorithm: string;
}

/**
 * 预算建议接口
 */
export interface BudgetAdvice {
  adviceId: string;
  categoryId: number;
  categoryName: string;
  adviceType: string;
  currentBudget: number;
  suggestedBudget: number;
  changePercent: number;
  reason: string;
  priority: number;
  potentialSavings: number;
  historicalTrend: string;
}

/**
 * 分类预算分配接口
 */
export interface CategoryBudgetAllocation {
  categoryId: number;
  categoryName: string;
  allocatedAmount: number;
  percentage: number;
  historicalAvg: number;
  predictedAmount: number;
  priority: string;
  flexibility: number;
}

/**
 * 季节性因子接口
 */
export interface SeasonalFactor {
  period: string;
  factor: number;
  seasonType: string;
  description: string;
}

/**
 * 历史数据点接口
 */
export interface HistoricalDataPoint {
  period: string;
  amount: number;
  categoryId: number;
}

/**
 * 智能预算计划接口
 */
export interface SmartBudgetPlanJSON {
  planId: number;
  userId: number;
  planName: string;
  period: string;
  startDate: string;
  endDate: string;
  totalBudget: number;
  categoryBudgets: CategoryBudgetAllocation[];
  forecasts: ForecastResult[];
  advices: BudgetAdvice[];
  seasonalFactors: SeasonalFactor[];
  generatedAt: string;
  algorithm: string;
  accuracy: number;
  status: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 预测引擎配置接口
 */
export interface ForecastEngineConfig {
  algorithm: string;
  windowSize: number;
  alpha: number;
  beta: number;
  gamma: number;
  seasonalPeriod: number;
  confidenceLevel: number;
  minDataPoints: number;
}

/**
 * 线性回归结果接口
 */
export interface LinearRegressionResult {
  slope: number;
  intercept: number;
}

/**
 * 置信区间接口
 */
export interface ConfidenceInterval {
  lower: number;
  upper: number;
}

/**
 * 集成预测结果接口
 */
export interface EnsembleForecastResult {
  predicted: number;
  confidence: number;
}

// ==================== 类实现 ====================

/**
 * 智能预算计划类
 */
export class SmartBudgetPlan {
  static readonly tableName: string = 'smart_budget_plans';

  planId: number = 0;
  userId: number = 0;
  planName: string = '';
  period: string = 'monthly';
  startDate: string = '';
  endDate: string = '';
  totalBudget: number = 0;
  categoryBudgetsJson: string = '[]';
  forecastsJson: string = '[]';
  advicesJson: string = '[]';
  seasonalFactorsJson: string = '[]';
  generatedAt: string = '';
  algorithm: string = FORECAST_ENSEMBLE;
  accuracy: number = 0;
  status: string = 'draft';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    planId: number = 0,
    userId: number = 0,
    planName: string = '',
    period: string = 'monthly',
    startDate: string = '',
    endDate: string = '',
    totalBudget: number = 0,
    categoryBudgetsJson: string = '[]',
    forecastsJson: string = '[]',
    advicesJson: string = '[]',
    seasonalFactorsJson: string = '[]',
    generatedAt: string = '',
    algorithm: string = FORECAST_ENSEMBLE,
    accuracy: number = 0,
    status: string = 'draft',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.planId = planId;
    this.userId = userId;
    this.planName = planName;
    this.period = period;
    this.startDate = startDate;
    this.endDate = endDate;
    this.totalBudget = totalBudget;
    this.categoryBudgetsJson = categoryBudgetsJson;
    this.forecastsJson = forecastsJson;
    this.advicesJson = advicesJson;
    this.seasonalFactorsJson = seasonalFactorsJson;
    this.generatedAt = generatedAt;
    this.algorithm = algorithm;
    this.accuracy = accuracy;
    this.status = status;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  /**
   * 获取分类预算分配
   */
  getCategoryBudgets(): CategoryBudgetAllocation[] {
    try {
      const parsed = JSON.parse(this.categoryBudgetsJson) as CategoryBudgetAllocation[];
      return parsed;
    } catch (e) {
      return [];
    }
  }

  /**
   * 设置分类预算分配
   */
  setCategoryBudgets(budgets: CategoryBudgetAllocation[]): void {
    this.categoryBudgetsJson = JSON.stringify(budgets);
  }

  /**
   * 获取预测结果
   */
  getForecasts(): ForecastResult[] {
    try {
      const parsed = JSON.parse(this.forecastsJson) as ForecastResult[];
      return parsed;
    } catch (e) {
      return [];
    }
  }

  /**
   * 获取预算建议
   */
  getAdvices(): BudgetAdvice[] {
    try {
      const parsed = JSON.parse(this.advicesJson) as BudgetAdvice[];
      return parsed;
    } catch (e) {
      return [];
    }
  }

  /**
   * 获取季节性因子
   */
  getSeasonalFactors(): SeasonalFactor[] {
    try {
      const parsed = JSON.parse(this.seasonalFactorsJson) as SeasonalFactor[];
      return parsed;
    } catch (e) {
      return [];
    }
  }

  toJSON(): SmartBudgetPlanJSON {
    const result: SmartBudgetPlanJSON = {
      planId: this.planId,
      userId: this.userId,
      planName: this.planName,
      period: this.period,
      startDate: this.startDate,
      endDate: this.endDate,
      totalBudget: this.totalBudget,
      categoryBudgets: this.getCategoryBudgets(),
      forecasts: this.getForecasts(),
      advices: this.getAdvices(),
      seasonalFactors: this.getSeasonalFactors(),
      generatedAt: this.generatedAt,
      algorithm: this.algorithm,
      accuracy: this.accuracy,
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
      this.planName.trim().length > 0 &&
      this.totalBudget >= 0
    );
  }
}

/**
 * 预算预测工具类
 */
export class BudgetForecastUtils {

  /**
   * 简单移动平均
   */
  static simpleMovingAverage(data: number[], windowSize: number): number {
    if (data.length === 0) {
      return 0;
    }
    const actualWindow = Math.min(windowSize, data.length);
    let sum = 0;
    const startIndex = data.length - actualWindow;
    for (let i = startIndex; i < data.length; i++) {
      sum += data[i];
    }
    return sum / actualWindow;
  }

  /**
   * 加权移动平均
   */
  static weightedMovingAverage(data: number[], windowSize: number): number {
    if (data.length === 0) {
      return 0;
    }
    const actualWindow = Math.min(windowSize, data.length);
    const startIndex = data.length - actualWindow;

    let weightSum = 0;
    let result = 0;

    for (let i = 0; i < actualWindow; i++) {
      const weight = i + 1;
      result += data[startIndex + i] * weight;
      weightSum += weight;
    }

    if (weightSum === 0) {
      return 0;
    }
    return result / weightSum;
  }

  /**
   * 指数平滑
   */
  static exponentialSmoothing(data: number[], alpha: number): number {
    if (data.length === 0) {
      return 0;
    }
    if (data.length === 1) {
      return data[0];
    }

    let smoothed = data[0];
    for (let i = 1; i < data.length; i++) {
      smoothed = alpha * data[i] + (1 - alpha) * smoothed;
    }

    return smoothed;
  }

  /**
   * Holt-Winters 双参数指数平滑
   */
  static holtWintersDouble(data: number[], alpha: number, beta: number, periodsAhead: number): number {
    if (data.length < 2) {
      if (data.length === 1) {
        return data[0];
      }
      return 0;
    }

    let level = data[0];
    let trend = data[1] - data[0];

    for (let i = 1; i < data.length; i++) {
      const prevLevel = level;
      level = alpha * data[i] + (1 - alpha) * (level + trend);
      trend = beta * (level - prevLevel) + (1 - beta) * trend;
    }

    return level + periodsAhead * trend;
  }

  /**
   * 线性回归预测
   */
  static linearRegression(data: number[]): LinearRegressionResult {
    const n = data.length;
    if (n === 0) {
      const empty: LinearRegressionResult = {
        slope: 0,
        intercept: 0
      };
      return empty;
    }

    let sumX = 0;
    let sumY = 0;
    let sumXY = 0;
    let sumX2 = 0;

    for (let i = 0; i < n; i++) {
      sumX += i;
      sumY += data[i];
      sumXY += i * data[i];
      sumX2 += i * i;
    }

    const denominator = n * sumX2 - sumX * sumX;
    if (denominator === 0) {
      const result: LinearRegressionResult = {
        slope: 0,
        intercept: sumY / n
      };
      return result;
    }

    const slope = (n * sumXY - sumX * sumY) / denominator;
    const intercept = (sumY - slope * sumX) / n;

    const result: LinearRegressionResult = {
      slope: slope,
      intercept: intercept
    };
    return result;
  }

  /**
   * 使用线性回归预测未来值
   */
  static predictWithRegression(regression: LinearRegressionResult, x: number): number {
    return regression.slope * x + regression.intercept;
  }

  /**
   * 计算预测置信区间
   */
  static calculateConfidenceInterval(
    predicted: number,
    historicalData: number[],
    confidenceLevel: number
  ): ConfidenceInterval {
    if (historicalData.length < 2) {
      const result: ConfidenceInterval = {
        lower: predicted * 0.8,
        upper: predicted * 1.2
      };
      return result;
    }

    // 计算均值
    let sum = 0;
    for (let i = 0; i < historicalData.length; i++) {
      sum += historicalData[i];
    }
    const mean = sum / historicalData.length;

    // 计算标准差
    let varianceSum = 0;
    for (let i = 0; i < historicalData.length; i++) {
      varianceSum += Math.pow(historicalData[i] - mean, 2);
    }
    const variance = varianceSum / historicalData.length;
    const stdDev = Math.sqrt(variance);

    // 计算z值
    let zScore = 1.645; // 默认90%
    if (confidenceLevel >= 0.99) {
      zScore = 2.576;
    } else if (confidenceLevel >= 0.95) {
      zScore = 1.96;
    }

    const margin = zScore * stdDev;

    const result: ConfidenceInterval = {
      lower: Math.max(0, predicted - margin),
      upper: predicted + margin
    };
    return result;
  }

  /**
   * 集成预测
   */
  static ensembleForecast(data: number[], config: ForecastEngineConfig): EnsembleForecastResult {
    if (data.length === 0) {
      const empty: EnsembleForecastResult = {
        predicted: 0,
        confidence: 0
      };
      return empty;
    }

    const predictions: number[] = [];
    const weights: number[] = [];

    // 简单移动平均
    const sma = BudgetForecastUtils.simpleMovingAverage(data, config.windowSize);
    predictions.push(sma);
    weights.push(0.15);

    // 加权移动平均
    const wma = BudgetForecastUtils.weightedMovingAverage(data, config.windowSize);
    predictions.push(wma);
    weights.push(0.20);

    // 指数平滑
    const es = BudgetForecastUtils.exponentialSmoothing(data, config.alpha);
    predictions.push(es);
    weights.push(0.25);

    // Holt-Winters
    if (data.length >= 3) {
      const hw = BudgetForecastUtils.holtWintersDouble(data, config.alpha, config.beta, 1);
      predictions.push(hw);
      weights.push(0.25);
    }

    // 线性回归
    const regression = BudgetForecastUtils.linearRegression(data);
    const lr = BudgetForecastUtils.predictWithRegression(regression, data.length);
    predictions.push(lr);
    weights.push(0.15);

    // 加权平均
    let weightedSum = 0;
    let totalWeight = 0;
    for (let i = 0; i < predictions.length; i++) {
      const pred = predictions[i];
      if (!isNaN(pred) && isFinite(pred)) {
        weightedSum += pred * weights[i];
        totalWeight += weights[i];
      }
    }

    const predicted = totalWeight > 0 ? weightedSum / totalWeight : 0;

    // 计算一致性作为置信度
    let varianceSum = 0;
    let validCount = 0;
    for (let i = 0; i < predictions.length; i++) {
      const pred = predictions[i];
      if (!isNaN(pred) && isFinite(pred)) {
        varianceSum += Math.pow(pred - predicted, 2);
        validCount++;
      }
    }

    let confidence = 0;
    if (validCount > 0 && predicted !== 0) {
      const variance = varianceSum / validCount;
      const consistency = 1 / (1 + Math.sqrt(variance) / Math.abs(predicted));
      confidence = Math.round(consistency * 100) / 100;
    }

    const result: EnsembleForecastResult = {
      predicted: Math.round(predicted * 100) / 100,
      confidence: confidence
    };
    return result;
  }

  /**
   * 创建默认预测配置
   */
  static createDefaultConfig(): ForecastEngineConfig {
    const config: ForecastEngineConfig = {
      algorithm: FORECAST_ENSEMBLE,
      windowSize: 6,
      alpha: 0.3,
      beta: 0.1,
      gamma: 0.2,
      seasonalPeriod: 12,
      confidenceLevel: 0.95,
      minDataPoints: 12
    };
    return config;
  }

  /**
   * 创建预测结果对象
   */
  static createForecastResult(
    period: string,
    predictedAmount: number,
    lowerBound: number,
    upperBound: number,
    confidence: number,
    algorithm: string
  ): ForecastResult {
    const result: ForecastResult = {
      period: period,
      predictedAmount: predictedAmount,
      lowerBound: lowerBound,
      upperBound: upperBound,
      confidence: confidence,
      algorithm: algorithm
    };
    return result;
  }

  /**
   * 创建预算建议对象
   */
  static createBudgetAdvice(
    adviceId: string,
    categoryId: number,
    categoryName: string,
    adviceType: string,
    currentBudget: number,
    suggestedBudget: number,
    reason: string,
    priority: number,
    potentialSavings: number,
    historicalTrend: string
  ): BudgetAdvice {
    const changePercent = currentBudget !== 0 ?
      ((suggestedBudget - currentBudget) / currentBudget) * 100 : 0;

    const result: BudgetAdvice = {
      adviceId: adviceId,
      categoryId: categoryId,
      categoryName: categoryName,
      adviceType: adviceType,
      currentBudget: currentBudget,
      suggestedBudget: suggestedBudget,
      changePercent: changePercent,
      reason: reason,
      priority: priority,
      potentialSavings: potentialSavings,
      historicalTrend: historicalTrend
    };
    return result;
  }
}
