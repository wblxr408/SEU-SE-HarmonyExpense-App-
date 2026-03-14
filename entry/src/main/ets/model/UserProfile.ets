/**
 * 用户画像模型 - 用于个性化预算优化
 * 
 * 功能：
 * 1. 存储用户的基本特征信息
 * 2. 支持消费性格分析
 * 3. 为个性化算法提供参数
 * 
 * @version 1.0.0
 * @author HarmonyExpense Team
 */

// ==================== 常量定义 ====================

/**
 * 收入水平
 */
export const INCOME_LOW = 'low';           // < 5000
export const INCOME_MEDIUM = 'medium';     // 5000-15000
export const INCOME_HIGH = 'high';         // > 15000

/**
 * 风险承受能力
 */
export const RISK_CONSERVATIVE = 'conservative';  // 保守型
export const RISK_MODERATE = 'moderate';          // 稳健型
export const RISK_AGGRESSIVE = 'aggressive';      // 激进型

/**
 * 消费性格
 */
export const SPENDING_SAVER = 'saver';           // 储蓄型（很少超支）
export const SPENDING_BALANCED = 'balanced';     // 平衡型（偶尔超支）
export const SPENDING_SPENDER = 'spender';       // 消费型（经常超支）

/**
 * 预算执行模式
 */
export const EXECUTION_STRICT = 'strict';        // 严格执行（<10%偏差）
export const EXECUTION_FLEXIBLE = 'flexible';    // 灵活执行（10-30%偏差）
export const EXECUTION_LOOSE = 'loose';          // 宽松执行（>30%偏差）

// ==================== 接口定义 ====================

/**
 * 用户画像JSON接口
 */
export interface UserProfileJSON {
  profileId: number;
  userId: number;
  age: number;
  incomeLevel: string;
  familySize: number;
  riskTolerance: string;
  spendingPersonality: string;
  budgetExecutionPattern: string;
  averageMonthlyIncome: number;
  averageMonthlyExpense: number;
  budgetOverrunRate: number;
  adviceAcceptanceRate: number;
  createdAt: string;
  updatedAt: string;
}

// ==================== 类实现 ====================

/**
 * 用户画像类
 */
export class UserProfile {
  static readonly tableName: string = 'user_profiles';

  profileId: number = 0;
  userId: number = 0;
  age: number = 0;                                    // 年龄
  incomeLevel: string = INCOME_MEDIUM;                // 收入水平
  familySize: number = 1;                             // 家庭人数
  riskTolerance: string = RISK_MODERATE;              // 风险承受能力
  spendingPersonality: string = SPENDING_BALANCED;    // 消费性格
  budgetExecutionPattern: string = EXECUTION_FLEXIBLE; // 预算执行模式
  averageMonthlyIncome: number = 0;                   // 平均月收入
  averageMonthlyExpense: number = 0;                  // 平均月支出
  budgetOverrunRate: number = 0;                      // 预算超支率（0-1）
  adviceAcceptanceRate: number = 0;                   // 建议接受率（0-1）
  createdAt: string = '';
  updatedAt: string = '';

  constructor(
    profileId: number = 0,
    userId: number = 0,
    age: number = 0,
    incomeLevel: string = INCOME_MEDIUM,
    familySize: number = 1,
    riskTolerance: string = RISK_MODERATE,
    spendingPersonality: string = SPENDING_BALANCED,
    budgetExecutionPattern: string = EXECUTION_FLEXIBLE,
    averageMonthlyIncome: number = 0,
    averageMonthlyExpense: number = 0,
    budgetOverrunRate: number = 0,
    adviceAcceptanceRate: number = 0,
    createdAt: string = '',
    updatedAt: string = ''
  ) {
    this.profileId = profileId;
    this.userId = userId;
    this.age = age;
    this.incomeLevel = incomeLevel;
    this.familySize = familySize;
    this.riskTolerance = riskTolerance;
    this.spendingPersonality = spendingPersonality;
    this.budgetExecutionPattern = budgetExecutionPattern;
    this.averageMonthlyIncome = averageMonthlyIncome;
    this.averageMonthlyExpense = averageMonthlyExpense;
    this.budgetOverrunRate = budgetOverrunRate;
    this.adviceAcceptanceRate = adviceAcceptanceRate;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  /**
   * 序列化为JSON
   */
  toJSON(): UserProfileJSON {
    return {
      profileId: this.profileId,
      userId: this.userId,
      age: this.age,
      incomeLevel: this.incomeLevel,
      familySize: this.familySize,
      riskTolerance: this.riskTolerance,
      spendingPersonality: this.spendingPersonality,
      budgetExecutionPattern: this.budgetExecutionPattern,
      averageMonthlyIncome: this.averageMonthlyIncome,
      averageMonthlyExpense: this.averageMonthlyExpense,
      budgetOverrunRate: this.budgetOverrunRate,
      adviceAcceptanceRate: this.adviceAcceptanceRate,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }

  /**
   * 从JSON反序列化
   */
  static fromJSON(data: UserProfileJSON): UserProfile {
    return new UserProfile(
      data.profileId,
      data.userId,
      data.age,
      data.incomeLevel,
      data.familySize,
      data.riskTolerance,
      data.spendingPersonality,
      data.budgetExecutionPattern,
      data.averageMonthlyIncome,
      data.averageMonthlyExpense,
      data.budgetOverrunRate,
      data.adviceAcceptanceRate,
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
      this.age >= 0 &&
      this.familySize > 0 &&
      this.budgetOverrunRate >= 0 && this.budgetOverrunRate <= 1 &&
      this.adviceAcceptanceRate >= 0 && this.adviceAcceptanceRate <= 1
    );
  }

  /**
   * 克隆
   */
  clone(): UserProfile {
    return new UserProfile(
      this.profileId,
      this.userId,
      this.age,
      this.incomeLevel,
      this.familySize,
      this.riskTolerance,
      this.spendingPersonality,
      this.budgetExecutionPattern,
      this.averageMonthlyIncome,
      this.averageMonthlyExpense,
      this.budgetOverrunRate,
      this.adviceAcceptanceRate,
      this.createdAt,
      this.updatedAt
    );
  }

  /**
   * 判断是否为年轻用户（<30岁）
   */
  isYoungUser(): boolean {
    return this.age > 0 && this.age < 30;
  }

  /**
   * 判断是否为高收入用户
   */
  isHighIncome(): boolean {
    return this.incomeLevel === INCOME_HIGH;
  }

  /**
   * 判断是否为大家庭
   */
  isLargeFamily(): boolean {
    return this.familySize >= 3;
  }

  /**
   * 判断是否为储蓄型用户
   */
  isSaver(): boolean {
    return this.spendingPersonality === SPENDING_SAVER;
  }

  /**
   * 判断是否为消费型用户
   */
  isSpender(): boolean {
    return this.spendingPersonality === SPENDING_SPENDER;
  }

  /**
   * 判断预算执行是否严格
   */
  isStrictBudgetExecutor(): boolean {
    return this.budgetExecutionPattern === EXECUTION_STRICT;
  }

  /**
   * 获取储蓄率
   */
  getSavingsRate(): number {
    if (this.averageMonthlyIncome === 0) {
      return 0;
    }
    return (this.averageMonthlyIncome - this.averageMonthlyExpense) / this.averageMonthlyIncome;
  }
}
