/**
 * 建议反馈追踪模型
 * 
 * 功能：
 * 1. 记录用户对预算建议的反馈
 * 2. 追踪建议的采纳情况
 * 3. 评估建议的实际效果
 * 
 * @version 1.0.0
 * @author HarmonyExpense Team
 */

// ==================== 常量定义 ====================

/**
 * 反馈状态
 */
export const FEEDBACK_PENDING = 'pending';       // 待处理
export const FEEDBACK_ACCEPTED = 'accepted';     // 已接受
export const FEEDBACK_REJECTED = 'rejected';     // 已拒绝
export const FEEDBACK_IGNORED = 'ignored';       // 已忽略

/**
 * 建议类型（与SmartBudgetPlan保持一致）
 */
export const ADVICE_INCREASE = 'increase';
export const ADVICE_DECREASE = 'decrease';
export const ADVICE_MAINTAIN = 'maintain';
export const ADVICE_WARNING = 'warning';
export const ADVICE_OPTIMIZATION = 'optimization';

// ==================== 接口定义 ====================

/**
 * 建议反馈JSON接口
 */
export interface AdviceFeedbackJSON {
  feedbackId: number;
  userId: number;
  adviceId: string;
  adviceType: string;
  categoryId: number;
  categoryName: string;
  suggestedBudget: number;
  originalBudget: number;
  feedbackStatus: string;
  actualBudgetSet: number;
  feedbackDate: string;
  effectiveDate: string;
  actualSpending: number;
  accuracyScore: number;
  userComment: string;
  createdAt: string;
  updatedAt: string;
}

// ==================== 类实现 ====================

/**
 * 建议反馈类
 */
export class AdviceFeedback {
  static readonly tableName: string = 'advice_feedbacks';

  feedbackId: number = 0;
  userId: number = 0;
  adviceId: string = '';                    // 建议ID（关联到BudgetAdvice）
  adviceType: string = '';                  // 建议类型
  categoryId: number = 0;                   // 分类ID
  categoryName: string = '';                // 分类名称
  suggestedBudget: number = 0;              // 建议的预算金额
  originalBudget: number = 0;               // 原始预算金额
  feedbackStatus: string = FEEDBACK_PENDING; // 反馈状态
  actualBudgetSet: number = 0;              // 用户实际设置的预算
  feedbackDate: string = '';                // 反馈日期
  effectiveDate: string = '';               // 生效日期（用于后续评估）
  actualSpending: number = 0;               // 实际支出（用于评估准确性）
  accuracyScore: number = 0;                // 准确性评分（0-100）
  userComment: string = '';                 // 用户评论
  createdAt: string = '';
  updatedAt: string = '';

  constructor(
    feedbackId: number = 0,
    userId: number = 0,
    adviceId: string = '',
    adviceType: string = '',
    categoryId: number = 0,
    categoryName: string = '',
    suggestedBudget: number = 0,
    originalBudget: number = 0,
    feedbackStatus: string = FEEDBACK_PENDING,
    actualBudgetSet: number = 0,
    feedbackDate: string = '',
    effectiveDate: string = '',
    actualSpending: number = 0,
    accuracyScore: number = 0,
    userComment: string = '',
    createdAt: string = '',
    updatedAt: string = ''
  ) {
    this.feedbackId = feedbackId;
    this.userId = userId;
    this.adviceId = adviceId;
    this.adviceType = adviceType;
    this.categoryId = categoryId;
    this.categoryName = categoryName;
    this.suggestedBudget = suggestedBudget;
    this.originalBudget = originalBudget;
    this.feedbackStatus = feedbackStatus;
    this.actualBudgetSet = actualBudgetSet;
    this.feedbackDate = feedbackDate;
    this.effectiveDate = effectiveDate;
    this.actualSpending = actualSpending;
    this.accuracyScore = accuracyScore;
    this.userComment = userComment;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  /**
   * 序列化为JSON
   */
  toJSON(): AdviceFeedbackJSON {
    return {
      feedbackId: this.feedbackId,
      userId: this.userId,
      adviceId: this.adviceId,
      adviceType: this.adviceType,
      categoryId: this.categoryId,
      categoryName: this.categoryName,
      suggestedBudget: this.suggestedBudget,
      originalBudget: this.originalBudget,
      feedbackStatus: this.feedbackStatus,
      actualBudgetSet: this.actualBudgetSet,
      feedbackDate: this.feedbackDate,
      effectiveDate: this.effectiveDate,
      actualSpending: this.actualSpending,
      accuracyScore: this.accuracyScore,
      userComment: this.userComment,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }

  /**
   * 从JSON反序列化
   */
  static fromJSON(data: AdviceFeedbackJSON): AdviceFeedback {
    return new AdviceFeedback(
      data.feedbackId,
      data.userId,
      data.adviceId,
      data.adviceType,
      data.categoryId,
      data.categoryName,
      data.suggestedBudget,
      data.originalBudget,
      data.feedbackStatus,
      data.actualBudgetSet,
      data.feedbackDate,
      data.effectiveDate,
      data.actualSpending,
      data.accuracyScore,
      data.userComment,
      data.createdAt,
      data.updatedAt
    );
  }

  /**
   * 数据验证
   */
  validate(): boolean {
    return (
      this.userId > 0 &&
      this.adviceId !== '' &&
      this.categoryId > 0 &&
      this.accuracyScore >= 0 && this.accuracyScore <= 100
    );
  }

  /**
   * 克隆
   */
  clone(): AdviceFeedback {
    return new AdviceFeedback(
      this.feedbackId,
      this.userId,
      this.adviceId,
      this.adviceType,
      this.categoryId,
      this.categoryName,
      this.suggestedBudget,
      this.originalBudget,
      this.feedbackStatus,
      this.actualBudgetSet,
      this.feedbackDate,
      this.effectiveDate,
      this.actualSpending,
      this.accuracyScore,
      this.userComment,
      this.createdAt,
      this.updatedAt
    );
  }

  /**
   * 判断是否已接受
   */
  isAccepted(): boolean {
    return this.feedbackStatus === FEEDBACK_ACCEPTED;
  }

  /**
   * 判断是否已拒绝
   */
  isRejected(): boolean {
    return this.feedbackStatus === FEEDBACK_REJECTED;
  }

  /**
   * 计算建议偏差率
   */
  getDeviationRate(): number {
    if (this.suggestedBudget === 0) {
      return 0;
    }
    return Math.abs(this.actualBudgetSet - this.suggestedBudget) / this.suggestedBudget;
  }

  /**
   * 计算预测准确性（基于实际支出）
   */
  calculateAccuracy(): number {
    if (this.actualSpending === 0 || this.suggestedBudget === 0) {
      return 0;
    }
    
    const deviation = Math.abs(this.actualSpending - this.suggestedBudget);
    const deviationRate = deviation / this.suggestedBudget;
    
    // 偏差越小，准确性越高
    // 偏差<10%: 90-100分
    // 偏差10-20%: 70-90分
    // 偏差20-30%: 50-70分
    // 偏差>30%: <50分
    if (deviationRate < 0.1) {
      return 90 + (1 - deviationRate / 0.1) * 10;
    } else if (deviationRate < 0.2) {
      return 70 + (1 - (deviationRate - 0.1) / 0.1) * 20;
    } else if (deviationRate < 0.3) {
      return 50 + (1 - (deviationRate - 0.2) / 0.1) * 20;
    } else {
      return Math.max(0, 50 - (deviationRate - 0.3) * 50);
    }
  }
}
