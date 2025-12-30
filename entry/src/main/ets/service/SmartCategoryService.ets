/**
 * 智能分类服务 - 业务逻辑层
 *
 * 功能：
 * 1. 基于历史数据的智能分类推荐
 * 2. 分类规则管理与匹配
 * 3. 用户行为学习
 * 4. 训练数据管理
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import { SmartCategoryTrainingDAO, SmartCategoryRuleDAO } from '../dao/SmartCategoryDAO';
import { SmartCategoryTraining, SmartCategoryRule } from '../model/SmartCategory';
import { BillDAO } from '../dao/BillDAO';
import { CategoryDAO } from '../dao/CategoryDAO';
import { Bill } from '../model/Bill';
import { Category } from '../model/Category';

/**
 * 分类推荐结果接口
 */
export interface CategoryRecommendation {
  categoryId: number;
  categoryName: string;
  confidence: number;
  matchedRules: string[];
  matchedKeywords: string[];
  reason: string;
}

/**
 * 学习结果接口
 */
export interface LearningResult {
  rulesCreated: number;
  rulesUpdated: number;
  trainingRecordsCreated: number;
  scannedBills: number;
  totalKeywords: number;
  categoryCount: number; // Number of unique categories with keywords
}

/**
 * 分类匹配结果接口
 */
export interface CategoryMatchData {
  category: CategoryInfo;
  score: number;
  matchedRules: string[];
  matchedKeywords: string[];
}

/**
 * 分类信息接口
 */
export interface CategoryInfo {
  id: number;
  name: string;
}

/**
 * 规则匹配结果接口
 */
export interface RuleMatchResult {
  matched: boolean;
  score: number;
  matchedKeywords: string[];
}

/**
 * 关键词统计接口
 */
export interface KeywordCount {
  keyword: string;
  count: number;
}

/**
 * 智能分类服务类
 */
export class SmartCategoryService {

  // ==================== 智能推荐 ====================

  private static splitKeywords(raw: string): string[] {
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
   * 为账单推荐分类
   * @param userId 用户ID
   * @param billNote 账单备注
   * @param amount 账单金额（可选）
   * @param topN 返回前N个推荐
   * @returns 推荐结果列表
   */
  static async recommendCategory(
    userId: number,
    billNote: string,
    amount: number = 0,
    topN: number = 3
  ): Promise<CategoryRecommendation[]> {
    try {
      // 1. 获取激活的规则
      const rules = await SmartCategoryRuleDAO.getActiveRules(userId);

      // 2. 计算每个规则的匹配度
      const matchResults: Map<number, CategoryMatchData> = new Map();

      for (let i = 0; i < rules.length; i++) {
        const rule = rules[i];
        const matchResult = SmartCategoryService.matchRule(rule, billNote, amount);

        if (matchResult.matched) {
          const existing = matchResults.get(rule.categoryId);
          if (existing) {
            existing.score += matchResult.score * rule.priority;
            existing.matchedRules.push(rule.ruleName);
            if (matchResult.matchedKeywords.length > 0) {
              existing.matchedKeywords.push(...matchResult.matchedKeywords);
            }
          } else {
            const categoryInfo: CategoryInfo = { id: rule.categoryId, name: rule.categoryName };
            const matchData: CategoryMatchData = {
              category: categoryInfo,
              score: matchResult.score * rule.priority,
              matchedRules: [rule.ruleName],
              matchedKeywords: matchResult.matchedKeywords
            };
            matchResults.set(rule.categoryId, matchData);
          }
        }
      }

      // 3. 构建推荐结果
      const recommendations: CategoryRecommendation[] = [];
      matchResults.forEach((value: CategoryMatchData, categoryId: number) => {
        recommendations.push({
          categoryId: categoryId,
          categoryName: value.category.name,
          confidence: Math.min(value.score / 100, 1.0), // 归一化到0-1
          matchedRules: value.matchedRules,
          matchedKeywords: value.matchedKeywords,
          reason: SmartCategoryService.generateReason(value.matchedRules, value.matchedKeywords)
        });
      });

      // 4. 按置信度排序
      recommendations.sort((a, b) => b.confidence - a.confidence);

      // 5. 返回前N个
      return recommendations.slice(0, topN);
    } catch (error) {
      console.error('[SmartCategoryService] 推荐分类失败:', error);
      return [];
    }
  }

  /**
   * 匹配规则
   */
  private static matchRule(
    rule: SmartCategoryRule,
    billNote: string,
    amount: number
  ): RuleMatchResult {
    const lowerNote = billNote.toLowerCase();
    let matched = false;
    let score = 0;
    const matchedKeywords: string[] = [];

    switch (rule.ruleType) {
      case 'keyword':
        // 关键词匹配
        const keywords = SmartCategoryService.splitKeywords(rule.keywords);
        for (let i = 0; i < keywords.length; i++) {
          const keyword = keywords[i].toLowerCase();
          if (keyword && lowerNote.indexOf(keyword) >= 0) {
            matched = true;
            score += 30;
            matchedKeywords.push(keywords[i]);
          }
        }
        break;

      case 'regex':
        // 正则匹配
        try {
          const regex = new RegExp(rule.pattern, 'i');
          if (regex.test(billNote)) {
            matched = true;
            score += 40;
          }
        } catch (e) {
          console.warn('[SmartCategoryService] 正则表达式无效:', rule.pattern);
        }
        break;

      case 'amount':
        // 金额范围匹配
        if (amount > 0 && rule.amountMin > 0 && rule.amountMax > 0) {
          if (amount >= rule.amountMin && amount <= rule.amountMax) {
            matched = true;
            score += 20;
          }
        }
        break;

      case 'merchant':
        // 商户匹配
        if (rule.pattern && lowerNote.indexOf(rule.pattern.toLowerCase()) >= 0) {
          matched = true;
          score += 35;
          matchedKeywords.push(rule.pattern);
        }
        break;

      case 'composite':
        // 组合匹配（关键词 + 金额）
        const compositeKeywords = SmartCategoryService.splitKeywords(rule.keywords);
        let keywordMatched = false;
        for (let i = 0; i < compositeKeywords.length; i++) {
          const kw = compositeKeywords[i].toLowerCase();
          if (kw && lowerNote.indexOf(kw) >= 0) {
            keywordMatched = true;
            matchedKeywords.push(compositeKeywords[i]);
            break;
          }
        }

        let amountMatched = false;
        if (amount > 0 && rule.amountMin > 0 && rule.amountMax > 0) {
          amountMatched = amount >= rule.amountMin && amount <= rule.amountMax;
        }

        if (keywordMatched && amountMatched) {
          matched = true;
          score += 50;
        } else if (keywordMatched || amountMatched) {
          matched = true;
          score += 25;
        }
        break;
    }

    // 根据历史准确率调整分数
    score = score * rule.accuracy;

    return { matched, score, matchedKeywords };
  }

  /**
   * 生成推荐理由
   */
  private static generateReason(matchedRules: string[], matchedKeywords: string[]): string {
    if (matchedKeywords.length > 0) {
      return `匹配关键词: ${matchedKeywords.slice(0, 3).join('、')}`;
    } else if (matchedRules.length > 0) {
      return `匹配规则: ${matchedRules[0]}`;
    }
    return '基于历史习惯推荐';
  }

  // ==================== 学习与训练 ====================

  /**
   * 从用户行为学习（用户手动分类后）
   * @param userId 用户ID
   * @param billNote 账单备注
   * @param billAmount 账单金额
   * @param actualCategoryId 实际选择的分类ID
   * @param actualCategoryName 实际选择的分类名称
   * @param predictedCategoryId 预测的分类ID（可选）
   */
  static async learnFromUserAction(
    userId: number,
    billNote: string,
    billAmount: number,
    actualCategoryId: number,
    actualCategoryName: string,
    predictedCategoryId?: number
  ): Promise<void> {
    try {
      // 1. 创建训练记录
      const training = new SmartCategoryTraining();
      training.userId = userId;
      training.billNote = billNote;
      training.billAmount = billAmount;
      training.actualCategoryId = actualCategoryId;
      training.actualCategoryName = actualCategoryName;
      training.predictedCategoryId = predictedCategoryId || 0;
      training.confidence = 0;
      training.isCorrect = predictedCategoryId ? (predictedCategoryId === actualCategoryId ? 1 : 0) : 0;
      training.keywordsMatched = '';
      training.trainingType = 'manual';
      training.modelVersion = '1.0.0';

      await SmartCategoryTrainingDAO.insert(training);

      // 2. 提取关键词并创建/更新规则
      const keywords = SmartCategoryService.extractKeywords(billNote);
      if (keywords.length > 0) {
        await SmartCategoryService.createOrUpdateKeywordRule(
          userId,
          actualCategoryId,
          actualCategoryName,
          keywords,
          billAmount
        );
      }

      // 3. 如果预测错误，降低错误规则的优先级
      if (predictedCategoryId && predictedCategoryId !== actualCategoryId) {
        await SmartCategoryService.penalizeWrongRules(userId, predictedCategoryId, billNote);
      }
    } catch (error) {
      console.error('[SmartCategoryService] 学习用户行为失败:', error);
    }
  }

  /**
   * 提取关键词
   */
  private static extractKeywords(text: string): string[] {
    const keywords: string[] = [];
    const words = text.split(/[\s,，。.!！?？、]+/);

    for (let i = 0; i < words.length; i++) {
      const word = words[i].trim();
      // 保留2-10个字符的词
      if (word.length >= 2 && word.length <= 10) {
        // 过滤数字和纯符号
        if (!/^\d+$/.test(word) && /[\u4e00-\u9fa5a-zA-Z]/.test(word)) {
          keywords.push(word);
        }
      }
    }

    return keywords;
  }

  /**
   * 创建或更新关键词规则
   */
  private static async createOrUpdateKeywordRule(
    userId: number,
    categoryId: number,
    categoryName: string,
    keywords: string[],
    amount: number
  ): Promise<void> {
    try {
      // 查找该分类的现有关键词规则
      const existingRules = await SmartCategoryRuleDAO.getByCategoryId(userId, categoryId);
      const keywordRules = existingRules.filter(r => r.ruleType === 'keyword');

      for (let i = 0; i < keywords.length; i++) {
        const keyword = keywords[i];

        // 检查是否已有包含该关键词的规则
        let found = false;
      for (let j = 0; j < keywordRules.length; j++) {
          const rule = keywordRules[j];
          const ruleKeywords = SmartCategoryService.splitKeywords(rule.keywords);

          if (ruleKeywords.indexOf(keyword) >= 0) {
            // 更新规则统计
            await SmartCategoryRuleDAO.updateMatchStats(rule.ruleId, 1.0);
            found = true;
            break;
          }
        }

        if (!found) {
          // 创建新规则
          const newRule = new SmartCategoryRule();
          newRule.userId = userId;
          newRule.ruleName = `自动规则: ${keyword}`;
          newRule.categoryId = categoryId;
          newRule.categoryName = categoryName;
          newRule.ruleType = 'keyword';
          newRule.pattern = '';
          newRule.keywords = keyword;
          newRule.amountMin = 0;
          newRule.amountMax = 999999999;
          newRule.priority = 5; // 中等优先级
          newRule.isActive = 1;
          newRule.accuracy = 0.7; // 初始准确率
          newRule.matchCount = 1;

          await SmartCategoryRuleDAO.insert(newRule);
        }
      }
    } catch (error) {
      console.error('[SmartCategoryService] 创建/更新关键词规则失败:', error);
    }
  }

  /**
   * 惩罚错误规则（降低优先级和准确率）
   */
  private static async penalizeWrongRules(
    userId: number,
    wrongCategoryId: number,
    billNote: string
  ): Promise<void> {
    try {
      const rules = await SmartCategoryRuleDAO.getByCategoryId(userId, wrongCategoryId);

      for (let i = 0; i < rules.length; i++) {
        const rule = rules[i];
        const matchResult = SmartCategoryService.matchRule(rule, billNote, 0);

        if (matchResult.matched) {
          // 更新准确率（降低）
          await SmartCategoryRuleDAO.updateMatchStats(rule.ruleId, 0.0);

          // 如果准确率过低，禁用规则
          if (rule.accuracy < 0.3 && rule.matchCount >= 10) {
            await SmartCategoryRuleDAO.toggleActive(rule.ruleId, false);
          }
        }
      }
    } catch (error) {
      console.error('[SmartCategoryService] 惩罚错误规则失败:', error);
    }
  }

  /**
   * 批量学习（从历史账单）
   * @param userId 用户ID
   * @param daysBack 回溯天数
   * @returns 学习结果
   */
  static async batchLearnFromHistory(userId: number, daysBack: number = 30): Promise<LearningResult> {
    try {
      const result: LearningResult = {
        rulesCreated: 0,
        rulesUpdated: 0,
        trainingRecordsCreated: 0,
        scannedBills: 0,
        totalKeywords: 0,
        categoryCount: 0
      };

      // 获取历史账单
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - daysBack);

      // 辅助函数：格式化日期为 YYYY-MM-DD
      const formatDate = (date: Date): string => {
        const y = date.getFullYear();
        const m = (date.getMonth() + 1).toString().padStart(2, '0');
        const d = date.getDate().toString().padStart(2, '0');
        return `${y}-${m}-${d}`;
      };

      const startStr = formatDate(startDate);
      const endStr = formatDate(endDate);

      // use getBillsByFilters instead of getByTimeRange for better reliability
      // 使用 getBillsByFilters 代替 getByTimeRange 以获得更好的可靠性
      const bills = await BillDAO.getBillsByFilters(userId, { start: startStr, end: endStr });
      result.scannedBills = bills.length;
      
      // 统计每个分类的关键词频率
      const categoryKeywords: Map<number, Map<string, number>> = new Map();

      for (let i = 0; i < bills.length; i++) {
        const bill = bills[i];
        const keywords = SmartCategoryService.extractKeywords(bill.note);
        
        result.totalKeywords += keywords.length; // 统计发现的总关键词数量

        if (keywords.length === 0) continue;

        if (!categoryKeywords.has(bill.categoryId)) {
          categoryKeywords.set(bill.categoryId, new Map());
        }

        const keywordMap = categoryKeywords.get(bill.categoryId)!;
        for (let j = 0; j < keywords.length; j++) {
          const keyword = keywords[j];
          keywordMap.set(keyword, (keywordMap.get(keyword) || 0) + 1);
        }

        // 创建训练记录
        try {
            const training = new SmartCategoryTraining();
            training.userId = userId;
            training.billNote = bill.note;
            training.billAmount = bill.amount;
            training.actualCategoryId = bill.categoryId;
            training.actualCategoryName = ''; // 需要从CategoryDAO获取
            training.trainingType = 'auto';
            training.modelVersion = '1.0.0';

            await SmartCategoryTrainingDAO.insert(training);
            result.trainingRecordsCreated++;
        } catch (e) {
            console.warn(`[SmartCategoryService] 创建训练记录失败: ${e.message}`);
        }
      }

      // 为每个分类创建规则
      const categories = await CategoryDAO.getAll(userId);

      // 为每个分类创建规则 (使用 for-of 确保异步操作完成)
      const categoryIds = Array.from(categoryKeywords.keys());
      result.categoryCount = categoryIds.length; // 记录有多少个分类包含关键词
      for (const categoryId of categoryIds) {
        const keywordMap = categoryKeywords.get(categoryId)!;
        const category = categories.find((c: Category) => c.categoryId === categoryId);
        if (!category) continue;

        // 选择频率最高的前5个关键词
        const sortedKeywords: KeywordCount[] = [];
        keywordMap.forEach((count: number, keyword: string) => {
          const item: KeywordCount = { keyword, count };
          sortedKeywords.push(item);
        });
        sortedKeywords.sort((a, b) => b.count - a.count);

        const topKeywords = sortedKeywords.slice(0, 5);

        // 为每个高频关键词创建规则 (使用 for-of 确保 await 生效)
        for (const item of topKeywords) {
          if (item.count >= 1) { // 降低阈值：至少出现1次即可
            try {
                const rule = new SmartCategoryRule();
                rule.userId = userId;
                rule.ruleName = `学习规则: ${item.keyword}`;
                rule.categoryId = categoryId;
                rule.categoryName = category.name;
                rule.ruleType = 'keyword';
                rule.keywords = item.keyword;
                rule.priority = Math.min(item.count + 4, 10); // 提高初始优先级 (1次 -> 优先级5)
                rule.isActive = 1;
                rule.accuracy = 0.8;
                rule.matchCount = item.count;

                await SmartCategoryRuleDAO.insert(rule);
                result.rulesCreated++;
            } catch (e) {
                console.error(`[SmartCategoryService] 创建规则失败: ${e.message}`);
            }
          }
        }
      }

      return result;
    } catch (error) {
      console.error('[SmartCategoryService] 批量学习失败:', error);
      const emptyResult: LearningResult = { rulesCreated: 0, rulesUpdated: 0, trainingRecordsCreated: 0, scannedBills: 0, totalKeywords: 0, categoryCount: 0 };
      return emptyResult;
    }

  }

  // ==================== 规则管理 ====================

  /**
   * 创建自定义规则
   */
  static async createCustomRule(
    userId: number,
    ruleName: string,
    categoryId: number,
    categoryName: string,
    ruleType: 'keyword' | 'regex' | 'amount' | 'merchant' | 'composite',
    pattern: string,
    keywords: string,
    amountMin?: number,
    amountMax?: number,
    priority: number = 5
  ): Promise<number> {
    try {
      const rule = new SmartCategoryRule();
      rule.userId = userId;
      rule.ruleName = ruleName;
      rule.categoryId = categoryId;
      rule.categoryName = categoryName;
      rule.ruleType = ruleType;
      rule.pattern = pattern;
      rule.keywords = keywords;
      rule.amountMin = amountMin || 0;
      rule.amountMax = amountMax || 999999999;
      rule.priority = priority;
      rule.isActive = 1;
      rule.accuracy = 1.0; // 用户自定义规则初始准确率为1
      rule.matchCount = 0;

      return await SmartCategoryRuleDAO.insert(rule);
    } catch (error) {
      console.error('[SmartCategoryService] 创建自定义规则失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 更新规则
   */
  static async updateRule(rule: SmartCategoryRule): Promise<boolean> {
    try {
      return await SmartCategoryRuleDAO.update(rule);
    } catch (error) {
      console.error('[SmartCategoryService] 更新规则失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 删除规则
   */
  static async deleteRule(ruleId: number): Promise<boolean> {
    try {
      return await SmartCategoryRuleDAO.softDelete(ruleId);
    } catch (error) {
      console.error('[SmartCategoryService] 删除规则失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取用户的所有规则
   */
  static async getUserRules(userId: number): Promise<SmartCategoryRule[]> {
    try {
      return await SmartCategoryRuleDAO.getByUserId(userId);
    } catch (error) {
      console.error('[SmartCategoryService] 获取用户规则失败:', error);
      return [];
    }
  }

  /**
   * 启用/禁用规则
   */
  static async toggleRule(ruleId: number, isActive: boolean): Promise<boolean> {
    try {
      return await SmartCategoryRuleDAO.toggleActive(ruleId, isActive);
    } catch (error) {
      console.error('[SmartCategoryService] 切换规则状态失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  // ==================== 统计与分析 ====================

  /**
   * 获取训练统计
   */
  static async getTrainingStatistics(userId: number) {
    try {
      return await SmartCategoryTrainingDAO.getStatistics(userId);
    } catch (error) {
      console.error('[SmartCategoryService] 获取训练统计失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取规则统计
   */
  static async getRuleStatistics(userId: number) {
    try {
      return await SmartCategoryRuleDAO.getStatistics(userId);
    } catch (error) {
      console.error('[SmartCategoryService] 获取规则统计失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 清理低效规则
   */
  static async cleanupLowPerformanceRules(userId: number): Promise<number> {
    try {
      return await SmartCategoryRuleDAO.cleanupLowAccuracyRules(userId, 0.3, 10);
    } catch (error) {
      console.error('[SmartCategoryService] 清理低效规则失败:', error);
      return 0;
    }
  }
}
