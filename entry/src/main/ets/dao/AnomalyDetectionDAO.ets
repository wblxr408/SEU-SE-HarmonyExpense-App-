/**
 * 异常检测数据访问对象 (DAO)
 *
 * 功能：
 * - 异常记录的CRUD操作
 * - 用户消费基线的管理
 * - 异常统计和查询
 *
 * @version 1.0.0
 * @author HarmonyExpense Team
 */

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { DAOHelper } from '../common/DAOHelper';
import {
  AnomalyRecord,
  UserSpendingBaseline,
  AnomalyDetectionUtils,
  ANOMALY_TYPE_HIGH_AMOUNT,
  ANOMALY_TYPE_LOW_AMOUNT,
  SEVERITY_HIGH,
  SEVERITY_CRITICAL
} from '../model/AnomalyDetection';
import { Bill } from '../model/Bill';

/**
 * 异常统计接口
 */
export interface AnomalyStatistics {
  totalCount: number;
  unacknowledgedCount: number;
  bySeverity: Map<string, number>;
  byType: Map<string, number>;
  recentAnomalies: AnomalyRecord[];
}

/**
 * 异常记录DAO
 */
export class AnomalyRecordDAO {
  /**
   * 插入异常记录
   */
  static async insert(record: AnomalyRecord): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      record.createdAt = now;
      record.updatedAt = now;

      const values: relationalStore.ValuesBucket = {
        user_id: record.userId,
        bill_id: record.billId,
        anomaly_type: record.anomalyType,
        severity: record.severity,
        algorithm: record.algorithm,
        score: record.score,
        threshold: record.threshold,
        expected_value: record.expectedValue,
        actual_value: record.actualValue,
        deviation: record.deviation,
        description: record.description,
        is_acknowledged: record.isAcknowledged,
        acknowledged_at: record.acknowledgedAt || null,
        created_at: record.createdAt,
        updated_at: record.updatedAt,
        is_deleted: record.isDeleted
      };

      const rowId = await store.insert(AnomalyRecord.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[AnomalyRecordDAO] 插入异常记录失败', error);
    }
  }

  /**
   * 批量插入异常记录
   */
  static async batchInsert(records: AnomalyRecord[]): Promise<number[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      const ids: number[] = [];

      await store.beginTransaction();
      try {
        for (let i = 0; i < records.length; i++) {
          const record = records[i];
          record.createdAt = now;
          record.updatedAt = now;

          const values: relationalStore.ValuesBucket = {
            user_id: record.userId,
            bill_id: record.billId,
            anomaly_type: record.anomalyType,
            severity: record.severity,
            algorithm: record.algorithm,
            score: record.score,
            threshold: record.threshold,
            expected_value: record.expectedValue,
            actual_value: record.actualValue,
            deviation: record.deviation,
            description: record.description,
            is_acknowledged: record.isAcknowledged,
            acknowledged_at: record.acknowledgedAt || null,
            created_at: record.createdAt,
            updated_at: record.updatedAt,
            is_deleted: record.isDeleted
          };

          const rowId = await store.insert(AnomalyRecord.tableName, values);
          ids.push(rowId);
        }
        await store.commit();
        return ids;
      } catch (error) {
        await store.rollBack();
        throw DAOHelper.toError('[AnomalyRecordDAO] 批量插入异常记录失败', error);
      }
    } catch (error) {
      throw DAOHelper.toError('[AnomalyRecordDAO] 批量插入异常记录失败', error);
    }
  }

  /**
   * 根据ID获取异常记录
   */
  static async getById(anomalyId: number): Promise<AnomalyRecord | null> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(AnomalyRecord.tableName);
      predicates.equalTo('anomaly_id', anomalyId);
      predicates.equalTo('is_deleted', 0);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        return AnomalyRecordDAO.mapRowToAnomalyRecord(resultSet);
      }
      return null;
    } catch (error) {
      throw DAOHelper.toError('[AnomalyRecordDAO] 根据ID获取异常记录失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取用户的所有异常记录
   */
  static async getByUserId(userId: number): Promise<AnomalyRecord[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(AnomalyRecord.tableName);
      predicates.equalTo('user_id', userId);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('created_at');

      resultSet = await store.query(predicates);

      const records: AnomalyRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(AnomalyRecordDAO.mapRowToAnomalyRecord(resultSet));
      }
      return records;
    } catch (error) {
      throw DAOHelper.toError('[AnomalyRecordDAO] 获取用户异常记录失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取未确认的异常记录
   */
  static async getUnacknowledged(userId: number): Promise<AnomalyRecord[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(AnomalyRecord.tableName);
      predicates.equalTo('user_id', userId);
      predicates.equalTo('is_acknowledged', 0);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('severity');
      predicates.orderByDesc('created_at');

      resultSet = await store.query(predicates);

      const records: AnomalyRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(AnomalyRecordDAO.mapRowToAnomalyRecord(resultSet));
      }
      return records;
    } catch (error) {
      throw DAOHelper.toError('[AnomalyRecordDAO] 获取未确认异常记录失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 根据严重程度获取异常记录
   */
  static async getBySeverity(userId: number, severity: string): Promise<AnomalyRecord[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(AnomalyRecord.tableName);
      predicates.equalTo('user_id', userId);
      predicates.equalTo('severity', severity);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('created_at');

      resultSet = await store.query(predicates);

      const records: AnomalyRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(AnomalyRecordDAO.mapRowToAnomalyRecord(resultSet));
      }
      return records;
    } catch (error) {
      throw DAOHelper.toError('[AnomalyRecordDAO] 根据严重程度获取异常记录失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 确认异常记录
   */
  static async acknowledge(anomalyId: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        is_acknowledged: 1,
        acknowledged_at: now,
        updated_at: now
      };

      const predicates = new relationalStore.RdbPredicates(AnomalyRecord.tableName);
      predicates.equalTo('anomaly_id', anomalyId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[AnomalyRecordDAO] 确认异常记录失败', error);
    }
  }

  /**
   * 批量确认异常记录
   */
  static async batchAcknowledge(anomalyIds: number[]): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        is_acknowledged: 1,
        acknowledged_at: now,
        updated_at: now
      };

      const predicates = new relationalStore.RdbPredicates(AnomalyRecord.tableName);
      predicates.in('anomaly_id', anomalyIds);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected;
    } catch (error) {
      throw DAOHelper.toError('[AnomalyRecordDAO] 批量确认异常记录失败', error);
    }
  }

  /**
   * 获取异常统计
   */
  static async getStatistics(userId: number): Promise<AnomalyStatistics> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();

      // 获取总数和未确认数
      const countSql = `
        SELECT
          COUNT(*) as total_count,
          SUM(CASE WHEN is_acknowledged = 0 THEN 1 ELSE 0 END) as unacknowledged_count
        FROM ${AnomalyRecord.tableName}
        WHERE user_id = ? AND is_deleted = 0
      `;
      resultSet = await store.querySql(countSql, [userId.toString()]);

      let totalCount = 0;
      let unacknowledgedCount = 0;
      if (resultSet.goToFirstRow()) {
        totalCount = DAOHelper.getLong(resultSet, 'total_count');
        unacknowledgedCount = DAOHelper.getLong(resultSet, 'unacknowledged_count');
      }
      DAOHelper.closeResultSet(resultSet);
      resultSet = null;

      // 按严重程度统计
      const bySeverity = new Map<string, number>();
      const severitySql = `
        SELECT severity, COUNT(*) as count
        FROM ${AnomalyRecord.tableName}
        WHERE user_id = ? AND is_deleted = 0
        GROUP BY severity
      `;
      resultSet = await store.querySql(severitySql, [userId.toString()]);
      while (resultSet.goToNextRow()) {
        const severity = DAOHelper.getString(resultSet, 'severity');
        const count = DAOHelper.getLong(resultSet, 'count');
        bySeverity.set(severity, count);
      }
      DAOHelper.closeResultSet(resultSet);
      resultSet = null;

      // 按类型统计
      const byType = new Map<string, number>();
      const typeSql = `
        SELECT anomaly_type, COUNT(*) as count
        FROM ${AnomalyRecord.tableName}
        WHERE user_id = ? AND is_deleted = 0
        GROUP BY anomaly_type
      `;
      resultSet = await store.querySql(typeSql, [userId.toString()]);
      while (resultSet.goToNextRow()) {
        const type = DAOHelper.getString(resultSet, 'anomaly_type');
        const count = DAOHelper.getLong(resultSet, 'count');
        byType.set(type, count);
      }
      DAOHelper.closeResultSet(resultSet);
      resultSet = null;

      // 获取最近的异常记录
      const recentAnomalies = await AnomalyRecordDAO.getUnacknowledged(userId);
      const topRecent = recentAnomalies.slice(0, 10);

      const statistics: AnomalyStatistics = {
        totalCount: totalCount,
        unacknowledgedCount: unacknowledgedCount,
        bySeverity: bySeverity,
        byType: byType,
        recentAnomalies: topRecent
      };

      return statistics;
    } catch (error) {
      throw DAOHelper.toError('[AnomalyRecordDAO] 获取异常统计失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 软删除异常记录
   */
  static async softDelete(anomalyId: number): Promise<void> {
    try {
      await DAOHelper.softDelete(AnomalyRecord.tableName, 'anomaly_id', anomalyId);
    } catch (error) {
      throw DAOHelper.toError('[AnomalyRecordDAO] 软删除异常记录失败', error);
    }
  }

  /**
   * 映射数据库行到 AnomalyRecord 对象
   */
  private static mapRowToAnomalyRecord(resultSet: relationalStore.ResultSet): AnomalyRecord {
    return new AnomalyRecord(
      DAOHelper.getLong(resultSet, 'anomaly_id'),
      DAOHelper.getLong(resultSet, 'user_id'),
      DAOHelper.getLong(resultSet, 'bill_id'),
      DAOHelper.getString(resultSet, 'anomaly_type'),
      DAOHelper.getString(resultSet, 'severity'),
      DAOHelper.getString(resultSet, 'algorithm'),
      DAOHelper.getDouble(resultSet, 'score'),
      DAOHelper.getDouble(resultSet, 'threshold'),
      DAOHelper.getDouble(resultSet, 'expected_value'),
      DAOHelper.getDouble(resultSet, 'actual_value'),
      DAOHelper.getDouble(resultSet, 'deviation'),
      DAOHelper.getString(resultSet, 'description'),
      DAOHelper.getLong(resultSet, 'is_acknowledged'),
      DAOHelper.getString(resultSet, 'acknowledged_at'),
      DAOHelper.getString(resultSet, 'created_at'),
      DAOHelper.getString(resultSet, 'updated_at'),
      DAOHelper.getLong(resultSet, 'is_deleted')
    );
  }
}

/**
 * 用户消费基线DAO
 */
export class UserSpendingBaselineDAO {
  /**
   * 插入或更新基线数据
   */
  static async upsert(baseline: UserSpendingBaseline): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();

      // 检查是否已存在
      const existing = await UserSpendingBaselineDAO.get(baseline.userId, baseline.categoryId, baseline.period);

      const values: relationalStore.ValuesBucket = {
        user_id: baseline.userId,
        category_id: baseline.categoryId,
        period: baseline.period,
        mean: baseline.mean,
        median: baseline.median,
        std_dev: baseline.stdDev,
        variance: baseline.variance,
        min: baseline.min,
        max: baseline.max,
        q1: baseline.q1,
        q3: baseline.q3,
        iqr: baseline.iqr,
        sample_size: baseline.sampleSize,
        last_calculated_at: baseline.lastCalculatedAt || now,
        sample_start_date: baseline.sampleStartDate,
        sample_end_date: baseline.sampleEndDate,
        updated_at: now
      };

      if (existing) {
        // 更新现有记录
        const predicates = new relationalStore.RdbPredicates(UserSpendingBaseline.tableName);
        predicates.equalTo('baseline_id', existing.baselineId);
        await store.update(values, predicates);
        return existing.baselineId;
      } else {
        // 插入新记录
        values['created_at'] = now;
        values['is_deleted'] = 0;
        const rowId = await store.insert(UserSpendingBaseline.tableName, values);
        return rowId;
      }
    } catch (error) {
      throw DAOHelper.toError('[UserSpendingBaselineDAO] 插入或更新基线失败', error);
    }
  }

  /**
   * 获取基线数据
   */
  static async get(userId: number, categoryId: number, period: string): Promise<UserSpendingBaseline | null> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(UserSpendingBaseline.tableName);
      predicates.equalTo('user_id', userId);
      predicates.equalTo('category_id', categoryId);
      predicates.equalTo('period', period);
      predicates.equalTo('is_deleted', 0);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        return UserSpendingBaselineDAO.mapRowToBaseline(resultSet);
      }
      return null;
    } catch (error) {
      throw DAOHelper.toError('[UserSpendingBaselineDAO] 获取基线失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取用户所有基线数据
   */
  static async getAllByUser(userId: number): Promise<UserSpendingBaseline[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(UserSpendingBaseline.tableName);
      predicates.equalTo('user_id', userId);
      predicates.equalTo('is_deleted', 0);
      predicates.orderByDesc('last_calculated_at');

      resultSet = await store.query(predicates);

      const baselines: UserSpendingBaseline[] = [];
      while (resultSet.goToNextRow()) {
        baselines.push(UserSpendingBaselineDAO.mapRowToBaseline(resultSet));
      }
      return baselines;
    } catch (error) {
      throw DAOHelper.toError('[UserSpendingBaselineDAO] 获取用户所有基线失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取用户的主基线（全类别、月度）
   */
  static async getByUserId(userId: number): Promise<UserSpendingBaseline | null> {
    return await UserSpendingBaselineDAO.get(userId, 0, 'monthly');
  }

  /**
   * 删除基线数据
   */
  static async delete(baselineId: number): Promise<void> {
    try {
      await DAOHelper.softDelete(UserSpendingBaseline.tableName, 'baseline_id', baselineId);
    } catch (error) {
      throw DAOHelper.toError('[UserSpendingBaselineDAO] 删除基线失败', error);
    }
  }

  /**
   * 映射数据库行到 UserSpendingBaseline 对象
   */
  private static mapRowToBaseline(resultSet: relationalStore.ResultSet): UserSpendingBaseline {
    return new UserSpendingBaseline(
      DAOHelper.getLong(resultSet, 'baseline_id'),
      DAOHelper.getLong(resultSet, 'user_id'),
      DAOHelper.getLong(resultSet, 'category_id'),
      DAOHelper.getString(resultSet, 'period'),
      DAOHelper.getDouble(resultSet, 'mean'),
      DAOHelper.getDouble(resultSet, 'median'),
      DAOHelper.getDouble(resultSet, 'std_dev'),
      DAOHelper.getDouble(resultSet, 'variance'),
      DAOHelper.getDouble(resultSet, 'min'),
      DAOHelper.getDouble(resultSet, 'max'),
      DAOHelper.getDouble(resultSet, 'q1'),
      DAOHelper.getDouble(resultSet, 'q3'),
      DAOHelper.getDouble(resultSet, 'iqr'),
      DAOHelper.getLong(resultSet, 'sample_size'),
      DAOHelper.getString(resultSet, 'last_calculated_at'),
      DAOHelper.getString(resultSet, 'sample_start_date'),
      DAOHelper.getString(resultSet, 'sample_end_date'),
      DAOHelper.getString(resultSet, 'created_at'),
      DAOHelper.getString(resultSet, 'updated_at'),
      DAOHelper.getLong(resultSet, 'is_deleted')
    );
  }
}
