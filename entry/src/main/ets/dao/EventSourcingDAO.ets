/**
 * 事件溯源数据访问对象 (DAO)
 *
 * 功能：
 * - 领域事件的存储和查询
 * - 命令的执行和管理
 * - 聚合快照的管理
 * - 读模型的维护
 *
 * @version 1.0.0
 * @author HarmonyExpense Team
 */

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { DAOHelper } from '../common/DAOHelper';
import {
  DomainEvent,
  Command,
  AggregateSnapshot,
  ReadModel,
  EventStoreStats,
  EventTypeStats,
  AggregateTypeStats,
  COMMAND_STATUS_PENDING,
  COMMAND_STATUS_PROCESSING
} from '../model/EventSourcing';

/**
 * 命令统计接口
 */
export interface CommandStats {
  totalCommands: number;
  pendingCommands: number;
  processingCommands: number;
  completedCommands: number;
  failedCommands: number;
}

/**
 * 领域事件DAO
 */
export class DomainEventDAO {
  /**
   * 插入领域事件
   */
  static async insert(event: DomainEvent): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      event.createdAt = now;

      const values: relationalStore.ValuesBucket = {
        event_id: event.eventId,
        event_type: event.eventType,
        aggregate_type: event.aggregateType,
        aggregate_id: event.aggregateId,
        user_id: event.userId,
        version: event.version,
        payload_json: event.payloadJson,
        metadata_json: event.metadataJson,
        occurred_at: event.occurredAt,
        created_at: event.createdAt
      };

      await store.insert(DomainEvent.tableName, values);
      return true;
    } catch (error) {
      throw DAOHelper.toError('[DomainEventDAO] 插入领域事件失败', error);
    }
  }

  /**
   * 批量插入事件
   */
  static async batchInsert(events: DomainEvent[]): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();

      await store.beginTransaction();
      try {
        for (let i = 0; i < events.length; i++) {
          const event = events[i];
          event.createdAt = now;

          const values: relationalStore.ValuesBucket = {
            event_id: event.eventId,
            event_type: event.eventType,
            aggregate_type: event.aggregateType,
            aggregate_id: event.aggregateId,
            user_id: event.userId,
            version: event.version,
            payload_json: event.payloadJson,
            metadata_json: event.metadataJson,
            occurred_at: event.occurredAt,
            created_at: event.createdAt
          };

          await store.insert(DomainEvent.tableName, values);
        }
        await store.commit();
        return true;
      } catch (error) {
        await store.rollBack();
        throw DAOHelper.toError('[DomainEventDAO] 批量插入事件失败', error);
      }
    } catch (error) {
      throw DAOHelper.toError('[DomainEventDAO] 批量插入事件失败', error);
    }
  }

  /**
   * 获取聚合的所有事件
   */
  static async getByAggregate(
    aggregateType: string,
    aggregateId: number,
    fromVersion: number = 0
  ): Promise<DomainEvent[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(DomainEvent.tableName);
      predicates.equalTo('aggregate_type', aggregateType);
      predicates.equalTo('aggregate_id', aggregateId);
      if (fromVersion > 0) {
        predicates.greaterThan('version', fromVersion);
      }
      predicates.orderByAsc('version');

      resultSet = await store.query(predicates);

      const events: DomainEvent[] = [];
      while (resultSet.goToNextRow()) {
        events.push(DomainEventDAO.mapRowToEvent(resultSet));
      }
      return events;
    } catch (error) {
      throw DAOHelper.toError('[DomainEventDAO] 获取聚合事件失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取用户的所有事件
   */
  static async getByUser(userId: number, limit: number = 100): Promise<DomainEvent[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(DomainEvent.tableName);
      predicates.equalTo('user_id', userId);
      predicates.orderByDesc('occurred_at');

      resultSet = await store.query(predicates);

      const events: DomainEvent[] = [];
      let count = 0;
      while (resultSet.goToNextRow() && count < limit) {
        events.push(DomainEventDAO.mapRowToEvent(resultSet));
        count++;
      }
      return events;
    } catch (error) {
      throw DAOHelper.toError('[DomainEventDAO] 获取用户事件失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 根据事件类型查询
   */
  static async getByEventType(eventType: string, limit: number = 100): Promise<DomainEvent[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(DomainEvent.tableName);
      predicates.equalTo('event_type', eventType);
      predicates.orderByDesc('occurred_at');

      resultSet = await store.query(predicates);

      const events: DomainEvent[] = [];
      let count = 0;
      while (resultSet.goToNextRow() && count < limit) {
        events.push(DomainEventDAO.mapRowToEvent(resultSet));
        count++;
      }
      return events;
    } catch (error) {
      throw DAOHelper.toError('[DomainEventDAO] 根据事件类型查询失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 根据时间范围查询事件
   */
  static async getByDateRange(startDate: string, endDate: string): Promise<DomainEvent[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(DomainEvent.tableName);
      predicates.greaterThanOrEqualTo('occurred_at', startDate);
      predicates.lessThanOrEqualTo('occurred_at', endDate);
      predicates.orderByDesc('occurred_at');

      resultSet = await store.query(predicates);

      const events: DomainEvent[] = [];
      while (resultSet.goToNextRow()) {
        events.push(DomainEventDAO.mapRowToEvent(resultSet));
      }
      return events;
    } catch (error) {
      throw DAOHelper.toError('[DomainEventDAO] 根据时间范围查询事件失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取事件存储统计
   */
  static async getStatistics(): Promise<EventStoreStats> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();

      // 获取总数
      const countSql = `SELECT COUNT(*) as total FROM ${DomainEvent.tableName}`;
      resultSet = await store.querySql(countSql, []);
      let totalEvents = 0;
      if (resultSet.goToFirstRow()) {
        totalEvents = DAOHelper.getLong(resultSet, 'total');
      }
      DAOHelper.closeResultSet(resultSet);
      resultSet = null;

      // 按类型统计
      const eventsByType: EventTypeStats[] = [];
      const typeSql = `
        SELECT event_type, COUNT(*) as count
        FROM ${DomainEvent.tableName}
        GROUP BY event_type
      `;
      resultSet = await store.querySql(typeSql, []);
      while (resultSet.goToNextRow()) {
        eventsByType.push({
          eventType: DAOHelper.getString(resultSet, 'event_type'),
          count: DAOHelper.getLong(resultSet, 'count')
        });
      }
      DAOHelper.closeResultSet(resultSet);
      resultSet = null;

      // 按聚合统计
      const eventsByAggregate: AggregateTypeStats[] = [];
      const aggSql = `
        SELECT aggregate_type, COUNT(*) as count
        FROM ${DomainEvent.tableName}
        GROUP BY aggregate_type
      `;
      resultSet = await store.querySql(aggSql, []);
      while (resultSet.goToNextRow()) {
        eventsByAggregate.push({
          aggregateType: DAOHelper.getString(resultSet, 'aggregate_type'),
          count: DAOHelper.getLong(resultSet, 'count')
        });
      }
      DAOHelper.closeResultSet(resultSet);
      resultSet = null;

      // 时间统计
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
      const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
      const monthAgo = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

      const todaySql = `SELECT COUNT(*) as count FROM ${DomainEvent.tableName} WHERE occurred_at >= ?`;
      resultSet = await store.querySql(todaySql, [today]);
      let eventsToday = 0;
      if (resultSet.goToFirstRow()) {
        eventsToday = DAOHelper.getLong(resultSet, 'count');
      }
      DAOHelper.closeResultSet(resultSet);
      resultSet = null;

      resultSet = await store.querySql(todaySql, [weekAgo]);
      let eventsThisWeek = 0;
      if (resultSet.goToFirstRow()) {
        eventsThisWeek = DAOHelper.getLong(resultSet, 'count');
      }
      DAOHelper.closeResultSet(resultSet);
      resultSet = null;

      resultSet = await store.querySql(todaySql, [monthAgo]);
      let eventsThisMonth = 0;
      if (resultSet.goToFirstRow()) {
        eventsThisMonth = DAOHelper.getLong(resultSet, 'count');
      }
      DAOHelper.closeResultSet(resultSet);
      resultSet = null;

      // 日期范围
      const dateSql = `
        SELECT MIN(occurred_at) as oldest, MAX(occurred_at) as newest
        FROM ${DomainEvent.tableName}
      `;
      resultSet = await store.querySql(dateSql, []);
      let oldestEventDate = '';
      let newestEventDate = '';
      if (resultSet.goToFirstRow()) {
        oldestEventDate = DAOHelper.getString(resultSet, 'oldest');
        newestEventDate = DAOHelper.getString(resultSet, 'newest');
      }
      DAOHelper.closeResultSet(resultSet);
      resultSet = null;

      const stats: EventStoreStats = {
        totalEvents: totalEvents,
        eventsByType: eventsByType,
        eventsByAggregate: eventsByAggregate,
        eventsToday: eventsToday,
        eventsThisWeek: eventsThisWeek,
        eventsThisMonth: eventsThisMonth,
        averageEventsPerDay: 0,
        oldestEventDate: oldestEventDate,
        newestEventDate: newestEventDate
      };

      return stats;
    } catch (error) {
      throw DAOHelper.toError('[DomainEventDAO] 获取事件统计失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 映射数据库行到领域事件对象
   */
  private static mapRowToEvent(resultSet: relationalStore.ResultSet): DomainEvent {
    return new DomainEvent(
      DAOHelper.getString(resultSet, 'event_id'),
      DAOHelper.getString(resultSet, 'event_type'),
      DAOHelper.getString(resultSet, 'aggregate_type'),
      DAOHelper.getLong(resultSet, 'aggregate_id'),
      DAOHelper.getLong(resultSet, 'user_id'),
      DAOHelper.getLong(resultSet, 'version'),
      DAOHelper.getString(resultSet, 'payload_json'),
      DAOHelper.getString(resultSet, 'metadata_json'),
      DAOHelper.getString(resultSet, 'occurred_at'),
      DAOHelper.getString(resultSet, 'created_at')
    );
  }

  /**
   * 按用户ID查询事件
   */
  static async getByUserId(userId: number, limit: number = 100): Promise<DomainEvent[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(DomainEvent.tableName);
      predicates.equalTo('user_id', userId);
      predicates.orderByDesc('created_at');
      predicates.limitAs(limit);

      resultSet = await store.query(predicates);

      const events: DomainEvent[] = [];
      while (resultSet.goToNextRow()) {
        events.push(DomainEventDAO.mapRowToEvent(resultSet));
      }
      return events;
    } catch (error) {
      throw DAOHelper.toError('[DomainEventDAO] 按用户ID查询事件失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 按聚合类型查询事件
   */
  static async getByAggregateType(aggregateType: string, limit: number = 1000): Promise<DomainEvent[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(DomainEvent.tableName);
      predicates.equalTo('aggregate_type', aggregateType);
      predicates.orderByDesc('created_at');
      predicates.limitAs(limit);

      resultSet = await store.query(predicates);

      const events: DomainEvent[] = [];
      while (resultSet.goToNextRow()) {
        events.push(DomainEventDAO.mapRowToEvent(resultSet));
      }
      return events;
    } catch (error) {
      throw DAOHelper.toError('[DomainEventDAO] 按聚合类型查询事件失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }
}

/**
 * 命令DAO
 */
export class CommandDAO {
  /**
   * 插入命令
   */
  static async insert(command: Command): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      command.issuedAt = now;

      const values: relationalStore.ValuesBucket = {
        command_id: command.commandId,
        command_type: command.commandType,
        aggregate_type: command.aggregateType,
        aggregate_id: command.aggregateId,
        user_id: command.userId,
        payload_json: command.payloadJson,
        status: command.status,
        metadata_json: command.metadataJson,
        expected_version: command.expectedVersion,
        issued_at: command.issuedAt,
        processed_at: command.processedAt || null,
        error_message: command.errorMessage || null
      };

      await store.insert(Command.tableName, values);
      return true;
    } catch (error) {
      throw DAOHelper.toError('[CommandDAO] 插入命令失败', error);
    }
  }

  /**
   * 更新命令状态
   */
  static async updateStatus(commandId: string, status: string, errorMessage?: string): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        status: status,
        processed_at: now
      };

      if (errorMessage) {
        values['error_message'] = errorMessage;
      }

      const predicates = new relationalStore.RdbPredicates(Command.tableName);
      predicates.equalTo('command_id', commandId);

      const rowsAffected = await store.update(values, predicates);
      return rowsAffected > 0;
    } catch (error) {
      throw DAOHelper.toError('[CommandDAO] 更新命令状态失败', error);
    }
  }

  /**
   * 获取待处理命令
   */
  static async getPendingCommands(limit: number = 100): Promise<Command[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(Command.tableName);
      predicates.in('status', [COMMAND_STATUS_PENDING, COMMAND_STATUS_PROCESSING]);
      predicates.orderByAsc('issued_at');

      resultSet = await store.query(predicates);

      const commands: Command[] = [];
      let count = 0;
      while (resultSet.goToNextRow() && count < limit) {
        commands.push(CommandDAO.mapRowToCommand(resultSet));
        count++;
      }
      return commands;
    } catch (error) {
      throw DAOHelper.toError('[CommandDAO] 获取待处理命令失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 根据用户获取命令
   */
  static async getByUser(userId: number, limit: number = 100): Promise<Command[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(Command.tableName);
      predicates.equalTo('user_id', userId);
      predicates.orderByDesc('issued_at');

      resultSet = await store.query(predicates);

      const commands: Command[] = [];
      let count = 0;
      while (resultSet.goToNextRow() && count < limit) {
        commands.push(CommandDAO.mapRowToCommand(resultSet));
        count++;
      }
      return commands;
    } catch (error) {
      throw DAOHelper.toError('[CommandDAO] 根据用户获取命令失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 映射数据库行到命令对象
   */
  private static mapRowToCommand(resultSet: relationalStore.ResultSet): Command {
    return new Command(
      DAOHelper.getString(resultSet, 'command_id'),
      DAOHelper.getString(resultSet, 'command_type'),
      DAOHelper.getString(resultSet, 'aggregate_type'),
      DAOHelper.getLong(resultSet, 'aggregate_id'),
      DAOHelper.getLong(resultSet, 'user_id'),
      DAOHelper.getString(resultSet, 'payload_json'),
      DAOHelper.getString(resultSet, 'status'),
      DAOHelper.getString(resultSet, 'metadata_json'),
      DAOHelper.getLong(resultSet, 'expected_version'),
      DAOHelper.getString(resultSet, 'issued_at'),
      DAOHelper.getString(resultSet, 'processed_at'),
      DAOHelper.getString(resultSet, 'error_message')
    );
  }

  /**
   * 获取命令统计
   */
  static async getStatistics(): Promise<CommandStats> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();

      const sql = `
        SELECT
          COUNT(*) as total_commands,
          SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_commands,
          SUM(CASE WHEN status = 'processing' THEN 1 ELSE 0 END) as processing_commands,
          SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_commands,
          SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_commands
        FROM ${Command.tableName}
      `;

      resultSet = await store.querySql(sql, []);

      const stats: CommandStats = {
        totalCommands: 0,
        pendingCommands: 0,
        processingCommands: 0,
        completedCommands: 0,
        failedCommands: 0
      };

      if (resultSet.goToFirstRow()) {
        stats.totalCommands = DAOHelper.getLong(resultSet, 'total_commands');
        stats.pendingCommands = DAOHelper.getLong(resultSet, 'pending_commands');
        stats.processingCommands = DAOHelper.getLong(resultSet, 'processing_commands');
        stats.completedCommands = DAOHelper.getLong(resultSet, 'completed_commands');
        stats.failedCommands = DAOHelper.getLong(resultSet, 'failed_commands');
      }

      return stats;
    } catch (error) {
      throw DAOHelper.toError('[CommandDAO] 获取统计信息失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }
}

/**
 * 聚合快照DAO
 */
export class AggregateSnapshotDAO {
  /**
   * 保存快照
   */
  static async save(snapshot: AggregateSnapshot): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      snapshot.createdAt = now;

      const values: relationalStore.ValuesBucket = {
        aggregate_type: snapshot.aggregateType,
        aggregate_id: snapshot.aggregateId,
        version: snapshot.version,
        state_json: snapshot.stateJson,
        created_at: snapshot.createdAt
      };

      const rowId = await store.insert(AggregateSnapshot.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[AggregateSnapshotDAO] 保存快照失败', error);
    }
  }

  /**
   * 获取最新快照
   */
  static async getLatest(aggregateType: string, aggregateId: number): Promise<AggregateSnapshot | null> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(AggregateSnapshot.tableName);
      predicates.equalTo('aggregate_type', aggregateType);
      predicates.equalTo('aggregate_id', aggregateId);
      predicates.orderByDesc('version');

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        return AggregateSnapshotDAO.mapRowToSnapshot(resultSet);
      }
      return null;
    } catch (error) {
      throw DAOHelper.toError('[AggregateSnapshotDAO] 获取最新快照失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 删除旧快照
   */
  static async deleteOldSnapshots(
    aggregateType: string,
    aggregateId: number,
    keepLatestN: number = 5
  ): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();

      // 获取要保留的版本号
      const sql = `
        SELECT version FROM ${AggregateSnapshot.tableName}
        WHERE aggregate_type = ? AND aggregate_id = ?
        ORDER BY version DESC
        LIMIT ?
      `;
      const resultSet = await store.querySql(sql, [aggregateType, aggregateId.toString(), keepLatestN.toString()]);

      const versionsToKeep: number[] = [];
      while (resultSet.goToNextRow()) {
        versionsToKeep.push(DAOHelper.getLong(resultSet, 'version'));
      }
      DAOHelper.closeResultSet(resultSet);

      if (versionsToKeep.length === 0) {
        return 0;
      }

      // 删除旧版本
      const predicates = new relationalStore.RdbPredicates(AggregateSnapshot.tableName);
      predicates.equalTo('aggregate_type', aggregateType);
      predicates.equalTo('aggregate_id', aggregateId);
      predicates.notIn('version', versionsToKeep);

      const rowsDeleted = await store.delete(predicates);
      return rowsDeleted;
    } catch (error) {
      throw DAOHelper.toError('[AggregateSnapshotDAO] 删除旧快照失败', error);
    }
  }

  /**
   * 映射数据库行到快照对象
   */
  private static mapRowToSnapshot(resultSet: relationalStore.ResultSet): AggregateSnapshot {
    return new AggregateSnapshot(
      DAOHelper.getLong(resultSet, 'snapshot_id'),
      DAOHelper.getString(resultSet, 'aggregate_type'),
      DAOHelper.getLong(resultSet, 'aggregate_id'),
      DAOHelper.getLong(resultSet, 'version'),
      DAOHelper.getString(resultSet, 'state_json'),
      DAOHelper.getString(resultSet, 'created_at')
    );
  }

  /**
   * insert 方法别名（兼容性）
   */
  static async insert(snapshot: AggregateSnapshot): Promise<number> {
    return await AggregateSnapshotDAO.save(snapshot);
  }
}

/**
 * 读模型DAO
 */
export class ReadModelDAO {
  /**
   * 插入或更新读模型
   */
  static async upsert(model: ReadModel): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();

      // 检查是否存在
      const existing = await ReadModelDAO.get(model.modelType, model.userId);

      const values: relationalStore.ValuesBucket = {
        model_type: model.modelType,
        user_id: model.userId,
        aggregate_id: model.aggregateId,
        version: model.version,
        last_event_id: model.lastEventId,
        data_json: model.dataJson,
        last_event_version: model.lastEventVersion,
        last_updated_at: now
      };

      if (existing) {
        // 更新
        const predicates = new relationalStore.RdbPredicates(ReadModel.tableName);
        predicates.equalTo('model_id', existing.modelId);
        await store.update(values, predicates);
        return existing.modelId;
      } else {
        // 插入
        values['created_at'] = now;
        const rowId = await store.insert(ReadModel.tableName, values);
        return rowId;
      }
    } catch (error) {
      throw DAOHelper.toError('[ReadModelDAO] 插入或更新读模型失败', error);
    }
  }

  /**
   * 获取读模型
   */
  static async get(modelType: string, userId: number): Promise<ReadModel | null> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(ReadModel.tableName);
      predicates.equalTo('model_type', modelType);
      predicates.equalTo('user_id', userId);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        return ReadModelDAO.mapRowToReadModel(resultSet);
      }
      return null;
    } catch (error) {
      throw DAOHelper.toError('[ReadModelDAO] 获取读模型失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 获取用户的所有读模型
   */
  static async getAllByUser(userId: number): Promise<ReadModel[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(ReadModel.tableName);
      predicates.equalTo('user_id', userId);

      resultSet = await store.query(predicates);

      const models: ReadModel[] = [];
      while (resultSet.goToNextRow()) {
        models.push(ReadModelDAO.mapRowToReadModel(resultSet));
      }
      return models;
    } catch (error) {
      throw DAOHelper.toError('[ReadModelDAO] 获取用户所有读模型失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }

  /**
   * 删除读模型
   */
  static async delete(modelType: string, userId: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(ReadModel.tableName);
      predicates.equalTo('model_type', modelType);
      predicates.equalTo('user_id', userId);

      const rowsDeleted = await store.delete(predicates);
      return rowsDeleted > 0;
    } catch (error) {
      throw DAOHelper.toError('[ReadModelDAO] 删除读模型失败', error);
    }
  }

  /**
   * 映射数据库行到读模型对象
   */
  private static mapRowToReadModel(resultSet: relationalStore.ResultSet): ReadModel {
    return new ReadModel(
      DAOHelper.getLong(resultSet, 'model_id'),
      DAOHelper.getString(resultSet, 'model_type'),
      DAOHelper.getLong(resultSet, 'user_id'),
      DAOHelper.getLong(resultSet, 'aggregate_id'),
      DAOHelper.getLong(resultSet, 'version'),
      DAOHelper.getString(resultSet, 'last_event_id'),
      DAOHelper.getString(resultSet, 'data_json'),
      DAOHelper.getLong(resultSet, 'last_event_version'),
      DAOHelper.getString(resultSet, 'last_updated_at'),
      DAOHelper.getString(resultSet, 'created_at')
    );
  }

  /**
   * insertOrUpdate 方法别名（兼容性）
   */
  static async insertOrUpdate(model: ReadModel): Promise<number> {
    return await ReadModelDAO.upsert(model);
  }

  /**
   * 按聚合ID获取读模型
   */
  static async getByAggregateId(aggregateType: string, aggregateId: number): Promise<ReadModel | null> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(ReadModel.tableName);
      predicates.equalTo('model_type', aggregateType);
      predicates.equalTo('aggregate_id', aggregateId);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        return ReadModelDAO.mapRowToReadModel(resultSet);
      }
      return null;
    } catch (error) {
      throw DAOHelper.toError('[ReadModelDAO] 按聚合ID获取读模型失败', error);
    } finally {
      DAOHelper.closeResultSet(resultSet);
    }
  }
}

// 导出接口类型
export type { EventStoreStats, CommandStats };
