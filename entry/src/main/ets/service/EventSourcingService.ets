/**
 * 事件溯源服务 - CQRS架构实现
 *
 * 功能：
 * 1. 领域事件发布与存储
 * 2. 命令处理（Command Side）
 * 3. 查询模型维护（Query Side）
 * 4. 聚合快照管理
 * 5. 事件回放与状态重建
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import {
  DomainEventDAO,
  CommandDAO,
  AggregateSnapshotDAO,
  ReadModelDAO
} from '../dao/EventSourcingDAO';
import {
  DomainEvent,
  Command,
  AggregateSnapshot,
  ReadModel
} from '../model/EventSourcing';

/**
 * 事件发布结果接口
 */
export interface EventPublishResult {
  success: boolean;
  eventId: string;
  version: number;
  error?: string;
}

/**
 * 命令执行结果接口
 */
export interface CommandExecutionResult {
  success: boolean;
  commandId: string;
  eventsPublished: number;
  error?: string;
}

/**
 * 聚合状态接口
 */
export interface AggregateState {
  aggregateId: number;
  aggregateType: string;
  version: number;
  data: Record<string, Object>;
  lastEventAt: string;
}

/**
 * 事件数据接口
 */
export interface EventData {
  eventType: string;
  aggregateType: string;
  aggregateId: number;
  userId: number;
  payload: Record<string, Object>;
  metadata?: Record<string, Object>;
}

/**
 * 处理后的事件接口
 */
export interface ProcessedEvent {
  eventType: string;
  payload: Record<string, Object>;
}

/**
 * 事件溯源服务类
 */
export class EventSourcingService {

  // ==================== 事件发布 ====================

  /**
   * 发布领域事件
   * @param eventType 事件类型
   * @param aggregateType 聚合类型
   * @param aggregateId 聚合ID
   * @param userId 用户ID
   * @param payload 事件负载数据
   * @param metadata 元数据
   * @returns 发布结果
   */
  static async publishEvent(
    eventType: string,
    aggregateType: string,
    aggregateId: number,
    userId: number,
    payload: Record<string, Object>,
    metadata: Record<string, Object> = {}
  ): Promise<EventPublishResult> {
    try {
      // 获取当前聚合版本
      const currentVersion = await EventSourcingService.getCurrentVersion(aggregateType, aggregateId);
      const newVersion = currentVersion + 1;

      // 创建领域事件
      const event = new DomainEvent();
      event.eventId = EventSourcingService.generateEventId();
      event.eventType = eventType;
      event.aggregateType = aggregateType;
      event.aggregateId = aggregateId;
      event.userId = userId;
      event.version = newVersion;
      event.payloadJson = JSON.stringify(payload);
      event.metadataJson = JSON.stringify(metadata);
      event.occurredAt = new Date().toISOString();

      // 存储事件
      const success = await DomainEventDAO.insert(event);

      if (success) {
        // 异步更新读模型
        await EventSourcingService.updateReadModel(event);

        // 检查是否需要创建快照
        await EventSourcingService.checkAndCreateSnapshot(aggregateType, aggregateId, newVersion);
      }

      return {
        success: success,
        eventId: event.eventId,
        version: newVersion,
        error: success ? undefined : '事件存储失败'
      };
    } catch (error) {
      console.error('[EventSourcingService] 发布事件失败:', error);
      return {
        success: false,
        eventId: '',
        version: 0,
        error: String(error)
      };
    }
  }

  /**
   * 批量发布事件
   */
  static async publishEvents(events: EventData[]): Promise<EventPublishResult[]> {
    const results: EventPublishResult[] = [];

    for (let i = 0; i < events.length; i++) {
      const e = events[i];
      const result = await EventSourcingService.publishEvent(
        e.eventType,
        e.aggregateType,
        e.aggregateId,
        e.userId,
        e.payload,
        e.metadata || {}
      );
      results.push(result);
    }

    return results;
  }

  // ==================== 命令处理 ====================

  /**
   * 执行命令
   * @param commandType 命令类型
   * @param aggregateType 聚合类型
   * @param aggregateId 聚合ID
   * @param userId 用户ID
   * @param payload 命令负载
   * @returns 执行结果
   */
  static async executeCommand(
    commandType: string,
    aggregateType: string,
    aggregateId: number,
    userId: number,
    payload: Record<string, Object>
  ): Promise<CommandExecutionResult> {
    try {
      // 创建命令记录
      const command = new Command();
      command.commandId = EventSourcingService.generateCommandId();
      command.commandType = commandType;
      command.aggregateType = aggregateType;
      command.aggregateId = aggregateId;
      command.userId = userId;
      command.payloadJson = JSON.stringify(payload);
      command.status = 'pending';
      command.issuedAt = new Date().toISOString();

      // 保存命令
      await CommandDAO.insert(command);
      const commandId = command.commandId;

      // 标记为处理中
      await CommandDAO.updateStatus(commandId, 'processing');

      // 处理命令并生成事件
      const events = await EventSourcingService.processCommand(command);

      // 发布事件
      const publishResults: EventPublishResult[] = [];
      for (let i = 0; i < events.length; i++) {
        const metadata: Record<string, Object> = {};
        metadata['commandId'] = command.commandId;
        const result = await EventSourcingService.publishEvent(
          events[i].eventType,
          aggregateType,
          aggregateId,
          userId,
          events[i].payload,
          metadata
        );
        publishResults.push(result);
      }

      // 更新命令状态
      const allSuccess = publishResults.every((r: EventPublishResult) => r.success);
      await CommandDAO.updateStatus(
        commandId,
        allSuccess ? 'completed' : 'failed',
        allSuccess ? undefined : '部分事件发布失败'
      );

      return {
        success: allSuccess,
        commandId: command.commandId,
        eventsPublished: publishResults.filter((r: EventPublishResult) => r.success).length,
        error: allSuccess ? undefined : '命令执行失败'
      };
    } catch (error) {
      console.error('[EventSourcingService] 执行命令失败:', error);
      return {
        success: false,
        commandId: '',
        eventsPublished: 0,
        error: String(error)
      };
    }
  }

  /**
   * 处理命令（将命令转换为事件）
   */
  private static async processCommand(command: Command): Promise<ProcessedEvent[]> {
    const events: ProcessedEvent[] = [];
    const payload: Record<string, Object> = JSON.parse(command.payloadJson) as Record<string, Object>;

    // 根据命令类型生成对应事件
    switch (command.commandType) {
      case 'CreateBill':
        events.push({
          eventType: 'BillCreated',
          payload: payload
        });
        break;

      case 'UpdateBill':
        events.push({
          eventType: 'BillUpdated',
          payload: payload
        });
        break;

      case 'DeleteBill':
        events.push({
          eventType: 'BillDeleted',
          payload: payload
        });
        break;

      case 'CreateBudget':
        events.push({
          eventType: 'BudgetCreated',
          payload: payload
        });
        break;

      case 'UpdateBudget':
        events.push({
          eventType: 'BudgetUpdated',
          payload: payload
        });
        break;

      default:
        console.warn('[EventSourcingService] 未知命令类型:', command.commandType);
        events.push({
          eventType: 'UnknownCommandProcessed',
          payload: payload
        });
    }

    return events;
  }

  // ==================== 事件查询 ====================

  /**
   * 获取聚合的所有事件
   */
  static async getAggregateEvents(
    aggregateType: string,
    aggregateId: number,
    fromVersion: number = 0
  ): Promise<DomainEvent[]> {
    try {
      return await DomainEventDAO.getByAggregate(aggregateType, aggregateId, fromVersion);
    } catch (error) {
      console.error('[EventSourcingService] 获取聚合事件失败:', error);
      return [];
    }
  }

  /**
   * 获取用户的所有事件
   */
  static async getUserEvents(userId: number, limit: number = 100): Promise<DomainEvent[]> {
    try {
      return await DomainEventDAO.getByUserId(userId, limit);
    } catch (error) {
      console.error('[EventSourcingService] 获取用户事件失败:', error);
      return [];
    }
  }

  /**
   * 根据事件类型查询
   */
  static async getEventsByType(
    eventType: string,
    limit: number = 50
  ): Promise<DomainEvent[]> {
    try {
      return await DomainEventDAO.getByEventType(eventType, limit);
    } catch (error) {
      console.error('[EventSourcingService] 按类型查询事件失败:', error);
      return [];
    }
  }

  // ==================== 状态重建 ====================

  /**
   * 重建聚合状态（通过事件回放）
   */
  static async rebuildAggregateState(
    aggregateType: string,
    aggregateId: number
  ): Promise<AggregateState | null> {
    try {
      // 尝试从快照加载
      const snapshot = await AggregateSnapshotDAO.getLatest(aggregateType, aggregateId);

      let version = 0;
      let state: Record<string, Object> = {};

      if (snapshot) {
        // 从快照开始
        version = snapshot.version;
        state = JSON.parse(snapshot.stateJson) as Record<string, Object>;
      }

      // 获取快照之后的所有事件
      const events = await DomainEventDAO.getByAggregate(aggregateType, aggregateId, version);

      // 回放事件
      for (let i = 0; i < events.length; i++) {
        const event = events[i];
        state = EventSourcingService.applyEvent(state, event);
        version = event.version;
      }

      const lastEvent = events.length > 0 ? events[events.length - 1] : null;

      return {
        aggregateId: aggregateId,
        aggregateType: aggregateType,
        version: version,
        data: state,
        lastEventAt: lastEvent ? lastEvent.occurredAt : (snapshot ? snapshot.createdAt : '')
      };
    } catch (error) {
      console.error('[EventSourcingService] 重建聚合状态失败:', error);
      return null;
    }
  }

  /**
   * 应用事件到状态
   */
  private static applyEvent(state: Record<string, Object>, event: DomainEvent): Record<string, Object> {
    const payload: Record<string, Object> = JSON.parse(event.payloadJson) as Record<string, Object>;
    // 创建新状态对象，手动复制属性
    const newState: Record<string, Object> = {};
    const keys = Object.keys(state);
    for (let i = 0; i < keys.length; i++) {
      newState[keys[i]] = state[keys[i]];
    }

    // 根据事件类型应用状态变更
    switch (event.eventType) {
      case 'BillCreated':
        newState['billId'] = event.aggregateId;
        newState['amount'] = payload['amount'];
        newState['type'] = payload['type'];
        newState['categoryId'] = payload['categoryId'];
        newState['note'] = payload['note'];
        newState['createdAt'] = event.occurredAt;
        break;

      case 'BillUpdated':
        // 手动合并 payload 到 newState
        const payloadKeys = Object.keys(payload);
        for (let i = 0; i < payloadKeys.length; i++) {
          newState[payloadKeys[i]] = payload[payloadKeys[i]];
        }
        newState['updatedAt'] = event.occurredAt;
        break;

      case 'BillDeleted':
        newState['isDeleted'] = true;
        newState['deletedAt'] = event.occurredAt;
        break;

      default:
        console.warn('[EventSourcingService] 未处理的事件类型:', event.eventType);
    }

    return newState;
  }

  // ==================== 快照管理 ====================

  /**
   * 创建聚合快照
   */
  static async createSnapshot(
    aggregateType: string,
    aggregateId: number
  ): Promise<boolean> {
    try {
      // 重建当前状态
      const state = await EventSourcingService.rebuildAggregateState(aggregateType, aggregateId);
      if (!state) {
        return false;
      }

      // 创建快照
      const snapshot = new AggregateSnapshot();
      snapshot.aggregateType = aggregateType;
      snapshot.aggregateId = aggregateId;
      snapshot.version = state.version;
      snapshot.stateJson = JSON.stringify(state.data);

      const snapshotId = await AggregateSnapshotDAO.insert(snapshot);
      return snapshotId > 0;
    } catch (error) {
      console.error('[EventSourcingService] 创建快照失败:', error);
      return false;
    }
  }

  /**
   * 检查并创建快照（每隔N个版本创建一次）
   */
  private static async checkAndCreateSnapshot(
    aggregateType: string,
    aggregateId: number,
    currentVersion: number,
    snapshotInterval: number = 10
  ): Promise<void> {
    try {
      if (currentVersion % snapshotInterval === 0) {
        await EventSourcingService.createSnapshot(aggregateType, aggregateId);
      }
    } catch (error) {
      console.error('[EventSourcingService] 检查快照失败:', error);
    }
  }

  // ==================== 读模型维护 ====================

  /**
   * 更新读模型
   */
  private static async updateReadModel(event: DomainEvent): Promise<void> {
    try {
      const modelType = `${event.aggregateType}ReadModel`;

      // 查找或创建读模型
      let readModel = await ReadModelDAO.getByAggregateId(event.aggregateType, event.aggregateId);

      if (!readModel) {
        readModel = new ReadModel();
        readModel.modelType = modelType;
        readModel.aggregateId = event.aggregateId;
        readModel.version = 0;
        readModel.dataJson = '{}';
      }

      // 应用事件到读模型
      const data: Record<string, Object> = JSON.parse(readModel.dataJson) as Record<string, Object>;
      const updatedData = EventSourcingService.applyEvent(data, event);

      readModel.dataJson = JSON.stringify(updatedData);
      readModel.version = event.version;
      readModel.lastEventId = event.eventId;

      // 保存读模型
      await ReadModelDAO.insertOrUpdate(readModel);
    } catch (error) {
      console.error('[EventSourcingService] 更新读模型失败:', error);
    }
  }

  /**
   * 获取读模型
   */
  static async getReadModel(aggregateType: string, aggregateId: number): Promise<Record<string, Object> | null> {
    try {
      const readModel = await ReadModelDAO.getByAggregateId(aggregateType, aggregateId);
      if (!readModel) {
        return null;
      }
      return JSON.parse(readModel.dataJson) as Record<string, Object>;
    } catch (error) {
      console.error('[EventSourcingService] 获取读模型失败:', error);
      return null;
    }
  }

  /**
   * 重建所有读模型
   */
  static async rebuildAllReadModels(aggregateType: string): Promise<number> {
    try {
      // 获取所有该类型的聚合ID
      const events = await DomainEventDAO.getByAggregateType(aggregateType, 10000);

      const aggregateIds = new Set<number>();
      for (let i = 0; i < events.length; i++) {
        aggregateIds.add(events[i].aggregateId);
      }

      // 重建每个聚合的读模型
      let rebuilt = 0;
      aggregateIds.forEach(async (aggregateId) => {
        const state = await EventSourcingService.rebuildAggregateState(aggregateType, aggregateId);
        if (state) {
          const readModel = new ReadModel();
          readModel.modelType = `${aggregateType}ReadModel`;
          readModel.aggregateId = aggregateId;
          readModel.version = state.version;
          readModel.dataJson = JSON.stringify(state.data);
          readModel.lastEventId = '';

          await ReadModelDAO.insertOrUpdate(readModel);
          rebuilt++;
        }
      });

      return rebuilt;
    } catch (error) {
      console.error('[EventSourcingService] 重建读模型失败:', error);
      return 0;
    }
  }

  // ==================== 工具方法 ====================

  /**
   * 生成事件ID
   */
  private static generateEventId(): string {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 10000);
    return `evt_${timestamp}_${random}`;
  }

  /**
   * 生成命令ID
   */
  private static generateCommandId(): string {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 10000);
    return `cmd_${timestamp}_${random}`;
  }

  /**
   * 获取当前聚合版本
   */
  private static async getCurrentVersion(aggregateType: string, aggregateId: number): Promise<number> {
    try {
      const events = await DomainEventDAO.getByAggregate(aggregateType, aggregateId, 0);
      if (events.length === 0) {
        return 0;
      }
      return events[events.length - 1].version;
    } catch (error) {
      console.error('[EventSourcingService] 获取当前版本失败:', error);
      return 0;
    }
  }

  /**
   * 获取事件统计
   */
  static async getStatistics() {
    try {
      return await DomainEventDAO.getStatistics();
    } catch (error) {
      console.error('[EventSourcingService] 获取事件统计失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取命令统计
   */
  static async getCommandStatistics() {
    try {
      return await CommandDAO.getStatistics();
    } catch (error) {
      console.error('[EventSourcingService] 获取命令统计失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
}
