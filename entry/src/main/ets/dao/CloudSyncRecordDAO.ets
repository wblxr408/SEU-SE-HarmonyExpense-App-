/**
 * 云端同步记录数据访问对象（DAO）
 * 提供对 cloud_sync_records 表的CRUD操作
 */
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { CloudSyncRecord, CloudSyncRecordJSON } from '../model/CloudSyncRecord';
import { DAOHelper } from '../common/DAOHelper';

/**
 * 同步统计结果
 */
export class SyncStatisticsResult {
  total: number = 0;
  completed: number = 0;
  failed: number = 0;
  lastSyncTime?: string;

  constructor(total: number, completed: number, failed: number, lastSyncTime?: string) {
    this.total = total;
    this.completed = completed;
    this.failed = failed;
    this.lastSyncTime = lastSyncTime;
  }
}

export class CloudSyncRecordDAO {

  /**
   * 将 ResultSet 的一行数据映射为 CloudSyncRecord 对象
   */
  private static mapRowToCloudSyncRecord(resultSet: relationalStore.ResultSet): CloudSyncRecord {
    try {
      // 解析 dataTypes JSON 数组
      const dataTypesStr: string = DAOHelper.getString(resultSet, 'data_types', '[]');
      let dataTypes: string[] = [];
      try {
        const parsed: Object = JSON.parse(dataTypesStr);
        if (Array.isArray(parsed)) {
          dataTypes = parsed as string[];
        }
      } catch (e) {
        console.warn('[CloudSyncRecordDAO] 解析 dataTypes 失败:', e);
      }

      const row: CloudSyncRecordJSON = {
        syncId: DAOHelper.getLong(resultSet, 'sync_id'),
        userId: DAOHelper.getLong(resultSet, 'user_id'),
        syncType: DAOHelper.getString(resultSet, 'sync_type') as 'full' | 'incremental',
        syncDirection: DAOHelper.getString(resultSet, 'sync_direction') as 'upload' | 'download' | 'bidirectional',
        status: DAOHelper.getString(resultSet, 'status') as 'pending' | 'in_progress' | 'completed' | 'failed',
        dataTypes: dataTypes,
        recordCount: DAOHelper.getLong(resultSet, 'record_count'),
        startTime: DAOHelper.getString(resultSet, 'start_time'),
        endTime: DAOHelper.getString(resultSet, 'end_time'),
        cloudProvider: DAOHelper.getString(resultSet, 'cloud_provider') as 'huawei' | 'custom',
        createdAt: DAOHelper.getString(resultSet, 'created_at'),
        updatedAt: DAOHelper.getString(resultSet, 'updated_at')
      };

      // 可选字段
      const errorMsgIndex: number = resultSet.getColumnIndex('error_message');
      if (errorMsgIndex >= 0 && !resultSet.isColumnNull(errorMsgIndex)) {
        row.errorMessage = resultSet.getString(errorMsgIndex);
      }

      const lastSyncHashIndex: number = resultSet.getColumnIndex('last_sync_hash');
      if (lastSyncHashIndex >= 0 && !resultSet.isColumnNull(lastSyncHashIndex)) {
        row.lastSyncHash = resultSet.getString(lastSyncHashIndex);
      }

      return CloudSyncRecord.fromJSON(row);
    } catch (error) {
      throw DAOHelper.toError('[CloudSyncRecordDAO] 映射数据失败', error as Error);
    }
  }

  /**
   * 插入同步记录
   */
  static async insert(record: CloudSyncRecord): Promise<number> {
    if (!record.validate()) {
      throw new Error('[CloudSyncRecordDAO] 插入失败，数据验证不通过');
    }

    const now: string = DAOHelper.now();
    record.createdAt = now;
    record.updatedAt = now;

    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const valueBucket: relationalStore.ValuesBucket = {
      user_id: record.userId,
      sync_type: record.syncType,
      sync_direction: record.syncDirection,
      status: record.status,
      data_types: JSON.stringify(record.dataTypes),
      record_count: record.recordCount,
      start_time: record.startTime,
      end_time: record.endTime,
      cloud_provider: record.cloudProvider,
      created_at: record.createdAt,
      updated_at: record.updatedAt
    };

    // 可选字段
    if (record.errorMessage) {
      valueBucket.error_message = record.errorMessage;
    }
    if (record.lastSyncHash) {
      valueBucket.last_sync_hash = record.lastSyncHash;
    }

    try {
      const rowId: number = await store.insert(CloudSyncRecord.tableName, valueBucket) as number;
      console.log(`[CloudSyncRecordDAO] 插入成功 id=${rowId}`);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[CloudSyncRecordDAO] 插入失败', error as Error);
    }
  }

  /**
   * 根据ID查询同步记录
   */
  static async getById(userId: number, syncId: number): Promise<CloudSyncRecord | null> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const sql: string = `SELECT * FROM ${CloudSyncRecord.tableName} WHERE user_id = ? AND sync_id = ?`;
    let rs: relationalStore.ResultSet | null = null;

    try {
      rs = await store.querySql(sql, [userId, syncId]);
      if (!rs.goToNextRow()) {
        return null;
      }
      return CloudSyncRecordDAO.mapRowToCloudSyncRecord(rs);
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 查询用户的所有同步记录
   */
  static async getByUserId(userId: number, limit: number | undefined = undefined): Promise<CloudSyncRecord[]> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    let sql: string = `SELECT * FROM ${CloudSyncRecord.tableName} WHERE user_id = ? ORDER BY created_at DESC`;
    if (limit !== undefined && limit > 0) {
      sql += ` LIMIT ${limit}`;
    }
    let rs: relationalStore.ResultSet | null = null;
    const list: CloudSyncRecord[] = [];

    try {
      rs = await store.querySql(sql, [userId]);
      while (rs.goToNextRow()) {
        list.push(CloudSyncRecordDAO.mapRowToCloudSyncRecord(rs));
      }
      return list;
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 查询最近一次成功的同步记录
   */
  static async getLastSuccessfulSync(userId: number): Promise<CloudSyncRecord | null> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const sql: string = `SELECT * FROM ${CloudSyncRecord.tableName} 
                 WHERE user_id = ? AND status = 'completed' 
                 ORDER BY end_time DESC LIMIT 1`;
    let rs: relationalStore.ResultSet | null = null;

    try {
      rs = await store.querySql(sql, [userId]);
      if (!rs.goToNextRow()) {
        return null;
      }
      return CloudSyncRecordDAO.mapRowToCloudSyncRecord(rs);
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 按状态查询同步记录
   */
  static async getByStatus(
    userId: number,
    status: 'pending' | 'in_progress' | 'completed' | 'failed'
  ): Promise<CloudSyncRecord[]> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const sql: string = `SELECT * FROM ${CloudSyncRecord.tableName} 
                 WHERE user_id = ? AND status = ? 
                 ORDER BY created_at DESC`;
    let rs: relationalStore.ResultSet | null = null;
    const list: CloudSyncRecord[] = [];

    try {
      rs = await store.querySql(sql, [userId, status]);
      while (rs.goToNextRow()) {
        list.push(CloudSyncRecordDAO.mapRowToCloudSyncRecord(rs));
      }
      return list;
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 查询进行中的同步任务
   */
  static async getInProgressSync(userId: number): Promise<CloudSyncRecord | null> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const sql: string = `SELECT * FROM ${CloudSyncRecord.tableName} 
                 WHERE user_id = ? AND status = 'in_progress' 
                 ORDER BY start_time DESC LIMIT 1`;
    let rs: relationalStore.ResultSet | null = null;

    try {
      rs = await store.querySql(sql, [userId]);
      if (!rs.goToNextRow()) {
        return null;
      }
      return CloudSyncRecordDAO.mapRowToCloudSyncRecord(rs);
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 更新同步记录
   */
  static async update(record: CloudSyncRecord): Promise<void> {
    if (!record.validate()) {
      throw new Error('[CloudSyncRecordDAO] 更新失败，数据验证不通过');
    }

    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    record.updatedAt = DAOHelper.now();

    const valueBucket: relationalStore.ValuesBucket = {
      sync_type: record.syncType,
      sync_direction: record.syncDirection,
      status: record.status,
      data_types: JSON.stringify(record.dataTypes),
      record_count: record.recordCount,
      start_time: record.startTime,
      end_time: record.endTime,
      cloud_provider: record.cloudProvider,
      updated_at: record.updatedAt
    };

    // 可选字段
    if (record.errorMessage) {
      valueBucket.error_message = record.errorMessage;
    }
    if (record.lastSyncHash) {
      valueBucket.last_sync_hash = record.lastSyncHash;
    }

    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(CloudSyncRecord.tableName);
    predicates.equalTo('sync_id', record.syncId);

    try {
      await store.update(valueBucket, predicates);
      console.log(`[CloudSyncRecordDAO] 更新成功 id=${record.syncId}`);
    } catch (error) {
      throw DAOHelper.toError('[CloudSyncRecordDAO] 更新失败', error as Error);
    }
  }

  /**
   * 更新同步状态
   */
  static async updateStatus(
    syncId: number,
    status: 'pending' | 'in_progress' | 'completed' | 'failed',
    errorMessage?: string
  ): Promise<void> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const now: string = DAOHelper.now();

    let sql: string = `UPDATE ${CloudSyncRecord.tableName} SET status = ?, updated_at = ?`;
    const params: (string | number)[] = [status, now];

    if (status === 'completed' || status === 'failed') {
      sql += `, end_time = ?`;
      params.push(now);
    }

    if (errorMessage) {
      sql += `, error_message = ?`;
      params.push(errorMessage);
    }

    sql += ` WHERE sync_id = ?`;
    params.push(syncId);

    try {
      await store.executeSql(sql, params);
      console.log(`[CloudSyncRecordDAO] 更新状态成功 id=${syncId}, status=${status}`);
    } catch (error) {
      throw DAOHelper.toError('[CloudSyncRecordDAO] 更新状态失败', error as Error);
    }
  }

  /**
   * 删除旧的同步记录（保留最近N条）
   */
  static async deleteOldRecords(userId: number, keepCount: number = 50): Promise<void> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const sql: string = `DELETE FROM ${CloudSyncRecord.tableName} 
                 WHERE user_id = ? AND sync_id NOT IN (
                   SELECT sync_id FROM ${CloudSyncRecord.tableName} 
                   WHERE user_id = ? 
                   ORDER BY created_at DESC 
                   LIMIT ?
                 )`;

    try {
      await store.executeSql(sql, [userId, userId, keepCount]);
      console.log(`[CloudSyncRecordDAO] 清理旧记录成功，保留最近${keepCount}条`);
    } catch (error) {
      throw DAOHelper.toError('[CloudSyncRecordDAO] 清理旧记录失败', error as Error);
    }
  }

  /**
   * 统计同步记录
   */
  static async getStatistics(userId: number): Promise<SyncStatisticsResult> {
    const store: relationalStore.RdbStore = DatabaseManager.getDatabase();
    const sql: string = `SELECT 
                   COUNT(*) as total,
                   SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
                   SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
                   MAX(CASE WHEN status = 'completed' THEN end_time END) as last_sync_time
                 FROM ${CloudSyncRecord.tableName} 
                 WHERE user_id = ?`;
    let rs: relationalStore.ResultSet | null = null;

    try {
      rs = await store.querySql(sql, [userId]);
      if (!rs.goToNextRow()) {
        return new SyncStatisticsResult(0, 0, 0);
      }

      const total: number = DAOHelper.getLong(rs, 'total');
      const completed: number = DAOHelper.getLong(rs, 'completed');
      const failed: number = DAOHelper.getLong(rs, 'failed');
      const lastSyncTime: string = DAOHelper.getString(rs, 'last_sync_time');

      if (lastSyncTime) {
        return new SyncStatisticsResult(total, completed, failed, lastSyncTime);
      }

      return new SyncStatisticsResult(total, completed, failed);
    } finally {
      DAOHelper.closeResultSet(rs);
    }
  }

  /**
   * 批量插入同步记录
   */
  static async insertMany(records: CloudSyncRecord[]): Promise<void> {
    await DAOHelper.transaction(async () => {
      for (const record of records) {
        await CloudSyncRecordDAO.insert(record);
      }
    }, '[CloudSyncRecordDAO] 批量插入');
  }
}
