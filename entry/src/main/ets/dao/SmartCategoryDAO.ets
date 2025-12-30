/**
 * 智能分类DAO - 数据访问层
 *
 * 功能：
 * 1. 智能分类训练数据管理
 * 2. 分类规则管理
 * 3. 用户行为学习数据存储
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { SmartCategoryTraining, SmartCategoryRule } from '../model/SmartCategory';
import { DAOHelper } from '../common/DAOHelper';

interface ColumnSpec {
  name: string;
  addSql: string;
}

// 智能分类训练DAO

/**
 * 智能分类训练数据统计接口
 */
export interface TrainingStatistics {
  totalRecords: number;
  trainingCount: number;
  predictionCount: number;
  avgAccuracy: number;
  lastTrainingAt: string;
  modelVersion: string;
}

/**
 * 智能分类训练DAO
 */
export class SmartCategoryTrainingDAO {
  /**
   * 插入训练记录
   */
  static async insert(record: SmartCategoryTraining): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      record.createdAt = now;
      record.updatedAt = now;

      const values: relationalStore.ValuesBucket = {
        user_id: record.userId,
        bill_note: record.billNote,
        bill_amount: record.billAmount,
        actual_category_id: record.actualCategoryId,
        actual_category_name: record.actualCategoryName,
        predicted_category_id: record.predictedCategoryId || null,
        predicted_category_name: record.predictedCategoryName || null,
        confidence: record.confidence,
        is_correct: record.isCorrect,
        keywords_matched: record.keywordsMatched,
        training_type: record.trainingType,
        model_version: record.modelVersion,
        created_at: record.createdAt,
        updated_at: record.updatedAt,
        is_deleted: record.isDeleted
      };

      const rowId = await store.insert(SmartCategoryTraining.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryTrainingDAO] 插入训练记录失败', error);
    }
  }

  /**
   * 根据ID查询训练记录
   */
  static async getById(recordId: number): Promise<SmartCategoryTraining | null> {
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(SmartCategoryTraining.tableName);
      predicates.equalTo('record_id', recordId).and().equalTo('is_deleted', 0);

      const resultSet = await store.query(predicates);
      if (!resultSet || resultSet.rowCount === 0) {
        resultSet?.close();
        return null;
      }

      resultSet.goToFirstRow();
      const record = DAOHelper.convertToSmartCategoryTraining(resultSet);
      resultSet.close();
      return record;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryTrainingDAO] 查询训练记录失败', error);
    }
  }

  /**
   * 根据用户ID查询训练记录列表
   */
  static async getByUserId(
    userId: number,
    limit: number = 100,
    offset: number = 0
  ): Promise<SmartCategoryTraining[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${SmartCategoryTraining.tableName}
        WHERE user_id = ? AND is_deleted = 0
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
      `;
      const resultSet = await store.querySql(sql, [userId, limit, offset]);

      const records: SmartCategoryTraining[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToSmartCategoryTraining(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryTrainingDAO] 查询用户训练记录失败', error);
    }
  }

  /**
   * 根据训练类型查询
   */
  static async getByType(
    userId: number,
    trainingType: 'manual' | 'auto' | 'correction',
    limit: number = 50
  ): Promise<SmartCategoryTraining[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${SmartCategoryTraining.tableName}
        WHERE user_id = ? AND training_type = ? AND is_deleted = 0
        ORDER BY created_at DESC
        LIMIT ?
      `;
      const resultSet = await store.querySql(sql, [userId, trainingType, limit]);

      const records: SmartCategoryTraining[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToSmartCategoryTraining(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryTrainingDAO] 按类型查询训练记录失败', error);
    }
  }

  /**
   * 查询正确的预测记录（用于模型评估）
   */
  static async getCorrectPredictions(
    userId: number,
    limit: number = 100
  ): Promise<SmartCategoryTraining[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${SmartCategoryTraining.tableName}
        WHERE user_id = ? AND is_correct = 1 AND is_deleted = 0
        ORDER BY created_at DESC
        LIMIT ?
      `;
      const resultSet = await store.querySql(sql, [userId, limit]);

      const records: SmartCategoryTraining[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToSmartCategoryTraining(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryTrainingDAO] 查询正确预测记录失败', error);
    }
  }

  /**
   * 获取训练数据统计
   */
  static async getStatistics(userId: number): Promise<TrainingStatistics> {
    try {
      const store = DatabaseManager.getDatabase();

      // 统计总记录数和各类型数量
      const sql = `
        SELECT
          COUNT(*) as total_records,
          SUM(CASE WHEN training_type = 'manual' OR training_type = 'auto' THEN 1 ELSE 0 END) as training_count,
          SUM(CASE WHEN predicted_category_id IS NOT NULL THEN 1 ELSE 0 END) as prediction_count,
          AVG(CASE WHEN is_correct = 1 THEN 1.0 ELSE 0.0 END) as avg_accuracy,
          MAX(created_at) as last_training_at,
          model_version
        FROM ${SmartCategoryTraining.tableName}
        WHERE user_id = ? AND is_deleted = 0
        GROUP BY model_version
        ORDER BY last_training_at DESC
        LIMIT 1
      `;
      const resultSet = await store.querySql(sql, [userId]);

      let stats: TrainingStatistics = {
        totalRecords: 0,
        trainingCount: 0,
        predictionCount: 0,
        avgAccuracy: 0,
        lastTrainingAt: '',
        modelVersion: '1.0.0'
      };

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        stats = {
          totalRecords: DAOHelper.getNumberValue(resultSet, 'total_records'),
          trainingCount: DAOHelper.getNumberValue(resultSet, 'training_count'),
          predictionCount: DAOHelper.getNumberValue(resultSet, 'prediction_count'),
          avgAccuracy: DAOHelper.getNumberValue(resultSet, 'avg_accuracy'),
          lastTrainingAt: DAOHelper.getStringValue(resultSet, 'last_training_at'),
          modelVersion: DAOHelper.getStringValue(resultSet, 'model_version')
        };
      }
      resultSet?.close();
      return stats;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryTrainingDAO] 获取训练统计失败', error);
    }
  }

  /**
   * 更新训练记录
   */
  static async update(record: SmartCategoryTraining): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      record.updatedAt = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        user_id: record.userId,
        bill_note: record.billNote,
        bill_amount: record.billAmount,
        actual_category_id: record.actualCategoryId,
        actual_category_name: record.actualCategoryName,
        predicted_category_id: record.predictedCategoryId || null,
        predicted_category_name: record.predictedCategoryName || null,
        confidence: record.confidence,
        is_correct: record.isCorrect,
        keywords_matched: record.keywordsMatched,
        training_type: record.trainingType,
        model_version: record.modelVersion,
        updated_at: record.updatedAt
      };

      const predicates = new relationalStore.RdbPredicates(SmartCategoryTraining.tableName);
      predicates.equalTo('record_id', record.recordId);

      const rows = await store.update(values, predicates);
      return rows > 0;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryTrainingDAO] 更新训练记录失败', error);
    }
  }

  /**
   * 软删除训练记录
   */
  static async softDelete(recordId: number): Promise<void> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        is_deleted: 1,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(SmartCategoryTraining.tableName);
      predicates.equalTo('record_id', recordId);

      await store.update(values, predicates);
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryTrainingDAO] 软删除训练记录失败', error);
    }
  }

  /**
   * 批量删除用户的训练记录
   */
  static async deleteByUserId(userId: number): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        is_deleted: 1,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(SmartCategoryTraining.tableName);
      predicates.equalTo('user_id', userId);

      const rows = await store.update(values, predicates);
      return rows;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryTrainingDAO] 批量删除用户训练记录失败', error);
    }
  }

  /**
   * 清理旧的训练数据（保留最近N条）
   */
  static async cleanupOldRecords(userId: number, keepCount: number = 1000): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();

      // 查找要保留的最早记录的时间
      const sql = `
        SELECT created_at
        FROM ${SmartCategoryTraining.tableName}
        WHERE user_id = ? AND is_deleted = 0
        ORDER BY created_at DESC
        LIMIT 1 OFFSET ?
      `;
      const resultSet = await store.querySql(sql, [userId, keepCount - 1]);

      if (!resultSet || resultSet.rowCount === 0) {
        resultSet?.close();
        return 0; // 没有需要清理的记录
      }

      resultSet.goToFirstRow();
      const cutoffTime = DAOHelper.getStringValue(resultSet, 'created_at');
      resultSet.close();

      // 软删除早于cutoffTime的记录
      const deleteSql = `
        UPDATE ${SmartCategoryTraining.tableName}
        SET is_deleted = 1, updated_at = ?
        WHERE user_id = ? AND created_at < ? AND is_deleted = 0
      `;
      const now = new Date().toISOString();
      await store.executeSql(deleteSql, [now, userId, cutoffTime]);

      // 返回成功（executeSql不返回影响行数）
      return 0;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryTrainingDAO] 清理旧训练记录失败', error);
    }
  }
}

//  智能分类规则DAO 
/**
 * 规则统计接口
 */
export interface RuleStatistics {
  totalRules: number;
  activeRules: number;
  systemRules: number;
  userRules: number;
  avgPriority: number;
  avgAccuracy: number;
}

/**
 * 智能分类规则DAO
 */
export class SmartCategoryRuleDAO {
  private static schemaEnsured: boolean = false;

  private static async ensureSchema(): Promise<void> {
    if (SmartCategoryRuleDAO.schemaEnsured) {
      return;
    }

    const store = DatabaseManager.getDatabase();

    // 1) Ensure table exists
    const tableInfoRs = await store.querySql(`PRAGMA table_info(${SmartCategoryRule.tableName});`);
    const existingColumns: Set<string> = new Set<string>();

    try {
      while (tableInfoRs.goToNextRow()) {
        const nameIndex = tableInfoRs.getColumnIndex('name');
        if (nameIndex >= 0) {
          const colName = tableInfoRs.getString(nameIndex);
          existingColumns.add(colName);
        }
      }
    } finally {
      tableInfoRs.close();
    }

    if (existingColumns.size === 0) {
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS ${SmartCategoryRule.tableName} (
          rule_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          rule_name TEXT NOT NULL,
          category_id INTEGER NOT NULL,
          category_name TEXT NOT NULL,
          rule_type TEXT NOT NULL DEFAULT 'keyword',
          pattern TEXT NOT NULL DEFAULT '',
          keywords TEXT NOT NULL DEFAULT '',
          amount_min REAL NOT NULL DEFAULT 0,
          amount_max REAL NOT NULL DEFAULT 999999999,
          priority INTEGER NOT NULL DEFAULT 5,
          is_active INTEGER DEFAULT 1,
          accuracy REAL NOT NULL DEFAULT 0.8,
          match_count INTEGER NOT NULL DEFAULT 0,
          last_matched_at TEXT DEFAULT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (category_id) REFERENCES categories(category_id)
        );
      `);

      SmartCategoryRuleDAO.schemaEnsured = true;
      return;
    }

    // 2) Ensure required columns exist (for legacy DB schemas)
    const requiredColumns: ColumnSpec[] = [
      { name: 'user_id', addSql: 'user_id INTEGER NOT NULL DEFAULT 0' },
      { name: 'rule_name', addSql: "rule_name TEXT NOT NULL DEFAULT ''" },
      { name: 'category_id', addSql: 'category_id INTEGER NOT NULL DEFAULT 0' },
      { name: 'category_name', addSql: "category_name TEXT NOT NULL DEFAULT ''" },
      { name: 'rule_type', addSql: "rule_type TEXT NOT NULL DEFAULT 'keyword'" },
      { name: 'pattern', addSql: "pattern TEXT NOT NULL DEFAULT ''" },
      { name: 'keywords', addSql: "keywords TEXT NOT NULL DEFAULT ''" },
      { name: 'amount_min', addSql: 'amount_min REAL NOT NULL DEFAULT 0' },
      { name: 'amount_max', addSql: 'amount_max REAL NOT NULL DEFAULT 999999999' },
      { name: 'priority', addSql: 'priority INTEGER NOT NULL DEFAULT 5' },
      { name: 'is_active', addSql: 'is_active INTEGER DEFAULT 1' },
      { name: 'accuracy', addSql: 'accuracy REAL NOT NULL DEFAULT 0.8' },
      { name: 'match_count', addSql: 'match_count INTEGER NOT NULL DEFAULT 0' },
      { name: 'last_matched_at', addSql: 'last_matched_at TEXT DEFAULT NULL' },
      { name: 'created_at', addSql: "created_at TEXT NOT NULL DEFAULT ''" },
      { name: 'updated_at', addSql: "updated_at TEXT NOT NULL DEFAULT ''" },
      { name: 'is_deleted', addSql: 'is_deleted INTEGER DEFAULT 0' }
    ];

    for (const col of requiredColumns) {
      if (!existingColumns.has(col.name)) {
        await store.executeSql(`ALTER TABLE ${SmartCategoryRule.tableName} ADD COLUMN ${col.addSql};`);
      }
    }

    SmartCategoryRuleDAO.schemaEnsured = true;
  }

  /**
   * 插入分类规则
   */
  static async insert(rule: SmartCategoryRule): Promise<number> {
    try {
      if (!rule.validate()) {
        throw new Error('[SmartCategoryRuleDAO] 无效规则数据');
      }

      await SmartCategoryRuleDAO.ensureSchema();

      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      rule.createdAt = now;
      rule.updatedAt = now;

      const values: relationalStore.ValuesBucket = {
        user_id: rule.userId,
        rule_name: rule.ruleName,
        category_id: rule.categoryId,
        category_name: rule.categoryName,
        rule_type: rule.ruleType,
        pattern: rule.pattern,
        keywords: rule.keywords,
        amount_min: rule.amountMin,
        amount_max: rule.amountMax,
        priority: rule.priority,
        is_active: rule.isActive,
        accuracy: rule.accuracy,
        match_count: rule.matchCount,
        last_matched_at: rule.lastMatchedAt || null,
        created_at: rule.createdAt,
        updated_at: rule.updatedAt,
        is_deleted: rule.isDeleted
      };

      const rowId = await store.insert(SmartCategoryRule.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 插入分类规则失败', error);
    }
  }

  /**
   * 根据ID查询规则
   */
  static async getById(ruleId: number): Promise<SmartCategoryRule | null> {
    try {
      await SmartCategoryRuleDAO.ensureSchema();
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(SmartCategoryRule.tableName);
      predicates.equalTo('rule_id', ruleId).and().equalTo('is_deleted', 0);

      const resultSet = await store.query(predicates);
      if (!resultSet || resultSet.rowCount === 0) {
        resultSet?.close();
        return null;
      }

      resultSet.goToFirstRow();
      const rule = DAOHelper.convertToSmartCategoryRule(resultSet);
      resultSet.close();
      return rule;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 查询分类规则失败', error);
    }
  }

  /**
   * 根据用户ID查询所有规则
   */
  static async getByUserId(userId: number): Promise<SmartCategoryRule[]> {
    try {
      await SmartCategoryRuleDAO.ensureSchema();
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${SmartCategoryRule.tableName}
        WHERE user_id = ? AND is_deleted = 0
        ORDER BY priority DESC, created_at DESC
      `;
      const resultSet = await store.querySql(sql, [userId]);

      const rules: SmartCategoryRule[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          rules.push(DAOHelper.convertToSmartCategoryRule(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return rules;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 查询用户规则失败', error);
    }
  }

  /**
   * 查询激活的规则（按优先级排序）
   */
  static async getActiveRules(userId: number): Promise<SmartCategoryRule[]> {
    try {
      await SmartCategoryRuleDAO.ensureSchema();
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${SmartCategoryRule.tableName}
        WHERE user_id = ? AND is_active = 1 AND is_deleted = 0
        ORDER BY priority DESC, accuracy DESC
      `;
      const resultSet = await store.querySql(sql, [userId]);

      const rules: SmartCategoryRule[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          rules.push(DAOHelper.convertToSmartCategoryRule(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return rules;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 查询激活规则失败', error);
    }
  }

  /**
   * 根据规则类型查询
   */
  static async getByType(
    userId: number,
    ruleType: 'keyword' | 'regex' | 'amount' | 'merchant' | 'composite'
  ): Promise<SmartCategoryRule[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${SmartCategoryRule.tableName}
        WHERE user_id = ? AND rule_type = ? AND is_deleted = 0
        ORDER BY priority DESC
      `;
      const resultSet = await store.querySql(sql, [userId, ruleType]);

      const rules: SmartCategoryRule[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          rules.push(DAOHelper.convertToSmartCategoryRule(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return rules;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 按类型查询规则失败', error);
    }
  }

  /**
   * 根据分类ID查询规则
   */
  static async getByCategoryId(
    userId: number,
    categoryId: number
  ): Promise<SmartCategoryRule[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${SmartCategoryRule.tableName}
        WHERE user_id = ? AND category_id = ? AND is_deleted = 0
        ORDER BY priority DESC
      `;
      const resultSet = await store.querySql(sql, [userId, categoryId]);

      const rules: SmartCategoryRule[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          rules.push(DAOHelper.convertToSmartCategoryRule(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return rules;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 按分类查询规则失败', error);
    }
  }

  /**
   * 更新规则
   */
  static async update(rule: SmartCategoryRule): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      rule.updatedAt = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        rule_name: rule.ruleName,
        category_id: rule.categoryId,
        category_name: rule.categoryName,
        rule_type: rule.ruleType,
        pattern: rule.pattern,
        keywords: rule.keywords,
        amount_min: rule.amountMin,
        amount_max: rule.amountMax,
        priority: rule.priority,
        is_active: rule.isActive,
        accuracy: rule.accuracy,
        match_count: rule.matchCount,
        last_matched_at: rule.lastMatchedAt || null,
        updated_at: rule.updatedAt
      };

      const predicates = new relationalStore.RdbPredicates(SmartCategoryRule.tableName);
      predicates.equalTo('rule_id', rule.ruleId);

      const rows = await store.update(values, predicates);
      return rows > 0;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 更新规则失败', error);
    }
  }

  /**
   * 激活/禁用规则
   */
  static async toggleActive(ruleId: number, isActive: boolean): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        is_active: isActive ? 1 : 0,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(SmartCategoryRule.tableName);
      predicates.equalTo('rule_id', ruleId);

      const rows = await store.update(values, predicates);
      return rows > 0;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 切换规则状态失败', error);
    }
  }

  /**
   * 更新规则匹配统计
   */
  static async updateMatchStats(ruleId: number, accuracy: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();

      // 先获取当前统计
      const rule = await SmartCategoryRuleDAO.getById(ruleId);
      if (!rule) {
        return false;
      }

      // 更新匹配次数和准确率（移动平均）
      const newMatchCount = rule.matchCount + 1;
      const newAccuracy = (rule.accuracy * rule.matchCount + accuracy) / newMatchCount;

      const values: relationalStore.ValuesBucket = {
        accuracy: newAccuracy,
        match_count: newMatchCount,
        last_matched_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(SmartCategoryRule.tableName);
      predicates.equalTo('rule_id', ruleId);

      const rows = await store.update(values, predicates);
      return rows > 0;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 更新匹配统计失败', error);
    }
  }

  /**
   * 获取规则统计
   */
  static async getStatistics(userId: number): Promise<RuleStatistics> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT
          COUNT(*) as total_rules,
          SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as active_rules,
          SUM(CASE WHEN rule_type = 'system' THEN 1 ELSE 0 END) as system_rules,
          SUM(CASE WHEN rule_type != 'system' THEN 1 ELSE 0 END) as user_rules,
          AVG(priority) as avg_priority,
          AVG(accuracy) as avg_accuracy
        FROM ${SmartCategoryRule.tableName}
        WHERE user_id = ? AND is_deleted = 0
      `;
      const resultSet = await store.querySql(sql, [userId]);

      let stats: RuleStatistics = {
        totalRules: 0,
        activeRules: 0,
        systemRules: 0,
        userRules: 0,
        avgPriority: 0,
        avgAccuracy: 0
      };

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        stats = {
          totalRules: DAOHelper.getNumberValue(resultSet, 'total_rules'),
          activeRules: DAOHelper.getNumberValue(resultSet, 'active_rules'),
          systemRules: DAOHelper.getNumberValue(resultSet, 'system_rules'),
          userRules: DAOHelper.getNumberValue(resultSet, 'user_rules'),
          avgPriority: DAOHelper.getNumberValue(resultSet, 'avg_priority'),
          avgAccuracy: DAOHelper.getNumberValue(resultSet, 'avg_accuracy')
        };
      }
      resultSet?.close();
      return stats;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 获取规则统计失败', error);
    }
  }

  /**
   * 软删除规则
   */
  static async softDelete(ruleId: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        is_deleted: 1,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(SmartCategoryRule.tableName);
      predicates.equalTo('rule_id', ruleId);

      const rows = await store.update(values, predicates);
      return rows > 0;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 软删除规则失败', error);
    }
  }

  /**
   * 批量删除用户的规则
   */
  static async deleteByUserId(userId: number): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        is_deleted: 1,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(SmartCategoryRule.tableName);
      predicates.equalTo('user_id', userId);

      const rows = await store.update(values, predicates);
      return rows;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 批量删除用户规则失败', error);
    }
  }

  /**
   * 批量删除分类的规则
   */
  static async deleteByCategoryId(userId: number, categoryId: number): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        is_deleted: 1,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(SmartCategoryRule.tableName);
      predicates.equalTo('user_id', userId).and().equalTo('category_id', categoryId);

      const rows = await store.update(values, predicates);
      return rows;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 批量删除分类规则失败', error);
    }
  }

  /**
   * 清理低准确率规则
   */
  static async cleanupLowAccuracyRules(
    userId: number,
    accuracyThreshold: number = 0.3,
    minMatchCount: number = 10
  ): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        UPDATE ${SmartCategoryRule.tableName}
        SET is_deleted = 1, updated_at = ?
        WHERE user_id = ?
          AND accuracy < ?
          AND match_count >= ?
          AND is_deleted = 0
      `;
      const now = new Date().toISOString();
      await store.executeSql(sql, [now, userId, accuracyThreshold, minMatchCount]);

      // 返回成功（executeSql不返回影响行数）
      return 0;
    } catch (error) {
      throw DAOHelper.toError('[SmartCategoryRuleDAO] 清理低准确率规则失败', error);
    }
  }
}
