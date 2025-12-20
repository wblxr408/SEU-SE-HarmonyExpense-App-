/**
 * 异常检测服务 - 业务逻辑层
 *
 * 功能：
 * 1. 用户消费异常检测
 * 2. 多种检测算法实现（3σ、Z-Score、IQR等）
 * 3. 异常记录管理
 * 4. 用户消费基线维护
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import { AnomalyRecordDAO, UserSpendingBaselineDAO } from '../dao/AnomalyDetectionDAO';
import { BillDAO } from '../dao/BillDAO';
import { AnomalyRecord, UserSpendingBaseline } from '../model/AnomalyDetection';
import { Bill } from '../model/Bill';

/**
 * 异常检测结果接口
 */
export interface AnomalyDetectionResult {
  isAnomaly: boolean;
  anomalyType: string;
  severity: string;
  algorithm: string;
  score: number;
  threshold: number;
  expectedValue: number;
  actualValue: number;
  deviation: number;
  description: string;
}

/**
 * 异常检测服务类
 */
export class AnomalyDetectionService {

  /**
   * 检测单条账单是否异常
   * @param bill 账单对象
   * @param userId 用户ID
   * @returns 异常检测结果
   */
  static async detectBillAnomaly(bill: Bill, userId: number): Promise<AnomalyDetectionResult[]> {
    try {
      const results: AnomalyDetectionResult[] = [];

      // 获取用户的消费基线
      const baseline = await UserSpendingBaselineDAO.getByUserId(userId);
      if (!baseline) {
        // 如果没有基线，先创建基线
        await AnomalyDetectionService.updateUserBaseline(userId);
        return results; // 首次创建基线，暂不检测异常
      }

      // 1. 金额异常检测
      const amountAnomaly = AnomalyDetectionService.detectAmountAnomaly(bill, baseline);
      if (amountAnomaly.isAnomaly) {
        results.push(amountAnomaly);

        // 创建异常记录
        await AnomalyDetectionService.createAnomalyRecord(bill, userId, amountAnomaly);
      }

      // 2. 频率异常检测
      const frequencyAnomaly = await AnomalyDetectionService.detectFrequencyAnomaly(bill, userId, baseline);
      if (frequencyAnomaly.isAnomaly) {
        results.push(frequencyAnomaly);
        await AnomalyDetectionService.createAnomalyRecord(bill, userId, frequencyAnomaly);
      }

      // 3. 分类异常检测
      const categoryAnomaly = await AnomalyDetectionService.detectCategoryAnomaly(bill, userId, baseline);
      if (categoryAnomaly.isAnomaly) {
        results.push(categoryAnomaly);
        await AnomalyDetectionService.createAnomalyRecord(bill, userId, categoryAnomaly);
      }

      return results;
    } catch (error) {
      console.error('[AnomalyDetectionService] 检测账单异常失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 金额异常检测（3σ原则）
   */
  private static detectAmountAnomaly(bill: Bill, baseline: UserSpendingBaseline): AnomalyDetectionResult {
    const mean = baseline.mean;
    const stdDev = baseline.stdDev;
    const amount = bill.amount;

    // 计算Z-Score
    const zScore = stdDev > 0 ? Math.abs((amount - mean) / stdDev) : 0;

    // 判断异常
    let isAnomaly = false;
    let severity = 'low';
    let anomalyType = '';

    if (zScore > 3) {
      isAnomaly = true;
      severity = 'critical';
      anomalyType = amount > mean ? 'high_amount' : 'low_amount';
    } else if (zScore > 2.5) {
      isAnomaly = true;
      severity = 'high';
      anomalyType = amount > mean ? 'high_amount' : 'low_amount';
    } else if (zScore > 2) {
      isAnomaly = true;
      severity = 'medium';
      anomalyType = amount > mean ? 'high_amount' : 'low_amount';
    }

    const deviation = ((amount - mean) / mean) * 100;

    const result: AnomalyDetectionResult = {
      isAnomaly: isAnomaly,
      anomalyType: anomalyType,
      severity: severity,
      algorithm: 'sigma_3',
      score: zScore,
      threshold: 2.0,
      expectedValue: mean,
      actualValue: amount,
      deviation: deviation,
      description: isAnomaly
        ? `金额 ¥${amount.toFixed(2)} 偏离平均值 ¥${mean.toFixed(2)} 达 ${Math.abs(deviation).toFixed(1)}%（${zScore.toFixed(2)}σ）`
        : ''
    };

    return result;
  }

  /**
   * 频率异常检测
   */
  private static async detectFrequencyAnomaly(
    bill: Bill,
    userId: number,
    baseline: UserSpendingBaseline
  ): Promise<AnomalyDetectionResult> {
    try {
      // 获取当天的账单数量
      const today = new Date();
      const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      const endOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59);

      const todayBills = await BillDAO.getByTimeRange(
        userId,
        startOfDay.toISOString(),
        endOfDay.toISOString()
      );

      const todayCount = todayBills.length;
      // 使用sampleSize作为平均交易频率的估算
      // sampleSize / 天数 = 每天平均交易数
      const avgFrequency = baseline.sampleSize > 0 ? baseline.sampleSize / 30 : 0;

      // 计算频率异常
      const frequencyDeviation = avgFrequency > 0 ? ((todayCount - avgFrequency) / avgFrequency) * 100 : 0;

      let isAnomaly = false;
      let severity = 'low';

      if (frequencyDeviation > 150) {
        isAnomaly = true;
        severity = 'high';
      } else if (frequencyDeviation > 100) {
        isAnomaly = true;
        severity = 'medium';
      }

      const result: AnomalyDetectionResult = {
        isAnomaly: isAnomaly,
        anomalyType: 'frequency_spike',
        severity: severity,
        algorithm: 'z_score',
        score: frequencyDeviation / 100,
        threshold: 1.0,
        expectedValue: avgFrequency,
        actualValue: todayCount,
        deviation: frequencyDeviation,
        description: isAnomaly
          ? `今日交易频率 ${todayCount} 笔，超过日均 ${avgFrequency.toFixed(1)} 笔的 ${frequencyDeviation.toFixed(0)}%`
          : ''
      };

      return result;
    } catch (error) {
      console.error('[AnomalyDetectionService] 频率异常检测失败:', error);
      return {
        isAnomaly: false,
        anomalyType: '',
        severity: 'low',
        algorithm: 'z_score',
        score: 0,
        threshold: 0,
        expectedValue: 0,
        actualValue: 0,
        deviation: 0,
        description: ''
      };
    }
  }

  /**
   * 分类异常检测
   */
  private static async detectCategoryAnomaly(
    bill: Bill,
    userId: number,
    baseline: UserSpendingBaseline
  ): Promise<AnomalyDetectionResult> {
    try {
      // 获取该分类的历史平均消费
      const categoryBills = await BillDAO.getByCategoryId(userId, bill.categoryId, 100);

      if (categoryBills.length < 3) {
        // 数据不足，不检测
        return {
          isAnomaly: false,
          anomalyType: '',
          severity: 'low',
          algorithm: 'iqr',
          score: 0,
          threshold: 0,
          expectedValue: 0,
          actualValue: bill.amount,
          deviation: 0,
          description: ''
        };
      }

      // 计算该分类的统计数据
      const amounts = categoryBills.map((b: Bill) => b.amount).sort((a: number, b: number) => a - b);
      const q1Index = Math.floor(amounts.length * 0.25);
      const q3Index = Math.floor(amounts.length * 0.75);
      const q1 = amounts[q1Index];
      const q3 = amounts[q3Index];
      const iqr = q3 - q1;

      const lowerBound = q1 - 1.5 * iqr;
      const upperBound = q3 + 1.5 * iqr;

      // 计算平均值
      let sum = 0;
      for (let i = 0; i < amounts.length; i++) {
        sum += amounts[i];
      }
      const mean = sum / amounts.length;

      // 判断是否异常
      const isAnomaly = bill.amount < lowerBound || bill.amount > upperBound;
      let severity = 'low';

      if (bill.amount > upperBound) {
        const deviation = ((bill.amount - upperBound) / upperBound) * 100;
        if (deviation > 100) {
          severity = 'high';
        } else if (deviation > 50) {
          severity = 'medium';
        }
      }

      const anomalyType = bill.amount > upperBound ? 'unusual_category' : 'pattern_break';
      const deviation = ((bill.amount - mean) / mean) * 100;

      const result: AnomalyDetectionResult = {
        isAnomaly: isAnomaly,
        anomalyType: anomalyType,
        severity: severity,
        algorithm: 'iqr',
        score: Math.abs(deviation) / 100,
        threshold: 1.5,
        expectedValue: mean,
        actualValue: bill.amount,
        deviation: deviation,
        description: isAnomaly
          ? `该分类消费 ¥${bill.amount.toFixed(2)} 偏离正常范围（¥${lowerBound.toFixed(2)} - ¥${upperBound.toFixed(2)}）`
          : ''
      };

      return result;
    } catch (error) {
      console.error('[AnomalyDetectionService] 分类异常检测失败:', error);
      return {
        isAnomaly: false,
        anomalyType: '',
        severity: 'low',
        algorithm: 'iqr',
        score: 0,
        threshold: 0,
        expectedValue: 0,
        actualValue: 0,
        deviation: 0,
        description: ''
      };
    }
  }

  /**
   * 创建异常记录
   */
  private static async createAnomalyRecord(
    bill: Bill,
    userId: number,
    anomaly: AnomalyDetectionResult
  ): Promise<void> {
    try {
      const record = new AnomalyRecord();
      record.userId = userId;
      record.billId = bill.billId;
      record.anomalyType = anomaly.anomalyType;
      record.severity = anomaly.severity;
      record.algorithm = anomaly.algorithm;
      record.score = anomaly.score;
      record.threshold = anomaly.threshold;
      record.expectedValue = anomaly.expectedValue;
      record.actualValue = anomaly.actualValue;
      record.deviation = anomaly.deviation;
      record.description = anomaly.description;
      record.isAcknowledged = 0;

      await AnomalyRecordDAO.insert(record);
    } catch (error) {
      console.error('[AnomalyDetectionService] 创建异常记录失败:', error);
    }
  }

  /**
   * 更新用户消费基线
   */
  static async updateUserBaseline(userId: number): Promise<UserSpendingBaseline> {
    try {
      // 获取最近30天的账单
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - 30);

      const bills = await BillDAO.getByTimeRange(
        userId,
        startDate.toISOString(),
        endDate.toISOString()
      );

      if (bills.length === 0) {
        // 没有数据，创建默认基线
        const baseline = new UserSpendingBaseline();
        baseline.userId = userId;
        baseline.categoryId = 0; // 全类别
        baseline.period = 'monthly';
        baseline.mean = 0;
        baseline.median = 0;
        baseline.stdDev = 0;
        baseline.variance = 0;
        baseline.min = 0;
        baseline.max = 0;
        baseline.q1 = 0;
        baseline.q3 = 0;
        baseline.iqr = 0;
        baseline.sampleSize = 0;
        baseline.lastCalculatedAt = new Date().toISOString();
        baseline.sampleStartDate = startDate.toISOString();
        baseline.sampleEndDate = endDate.toISOString();
        baseline.createdAt = new Date().toISOString();
        baseline.updatedAt = new Date().toISOString();

        await UserSpendingBaselineDAO.upsert(baseline);
        return baseline;
      }

      // 计算每日消费
      const dailySpending: Map<string, number> = new Map();
      const dailyCount: Map<string, number> = new Map();

      for (let i = 0; i < bills.length; i++) {
        const bill = bills[i];
        const date = bill.transactionDate.substring(0, 10); // YYYY-MM-DD

        const currentSpending = dailySpending.get(date) || 0;
        dailySpending.set(date, currentSpending + bill.amount);

        const currentCount = dailyCount.get(date) || 0;
        dailyCount.set(date, currentCount + 1);
      }

      // 计算统计数据
      const dailyAmounts: number[] = [];
      dailySpending.forEach((value: number) => {
        dailyAmounts.push(value);
      });

      // 平均值 (mean)
      let sum = 0;
      for (let i = 0; i < dailyAmounts.length; i++) {
        sum += dailyAmounts[i];
      }
      const mean = dailyAmounts.length > 0 ? sum / dailyAmounts.length : 0;

      // 标准差 (stdDev)
      let squaredDiffSum = 0;
      for (let i = 0; i < dailyAmounts.length; i++) {
        const diff = dailyAmounts[i] - mean;
        squaredDiffSum += diff * diff;
      }
      const stdDev = dailyAmounts.length > 0 ? Math.sqrt(squaredDiffSum / dailyAmounts.length) : 0;
      const variance = stdDev * stdDev;

      // 最大最小值
      let max = dailyAmounts.length > 0 ? dailyAmounts[0] : 0;
      let min = dailyAmounts.length > 0 ? dailyAmounts[0] : 0;
      for (let i = 1; i < dailyAmounts.length; i++) {
        if (dailyAmounts[i] > max) {
          max = dailyAmounts[i];
        }
        if (dailyAmounts[i] < min) {
          min = dailyAmounts[i];
        }
      }

      // 计算中位数和四分位数
      const sortedAmounts = dailyAmounts.slice().sort((a: number, b: number) => a - b);
      const median = AnomalyDetectionService.calculateMedian(sortedAmounts);
      const q1 = AnomalyDetectionService.calculateMedian(sortedAmounts.slice(0, Math.floor(sortedAmounts.length / 2)));
      const q3 = AnomalyDetectionService.calculateMedian(sortedAmounts.slice(Math.ceil(sortedAmounts.length / 2)));
      const iqr = q3 - q1;

      // 创建或更新基线
      const baseline = new UserSpendingBaseline();
      baseline.userId = userId;
      baseline.categoryId = 0; // 全类别
      baseline.period = 'monthly';
      baseline.mean = mean;
      baseline.median = median;
      baseline.stdDev = stdDev;
      baseline.variance = variance;
      baseline.min = min;
      baseline.max = max;
      baseline.q1 = q1;
      baseline.q3 = q3;
      baseline.iqr = iqr;
      baseline.sampleSize = bills.length;
      baseline.lastCalculatedAt = new Date().toISOString();
      baseline.sampleStartDate = startDate.toISOString();
      baseline.sampleEndDate = endDate.toISOString();
      baseline.createdAt = new Date().toISOString();
      baseline.updatedAt = new Date().toISOString();

      await UserSpendingBaselineDAO.upsert(baseline);
      return baseline;
    } catch (error) {
      console.error('[AnomalyDetectionService] 更新用户基线失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取用户的未确认异常
   */
  static async getUnacknowledgedAnomalies(userId: number): Promise<AnomalyRecord[]> {
    try {
      return await AnomalyRecordDAO.getUnacknowledged(userId);
    } catch (error) {
      console.error('[AnomalyDetectionService] 获取未确认异常失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 计算中位数
   */
  private static calculateMedian(sortedArray: number[]): number {
    if (sortedArray.length === 0) {
      return 0;
    }
    const mid = Math.floor(sortedArray.length / 2);
    if (sortedArray.length % 2 === 0) {
      return (sortedArray[mid - 1] + sortedArray[mid]) / 2;
    }
    return sortedArray[mid];
  }

  /**
   * 确认异常
   */
  static async acknowledgeAnomaly(anomalyId: number): Promise<boolean> {
    try {
      return await AnomalyRecordDAO.acknowledge(anomalyId);
    } catch (error) {
      console.error('[AnomalyDetectionService] 确认异常失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 批量确认异常
   */
  static async acknowledgeBatch(anomalyIds: number[]): Promise<number> {
    try {
      let count = 0;
      for (let i = 0; i < anomalyIds.length; i++) {
        const success = await AnomalyRecordDAO.acknowledge(anomalyIds[i]);
        if (success) {
          count++;
        }
      }
      return count;
    } catch (error) {
      console.error('[AnomalyDetectionService] 批量确认异常失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取异常统计
   */
  static async getStatistics(userId: number) {
    try {
      return await AnomalyRecordDAO.getStatistics(userId);
    } catch (error) {
      console.error('[AnomalyDetectionService] 获取异常统计失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取用户消费基线
   */
  static async getUserBaseline(userId: number): Promise<UserSpendingBaseline | null> {
    try {
      return await UserSpendingBaselineDAO.getByUserId(userId);
    } catch (error) {
      console.error('[AnomalyDetectionService] 获取用户基线失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
}
