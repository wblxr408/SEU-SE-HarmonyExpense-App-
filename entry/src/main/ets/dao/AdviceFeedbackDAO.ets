/**
 * 建议反馈数据访问对象
 * 
 * 功能：
 * 1. 建议反馈的CRUD操作
 * 2. 统计建议接受率
 * 3. 评估建议准确性
 * 
 * @version 1.0.0
 * @author HarmonyExpense Team
 */

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { AdviceFeedback, FEEDBACK_ACCEPTED, FEEDBACK_REJECTED } from '../model/AdviceFeedback';
import hilog from '@ohos.hilog';

const LOG_TAG = 'AdviceFeedbackDAO';
const HILOG_DOMAIN = 0x0001;

export class AdviceFeedbackDAO {

  /**
   * 插入反馈记录
   */
  static async insert(feedback: AdviceFeedback): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const valueBucket: relationalStore.ValuesBucket = {
        user_id: feedback.userId,
        advice_id: feedback.adviceId,
        advice_type: feedback.adviceType,
        category_id: feedback.categoryId,
        category_name: feedback.categoryName,
        suggested_budget: feedback.suggestedBudget,
        original_budget: feedback.originalBudget,
        feedback_status: feedback.feedbackStatus,
        actual_budget_set: feedback.actualBudgetSet,
        feedback_date: feedback.feedbackDate || new Date().toISOString(),
        effective_date: feedback.effectiveDate,
        actual_spending: feedback.actualSpending,
        accuracy_score: feedback.accuracyScore,
        user_comment: feedback.userComment,
        created_at: feedback.createdAt || new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const rowId = await store.insert(AdviceFeedback.tableName, valueBucket);
      hilog.info(HILOG_DOMAIN, LOG_TAG, `建议反馈插入成功，ID: ${rowId}`);
      return rowId;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `插入建议反馈失败: ${error.message}`);
      throw new Error(`插入建议反馈失败: ${error.message}`);
    }
  }

  /**
   * 更新反馈记录
   */
  static async update(feedback: AdviceFeedback): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const valueBucket: relationalStore.ValuesBucket = {
        feedback_status: feedback.feedbackStatus,
        actual_budget_set: feedback.actualBudgetSet,
        feedback_date: feedback.feedbackDate,
        actual_spending: feedback.actualSpending,
        accuracy_score: feedback.accuracyScore,
        user_comment: feedback.userComment,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(AdviceFeedback.tableName);
      predicates.equalTo('feedback_id', feedback.feedbackId);

      const rows = await store.update(valueBucket, predicates);
      hilog.info(HILOG_DOMAIN, LOG_TAG, `建议反馈更新成功，影响行数: ${rows}`);
      return rows > 0;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `更新建议反馈失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 根据建议ID获取反馈
   */
  static async getByAdviceId(adviceId: string): Promise<AdviceFeedback | null> {
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(AdviceFeedback.tableName);
      predicates.equalTo('advice_id', adviceId);

      const resultSet = await store.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }

      resultSet.goToFirstRow();
      const feedback = AdviceFeedbackDAO.parseResultSet(resultSet);
      resultSet.close();
      
      return feedback;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `查询建议反馈失败: ${error.message}`);
      return null;
    }
  }

  /**
   * 获取用户的所有反馈记录
   */
  static async getByUserId(userId: number, limit?: number): Promise<AdviceFeedback[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(AdviceFeedback.tableName);
      predicates.equalTo('user_id', userId);
      predicates.orderByDesc('created_at');
      
      if (limit) {
        predicates.limitAs(limit);
      }

      const resultSet = await store.query(predicates);
      const feedbacks: AdviceFeedback[] = [];

      while (resultSet.goToNextRow()) {
        feedbacks.push(AdviceFeedbackDAO.parseResultSet(resultSet));
      }

      resultSet.close();
      return feedbacks;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `查询用户反馈失败: ${error.message}`);
      return [];
    }
  }

  /**
   * 计算用户的建议接受率
   */
  static async calculateAcceptanceRate(userId: number): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const query = `
        SELECT 
          COUNT(CASE WHEN feedback_status = ? THEN 1 END) * 1.0 / COUNT(*) as acceptance_rate
        FROM advice_feedbacks
        WHERE user_id = ?
      `;

      const resultSet = await store.querySql(query, [FEEDBACK_ACCEPTED, userId.toString()]);
      
      let rate = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        rate = resultSet.getDouble(resultSet.getColumnIndex('acceptance_rate'));
      }
      
      resultSet.close();
      return Math.round(rate * 100) / 100;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `计算接受率失败: ${error.message}`);
      return 0;
    }
  }

  /**
   * 获取特定建议类型的接受率
   */
  static async getAcceptanceRateByType(userId: number, adviceType: string): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const query = `
        SELECT 
          COUNT(CASE WHEN feedback_status = ? THEN 1 END) * 1.0 / COUNT(*) as acceptance_rate
        FROM advice_feedbacks
        WHERE user_id = ? AND advice_type = ?
      `;

      const resultSet = await store.querySql(query, [FEEDBACK_ACCEPTED, userId.toString(), adviceType]);
      
      let rate = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        rate = resultSet.getDouble(resultSet.getColumnIndex('acceptance_rate'));
      }
      
      resultSet.close();
      return Math.round(rate * 100) / 100;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `计算类型接受率失败: ${error.message}`);
      return 0;
    }
  }

  /**
   * 获取平均准确性评分
   */
  static async getAverageAccuracyScore(userId: number): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const query = `
        SELECT AVG(accuracy_score) as avg_score
        FROM advice_feedbacks
        WHERE user_id = ? AND accuracy_score > 0
      `;

      const resultSet = await store.querySql(query, [userId.toString()]);
      
      let score = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        score = resultSet.getDouble(resultSet.getColumnIndex('avg_score'));
      }
      
      resultSet.close();
      return Math.round(score * 100) / 100;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `计算平均准确性失败: ${error.message}`);
      return 0;
    }
  }

  /**
   * 更新实际支出并计算准确性
   */
  static async updateActualSpending(feedbackId: number, actualSpending: number): Promise<boolean> {
    try {
      // 先获取反馈记录
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(AdviceFeedback.tableName);
      predicates.equalTo('feedback_id', feedbackId);

      const resultSet = await store.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return false;
      }

      resultSet.goToFirstRow();
      const feedback = AdviceFeedbackDAO.parseResultSet(resultSet);
      resultSet.close();

      // 更新实际支出
      feedback.actualSpending = actualSpending;
      
      // 计算准确性评分
      feedback.accuracyScore = feedback.calculateAccuracy();

      // 保存
      return await AdviceFeedbackDAO.update(feedback);
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `更新实际支出失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 获取需要评估的反馈（已过生效期但未评估的）
   */
  static async getPendingEvaluations(userId: number): Promise<AdviceFeedback[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      
      const predicates = new relationalStore.RdbPredicates(AdviceFeedback.tableName);
      predicates.equalTo('user_id', userId);
      predicates.equalTo('feedback_status', FEEDBACK_ACCEPTED);
      predicates.lessThan('effective_date', now);
      predicates.equalTo('accuracy_score', 0);

      const resultSet = await store.query(predicates);
      const feedbacks: AdviceFeedback[] = [];

      while (resultSet.goToNextRow()) {
        feedbacks.push(AdviceFeedbackDAO.parseResultSet(resultSet));
      }

      resultSet.close();
      return feedbacks;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `查询待评估反馈失败: ${error.message}`);
      return [];
    }
  }

  /**
   * 解析查询结果
   */
  private static parseResultSet(resultSet: relationalStore.ResultSet): AdviceFeedback {
    const feedback = new AdviceFeedback();
    feedback.feedbackId = resultSet.getLong(resultSet.getColumnIndex('feedback_id'));
    feedback.userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
    feedback.adviceId = resultSet.getString(resultSet.getColumnIndex('advice_id'));
    feedback.adviceType = resultSet.getString(resultSet.getColumnIndex('advice_type'));
    feedback.categoryId = resultSet.getLong(resultSet.getColumnIndex('category_id'));
    feedback.categoryName = resultSet.getString(resultSet.getColumnIndex('category_name'));
    feedback.suggestedBudget = resultSet.getDouble(resultSet.getColumnIndex('suggested_budget'));
    feedback.originalBudget = resultSet.getDouble(resultSet.getColumnIndex('original_budget'));
    feedback.feedbackStatus = resultSet.getString(resultSet.getColumnIndex('feedback_status'));
    feedback.actualBudgetSet = resultSet.getDouble(resultSet.getColumnIndex('actual_budget_set'));
    feedback.feedbackDate = resultSet.getString(resultSet.getColumnIndex('feedback_date'));
    feedback.effectiveDate = resultSet.getString(resultSet.getColumnIndex('effective_date'));
    feedback.actualSpending = resultSet.getDouble(resultSet.getColumnIndex('actual_spending'));
    feedback.accuracyScore = resultSet.getDouble(resultSet.getColumnIndex('accuracy_score'));
    feedback.userComment = resultSet.getString(resultSet.getColumnIndex('user_comment'));
    feedback.createdAt = resultSet.getString(resultSet.getColumnIndex('created_at'));
    feedback.updatedAt = resultSet.getString(resultSet.getColumnIndex('updated_at'));
    return feedback;
  }
}
