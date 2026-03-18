/**
 * 个性化预算服务 - 基于用户画像的智能预算优化
 * 
 * 功能：
 * 1. 根据用户画像调整预测算法权重
 * 2. 个性化阈值调整
 * 3. 建议反馈追踪和学习
 * 
 * @version 1.0.0
 * @author HarmonyExpense Team
 */

import hilog from '@ohos.hilog';
import { UserProfile, SPENDING_SAVER, SPENDING_SPENDER, EXECUTION_STRICT } from '../model/UserProfile';
import { UserProfileDAO } from '../dao/UserProfileDAO';
import { AdviceFeedback, FEEDBACK_ACCEPTED, FEEDBACK_REJECTED, ADVICE_DECREASE, ADVICE_INCREASE } from '../model/AdviceFeedback';
import { AdviceFeedbackDAO } from '../dao/AdviceFeedbackDAO';
import { BudgetAdvice } from '../model/SmartBudgetPlan';
import { ForecastEngineConfig } from '../model/SmartBudgetPlan';

const LOG_TAG = 'PersonalizedBudgetService';
const HILOG_DOMAIN = 0x0002;

// ==================== 个性化配置接口 ====================

/**
 * 个性化算法权重
 */
export interface PersonalizedWeights {
  sma: number;        // 简单移动平均
  wma: number;        // 加权移动平均
  es: number;         // 指数平滑
  hw: number;         // Holt-Winters
  lr: number;         // 线性回归
}

/**
 * 个性化阈值
 */
export interface PersonalizedThresholds {
  increaseThreshold: number;    // 建议增加预算的阈值（百分比）
  decreaseThreshold: number;    // 建议减少预算的阈值（百分比）
  warningThreshold: number;     // 预警阈值（百分比）
  confidenceLevel: number;      // 置信水平
}

// ==================== 核心服务类 ====================

export class PersonalizedBudgetService {

  /**
   * 获取个性化算法权重
   * 根据用户画像调整不同算法的权重
   */
  static getPersonalizedWeights(profile: UserProfile | null): PersonalizedWeights {
    // 默认权重（平衡型）
    let weights: PersonalizedWeights = {
      sma: 0.15,
      wma: 0.20,
      es: 0.25,
      hw: 0.25,
      lr: 0.15
    };

    if (!profile) {
      return weights;
    }

    // 根据消费性格调整
    if (profile.spendingPersonality === SPENDING_SAVER) {
      // 储蓄型用户：消费稳定，增加简单平均权重
      weights = {
        sma: 0.25,
        wma: 0.25,
        es: 0.20,
        hw: 0.15,
        lr: 0.15
      };
      hilog.info(HILOG_DOMAIN, LOG_TAG, '应用储蓄型用户权重');
    } else if (profile.spendingPersonality === SPENDING_SPENDER) {
      // 消费型用户：消费波动大，增加指数平滑和趋势预测权重
      weights = {
        sma: 0.10,
        wma: 0.15,
        es: 0.30,
        hw: 0.30,
        lr: 0.15
      };
      hilog.info(HILOG_DOMAIN, LOG_TAG, '应用消费型用户权重');
    }

    // 根据年龄调整
    if (profile.isYoungUser()) {
      // 年轻用户：消费模式可能快速变化，增加趋势预测权重
      weights.lr += 0.05;
      weights.hw += 0.05;
      weights.sma -= 0.05;
      weights.wma -= 0.05;
      hilog.info(HILOG_DOMAIN, LOG_TAG, '应用年轻用户权重调整');
    }

    // 根据预算执行模式调整
    if (profile.budgetExecutionPattern === EXECUTION_STRICT) {
      // 严格执行型：消费可预测性强，增加简单方法权重
      weights.sma += 0.05;
      weights.wma += 0.05;
      weights.es -= 0.05;
      weights.hw -= 0.05;
      hilog.info(HILOG_DOMAIN, LOG_TAG, '应用严格执行型权重调整');
    }

    // 归一化权重（确保总和为1）
    const total = weights.sma + weights.wma + weights.es + weights.hw + weights.lr;
    weights.sma /= total;
    weights.wma /= total;
    weights.es /= total;
    weights.hw /= total;
    weights.lr /= total;

    return weights;
  }

  /**
   * 获取个性化阈值
   * 根据用户历史行为调整建议触发阈值
   */
  static async getPersonalizedThresholds(userId: number): Promise<PersonalizedThresholds> {
    // 默认阈值
    let thresholds: PersonalizedThresholds = {
      increaseThreshold: 20,      // 增加20%触发增加建议
      decreaseThreshold: -20,     // 减少20%触发减少建议
      warningThreshold: 15,       // 增加15%触发预警
      confidenceLevel: 0.95       // 95%置信水平
    };

    try {
      const profile = await UserProfileDAO.getByUserId(userId);
      if (!profile) {
        return thresholds;
      }

      // 根据预算超支率调整
      if (profile.budgetOverrunRate > 0.5) {
        // 经常超支的用户：降低阈值，更早提醒
        thresholds.increaseThreshold = 15;
        thresholds.warningThreshold = 10;
        hilog.info(HILOG_DOMAIN, LOG_TAG, '降低阈值（经常超支用户）');
      } else if (profile.budgetOverrunRate < 0.2) {
        // 很少超支的用户：提高阈值，减少打扰
        thresholds.increaseThreshold = 25;
        thresholds.warningThreshold = 20;
        hilog.info(HILOG_DOMAIN, LOG_TAG, '提高阈值（很少超支用户）');
      }

      // 根据建议接受率调整
      if (profile.adviceAcceptanceRate < 0.3) {
        // 很少接受建议：提高阈值，只在明显情况下建议
        thresholds.increaseThreshold += 5;
        thresholds.decreaseThreshold -= 5;
        hilog.info(HILOG_DOMAIN, LOG_TAG, '提高阈值（低接受率用户）');
      }

      // 根据风险承受能力调整置信水平
      if (profile.riskTolerance === 'conservative') {
        thresholds.confidenceLevel = 0.99;  // 保守型要求更高置信度
      } else if (profile.riskTolerance === 'aggressive') {
        thresholds.confidenceLevel = 0.90;  // 激进型可接受较低置信度
      }

      // 根据家庭规模调整
      if (profile.isLargeFamily()) {
        // 大家庭：消费波动正常，提高阈值
        thresholds.increaseThreshold += 5;
        thresholds.warningThreshold += 5;
        hilog.info(HILOG_DOMAIN, LOG_TAG, '提高阈值（大家庭）');
      }

      return thresholds;

    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `获取个性化阈值失败: ${error.message}`);
      return thresholds;
    }
  }

  /**
   * 过滤建议 - 根据用户历史反馈
   * 如果用户从不接受某类建议，降低该类建议的优先级或过滤掉
   */
  static async filterAdvicesByHistory(
    userId: number,
    advices: BudgetAdvice[]
  ): Promise<BudgetAdvice[]> {
    try {
      // 获取各类建议的接受率
      const decreaseRate = await AdviceFeedbackDAO.getAcceptanceRateByType(userId, ADVICE_DECREASE);
      const increaseRate = await AdviceFeedbackDAO.getAcceptanceRateByType(userId, ADVICE_INCREASE);

      hilog.info(HILOG_DOMAIN, LOG_TAG, 
        `建议接受率 - 减少: ${decreaseRate}, 增加: ${increaseRate}`);

      const filteredAdvices: BudgetAdvice[] = [];

      for (const advice of advices) {
        let shouldInclude = true;
        let priorityAdjustment = 0;

        // 如果用户从不接受"减少预算"建议（接受率<10%），降低优先级
        if (advice.adviceType === ADVICE_DECREASE && decreaseRate < 0.1) {
          priorityAdjustment = 2;  // 降低2级优先级
          hilog.info(HILOG_DOMAIN, LOG_TAG, 
            `降低"减少预算"建议优先级（低接受率）`);
        }

        // 如果用户从不接受"增加预算"建议，降低优先级
        if (advice.adviceType === ADVICE_INCREASE && increaseRate < 0.1) {
          priorityAdjustment = 2;
          hilog.info(HILOG_DOMAIN, LOG_TAG, 
            `降低"增加预算"建议优先级（低接受率）`);
        }

        // 调整优先级
        if (shouldInclude) {
          const adjustedAdvice = { ...advice };
          adjustedAdvice.priority = Math.min(5, advice.priority + priorityAdjustment);
          filteredAdvices.push(adjustedAdvice);
        }
      }

      // 重新排序
      filteredAdvices.sort((a, b) => a.priority - b.priority);

      return filteredAdvices;

    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `过滤建议失败: ${error.message}`);
      return advices;
    }
  }

  /**
   * 记录建议反馈
   */
  static async recordAdviceFeedback(
    userId: number,
    advice: BudgetAdvice,
    accepted: boolean,
    actualBudgetSet: number,
    comment?: string
  ): Promise<boolean> {
    try {
      const feedback = new AdviceFeedback();
      feedback.userId = userId;
      feedback.adviceId = advice.adviceId;
      feedback.adviceType = advice.adviceType;
      feedback.categoryId = advice.categoryId;
      feedback.categoryName = advice.categoryName;
      feedback.suggestedBudget = advice.suggestedBudget;
      feedback.originalBudget = advice.currentBudget;
      feedback.feedbackStatus = accepted ? FEEDBACK_ACCEPTED : FEEDBACK_REJECTED;
      feedback.actualBudgetSet = actualBudgetSet;
      feedback.feedbackDate = new Date().toISOString();
      
      // 设置生效日期（下个月1号）
      const nextMonth = new Date();
      nextMonth.setMonth(nextMonth.getMonth() + 1);
      nextMonth.setDate(1);
      feedback.effectiveDate = nextMonth.toISOString().substring(0, 10);
      
      feedback.userComment = comment || '';
      feedback.createdAt = new Date().toISOString();
      feedback.updatedAt = new Date().toISOString();

      const feedbackId = await AdviceFeedbackDAO.insert(feedback);

      // 更新用户画像的建议接受率
      const acceptanceRate = await AdviceFeedbackDAO.calculateAcceptanceRate(userId);
      await UserProfileDAO.updateAdviceAcceptanceRate(userId, acceptanceRate);

      hilog.info(HILOG_DOMAIN, LOG_TAG, 
        `建议反馈已记录，ID: ${feedbackId}, 接受: ${accepted}`);

      return feedbackId > 0;

    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `记录建议反馈失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 评估建议准确性
   * 在建议生效一段时间后，对比实际支出和预测值
   */
  static async evaluateAdviceAccuracy(userId: number): Promise<number> {
    try {
      // 获取待评估的反馈
      const pendingFeedbacks = await AdviceFeedbackDAO.getPendingEvaluations(userId);

      if (pendingFeedbacks.length === 0) {
        hilog.info(HILOG_DOMAIN, LOG_TAG, '没有待评估的建议');
        return 0;
      }

      let evaluatedCount = 0;

      for (const feedback of pendingFeedbacks) {
        // TODO: 从bills表查询实际支出
        // 这里需要根据category_id和effective_date查询实际支出
        // 暂时跳过，等待集成时实现
        
        hilog.info(HILOG_DOMAIN, LOG_TAG, 
          `待评估建议: ${feedback.adviceId}, 分类: ${feedback.categoryName}`);
      }

      return evaluatedCount;

    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `评估建议准确性失败: ${error.message}`);
      return 0;
    }
  }

  /**
   * 创建个性化预测配置
   */
  static async createPersonalizedConfig(userId: number): Promise<ForecastEngineConfig> {
    const profile = await UserProfileDAO.getByUserId(userId);
    const thresholds = await PersonalizedBudgetService.getPersonalizedThresholds(userId);

    const config: ForecastEngineConfig = {
      algorithm: 'ensemble',
      windowSize: 6,
      alpha: 0.3,
      beta: 0.1,
      gamma: 0.2,
      seasonalPeriod: 12,
      confidenceLevel: thresholds.confidenceLevel,
      minDataPoints: 12
    };

    // 根据用户画像调整参数
    if (profile) {
      if (profile.spendingPersonality === SPENDING_SPENDER) {
        // 消费型用户：增加alpha（对新数据更敏感）
        config.alpha = 0.4;
      } else if (profile.spendingPersonality === SPENDING_SAVER) {
        // 储蓄型用户：降低alpha（更平滑）
        config.alpha = 0.2;
      }

      // 根据数据量调整窗口大小
      if (profile.averageMonthlyExpense > 0) {
        // 有足够历史数据，可以使用更大窗口
        config.windowSize = 6;
      } else {
        // 新用户，使用较小窗口
        config.windowSize = 3;
      }
    }

    return config;
  }
}
