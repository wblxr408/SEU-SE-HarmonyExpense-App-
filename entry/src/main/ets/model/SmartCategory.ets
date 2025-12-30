/**
 * 智能分类模型 - AI智能分类引擎
 *
 * 功能：
 * 1. 基于账单备注的智能分类推荐
 * 2. 用户行为学习和模式识别
 * 3. 关键词-分类映射管理
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import { Category, CategoryJSON } from './Category';
import { Bill, BillJSON } from './Bill';

// ==================== 接口定义 ====================

/**
 * 分类关键词映射接口
 */
export interface CategoryKeywordJSON {
  keywordId: number;
  userId: number;
  categoryId: number;
  keyword: string;
  weight: number;
  frequency: number;
  lastUsedAt: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 分类推荐结果接口
 */
export interface CategoryRecommendation {
  categoryId: number;
  categoryName: string;
  confidence: number;
  matchedKeywords: string[];
  score: number;
}

/**
 * 金额范围接口
 */
export interface AmountRange {
  min: number;
  max: number;
}

/**
 * 用户分类习惯接口
 */
export interface UserCategoryHabitJSON {
  habitId: number;
  userId: number;
  categoryId: number;
  merchantPattern: string;
  amountRange: AmountRange;
  timePattern: string;
  usageCount: number;
  lastUsedAt: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

// ==================== 类实现 ====================

/**
 * 分类关键词映射类
 */
export class CategoryKeyword {
  static readonly tableName: string = 'category_keywords';

  keywordId: number = 0;
  userId: number = 0;
  categoryId: number = 0;
  keyword: string = '';
  weight: number = 0.5;
  frequency: number = 0;
  lastUsedAt: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    keywordId: number = 0,
    userId: number = 0,
    categoryId: number = 0,
    keyword: string = '',
    weight: number = 0.5,
    frequency: number = 0,
    lastUsedAt: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.keywordId = keywordId;
    this.userId = userId;
    this.categoryId = categoryId;
    this.keyword = keyword;
    this.weight = weight;
    this.frequency = frequency;
    this.lastUsedAt = lastUsedAt;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  toJSON(): CategoryKeywordJSON {
    const result: CategoryKeywordJSON = {
      keywordId: this.keywordId,
      userId: this.userId,
      categoryId: this.categoryId,
      keyword: this.keyword,
      weight: this.weight,
      frequency: this.frequency,
      lastUsedAt: this.lastUsedAt,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: CategoryKeywordJSON): CategoryKeyword {
    return new CategoryKeyword(
      data.keywordId,
      data.userId,
      data.categoryId,
      data.keyword,
      data.weight,
      data.frequency,
      data.lastUsedAt,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      this.categoryId > 0 &&
      this.keyword.trim().length > 0 &&
      this.weight >= 0 && this.weight <= 1 &&
      this.frequency >= 0
    );
  }

  clone(): CategoryKeyword {
    return CategoryKeyword.fromJSON(this.toJSON());
  }
}

/**
 * 用户分类习惯类
 */
export class UserCategoryHabit {
  static readonly tableName: string = 'user_category_habits';

  habitId: number = 0;
  userId: number = 0;
  categoryId: number = 0;
  merchantPattern: string = '';
  amountMin: number = 0;
  amountMax: number = 999999999;
  timePattern: string = '';
  usageCount: number = 0;
  lastUsedAt: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    habitId: number = 0,
    userId: number = 0,
    categoryId: number = 0,
    merchantPattern: string = '',
    amountMin: number = 0,
    amountMax: number = 999999999,
    timePattern: string = '',
    usageCount: number = 0,
    lastUsedAt: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.habitId = habitId;
    this.userId = userId;
    this.categoryId = categoryId;
    this.merchantPattern = merchantPattern;
    this.amountMin = amountMin;
    this.amountMax = amountMax;
    this.timePattern = timePattern;
    this.usageCount = usageCount;
    this.lastUsedAt = lastUsedAt;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  toJSON(): UserCategoryHabitJSON {
    const amountRange: AmountRange = {
      min: this.amountMin,
      max: this.amountMax
    };
    const result: UserCategoryHabitJSON = {
      habitId: this.habitId,
      userId: this.userId,
      categoryId: this.categoryId,
      merchantPattern: this.merchantPattern,
      amountRange: amountRange,
      timePattern: this.timePattern,
      usageCount: this.usageCount,
      lastUsedAt: this.lastUsedAt,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: UserCategoryHabitJSON): UserCategoryHabit {
    return new UserCategoryHabit(
      data.habitId,
      data.userId,
      data.categoryId,
      data.merchantPattern,
      data.amountRange.min,
      data.amountRange.max,
      data.timePattern,
      data.usageCount,
      data.lastUsedAt,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      this.categoryId > 0 &&
      this.amountMin >= 0 &&
      this.amountMax >= this.amountMin
    );
  }

  /**
   * 检查金额是否在范围内
   */
  isAmountInRange(amount: number): boolean {
    return amount >= this.amountMin && amount <= this.amountMax;
  }

  /**
   * 检查商户名称是否匹配
   */
  matchesMerchant(merchantName: string): boolean {
    if (this.merchantPattern === '') {
      return false;
    }
    const lowerPattern = this.merchantPattern.toLowerCase();
    const lowerName = merchantName.toLowerCase();
    return lowerName.indexOf(lowerPattern) >= 0;
  }
}

/**
 * 智能分类结果类
 */
export class SmartCategoryResult {
  recommendations: CategoryRecommendation[] = [];
  topRecommendation: CategoryRecommendation | null = null;
  analysisTime: number = 0;
  matchMethod: string = 'hybrid';

  constructor(
    recommendations: CategoryRecommendation[] = [],
    analysisTime: number = 0,
    matchMethod: string = 'hybrid'
  ) {
    this.recommendations = recommendations;
    if (recommendations.length > 0) {
      this.topRecommendation = recommendations[0];
    } else {
      this.topRecommendation = null;
    }
    this.analysisTime = analysisTime;
    this.matchMethod = matchMethod;
  }

  /**
   * 是否有高置信度推荐
   */
  hasHighConfidence(threshold: number = 0.8): boolean {
    if (this.topRecommendation === null) {
      return false;
    }
    return this.topRecommendation.confidence >= threshold;
  }

  /**
   * 获取指定置信度以上的推荐
   */
  getRecommendationsAbove(threshold: number): CategoryRecommendation[] {
    const result: CategoryRecommendation[] = [];
    for (let i = 0; i < this.recommendations.length; i++) {
      if (this.recommendations[i].confidence >= threshold) {
        result.push(this.recommendations[i]);
      }
    }
    return result;
  }
}

/**
 * 智能分类服务工具类
 */
export class SmartCategoryUtils {
  /**
   * 计算文本相似度（简单实现）
   */
  static calculateSimilarity(text1: string, text2: string): number {
    const lower1 = text1.toLowerCase();
    const lower2 = text2.toLowerCase();

    if (lower1 === lower2) {
      return 1.0;
    }

    if (lower1.indexOf(lower2) >= 0 || lower2.indexOf(lower1) >= 0) {
      return 0.8;
    }

    // 简单的字符匹配
    let matches = 0;
    const chars1 = lower1.split('');
    const chars2Set = new Set<string>();
    const chars2 = lower2.split('');
    for (let i = 0; i < chars2.length; i++) {
      chars2Set.add(chars2[i]);
    }

    for (let i = 0; i < chars1.length; i++) {
      if (chars2Set.has(chars1[i])) {
        matches++;
      }
    }

    const maxLen = Math.max(chars1.length, chars2.length);
    if (maxLen === 0) {
      return 0;
    }
    return matches / maxLen;
  }

  /**
   * 从文本中提取关键词
   */
  static extractKeywords(text: string): string[] {
    // 简单的分词实现
    const result: string[] = [];
    const words = text.split(/[\s,，。.!！?？]+/);
    for (let i = 0; i < words.length; i++) {
      const word = words[i].trim();
      if (word.length >= 2) {
        result.push(word);
      }
    }
    return result;
  }

  /**
   * 创建推荐结果
   */
  static createRecommendation(
    categoryId: number,
    categoryName: string,
    confidence: number,
    matchedKeywords: string[],
    score: number
  ): CategoryRecommendation {
    const result: CategoryRecommendation = {
      categoryId: categoryId,
      categoryName: categoryName,
      confidence: confidence,
      matchedKeywords: matchedKeywords,
      score: score
    };
    return result;
  }

  // ==================== 与核心模型集成方法 ====================

  /**
   * 基于账单备注和分类列表进行智能推荐
   * @param billNote 账单备注
   * @param categories 分类列表
   * @param keywords 关键词映射列表
   * @param habits 用户习惯列表
   * @param amount 账单金额（可选）
   * @returns 智能分类结果
   */
  static recommendCategory(
    billNote: string,
    categories: Category[],
    keywords: CategoryKeyword[],
    habits: UserCategoryHabit[],
    amount: number = 0
  ): SmartCategoryResult {
    const startTime = Date.now();
    const scoreMap: Map<number, number> = new Map<number, number>();
    const matchedKeywordsMap: Map<number, string[]> = new Map<number, string[]>();

    // 初始化所有分类的分数
    for (let i = 0; i < categories.length; i++) {
      scoreMap.set(categories[i].categoryId, 0);
      matchedKeywordsMap.set(categories[i].categoryId, []);
    }

    // 从备注中提取关键词
    const noteKeywords = SmartCategoryUtils.extractKeywords(billNote);

    // 1. 基于关键词匹配
    for (let i = 0; i < keywords.length; i++) {
      const kw = keywords[i];
      for (let j = 0; j < noteKeywords.length; j++) {
        const similarity = SmartCategoryUtils.calculateSimilarity(kw.keyword, noteKeywords[j]);
        if (similarity >= 0.6) {
          const currentScore = scoreMap.get(kw.categoryId);
          if (currentScore !== undefined) {
            scoreMap.set(kw.categoryId, currentScore + similarity * kw.weight * kw.frequency);
          }
          const matched = matchedKeywordsMap.get(kw.categoryId);
          if (matched !== undefined) {
            matched.push(kw.keyword);
          }
        }
      }
    }

    // 2. 基于用户习惯匹配（金额范围）
    if (amount > 0) {
      for (let i = 0; i < habits.length; i++) {
        const habit = habits[i];
        if (habit.isAmountInRange(amount)) {
          const currentScore = scoreMap.get(habit.categoryId);
          if (currentScore !== undefined) {
            scoreMap.set(habit.categoryId, currentScore + 0.5 * habit.usageCount);
          }
        }
        // 商户模式匹配
        if (habit.matchesMerchant(billNote)) {
          const currentScore = scoreMap.get(habit.categoryId);
          if (currentScore !== undefined) {
            scoreMap.set(habit.categoryId, currentScore + 1.0 * habit.usageCount);
          }
        }
      }
    }

    // 3. 构建推荐结果
    const recommendations: CategoryRecommendation[] = [];
    let maxScore = 0;

    // 找到最大分数
    scoreMap.forEach((score: number, categoryId: number) => {
      if (score > maxScore) {
        maxScore = score;
      }
    });

    // 创建推荐列表
    for (let i = 0; i < categories.length; i++) {
      const cat = categories[i];
      const score = scoreMap.get(cat.categoryId);
      if (score !== undefined && score > 0) {
        const confidence = maxScore > 0 ? score / maxScore : 0;
        const matched = matchedKeywordsMap.get(cat.categoryId);
        const matchedList: string[] = matched !== undefined ? matched : [];

        recommendations.push(SmartCategoryUtils.createRecommendation(
          cat.categoryId,
          cat.name,
          Math.min(1.0, confidence),
          matchedList,
          score
        ));
      }
    }

    // 按分数排序
    for (let i = 0; i < recommendations.length - 1; i++) {
      for (let j = i + 1; j < recommendations.length; j++) {
        if (recommendations[j].score > recommendations[i].score) {
          const temp = recommendations[i];
          recommendations[i] = recommendations[j];
          recommendations[j] = temp;
        }
      }
    }

    const analysisTime = Date.now() - startTime;
    return new SmartCategoryResult(recommendations, analysisTime, 'hybrid');
  }

  /**
   * 从Bill对象推荐分类
   */
  static recommendFromBill(
    bill: Bill,
    categories: Category[],
    keywords: CategoryKeyword[],
    habits: UserCategoryHabit[]
  ): SmartCategoryResult {
    return SmartCategoryUtils.recommendCategory(
      bill.note,
      categories,
      keywords,
      habits,
      bill.amount
    );
  }

  /**
   * 从历史账单学习并创建关键词映射
   */
  static learnFromBill(
    bill: Bill,
    category: Category,
    userId: number,
    existingKeywords: CategoryKeyword[]
  ): CategoryKeyword[] {
    const newKeywords: CategoryKeyword[] = [];
    const noteKeywords = SmartCategoryUtils.extractKeywords(bill.note);
    const now = new Date().toISOString();

    for (let i = 0; i < noteKeywords.length; i++) {
      const word = noteKeywords[i];

      // 检查是否已存在
      let found = false;
      for (let j = 0; j < existingKeywords.length; j++) {
        if (existingKeywords[j].keyword === word &&
            existingKeywords[j].categoryId === category.categoryId) {
          // 更新现有关键词
          existingKeywords[j].frequency += 1;
          existingKeywords[j].lastUsedAt = now;
          existingKeywords[j].updatedAt = now;
          found = true;
          break;
        }
      }

      if (!found) {
        // 创建新关键词
        const newKeyword = new CategoryKeyword(
          0, // keywordId会由数据库生成
          userId,
          category.categoryId,
          word,
          0.5, // 初始权重
          1,   // 初始频率
          now,
          now,
          now,
          0
        );
        newKeywords.push(newKeyword);
      }
    }

    return newKeywords;
  }

  /**
   * 创建用户习惯记录
   */
  static createHabitFromBill(
    bill: Bill,
    userId: number
  ): UserCategoryHabit {
    const now = new Date().toISOString();
    // 创建金额范围（上下浮动20%）
    const amountMin = bill.amount * 0.8;
    const amountMax = bill.amount * 1.2;

    return new UserCategoryHabit(
      0, // habitId会由数据库生成
      userId,
      bill.categoryId,
      bill.note.length > 20 ? bill.note.substring(0, 20) : bill.note,
      amountMin,
      amountMax,
      '', // timePattern
      1,
      now,
      now,
      now,
      0
    );
  }
}

// ==================== 智能分类训练记录 ====================

/**
 * 智能分类训练记录JSON接口
 */
export interface SmartCategoryTrainingJSON {
  recordId: number;
  userId: number;
  billNote: string;
  billAmount: number;
  actualCategoryId: number;
  actualCategoryName: string;
  predictedCategoryId: number;
  predictedCategoryName: string;
  confidence: number;
  isCorrect: number;
  keywordsMatched: string;
  trainingType: string;
  modelVersion: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 智能分类训练记录类
 * 用于记录AI预测结果与用户实际选择的对比，用于模型训练和优化
 */
export class SmartCategoryTraining {
  static readonly tableName: string = 'smart_category_training';

  recordId: number = 0;
  userId: number = 0;
  billNote: string = '';
  billAmount: number = 0;
  actualCategoryId: number = 0;
  actualCategoryName: string = '';
  predictedCategoryId: number = 0;
  predictedCategoryName: string = '';
  confidence: number = 0;
  isCorrect: number = 0;
  keywordsMatched: string = '';
  trainingType: string = 'manual';
  modelVersion: string = '1.0.0';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    recordId: number = 0,
    userId: number = 0,
    billNote: string = '',
    billAmount: number = 0,
    actualCategoryId: number = 0,
    actualCategoryName: string = '',
    predictedCategoryId: number = 0,
    predictedCategoryName: string = '',
    confidence: number = 0,
    isCorrect: number = 0,
    keywordsMatched: string = '',
    trainingType: string = 'manual',
    modelVersion: string = '1.0.0',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.recordId = recordId;
    this.userId = userId;
    this.billNote = billNote;
    this.billAmount = billAmount;
    this.actualCategoryId = actualCategoryId;
    this.actualCategoryName = actualCategoryName;
    this.predictedCategoryId = predictedCategoryId;
    this.predictedCategoryName = predictedCategoryName;
    this.confidence = confidence;
    this.isCorrect = isCorrect;
    this.keywordsMatched = keywordsMatched;
    this.trainingType = trainingType;
    this.modelVersion = modelVersion;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  toJSON(): SmartCategoryTrainingJSON {
    const result: SmartCategoryTrainingJSON = {
      recordId: this.recordId,
      userId: this.userId,
      billNote: this.billNote,
      billAmount: this.billAmount,
      actualCategoryId: this.actualCategoryId,
      actualCategoryName: this.actualCategoryName,
      predictedCategoryId: this.predictedCategoryId,
      predictedCategoryName: this.predictedCategoryName,
      confidence: this.confidence,
      isCorrect: this.isCorrect,
      keywordsMatched: this.keywordsMatched,
      trainingType: this.trainingType,
      modelVersion: this.modelVersion,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: SmartCategoryTrainingJSON): SmartCategoryTraining {
    return new SmartCategoryTraining(
      data.recordId,
      data.userId,
      data.billNote,
      data.billAmount,
      data.actualCategoryId,
      data.actualCategoryName,
      data.predictedCategoryId,
      data.predictedCategoryName,
      data.confidence,
      data.isCorrect,
      data.keywordsMatched,
      data.trainingType,
      data.modelVersion,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      this.billNote.trim().length > 0 &&
      this.billAmount >= 0 &&
      this.actualCategoryId > 0 &&
      this.actualCategoryName.trim().length > 0 &&
      this.confidence >= 0 && this.confidence <= 1 &&
      (this.isCorrect === 0 || this.isCorrect === 1) &&
      this.trainingType.trim().length > 0 &&
      this.modelVersion.trim().length > 0
    );
  }

  clone(): SmartCategoryTraining {
    return SmartCategoryTraining.fromJSON(this.toJSON());
  }
}

// ==================== 智能分类规则 ====================

/**
 * 智能分类规则JSON接口
 */
export interface SmartCategoryRuleJSON {
  ruleId: number;
  userId: number;
  ruleName: string;
  categoryId: number;
  categoryName: string;
  ruleType: string;
  pattern: string;
  keywords: string;
  amountMin: number;
  amountMax: number;
  priority: number;
  isActive: number;
  accuracy: number;
  matchCount: number;
  lastMatchedAt: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 智能分类规则类
 * 用于定义自动分类规则，支持关键词匹配、金额范围、正则表达式等
 */
export class SmartCategoryRule {
  static readonly tableName: string = 'smart_category_rules';

  ruleId: number = 0;
  userId: number = 0;
  ruleName: string = '';
  categoryId: number = 0;
  categoryName: string = '';
  ruleType: string = 'keyword';
  pattern: string = '';
  keywords: string = '';
  amountMin: number = 0;
  amountMax: number = 999999999;
  priority: number = 0;
  isActive: number = 1;
  accuracy: number = 0;
  matchCount: number = 0;
  lastMatchedAt: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    ruleId: number = 0,
    userId: number = 0,
    ruleName: string = '',
    categoryId: number = 0,
    categoryName: string = '',
    ruleType: string = 'keyword',
    pattern: string = '',
    keywords: string = '',
    amountMin: number = 0,
    amountMax: number = 999999999,
    priority: number = 0,
    isActive: number = 1,
    accuracy: number = 0,
    matchCount: number = 0,
    lastMatchedAt: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.ruleId = ruleId;
    this.userId = userId;
    this.ruleName = ruleName;
    this.categoryId = categoryId;
    this.categoryName = categoryName;
    this.ruleType = ruleType;
    this.pattern = pattern;
    this.keywords = keywords;
    this.amountMin = amountMin;
    this.amountMax = amountMax;
    this.priority = priority;
    this.isActive = isActive;
    this.accuracy = accuracy;
    this.matchCount = matchCount;
    this.lastMatchedAt = lastMatchedAt;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  toJSON(): SmartCategoryRuleJSON {
    const result: SmartCategoryRuleJSON = {
      ruleId: this.ruleId,
      userId: this.userId,
      ruleName: this.ruleName,
      categoryId: this.categoryId,
      categoryName: this.categoryName,
      ruleType: this.ruleType,
      pattern: this.pattern,
      keywords: this.keywords,
      amountMin: this.amountMin,
      amountMax: this.amountMax,
      priority: this.priority,
      isActive: this.isActive,
      accuracy: this.accuracy,
      matchCount: this.matchCount,
      lastMatchedAt: this.lastMatchedAt,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: SmartCategoryRuleJSON): SmartCategoryRule {
    return new SmartCategoryRule(
      data.ruleId,
      data.userId,
      data.ruleName,
      data.categoryId,
      data.categoryName,
      data.ruleType,
      data.pattern,
      data.keywords,
      data.amountMin,
      data.amountMax,
      data.priority,
      data.isActive,
      data.accuracy,
      data.matchCount,
      data.lastMatchedAt,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      this.ruleName.trim().length > 0 &&
      this.categoryId > 0 &&
      this.categoryName.trim().length > 0 &&
      this.ruleType.trim().length > 0 &&
      this.amountMin >= 0 &&
      this.amountMax >= this.amountMin &&
      this.priority >= 0 &&
      (this.isActive === 0 || this.isActive === 1) &&
      this.accuracy >= 0 && this.accuracy <= 1 &&
      this.matchCount >= 0
    );
  }

  clone(): SmartCategoryRule {
    return SmartCategoryRule.fromJSON(this.toJSON());
  }

  private splitKeywords(raw: string): string[] {
    const trimmed: string = raw.trim();
    if (trimmed.length === 0) {
      return [];
    }

    return trimmed
      .split(/[\s,，;；、]+/)
      .map((part: string) => part.trim())
      .filter((part: string) => part.length > 0);
  }

  /**
   * 检查规则是否匹配账单
   */
  matchesBill(billNote: string, billAmount: number): boolean {
    if (this.isActive !== 1) {
      return false;
    }

    // 金额范围检查
    if (billAmount < this.amountMin || billAmount > this.amountMax) {
      return false;
    }

    // 关键词匹配
    if (this.ruleType === 'keyword' && this.keywords.trim().length > 0) {
      const keywordList: string[] = this.splitKeywords(this.keywords);
      const lowerNote = billNote.toLowerCase();
      for (let i = 0; i < keywordList.length; i++) {
        const keyword = keywordList[i].toLowerCase();
        if (keyword.length > 0 && lowerNote.indexOf(keyword) >= 0) {
          return true;
        }
      }
      return false;
    }

    // 正则表达式匹配
    if (this.ruleType === 'regex' && this.pattern.trim().length > 0) {
      try {
        const regex = new RegExp(this.pattern, 'i');
        return regex.test(billNote);
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  /**
   * 更新规则统计信息
   */
  updateStats(isMatch: boolean): void {
    if (isMatch) {
      this.matchCount += 1;
      this.lastMatchedAt = new Date().toISOString();
    }
    this.updatedAt = new Date().toISOString();
  }
}
