/**
 * 用户画像数据访问对象
 * 
 * 功能：
 * 1. 用户画像的CRUD操作
 * 2. 自动分析用户行为特征
 * 3. 更新用户画像统计数据
 * 
 * @version 1.0.0
 * @author HarmonyExpense Team
 */

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { UserProfile, INCOME_LOW, INCOME_MEDIUM, INCOME_HIGH, SPENDING_SAVER, SPENDING_BALANCED, SPENDING_SPENDER, EXECUTION_STRICT, EXECUTION_FLEXIBLE, EXECUTION_LOOSE } from '../model/UserProfile';
import hilog from '@ohos.hilog';

const LOG_TAG = 'UserProfileDAO';
const HILOG_DOMAIN = 0x0001;

export class UserProfileDAO {

  /**
   * 插入用户画像
   */
  static async insert(profile: UserProfile): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const valueBucket: relationalStore.ValuesBucket = {/* minimal insertion */};

      const rowId = await store.insert(UserProfile.tableName, valueBucket);
      hilog.info(HILOG_DOMAIN, LOG_TAG, `用户画像插入成功，ID: ${rowId}`);
      return rowId;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `插入用户画像失败: ${error.message}`);
      throw new Error(`插入用户画像失败: ${error.message}`);
    }
  }

  /**
   * 根据用户ID获取画像
   */
  static async getByUserId(userId: number): Promise<UserProfile | null> {
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(UserProfile.tableName);
      predicates.equalTo('user_id', userId);

      const resultSet = await store.query(predicates);
      
      if (resultSet.rowCount === 0) {
        resultSet.close();
        return null;
      }

      resultSet.goToFirstRow();
      const profile = UserProfileDAO.parseResultSet(resultSet);
      resultSet.close();
      
      return profile;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `查询用户画像失败: ${error.message}`);
      return null;
    }
  }

  /**
   * 更新用户画像
   */
  static async update(profile: UserProfile): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const valueBucket: relationalStore.ValuesBucket = {/* minimal update */};

      const predicates = new relationalStore.RdbPredicates(UserProfile.tableName);
      predicates.equalTo('user_id', profile.userId);

      const rows = await store.update(valueBucket, predicates);
      hilog.info(HILOG_DOMAIN, LOG_TAG, `用户画像更新成功，影响行数: ${rows}`);
      return rows > 0;
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `更新用户画像失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 创建或更新用户画像
   */
  static async upsert(profile: UserProfile): Promise<boolean> {
    const existing = await UserProfileDAO.getByUserId(profile.userId);
    
    if (existing) {
      profile.profileId = existing.profileId;
      return await UserProfileDAO.update(profile);
    } else {
      const id = await UserProfileDAO.insert(profile);
      return id > 0;
    }
  }

  /**
   * 自动分析并更新用户画像
   * 基于历史账单和预算数据
   */
  static async analyzeAndUpdate(userId: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      
      // 1. 计算平均月收入和支出（最近6个月）
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
      const startDate = sixMonthsAgo.toISOString().substring(0, 10);
      
      const incomeQuery = `SELECT ...`;
      
      const incomeResult = await store.querySql(incomeQuery, [userId.toString(), startDate]);
      
      let avgIncome = 0;
      let avgExpense = 0;
      
      if (incomeResult.rowCount > 0) {
        // parse
      }
      incomeResult.close();
      
      // 2. 计算预算超支率
      const overrunQuery = `SELECT ...`;
      
      const overrunResult = await store.querySql(overrunQuery, [userId.toString(), startDate]);
      
      let overrunRate = 0;
      if (overrunResult.rowCount > 0) {
        // parse
      }
      overrunResult.close();
      
      // 3. 获取或创建用户画像
      let profile = await UserProfileDAO.getByUserId(userId);
      if (!profile) {
        profile = new UserProfile();
        profile.userId = userId;
        profile.createdAt = new Date().toISOString();
      }
      
      // 4. 更新统计数据
      profile.averageMonthlyIncome = Math.round(avgIncome * 100) / 100;
      profile.averageMonthlyExpense = Math.round(avgExpense * 100) / 100;
      profile.budgetOverrunRate = Math.round(overrunRate * 100) / 100;
      
      // 5. 推断收入水平
      if (avgIncome < 5000) {
        profile.incomeLevel = INCOME_LOW;
      } else if (avgIncome < 15000) {
        profile.incomeLevel = INCOME_MEDIUM;
      } else {
        profile.incomeLevel = INCOME_HIGH;
      }
      
      // 6. 推断消费性格
      if (overrunRate < 0.2) {
        profile.spendingPersonality = SPENDING_SAVER;
      } else if (overrunRate < 0.5) {
        profile.spendingPersonality = SPENDING_BALANCED;
      } else {
        profile.spendingPersonality = SPENDING_SPENDER;
      }
      
      // 7. 推断预算执行模式
      if (overrunRate < 0.1) {
        profile.budgetExecutionPattern = EXECUTION_STRICT;
      } else if (overrunRate < 0.3) {
        profile.budgetExecutionPattern = EXECUTION_FLEXIBLE;
      } else {
        profile.budgetExecutionPattern = EXECUTION_LOOSE;
      }
      
      profile.updatedAt = new Date().toISOString();
      
      // 8. 保存
      return await UserProfileDAO.upsert(profile);
    } catch (err) {
      const error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, `分析用户画像失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 更新建议接受率
   */
  static async updateAdviceAcceptanceRate(userId: number, acceptanceRate: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const valueBucket: relationalStore.ValuesBucket = {/* minimal */};
      const predicates = new relationalStore.RdbPredicates(UserProfile.tableName);
      predicates.equalTo('user_id', userId);
      const rows = await store.update(valueBucket, predicates);
      return rows > 0;
    } catch (err) {
      return false;
    }
  }

  /**
   * 解析查询结果
   */
  private static parseResultSet(resultSet: relationalStore.ResultSet): UserProfile {
    const profile = new UserProfile();
    profile.profileId = resultSet.getLong(resultSet.getColumnIndex('profile_id'));
    profile.userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
    profile.age = resultSet.getLong(resultSet.getColumnIndex('age'));
    profile.incomeLevel = resultSet.getString(resultSet.getColumnIndex('income_level'));
    profile.familySize = resultSet.getLong(resultSet.getColumnIndex('family_size'));
    profile.riskTolerance = resultSet.getString(resultSet.getColumnIndex('risk_tolerance'));
    profile.spendingPersonality = resultSet.getString(resultSet.getColumnIndex('spending_personality'));
    profile.budgetExecutionPattern = resultSet.getString(resultSet.getColumnIndex('budget_execution_pattern'));
    profile.averageMonthlyIncome = resultSet.getDouble(resultSet.getColumnIndex('average_monthly_income'));
    profile.averageMonthlyExpense = resultSet.getDouble(resultSet.getColumnIndex('average_monthly_expense'));
    profile.budgetOverrunRate = resultSet.getDouble(resultSet.getColumnIndex('budget_overrun_rate'));
    profile.adviceAcceptanceRate = resultSet.getDouble(resultSet.getColumnIndex('advice_acceptance_rate'));
    profile.createdAt = resultSet.getString(resultSet.getColumnIndex('created_at'));
    profile.updatedAt = resultSet.getString(resultSet.getColumnIndex('updated_at'));
    return profile;
  }
}
