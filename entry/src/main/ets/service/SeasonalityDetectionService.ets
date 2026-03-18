/**
 * 季节性检测服务 - 高级统计分析
 * 
 * 功能：
 * 1. 自相关分析（ACF）检测周期性
 * 2. 变异系数分析检测波动性
 * 3. 峰值检测识别季节性高峰
 * 4. 趋势分解（STL简化版）
 * 5. 多维度季节性评分
 * 
 * 算法说明：
 * - 使用自相关函数检测周期性模式
 * - 使用变异系数量化波动程度
 * - 使用Z-score检测异常峰值
 * - 综合多个指标判断季节性强度
 * 
 * @version 1.0.0
 * @author HarmonyExpense Team
 */

import hilog from '@ohos.hilog';
import { SeasonalFactor } from '../model/SmartBudgetPlan';

const LOG_TAG = 'SeasonalityDetectionService';
const HILOG_DOMAIN = 0x0003;

// ==================== 常量定义 ====================

/**
 * 季节性强度等级
 */
export const SEASONALITY_STRENGTH_NONE = 'none';
export const SEASONALITY_STRENGTH_WEAK = 'weak';
export const SEASONALITY_STRENGTH_MODERATE = 'moderate';
export const SEASONALITY_STRENGTH_STRONG = 'strong';

/**
 * 检测阈值配置
 */
export interface SeasonalityThresholds {
  minDataPoints: number;           // 最少数据点数
  acfThreshold: number;             // 自相关阈值
  cvThreshold: number;              // 变异系数阈值
  peakThreshold: number;            // 峰值检测阈值（Z-score）
  significanceLevel: number;        // 显著性水平
}

/**
 * 季节性分析结果
 */
export interface SeasonalityAnalysisResult {
  categoryId: number;
  categoryName: string;
  hasSeasonality: boolean;
  strength: string;
  period: number;                   // 检测到的周期（月数）
  confidence: number;               // 置信度（0-1）
  acfScore: number;                 // 自相关得分
  cvScore: number;                  // 变异系数得分
  peakMonths: number[];             // 高峰月份索引
  troughMonths: number[];           // 低谷月份索引
  seasonalityFactor: number;        // 季节性因子（最大值/平均值）
  description: string;
}

/**
 * 统计指标
 */
interface StatisticalMetrics {
  mean: number;
  median: number;
  stdDev: number;
  variance: number;
  cv: number;                       // 变异系数
  min: number;
  max: number;
  range: number;
}

// ==================== 核心服务类 ====================

export class SeasonalityDetectionService {

  /**
   * 检测季节性（主入口）
   * 
   * @param categoryId 分类ID
   * @param categoryName 分类名称
   * @param monthlyData 月度数据数组（按时间顺序）
   * @param thresholds 检测阈值配置（可选）
   * @returns 季节性分析结果
   */
  static detectSeasonality(
    categoryId: number,
    categoryName: string,
    monthlyData: number[],
    thresholds?: SeasonalityThresholds
  ): SeasonalityAnalysisResult {
    // 参数验证
    if (!monthlyData || monthlyData.length === 0) {
      return SeasonalityDetectionService.createEmptyResult(categoryId, categoryName);
    }

    // 使用默认阈值或自定义阈值
    const config = thresholds ?? SeasonalityDetectionService.getDefaultThresholds();

    // 数据点不足，无法检测
    if (monthlyData.length < config.minDataPoints) {
      hilog.info(HILOG_DOMAIN, LOG_TAG, 
        `分类${categoryName}数据点不足（${monthlyData.length}/${config.minDataPoints}），跳过季节性检测`);
      return SeasonalityDetectionService.createEmptyResult(categoryId, categoryName);
    }

    try {
      // 1. 计算基础统计指标
      const metrics = SeasonalityDetectionService.calculateStatistics(monthlyData);

      // 2. 自相关分析
      const acfResult = SeasonalityDetectionService.calculateACF(monthlyData, 12);
      const acfScore = SeasonalityDetectionService.evaluateACF(acfResult, config.acfThreshold);

      // 3. 变异系数分析
      const cvScore = SeasonalityDetectionService.evaluateCV(metrics.cv, config.cvThreshold);

      // 4. 峰值检测
      const peaks = SeasonalityDetectionService.detectPeaks(monthlyData, metrics, config.peakThreshold);
      const troughs = SeasonalityDetectionService.detectTroughs(monthlyData, metrics, config.peakThreshold);

      // 5. 检测周期
      const detectedPeriod = SeasonalityDetectionService.detectPeriod(acfResult);

      // 6. 综合评分
      const confidence = SeasonalityDetectionService.calculateConfidence(
        acfScore,
        cvScore,
        peaks.length,
        troughs.length,
        monthlyData.length
      );

      // 7. 判断季节性强度
      const strength = SeasonalityDetectionService.determineStrength(confidence);
      const hasSeasonality = strength !== SEASONALITY_STRENGTH_NONE;

      // 8. 计算季节性因子
      const seasonalityFactor = metrics.max / (metrics.mean || 1);

      // 9. 生成描述
      const description = SeasonalityDetectionService.generateDescription(
        categoryName,
        hasSeasonality,
        strength,
        detectedPeriod,
        peaks,
        troughs,
        seasonalityFactor
      );

      const result: SeasonalityAnalysisResult = {
        categoryId: categoryId,
        categoryName: categoryName,
        hasSeasonality: hasSeasonality,
        strength: strength,
        period: detectedPeriod,
        confidence: confidence,
        acfScore: acfScore,
        cvScore: cvScore,
        peakMonths: peaks,
        troughMonths: troughs,
        seasonalityFactor: seasonalityFactor,
        description: description
      };

      hilog.info(HILOG_DOMAIN, LOG_TAG, 
        `分类${categoryName}季节性检测完成：${hasSeasonality ? '存在' : '不存在'}，强度：${strength}，置信度：${confidence.toFixed(2)}`);

      return result;

    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `季节性检测失败: ${error.message}`);
      return SeasonalityDetectionService.createEmptyResult(categoryId, categoryName);
    }
  }

  /**
   * 批量检测季节性
   */
  static detectSeasonalityBatch(
    dataList: Array<{ categoryId: number; categoryName: string; monthlyData: number[] }>,
    thresholds?: SeasonalityThresholds
  ): SeasonalityAnalysisResult[] {
    const results: SeasonalityAnalysisResult[] = [];

    for (const item of dataList) {
      const result = SeasonalityDetectionService.detectSeasonality(
        item.categoryId,
        item.categoryName,
        item.monthlyData,
        thresholds
      );
      results.push(result);
    }

    return results;
  }

  /**
   * 转换为SeasonalFactor格式（兼容现有代码）
   */
  static convertToSeasonalFactors(results: SeasonalityAnalysisResult[]): SeasonalFactor[] {
    const factors: SeasonalFactor[] = [];

    for (const result of results) {
      if (result.hasSeasonality) {
        const factor: SeasonalFactor = {
          period: result.categoryName,
          factor: result.seasonalityFactor,
          seasonType: SeasonalityDetectionService.getPeriodType(result.period),
          description: result.description
        };
        factors.push(factor);
      }
    }

    return factors;
  }

  // ==================== 私有方法：统计计算 ====================

  /**
   * 计算基础统计指标
   */
  private static calculateStatistics(data: number[]): StatisticalMetrics {
    const n = data.length;
    if (n === 0) {
      return {
        mean: 0,
        median: 0,
        stdDev: 0,
        variance: 0,
        cv: 0,
        min: 0,
        max: 0,
        range: 0
      };
    }

    // 均值
    const sum = data.reduce((acc: number, val: number) => acc + val, 0);
    const mean = sum / n;

    // 中位数
    const sorted = [...data].sort((a: number, b: number) => a - b);
    const median = n % 2 === 0
      ? (sorted[n / 2 - 1] + sorted[n / 2]) / 2
      : sorted[Math.floor(n / 2)];

    // 方差和标准差
    const squaredDiffs = data.map((val: number) => Math.pow(val - mean, 2));
    const variance = squaredDiffs.reduce((acc: number, val: number) => acc + val, 0) / n;
    const stdDev = Math.sqrt(variance);

    // 变异系数
    const cv = mean !== 0 ? stdDev / mean : 0;

    // 最小值、最大值、范围
    const min = Math.min(...data);
    const max = Math.max(...data);
    const range = max - min;

    return {
      mean: mean,
      median: median,
      stdDev: stdDev,
      variance: variance,
      cv: cv,
      min: min,
      max: max,
      range: range
    };
  }

  /**
   * 计算自相关函数（ACF）
   * 
   * @param data 时间序列数据
   * @param maxLag 最大滞后期
   * @returns 自相关系数数组
   */
  private static calculateACF(data: number[], maxLag: number): number[] {
    const n = data.length;
    const mean = data.reduce((acc: number, val: number) => acc + val, 0) / n;
    const acf: number[] = [];

    // 计算方差（lag=0的自协方差）
    let variance = 0;
    for (let i = 0; i < n; i++) {
      variance += Math.pow(data[i] - mean, 2);
    }

    if (variance === 0) {
      // 数据无变化，返回全0
      for (let lag = 0; lag <= maxLag; lag++) {
        acf.push(0);
      }
      return acf;
    }

    // 计算各滞后期的自相关系数
    for (let lag = 0; lag <= maxLag; lag++) {
      let covariance = 0;
      const effectiveN = n - lag;

      for (let i = 0; i < effectiveN; i++) {
        covariance += (data[i] - mean) * (data[i + lag] - mean);
      }

      const correlation = covariance / variance;
      acf.push(correlation);
    }

    return acf;
  }

  /**
   * 评估ACF得分
   */
  private static evaluateACF(acf: number[], threshold: number): number {
    if (acf.length < 2) {
      return 0;
    }

    // 跳过lag=0（总是1），检查其他滞后期
    let significantLags = 0;
    let maxACF = 0;

    for (let i = 1; i < acf.length; i++) {
      const absACF = Math.abs(acf[i]);
      if (absACF > threshold) {
        significantLags++;
      }
      if (absACF > maxACF) {
        maxACF = absACF;
      }
    }

    // 得分：显著滞后期数量 + 最大ACF值
    const score = (significantLags / (acf.length - 1)) * 0.5 + maxACF * 0.5;
    return Math.min(score, 1);
  }

  /**
   * 评估变异系数得分
   */
  private static evaluateCV(cv: number, threshold: number): number {
    if (cv < threshold) {
      return 0; // 变异太小，无季节性
    }

    // CV越大，季节性越明显
    // 使用sigmoid函数映射到0-1
    const normalized = cv / threshold;
    const score = 1 / (1 + Math.exp(-5 * (normalized - 1)));
    return Math.min(score, 1);
  }

  /**
   * 检测峰值（使用Z-score）
   */
  private static detectPeaks(
    data: number[],
    metrics: StatisticalMetrics,
    zThreshold: number
  ): number[] {
    const peaks: number[] = [];

    if (metrics.stdDev === 0) {
      return peaks;
    }

    for (let i = 0; i < data.length; i++) {
      const zScore = (data[i] - metrics.mean) / metrics.stdDev;

      // Z-score超过阈值，且是局部最大值
      if (zScore > zThreshold) {
        const isLocalMax = (i === 0 || data[i] > data[i - 1]) &&
                          (i === data.length - 1 || data[i] > data[i + 1]);
        if (isLocalMax) {
          peaks.push(i);
        }
      }
    }

    return peaks;
  }

  /**
   * 检测低谷（使用Z-score）
   */
  private static detectTroughs(
    data: number[],
    metrics: StatisticalMetrics,
    zThreshold: number
  ): number[] {
    const troughs: number[] = [];

    if (metrics.stdDev === 0) {
      return troughs;
    }

    for (let i = 0; i < data.length; i++) {
      const zScore = (data[i] - metrics.mean) / metrics.stdDev;

      // Z-score低于负阈值，且是局部最小值
      if (zScore < -zThreshold) {
        const isLocalMin = (i === 0 || data[i] < data[i - 1]) &&
                          (i === data.length - 1 || data[i] < data[i + 1]);
        if (isLocalMin) {
          troughs.push(i);
        }
      }
    }

    return troughs;
  }

  /**
   * 检测周期
   */
  private static detectPeriod(acf: number[]): number {
    if (acf.length < 3) {
      return 0;
    }

    // 寻找第一个显著的正自相关峰值（跳过lag=0）
    let maxACF = 0;
    let maxLag = 0;

    for (let lag = 1; lag < acf.length; lag++) {
      if (acf[lag] > maxACF && acf[lag] > 0.3) {
        maxACF = acf[lag];
        maxLag = lag;
      }
    }

    return maxLag;
  }

  /**
   * 计算综合置信度
   */
  private static calculateConfidence(
    acfScore: number,
    cvScore: number,
    peakCount: number,
    troughCount: number,
    dataLength: number
  ): number {
    // 权重分配
    const weights = {
      acf: 0.4,
      cv: 0.3,
      peaks: 0.2,
      troughs: 0.1
    };

    // 峰值和低谷得分（归一化）
    const peakScore = Math.min(peakCount / 3, 1);
    const troughScore = Math.min(troughCount / 3, 1);

    // 加权平均
    const confidence = 
      acfScore * weights.acf +
      cvScore * weights.cv +
      peakScore * weights.peaks +
      troughScore * weights.troughs;

    // 数据长度惩罚（数据太少，降低置信度）
    const lengthPenalty = Math.min(dataLength / 12, 1);

    return Math.round(confidence * lengthPenalty * 100) / 100;
  }

  /**
   * 判断季节性强度
   */
  private static determineStrength(confidence: number): string {
    if (confidence < 0.3) {
      return SEASONALITY_STRENGTH_NONE;
    } else if (confidence < 0.5) {
      return SEASONALITY_STRENGTH_WEAK;
    } else if (confidence < 0.7) {
      return SEASONALITY_STRENGTH_MODERATE;
    } else {
      return SEASONALITY_STRENGTH_STRONG;
    }
  }

  /**
   * 生成描述
   */
  private static generateDescription(
    categoryName: string,
    hasSeasonality: boolean,
    strength: string,
    period: number,
    peaks: number[],
    troughs: number[],
    factor: number
  ): string {
    if (!hasSeasonality) {
      return `${categoryName}消费较为稳定，未检测到明显的季节性模式`;
    }

    let desc = `${categoryName}存在`;

    // 强度描述
    switch (strength) {
      case SEASONALITY_STRENGTH_WEAK:
        desc += '较弱的';
        break;
      case SEASONALITY_STRENGTH_MODERATE:
        desc += '中等的';
        break;
      case SEASONALITY_STRENGTH_STRONG:
        desc += '明显的';
        break;
    }

    desc += '季节性波动';

    // 周期描述
    if (period > 0) {
      desc += `，周期约为${period}个月`;
    }

    // 峰值描述
    if (peaks.length > 0) {
      const peakMonths = peaks.map((idx: number) => `第${idx + 1}月`).join('、');
      desc += `，高峰期在${peakMonths}`;
    }

    // 因子描述
    if (factor > 1.5) {
      desc += `，最高月份是平均值的${factor.toFixed(1)}倍`;
    }

    return desc;
  }

  /**
   * 获取周期类型
   */
  private static getPeriodType(period: number): string {
    if (period === 0) {
      return 'none';
    } else if (period <= 2) {
      return 'monthly';
    } else if (period <= 4) {
      return 'quarterly';
    } else if (period <= 6) {
      return 'semi-annual';
    } else {
      return 'yearly';
    }
  }

  /**
   * 获取默认阈值
   */
  private static getDefaultThresholds(): SeasonalityThresholds {
    return {
      minDataPoints: 6,           // 至少6个月数据
      acfThreshold: 0.3,          // ACF显著性阈值
      cvThreshold: 0.3,           // 变异系数阈值（30%）
      peakThreshold: 1.5,         // Z-score阈值（1.5倍标准差）
      significanceLevel: 0.05     // 显著性水平（5%）
    };
  }

  /**
   * 创建空结果
   */
  private static createEmptyResult(categoryId: number, categoryName: string): SeasonalityAnalysisResult {
    return {
      categoryId: categoryId,
      categoryName: categoryName,
      hasSeasonality: false,
      strength: SEASONALITY_STRENGTH_NONE,
      period: 0,
      confidence: 0,
      acfScore: 0,
      cvScore: 0,
      peakMonths: [],
      troughMonths: [],
      seasonalityFactor: 1,
      description: `${categoryName}数据不足，无法进行季节性分析`
    };
  }
}
