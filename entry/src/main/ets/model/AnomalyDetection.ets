/**
 * 异常消费检测模型
 *
 * 功能：
 * 1. 基于统计学方法检测异常消费
 * 2. 支持多种检测算法（3σ原则、Z-Score、IQR）
 * 3. 实时告警和历史记录
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import { Bill } from './Bill';

// ==================== 常量定义 ====================

/**
 * 异常类型
 */
export const ANOMALY_TYPE_HIGH_AMOUNT = 'high_amount';
export const ANOMALY_TYPE_LOW_AMOUNT = 'low_amount';
export const ANOMALY_TYPE_FREQUENCY_SPIKE = 'frequency_spike';
export const ANOMALY_TYPE_UNUSUAL_TIME = 'unusual_time';
export const ANOMALY_TYPE_UNUSUAL_CATEGORY = 'unusual_category';
export const ANOMALY_TYPE_PATTERN_BREAK = 'pattern_break';

/**
 * 异常严重程度
 */
export const SEVERITY_LOW = 'low';
export const SEVERITY_MEDIUM = 'medium';
export const SEVERITY_HIGH = 'high';
export const SEVERITY_CRITICAL = 'critical';

/**
 * 检测算法
 */
export const ALGORITHM_SIGMA_3 = 'sigma_3';
export const ALGORITHM_Z_SCORE = 'z_score';
export const ALGORITHM_IQR = 'iqr';
export const ALGORITHM_MOVING_AVG = 'moving_avg';
export const ALGORITHM_ENSEMBLE = 'ensemble';

// ==================== 接口定义 ====================

/**
 * 期望范围接口
 */
export interface ExpectedRange {
  min: number;
  max: number;
}

/**
 * 检测详情接口
 */
export interface DetectionDetails {
  expectedRange: ExpectedRange;
  actualValue: number;
  deviation: number;
  percentile: number;
}

/**
 * 异常检测结果接口
 */
export interface AnomalyDetectionResult {
  isAnomaly: boolean;
  anomalyType: string;
  severity: string;
  score: number;
  algorithm: string;
  details: DetectionDetails;
}

/**
 * 异常记录接口
 */
export interface AnomalyRecordJSON {
  anomalyId: number;
  userId: number;
  billId: number;
  anomalyType: string;
  severity: string;
  algorithm: string;
  score: number;
  threshold: number;
  expectedValue: number;
  actualValue: number;
  deviation: number;
  description: string;
  isAcknowledged: number;
  acknowledgedAt: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 统计摘要接口
 */
export interface StatisticalSummary {
  mean: number;
  median: number;
  stdDev: number;
  variance: number;
  min: number;
  max: number;
  q1: number;
  q3: number;
  iqr: number;
  sampleSize: number;
}

/**
 * 用户消费基线接口
 */
export interface UserSpendingBaselineJSON {
  baselineId: number;
  userId: number;
  categoryId: number;
  period: string;
  statistics: StatisticalSummary;
  lastCalculatedAt: string;
  sampleStartDate: string;
  sampleEndDate: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 异常检测配置接口
 */
export interface AnomalyDetectionConfig {
  enabled: boolean;
  algorithms: string[];
  sigmaThreshold: number;
  zScoreThreshold: number;
  iqrMultiplier: number;
  minSampleSize: number;
  lookbackDays: number;
  categorySpecific: boolean;
  timeWindowHours: number;
}

// ==================== 类实现 ====================

/**
 * 异常记录类
 */
export class AnomalyRecord {
  static readonly tableName: string = 'anomaly_records';

  anomalyId: number = 0;
  userId: number = 0;
  billId: number = 0;
  anomalyType: string = ANOMALY_TYPE_HIGH_AMOUNT;
  severity: string = SEVERITY_LOW;
  algorithm: string = ALGORITHM_SIGMA_3;
  score: number = 0;
  threshold: number = 0;
  expectedValue: number = 0;
  actualValue: number = 0;
  deviation: number = 0;
  description: string = '';
  isAcknowledged: number = 0;
  acknowledgedAt: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    anomalyId: number = 0,
    userId: number = 0,
    billId: number = 0,
    anomalyType: string = ANOMALY_TYPE_HIGH_AMOUNT,
    severity: string = SEVERITY_LOW,
    algorithm: string = ALGORITHM_SIGMA_3,
    score: number = 0,
    threshold: number = 0,
    expectedValue: number = 0,
    actualValue: number = 0,
    deviation: number = 0,
    description: string = '',
    isAcknowledged: number = 0,
    acknowledgedAt: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.anomalyId = anomalyId;
    this.userId = userId;
    this.billId = billId;
    this.anomalyType = anomalyType;
    this.severity = severity;
    this.algorithm = algorithm;
    this.score = score;
    this.threshold = threshold;
    this.expectedValue = expectedValue;
    this.actualValue = actualValue;
    this.deviation = deviation;
    this.description = description;
    this.isAcknowledged = isAcknowledged;
    this.acknowledgedAt = acknowledgedAt;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  toJSON(): AnomalyRecordJSON {
    const result: AnomalyRecordJSON = {
      anomalyId: this.anomalyId,
      userId: this.userId,
      billId: this.billId,
      anomalyType: this.anomalyType,
      severity: this.severity,
      algorithm: this.algorithm,
      score: this.score,
      threshold: this.threshold,
      expectedValue: this.expectedValue,
      actualValue: this.actualValue,
      deviation: this.deviation,
      description: this.description,
      isAcknowledged: this.isAcknowledged,
      acknowledgedAt: this.acknowledgedAt,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: AnomalyRecordJSON): AnomalyRecord {
    return new AnomalyRecord(
      data.anomalyId,
      data.userId,
      data.billId,
      data.anomalyType,
      data.severity,
      data.algorithm,
      data.score,
      data.threshold,
      data.expectedValue,
      data.actualValue,
      data.deviation,
      data.description,
      data.isAcknowledged,
      data.acknowledgedAt,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      this.billId > 0 &&
      this.score >= 0
    );
  }

  /**
   * 确认异常
   */
  acknowledge(): void {
    this.isAcknowledged = 1;
    this.acknowledgedAt = new Date().toISOString();
    this.updatedAt = new Date().toISOString();
  }

  /**
   * 获取严重程度对应的颜色
   */
  getSeverityColor(): string {
    if (this.severity === SEVERITY_LOW) {
      return '#4CAF50';
    } else if (this.severity === SEVERITY_MEDIUM) {
      return '#FF9800';
    } else if (this.severity === SEVERITY_HIGH) {
      return '#F44336';
    } else if (this.severity === SEVERITY_CRITICAL) {
      return '#9C27B0';
    }
    return '#9E9E9E';
  }
}

/**
 * 用户消费基线类
 */
export class UserSpendingBaseline {
  static readonly tableName: string = 'user_spending_baselines';

  baselineId: number = 0;
  userId: number = 0;
  categoryId: number = 0;
  period: string = 'monthly';
  mean: number = 0;
  median: number = 0;
  stdDev: number = 0;
  variance: number = 0;
  min: number = 0;
  max: number = 0;
  q1: number = 0;
  q3: number = 0;
  iqr: number = 0;
  sampleSize: number = 0;
  lastCalculatedAt: string = '';
  sampleStartDate: string = '';
  sampleEndDate: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  // DAOHelper 需要的额外属性
  avgDailySpending: number = 0;
  stdDeviation: number = 0;
  maxDailySpending: number = 0;
  minDailySpending: number = 0;
  avgTransactionFrequency: number = 0;
  totalTransactions: number = 0;
  analysisStartDate: string = '';
  analysisEndDate: string = '';
  lastUpdatedAt: string = '';

  constructor(
    baselineId: number = 0,
    userId: number = 0,
    categoryId: number = 0,
    period: string = 'monthly',
    mean: number = 0,
    median: number = 0,
    stdDev: number = 0,
    variance: number = 0,
    min: number = 0,
    max: number = 0,
    q1: number = 0,
    q3: number = 0,
    iqr: number = 0,
    sampleSize: number = 0,
    lastCalculatedAt: string = '',
    sampleStartDate: string = '',
    sampleEndDate: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0,
    avgDailySpending: number = 0,
    stdDeviation: number = 0,
    maxDailySpending: number = 0,
    minDailySpending: number = 0,
    avgTransactionFrequency: number = 0,
    totalTransactions: number = 0,
    analysisStartDate: string = '',
    analysisEndDate: string = '',
    lastUpdatedAt: string = ''
  ) {
    this.baselineId = baselineId;
    this.userId = userId;
    this.categoryId = categoryId;
    this.period = period;
    this.mean = mean;
    this.median = median;
    this.stdDev = stdDev;
    this.variance = variance;
    this.min = min;
    this.max = max;
    this.q1 = q1;
    this.q3 = q3;
    this.iqr = iqr;
    this.sampleSize = sampleSize;
    this.lastCalculatedAt = lastCalculatedAt;
    this.sampleStartDate = sampleStartDate;
    this.sampleEndDate = sampleEndDate;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
    this.avgDailySpending = avgDailySpending;
    this.stdDeviation = stdDeviation;
    this.maxDailySpending = maxDailySpending;
    this.minDailySpending = minDailySpending;
    this.avgTransactionFrequency = avgTransactionFrequency;
    this.totalTransactions = totalTransactions;
    this.analysisStartDate = analysisStartDate;
    this.analysisEndDate = analysisEndDate;
    this.lastUpdatedAt = lastUpdatedAt;
  }

  /**
   * 获取统计摘要
   */
  getStatistics(): StatisticalSummary {
    const result: StatisticalSummary = {
      mean: this.mean,
      median: this.median,
      stdDev: this.stdDev,
      variance: this.variance,
      min: this.min,
      max: this.max,
      q1: this.q1,
      q3: this.q3,
      iqr: this.iqr,
      sampleSize: this.sampleSize
    };
    return result;
  }

  /**
   * 使用3σ原则检测异常
   */
  detectBySigma3(value: number): AnomalyDetectionResult {
    const lowerBound = this.mean - 3 * this.stdDev;
    const upperBound = this.mean + 3 * this.stdDev;
    const isAnomaly = value < lowerBound || value > upperBound;
    let deviation = 0;
    if (this.stdDev > 0) {
      deviation = Math.abs(value - this.mean) / this.stdDev;
    }

    let anomalyType = '';
    if (isAnomaly) {
      anomalyType = value > upperBound ? ANOMALY_TYPE_HIGH_AMOUNT : ANOMALY_TYPE_LOW_AMOUNT;
    }

    const severity = AnomalyDetectionUtils.calculateSeverity(deviation);
    const percentile = AnomalyDetectionUtils.calculatePercentile(value, this.mean, this.stdDev);

    const expectedRange: ExpectedRange = {
      min: lowerBound,
      max: upperBound
    };

    const details: DetectionDetails = {
      expectedRange: expectedRange,
      actualValue: value,
      deviation: this.mean !== 0 ? ((value - this.mean) / this.mean) * 100 : 0,
      percentile: percentile
    };

    const result: AnomalyDetectionResult = {
      isAnomaly: isAnomaly,
      anomalyType: anomalyType,
      severity: severity,
      score: deviation,
      algorithm: ALGORITHM_SIGMA_3,
      details: details
    };

    return result;
  }

  /**
   * 使用Z-Score检测异常
   */
  detectByZScore(value: number, threshold: number = 2.5): AnomalyDetectionResult {
    let zScore = 0;
    if (this.stdDev > 0) {
      zScore = (value - this.mean) / this.stdDev;
    }
    const absZScore = Math.abs(zScore);
    const isAnomaly = absZScore > threshold;

    let anomalyType = '';
    if (isAnomaly) {
      anomalyType = zScore > 0 ? ANOMALY_TYPE_HIGH_AMOUNT : ANOMALY_TYPE_LOW_AMOUNT;
    }

    const severity = AnomalyDetectionUtils.calculateSeverity(absZScore);
    const percentile = AnomalyDetectionUtils.calculatePercentile(value, this.mean, this.stdDev);

    const expectedRange: ExpectedRange = {
      min: this.mean - threshold * this.stdDev,
      max: this.mean + threshold * this.stdDev
    };

    const details: DetectionDetails = {
      expectedRange: expectedRange,
      actualValue: value,
      deviation: this.mean !== 0 ? ((value - this.mean) / this.mean) * 100 : 0,
      percentile: percentile
    };

    const result: AnomalyDetectionResult = {
      isAnomaly: isAnomaly,
      anomalyType: anomalyType,
      severity: severity,
      score: absZScore,
      algorithm: ALGORITHM_Z_SCORE,
      details: details
    };

    return result;
  }

  /**
   * 使用IQR方法检测异常
   */
  detectByIQR(value: number, multiplier: number = 1.5): AnomalyDetectionResult {
    const lowerBound = this.q1 - multiplier * this.iqr;
    const upperBound = this.q3 + multiplier * this.iqr;
    const isAnomaly = value < lowerBound || value > upperBound;

    let score = 0;
    if (isAnomaly) {
      if (value > upperBound) {
        score = this.iqr > 0 ? (value - upperBound) / this.iqr : 0;
      } else {
        score = this.iqr > 0 ? (lowerBound - value) / this.iqr : 0;
      }
    }

    let anomalyType = '';
    if (isAnomaly) {
      anomalyType = value > upperBound ? ANOMALY_TYPE_HIGH_AMOUNT : ANOMALY_TYPE_LOW_AMOUNT;
    }

    const severity = AnomalyDetectionUtils.calculateSeverity(score);
    const percentile = AnomalyDetectionUtils.calculatePercentile(value, this.mean, this.stdDev);

    const expectedRange: ExpectedRange = {
      min: Math.max(0, lowerBound),
      max: upperBound
    };

    const details: DetectionDetails = {
      expectedRange: expectedRange,
      actualValue: value,
      deviation: this.median !== 0 ? ((value - this.median) / this.median) * 100 : 0,
      percentile: percentile
    };

    const result: AnomalyDetectionResult = {
      isAnomaly: isAnomaly,
      anomalyType: anomalyType,
      severity: severity,
      score: score,
      algorithm: ALGORITHM_IQR,
      details: details
    };

    return result;
  }

  toJSON(): UserSpendingBaselineJSON {
    const statistics: StatisticalSummary = this.getStatistics();
    const result: UserSpendingBaselineJSON = {
      baselineId: this.baselineId,
      userId: this.userId,
      categoryId: this.categoryId,
      period: this.period,
      statistics: statistics,
      lastCalculatedAt: this.lastCalculatedAt,
      sampleStartDate: this.sampleStartDate,
      sampleEndDate: this.sampleEndDate,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      this.sampleSize >= 0 &&
      this.stdDev >= 0
    );
  }
}

/**
 * 异常检测工具类
 */
export class AnomalyDetectionUtils {

  /**
   * 计算百分位数
   */
  static calculatePercentile(value: number, mean: number, stdDev: number): number {
    if (stdDev === 0) {
      return 50;
    }
    const zScore = (value - mean) / stdDev;
    const t = 1 / (1 + 0.2316419 * Math.abs(zScore));
    const d = 0.3989423 * Math.exp(-zScore * zScore / 2);
    const p = d * t * (0.3193815 + t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))));
    if (zScore > 0) {
      return (1 - p) * 100;
    }
    return p * 100;
  }

  /**
   * 计算严重程度
   */
  static calculateSeverity(score: number): string {
    if (score < 2) {
      return '';
    }
    if (score < 3) {
      return SEVERITY_LOW;
    }
    if (score < 4) {
      return SEVERITY_MEDIUM;
    }
    if (score < 5) {
      return SEVERITY_HIGH;
    }
    return SEVERITY_CRITICAL;
  }

  /**
   * 从数据数组计算统计摘要
   */
  static calculateStatistics(data: number[]): StatisticalSummary {
    const n = data.length;
    if (n === 0) {
      const empty: StatisticalSummary = {
        mean: 0,
        median: 0,
        stdDev: 0,
        variance: 0,
        min: 0,
        max: 0,
        q1: 0,
        q3: 0,
        iqr: 0,
        sampleSize: 0
      };
      return empty;
    }

    // 排序数据
    const sorted: number[] = [];
    for (let i = 0; i < data.length; i++) {
      sorted.push(data[i]);
    }
    sorted.sort((a: number, b: number) => a - b);

    // 计算均值
    let sum = 0;
    for (let i = 0; i < n; i++) {
      sum += data[i];
    }
    const mean = sum / n;

    // 计算方差和标准差
    let varianceSum = 0;
    for (let i = 0; i < n; i++) {
      varianceSum += Math.pow(data[i] - mean, 2);
    }
    const variance = varianceSum / n;
    const stdDev = Math.sqrt(variance);

    // 计算中位数
    let median = 0;
    if (n % 2 === 0) {
      median = (sorted[n / 2 - 1] + sorted[n / 2]) / 2;
    } else {
      median = sorted[Math.floor(n / 2)];
    }

    // 计算四分位数
    const q1Index = Math.floor(n * 0.25);
    const q3Index = Math.floor(n * 0.75);
    const q1 = sorted[q1Index];
    const q3 = sorted[q3Index];
    const iqr = q3 - q1;

    const result: StatisticalSummary = {
      mean: mean,
      median: median,
      stdDev: stdDev,
      variance: variance,
      min: sorted[0],
      max: sorted[n - 1],
      q1: q1,
      q3: q3,
      iqr: iqr,
      sampleSize: n
    };
    return result;
  }

  /**
   * 创建默认配置
   */
  static createDefaultConfig(): AnomalyDetectionConfig {
    const config: AnomalyDetectionConfig = {
      enabled: true,
      algorithms: [ALGORITHM_ENSEMBLE],
      sigmaThreshold: 3,
      zScoreThreshold: 2.5,
      iqrMultiplier: 1.5,
      minSampleSize: 30,
      lookbackDays: 90,
      categorySpecific: true,
      timeWindowHours: 24
    };
    return config;
  }

  // ==================== Bill集成方法 ====================

  /**
   * 从账单列表中提取金额数组
   * @param bills 账单列表
   * @param expenseOnly 是否只包含支出
   */
  static extractAmountsFromBills(bills: Bill[], expenseOnly: boolean = true): number[] {
    const amounts: number[] = [];
    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.isDeleted === 0) {
        if (expenseOnly) {
          if (bill.type === 'expense') {
            amounts.push(bill.amount);
          }
        } else {
          amounts.push(bill.amount);
        }
      }
    }
    return amounts;
  }

  /**
   * 从账单列表计算基线
   * @param bills 账单列表
   * @param userId 用户ID
   * @param categoryId 分类ID（0表示所有分类）
   */
  static calculateBaselineFromBills(
    bills: Bill[],
    userId: number,
    categoryId: number = 0
  ): UserSpendingBaseline {
    // 筛选符合条件的账单
    const filteredBills: Bill[] = [];
    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.userId === userId && bill.isDeleted === 0 && bill.type === 'expense') {
        if (categoryId === 0 || bill.categoryId === categoryId) {
          filteredBills.push(bill);
        }
      }
    }

    // 提取金额
    const amounts = AnomalyDetectionUtils.extractAmountsFromBills(filteredBills, true);

    // 计算统计数据
    const stats = AnomalyDetectionUtils.calculateStatistics(amounts);

    // 获取日期范围
    let startDate = '';
    let endDate = '';
    if (filteredBills.length > 0) {
      const dates: string[] = [];
      for (let i = 0; i < filteredBills.length; i++) {
        dates.push(filteredBills[i].transactionDate);
      }
      dates.sort();
      startDate = dates[0];
      endDate = dates[dates.length - 1];
    }

    const now = new Date().toISOString();
    const baseline = new UserSpendingBaseline(
      0,
      userId,
      categoryId,
      'monthly',
      stats.mean,
      stats.median,
      stats.stdDev,
      stats.variance,
      stats.min,
      stats.max,
      stats.q1,
      stats.q3,
      stats.iqr,
      stats.sampleSize,
      now,
      startDate,
      endDate,
      now,
      now,
      0
    );

    return baseline;
  }

  /**
   * 检测单个账单是否异常
   * @param bill 待检测账单
   * @param baseline 用户消费基线
   * @param algorithm 检测算法
   */
  static detectBillAnomaly(
    bill: Bill,
    baseline: UserSpendingBaseline,
    algorithm: string = ALGORITHM_ENSEMBLE
  ): AnomalyDetectionResult {
    // 只检测支出类型
    if (bill.type !== 'expense') {
      const noAnomaly: AnomalyDetectionResult = {
        isAnomaly: false,
        anomalyType: '',
        severity: '',
        score: 0,
        algorithm: algorithm,
        details: {
          expectedRange: { min: 0, max: 0 },
          actualValue: bill.amount,
          deviation: 0,
          percentile: 50
        }
      };
      return noAnomaly;
    }

    // 根据算法选择检测方法
    if (algorithm === ALGORITHM_SIGMA_3) {
      return baseline.detectBySigma3(bill.amount);
    } else if (algorithm === ALGORITHM_Z_SCORE) {
      return baseline.detectByZScore(bill.amount);
    } else if (algorithm === ALGORITHM_IQR) {
      return baseline.detectByIQR(bill.amount);
    } else if (algorithm === ALGORITHM_ENSEMBLE) {
      // 集成方法：综合多种算法的结果
      return AnomalyDetectionUtils.detectByEnsemble(bill.amount, baseline);
    }

    return baseline.detectBySigma3(bill.amount);
  }

  /**
   * 集成检测方法
   * @param amount 金额
   * @param baseline 基线
   */
  static detectByEnsemble(amount: number, baseline: UserSpendingBaseline): AnomalyDetectionResult {
    const sigma3Result = baseline.detectBySigma3(amount);
    const zScoreResult = baseline.detectByZScore(amount);
    const iqrResult = baseline.detectByIQR(amount);

    // 投票机制：至少两种方法认为是异常
    let anomalyVotes = 0;
    if (sigma3Result.isAnomaly) {
      anomalyVotes++;
    }
    if (zScoreResult.isAnomaly) {
      anomalyVotes++;
    }
    if (iqrResult.isAnomaly) {
      anomalyVotes++;
    }

    const isAnomaly = anomalyVotes >= 2;

    // 取最高分数
    let maxScore = sigma3Result.score;
    if (zScoreResult.score > maxScore) {
      maxScore = zScoreResult.score;
    }
    if (iqrResult.score > maxScore) {
      maxScore = iqrResult.score;
    }

    // 确定异常类型
    let anomalyType = '';
    if (isAnomaly) {
      if (sigma3Result.isAnomaly) {
        anomalyType = sigma3Result.anomalyType;
      } else if (zScoreResult.isAnomaly) {
        anomalyType = zScoreResult.anomalyType;
      } else if (iqrResult.isAnomaly) {
        anomalyType = iqrResult.anomalyType;
      }
    }

    const severity = AnomalyDetectionUtils.calculateSeverity(maxScore);

    const result: AnomalyDetectionResult = {
      isAnomaly: isAnomaly,
      anomalyType: anomalyType,
      severity: severity,
      score: maxScore,
      algorithm: ALGORITHM_ENSEMBLE,
      details: sigma3Result.details
    };

    return result;
  }

  /**
   * 批量检测账单异常
   * @param bills 账单列表
   * @param baseline 用户消费基线
   * @param algorithm 检测算法
   */
  static detectBillsAnomaly(
    bills: Bill[],
    baseline: UserSpendingBaseline,
    algorithm: string = ALGORITHM_ENSEMBLE
  ): AnomalyRecord[] {
    const anomalies: AnomalyRecord[] = [];
    const now = new Date().toISOString();

    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.isDeleted === 0 && bill.type === 'expense') {
        const result = AnomalyDetectionUtils.detectBillAnomaly(bill, baseline, algorithm);

        if (result.isAnomaly) {
          const anomaly = new AnomalyRecord(
            0,
            bill.userId,
            bill.billId,
            result.anomalyType,
            result.severity,
            result.algorithm,
            result.score,
            3.0,
            baseline.mean,
            bill.amount,
            result.details.deviation,
            AnomalyDetectionUtils.generateDescription(bill, result),
            0,
            '',
            now,
            now,
            0
          );
          anomalies.push(anomaly);
        }
      }
    }

    return anomalies;
  }

  /**
   * 生成异常描述
   * @param bill 账单
   * @param result 检测结果
   */
  static generateDescription(bill: Bill, result: AnomalyDetectionResult): string {
    const amount = bill.amount.toFixed(2);
    const deviation = result.details.deviation.toFixed(1);

    if (result.anomalyType === ANOMALY_TYPE_HIGH_AMOUNT) {
      return '消费金额 ¥' + amount + ' 高于正常范围，偏离 ' + deviation + '%';
    } else if (result.anomalyType === ANOMALY_TYPE_LOW_AMOUNT) {
      return '消费金额 ¥' + amount + ' 低于正常范围，偏离 ' + deviation + '%';
    }

    return '检测到异常消费 ¥' + amount;
  }

  /**
   * 按分类分组计算基线
   * @param bills 账单列表
   * @param userId 用户ID
   */
  static calculateBaselinesByCategory(bills: Bill[], userId: number): UserSpendingBaseline[] {
    // 收集所有分类ID
    const categoryIds: number[] = [];
    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.userId === userId && bill.isDeleted === 0 && bill.type === 'expense') {
        let found = false;
        for (let j = 0; j < categoryIds.length; j++) {
          if (categoryIds[j] === bill.categoryId) {
            found = true;
            break;
          }
        }
        if (!found) {
          categoryIds.push(bill.categoryId);
        }
      }
    }

    // 为每个分类计算基线
    const baselines: UserSpendingBaseline[] = [];
    for (let i = 0; i < categoryIds.length; i++) {
      const baseline = AnomalyDetectionUtils.calculateBaselineFromBills(
        bills,
        userId,
        categoryIds[i]
      );
      baselines.push(baseline);
    }

    return baselines;
  }

  /**
   * 检测账单频率异常
   * @param bills 账单列表
   * @param windowDays 时间窗口天数
   */
  static detectFrequencyAnomaly(bills: Bill[], windowDays: number = 7): AnomalyDetectionResult {
    // 按日期分组统计每日账单数
    const dailyCounts: Map<string, number> = new Map();

    for (let i = 0; i < bills.length; i++) {
      const bill = bills[i];
      if (bill.isDeleted === 0 && bill.type === 'expense') {
        const date = bill.transactionDate.substring(0, 10);
        const current = dailyCounts.get(date);
        if (current !== undefined) {
          dailyCounts.set(date, current + 1);
        } else {
          dailyCounts.set(date, 1);
        }
      }
    }

    // 提取计数数组
    const counts: number[] = [];
    dailyCounts.forEach((count: number) => {
      counts.push(count);
    });

    if (counts.length < 3) {
      const noAnomaly: AnomalyDetectionResult = {
        isAnomaly: false,
        anomalyType: '',
        severity: '',
        score: 0,
        algorithm: ALGORITHM_SIGMA_3,
        details: {
          expectedRange: { min: 0, max: 0 },
          actualValue: 0,
          deviation: 0,
          percentile: 50
        }
      };
      return noAnomaly;
    }

    // 计算统计数据
    const stats = AnomalyDetectionUtils.calculateStatistics(counts);

    // 获取最近几天的平均频率
    const recentCounts: number[] = [];
    for (let i = Math.max(0, counts.length - windowDays); i < counts.length; i++) {
      recentCounts.push(counts[i]);
    }

    let recentAvg = 0;
    for (let i = 0; i < recentCounts.length; i++) {
      recentAvg += recentCounts[i];
    }
    recentAvg = recentAvg / recentCounts.length;

    // 检测是否异常
    let score = 0;
    if (stats.stdDev > 0) {
      score = Math.abs(recentAvg - stats.mean) / stats.stdDev;
    }

    const isAnomaly = score > 3;
    const severity = AnomalyDetectionUtils.calculateSeverity(score);

    const result: AnomalyDetectionResult = {
      isAnomaly: isAnomaly,
      anomalyType: isAnomaly ? ANOMALY_TYPE_FREQUENCY_SPIKE : '',
      severity: severity,
      score: score,
      algorithm: ALGORITHM_SIGMA_3,
      details: {
        expectedRange: {
          min: stats.mean - 3 * stats.stdDev,
          max: stats.mean + 3 * stats.stdDev
        },
        actualValue: recentAvg,
        deviation: stats.mean !== 0 ? ((recentAvg - stats.mean) / stats.mean) * 100 : 0,
        percentile: AnomalyDetectionUtils.calculatePercentile(recentAvg, stats.mean, stats.stdDev)
      }
    };

    return result;
  }

  /**
   * 检测时间异常（非正常时间消费）
   * @param bill 账单
   * @param normalStartHour 正常消费开始时间（小时）
   * @param normalEndHour 正常消费结束时间（小时）
   */
  static detectTimeAnomaly(
    bill: Bill,
    normalStartHour: number = 7,
    normalEndHour: number = 23
  ): AnomalyDetectionResult {
    const dateTime = new Date(bill.transactionDate);
    const hour = dateTime.getHours();

    const isUnusualTime = hour < normalStartHour || hour > normalEndHour;

    const result: AnomalyDetectionResult = {
      isAnomaly: isUnusualTime,
      anomalyType: isUnusualTime ? ANOMALY_TYPE_UNUSUAL_TIME : '',
      severity: isUnusualTime ? SEVERITY_LOW : '',
      score: isUnusualTime ? 1 : 0,
      algorithm: 'time_check',
      details: {
        expectedRange: { min: normalStartHour, max: normalEndHour },
        actualValue: hour,
        deviation: 0,
        percentile: 50
      }
    };

    return result;
  }
}
