/**
 * 智能预算服务层 - 2.0.0版本
 *
 * 功能说明:
 * 1. 基于历史消费数据的预算自动规划
 * 2. 多算法集成预测（简单移动平均、加权移动平均、指数平滑、Holt-Winters、线性回归）
 * 3. 分类级预算建议生成
 * 4. 季节性消费模式识别
 * 5. 预算健康评分与优化建议
 *
 * 架构说明:
 * - Service层负责业务逻辑编排和智能算法调用
 * - 依赖Model层的BudgetForecastUtils进行数学计算
 * - 调用DAO层进行数据持久化
 * - 为UI层提供简洁的业务接口
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import hilog from '@ohos.hilog';
import {
  SmartBudgetPlan,
  BudgetForecastUtils,
  ForecastResult,
  BudgetAdvice,
  CategoryBudgetAllocation,
  SeasonalFactor,
  ForecastEngineConfig,
  FORECAST_ENSEMBLE,
  ADVICE_INCREASE,
  ADVICE_DECREASE,
  ADVICE_MAINTAIN,
  ADVICE_WARNING,
  ADVICE_OPTIMIZATION
} from '../model/SmartBudgetPlan';
import { BillDAO } from '../dao/BillDAO';
import { CategoryDAO } from '../dao/CategoryDAO';
import { BudgetDAO } from '../dao/BudgetDAO';

const LOG_TAG = 'SmartBudgetService';
const HILOG_DOMAIN = 0x0002;

// ==================== 服务接口定义 ====================

/**
 * 智能预算生成参数
 */
export interface SmartBudgetGenerationParams {
  userId: number;
  planName: string;
  period: string;
  targetMonth: string;
  totalBudget?: number;
  algorithm?: string;
  lookbackMonths?: number;
  confidenceLevel?: number;
}

/**
 * 分类历史消费数据
 */
export class CategoryHistoricalData {
  categoryId: number = 0;
  categoryName: string = '';
  monthlyAmounts: number[] = [];
  average: number = 0;
  trend: string = 'stable';
}

/**
 * 预算优化建议参数
 */
export interface BudgetOptimizationParams {
  userId: number;
  currentMonth: string;
}

/**
 * 周期日期结果
 */
export class PeriodDatesResult {
  startDate: string = '';
  endDate: string = '';
}

// ==================== 核心服务类 ====================

export class SmartBudgetService {

  /**
   * 生成智能预算计划
   */
  static async generateSmartBudget(params: SmartBudgetGenerationParams): Promise<SmartBudgetPlan> {
    hilog.info(HILOG_DOMAIN, LOG_TAG, '开始生成智能预算计划: %{public}s', JSON.stringify(params));

    try {
      // 1. 参数默认值设置
      const lookbackMonths = params.lookbackMonths ?? 6;
      const algorithm = params.algorithm ?? FORECAST_ENSEMBLE;
      const confidenceLevel = params.confidenceLevel ?? 0.95;

      // 2. 获取历史消费数据
      const historicalData = await SmartBudgetService.fetchHistoricalData(params.userId, lookbackMonths);
      hilog.info(HILOG_DOMAIN, LOG_TAG, '获取到%{public}d个分类的历史数据', historicalData.length);

      // 3. 创建预测配置
      const config = BudgetForecastUtils.createDefaultConfig();
      config.algorithm = algorithm;
      config.confidenceLevel = confidenceLevel;
      config.windowSize = Math.min(lookbackMonths, 6);

      // 4. 生成分类预算分配
      const categoryBudgets = await SmartBudgetService.generateCategoryBudgets(
        historicalData,
        config,
        params.totalBudget
      );

      // 5. 生成预测结果
      const forecasts = SmartBudgetService.generateForecasts(historicalData, config, params.targetMonth);

      // 6. 生成预算建议
      const advices = await SmartBudgetService.generateBudgetAdvices(
        params.userId,
        historicalData,
        categoryBudgets
      );

      // 7. 识别季节性因子（简化版）
      const seasonalFactors = SmartBudgetService.detectSeasonalFactors(historicalData);

      // 8. 计算总预算（如果未提供）
      let totalBudget = params.totalBudget ?? 0;
      if (totalBudget === 0) {
        totalBudget = categoryBudgets.reduce((sum: number, cb: CategoryBudgetAllocation) => sum + cb.allocatedAmount, 0);
      }

      // 9. 计算计划的日期范围
      const periodDates = SmartBudgetService.calculatePeriodDates(params.targetMonth, params.period);
      const startDate = periodDates.startDate;
      const endDate = periodDates.endDate;

      // 10. 组装SmartBudgetPlan对象
      const plan = new SmartBudgetPlan();
      plan.userId = params.userId;
      plan.planName = params.planName;
      plan.period = params.period;
      plan.startDate = startDate;
      plan.endDate = endDate;
      plan.totalBudget = totalBudget;
      plan.setCategoryBudgets(categoryBudgets);
      plan.forecastsJson = JSON.stringify(forecasts);
      plan.advicesJson = JSON.stringify(advices);
      plan.seasonalFactorsJson = JSON.stringify(seasonalFactors);
      plan.algorithm = algorithm;
      plan.accuracy = SmartBudgetService.calculateAccuracy(historicalData, forecasts);
      plan.status = 'draft';
      plan.generatedAt = new Date().toISOString();
      plan.createdAt = new Date().toISOString();
      plan.updatedAt = new Date().toISOString();

      hilog.info(HILOG_DOMAIN, LOG_TAG, '智能预算计划生成完成');
      return plan;

    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, '生成智能预算失败: %{public}s', error.message);
      throw new Error('生成智能预算失败: ' + error.message);
    }
  }

  /**
   * 获取用户的历史消费数据（按分类和月份聚合）
   */
  private static async fetchHistoricalData(
    userId: number,
    lookbackMonths: number
  ): Promise<CategoryHistoricalData[]> {
    const now = new Date();
    const categories = await CategoryDAO.getByType(userId, 'expense');
    const result: CategoryHistoricalData[] = [];

    for (const category of categories) {
      const monthlyAmounts: number[] = [];

      // 获取过去N个月的数据
      for (let i = lookbackMonths - 1; i >= 0; i--) {
        const targetDate = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const year = targetDate.getFullYear();
        const month = targetDate.getMonth() + 1;
        const startDate = `${year}-${month.toString().padStart(2, '0')}-01`;
        const lastDay = new Date(year, month, 0).getDate();
        const endDate = `${year}-${month.toString().padStart(2, '0')}-${lastDay}`;

        const bills = await BillDAO.getBillsByFilters(userId, { start: startDate, end: endDate }, category.categoryId);
        const monthTotal = bills.reduce((sum: number, bill) => sum + bill.amount, 0);
        monthlyAmounts.push(monthTotal);
      }

      // 计算平均值
      const average = monthlyAmounts.reduce((sum: number, amt: number) => sum + amt, 0) / (monthlyAmounts.length || 1);

      // 简单趋势判断
      let trend = 'stable';
      if (monthlyAmounts.length >= 3) {
        const recent = monthlyAmounts.slice(-3);
        const earlier = monthlyAmounts.slice(0, 3);
        const recentAvg = recent.reduce((s: number, a: number) => s + a, 0) / recent.length;
        const earlierAvg = earlier.reduce((s: number, a: number) => s + a, 0) / earlier.length;
        if (recentAvg > earlierAvg * 1.2) {
          trend = 'increasing';
        } else if (recentAvg < earlierAvg * 0.8) {
          trend = 'decreasing';
        }
      }

      const data = new CategoryHistoricalData();
      data.categoryId = category.categoryId;
      data.categoryName = category.name;
      data.monthlyAmounts = monthlyAmounts;
      data.average = average;
      data.trend = trend;
      result.push(data);
    }

    return result;
  }

  /**
   * 生成分类预算分配
   */
  private static async generateCategoryBudgets(
    historicalData: CategoryHistoricalData[],
    config: ForecastEngineConfig,
    totalBudget?: number
  ): Promise<CategoryBudgetAllocation[]> {
    const allocations: CategoryBudgetAllocation[] = [];

    // 为每个分类预测下月支出
    for (const data of historicalData) {
      if (data.monthlyAmounts.length === 0) {
        continue;
      }

      const forecast = BudgetForecastUtils.ensembleForecast(data.monthlyAmounts, config);
      const predictedAmount = forecast.predicted;

      const allocation: CategoryBudgetAllocation = {
        categoryId: data.categoryId,
        categoryName: data.categoryName,
        allocatedAmount: predictedAmount,
        percentage: 0, // 稍后计算
        historicalAvg: data.average,
        predictedAmount: predictedAmount,
        priority: SmartBudgetService.determinePriority(data),
        flexibility: SmartBudgetService.calculateFlexibility(data)
      };
      allocations.push(allocation);
    }

    // 计算总额
    const predictedTotal = allocations.reduce((sum: number, a: CategoryBudgetAllocation) => sum + a.allocatedAmount, 0);

    // 如果用户指定了总预算，按比例调整
    if (totalBudget && totalBudget > 0 && predictedTotal > 0) {
      const ratio = totalBudget / predictedTotal;
      allocations.forEach((a: CategoryBudgetAllocation) => {
        a.allocatedAmount = a.allocatedAmount * ratio;
      });
    }

    // 计算百分比
    const finalTotal = allocations.reduce((sum: number, a: CategoryBudgetAllocation) => sum + a.allocatedAmount, 0);
    if (finalTotal > 0) {
      allocations.forEach((a: CategoryBudgetAllocation) => {
        a.percentage = (a.allocatedAmount / finalTotal) * 100;
      });
    }

    return allocations;
  }

  /**
   * 生成预测结果
   */
  private static generateForecasts(
    historicalData: CategoryHistoricalData[],
    config: ForecastEngineConfig,
    targetMonth: string
  ): ForecastResult[] {
    const forecasts: ForecastResult[] = [];

    for (const data of historicalData) {
      if (data.monthlyAmounts.length === 0) {
        continue;
      }

      const forecast = BudgetForecastUtils.ensembleForecast(data.monthlyAmounts, config);
      const interval = BudgetForecastUtils.calculateConfidenceInterval(
        forecast.predicted,
        data.monthlyAmounts,
        config.confidenceLevel
      );

      forecasts.push(
        BudgetForecastUtils.createForecastResult(
          `${data.categoryName}-${targetMonth}`,
          forecast.predicted,
          interval.lower,
          interval.upper,
          forecast.confidence,
          config.algorithm
        )
      );
    }

    return forecasts;
  }

  /**
   * 生成预算建议
   */
  private static async generateBudgetAdvices(
    userId: number,
    historicalData: CategoryHistoricalData[],
    categoryBudgets: CategoryBudgetAllocation[]
  ): Promise<BudgetAdvice[]> {
    const advices: BudgetAdvice[] = [];
    const currentBudgets = await BudgetDAO.getByUserId(userId);

    for (const catBudget of categoryBudgets) {
      const currentBudget = currentBudgets.find((b) => b.categoryId === catBudget.categoryId);
      const currentAmount = currentBudget ? currentBudget.amount : 0;
      const suggestedAmount = catBudget.allocatedAmount;
      const historicalDataItem = historicalData.find((h: CategoryHistoricalData) => h.categoryId === catBudget.categoryId);
      const trend = historicalDataItem ? historicalDataItem.trend : 'stable';

      let adviceType = ADVICE_MAINTAIN;
      let reason = '消费稳定，保持当前预算';
      let priority = 3;
      let potentialSavings = 0;

      if (currentAmount === 0) {
        adviceType = ADVICE_INCREASE;
        const monthsCount = historicalDataItem?.monthlyAmounts.length ?? 0;
        reason = `建议设置预算为 ¥${suggestedAmount.toFixed(0)}，基于${monthsCount}个月的历史数据`;
        priority = 2;
      } else {
        const changePercent = ((suggestedAmount - currentAmount) / currentAmount) * 100;
        if (changePercent > 20) {
          adviceType = ADVICE_INCREASE;
          reason = `消费呈上升趋势，建议增加预算 ${changePercent.toFixed(0)}%`;
          priority = 1;
        } else if (changePercent < -20) {
          adviceType = ADVICE_DECREASE;
          reason = `消费下降，可减少预算 ${Math.abs(changePercent).toFixed(0)}%`;
          priority = 2;
          potentialSavings = currentAmount - suggestedAmount;
        } else if (trend === 'increasing') {
          adviceType = ADVICE_WARNING;
          reason = '消费趋势上升，需关注预算执行';
          priority = 2;
        }
      }

      advices.push(
        BudgetForecastUtils.createBudgetAdvice(
          `advice-${catBudget.categoryId}-${Date.now()}`,
          catBudget.categoryId,
          catBudget.categoryName,
          adviceType,
          currentAmount,
          suggestedAmount,
          reason,
          priority,
          potentialSavings,
          trend
        )
      );
    }

    // 按优先级排序
    advices.sort((a: BudgetAdvice, b: BudgetAdvice) => a.priority - b.priority);

    return advices;
  }

  /**
   * 检测季节性因子（简化版）
   */
  private static detectSeasonalFactors(historicalData: CategoryHistoricalData[]): SeasonalFactor[] {
    const factors: SeasonalFactor[] = [];

    // 示例：简单判断是否有明显的月度波动
    for (const data of historicalData) {
      if (data.monthlyAmounts.length < 6) {
        continue;
      }

      const avg = data.average;
      const maxAmount = Math.max(...data.monthlyAmounts);
      const minAmount = Math.min(...data.monthlyAmounts);

      if (maxAmount > avg * 1.5 || minAmount < avg * 0.5) {
        const factor: SeasonalFactor = {
          period: data.categoryName,
          factor: maxAmount / (avg || 1),
          seasonType: 'monthly',
          description: `${data.categoryName}存在明显的消费波动，最高月份是平均值的${(maxAmount / (avg || 1)).toFixed(1)}倍`
        };
        factors.push(factor);
      }
    }

    return factors;
  }

  /**
   * 计算预测准确度
   */
  private static calculateAccuracy(
    historicalData: CategoryHistoricalData[],
    forecasts: ForecastResult[]
  ): number {
    // 简化实现：基于置信度的平均值
    if (forecasts.length === 0) {
      return 0;
    }

    const avgConfidence = forecasts.reduce((sum: number, f: ForecastResult) => sum + f.confidence, 0) / forecasts.length;
    return Math.round(avgConfidence * 100) / 100;
  }

  /**
   * 确定分类优先级
   */
  private static determinePriority(data: CategoryHistoricalData): string {
    // 根据消费金额和趋势确定优先级
    if (data.average > 1000 || data.trend === 'increasing') {
      return 'high';
    } else if (data.average > 300) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  /**
   * 计算灵活性系数（0-1，越大越灵活）
   */
  private static calculateFlexibility(data: CategoryHistoricalData): number {
    // 基于消费的变异系数
    if (data.monthlyAmounts.length < 2) {
      return 0.5;
    }

    const avg = data.average;
    if (avg === 0) {
      return 1;
    }

    const variance = data.monthlyAmounts.reduce((sum: number, amt: number) => {
      return sum + Math.pow(amt - avg, 2);
    }, 0) / data.monthlyAmounts.length;

    const stdDev = Math.sqrt(variance);
    const cv = stdDev / avg; // 变异系数

    // CV越大，灵活性越高
    return Math.min(cv, 1);
  }

  /**
   * 计算周期日期
   */
  private static calculatePeriodDates(targetMonth: string, period: string): PeriodDatesResult {
    // targetMonth 格式: "2025-01"
    const parts = targetMonth.split('-');
    const year = Number(parts[0]);
    const month = Number(parts[1]);
    const startDate = `${year}-${month.toString().padStart(2, '0')}-01`;

    let endDate: string;
    if (period === 'monthly') {
      const lastDay = new Date(year, month, 0).getDate();
      endDate = `${year}-${month.toString().padStart(2, '0')}-${lastDay}`;
    } else {
      // 其他周期暂不支持，默认为当月
      const lastDay = new Date(year, month, 0).getDate();
      endDate = `${year}-${month.toString().padStart(2, '0')}-${lastDay}`;
    }

    const result = new PeriodDatesResult();
    result.startDate = startDate;
    result.endDate = endDate;
    return result;
  }

  /**
   * 获取预算优化建议
   */
  static async getBudgetOptimization(params: BudgetOptimizationParams): Promise<BudgetAdvice[]> {
    hilog.info(HILOG_DOMAIN, LOG_TAG, '获取预算优化建议');

    try {
      const historicalData = await SmartBudgetService.fetchHistoricalData(params.userId, 6);
      const config = BudgetForecastUtils.createDefaultConfig();
      const categoryBudgets = await SmartBudgetService.generateCategoryBudgets(historicalData, config);
      const advices = await SmartBudgetService.generateBudgetAdvices(params.userId, historicalData, categoryBudgets);

      // 只返回高优先级的优化建议
      return advices.filter((a: BudgetAdvice) =>
        a.adviceType === ADVICE_OPTIMIZATION ||
        a.adviceType === ADVICE_WARNING ||
        a.priority <= 2
      );
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, '获取优化建议失败: %{public}s', error.message);
      return [];
    }
  }

  /**
   * 评估预算健康度（0-100分）
   */
  static async evaluateBudgetHealth(userId: number, currentMonth: string): Promise<number> {
    hilog.info(HILOG_DOMAIN, LOG_TAG, '评估预算健康度');

    try {
      // 获取当前预算
      const budgets = await BudgetDAO.getByUserId(userId);
      if (budgets.length === 0) {
        return 0;
      }

      // 计算日期范围
      const parts = currentMonth.split('-');
      const year = Number(parts[0]);
      const month = Number(parts[1]);
      const startDate = `${year}-${month.toString().padStart(2, '0')}-01`;
      const lastDay = new Date(year, month, 0).getDate();
      const endDate = `${year}-${month.toString().padStart(2, '0')}-${lastDay}`;

      let totalScore = 0;
      let count = 0;

      for (const budget of budgets) {
        const bills = await BillDAO.getBillsByFilters(userId, { start: startDate, end: endDate }, budget.categoryId);
        const spent = bills.reduce((sum: number, bill) => sum + bill.amount, 0);
        const usage = budget.amount > 0 ? (spent / budget.amount) : 0;

        // 评分规则：
        // 0-0.7: 100分
        // 0.7-0.9: 80分
        // 0.9-1.0: 60分
        // 1.0-1.2: 40分
        // >1.2: 20分
        let score = 100;
        if (usage > 1.2) {
          score = 20;
        } else if (usage > 1.0) {
          score = 40;
        } else if (usage > 0.9) {
          score = 60;
        } else if (usage > 0.7) {
          score = 80;
        }

        totalScore += score;
        count++;
      }

      return count > 0 ? Math.round(totalScore / count) : 0;

    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, '评估健康度失败: %{public}s', error.message);
      return 0;
    }
  }
}
