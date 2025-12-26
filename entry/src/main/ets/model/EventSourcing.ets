/**
 * 企业级架构 - Event Sourcing + CQRS 模式
 *
 * 功能：
 * 1. 事件溯源 (Event Sourcing) - 完整的数据变更历史
 * 2. CQRS (命令查询职责分离) - 读写分离优化
 * 3. 事件驱动架构 - 松耦合、可扩展
 * 4. 审计日志 - 完整的操作追踪
 *
 * 架构优势：
 * - 完整的数据变更历史
 * - 支持任意时间点数据回滚
 * - 审计合规需求
 * - 高并发读写分离
 * - 便于调试和问题追踪
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import { Bill, BillJSON } from './Bill';
import { Category } from './Category';
import { Account } from './Account';
import { Budget } from './Budget';

// ==================== 辅助接口定义 ====================

/**
 * 预算超支事件负载接口
 */
export interface BudgetExceededPayload {
  budgetId: number;
  categoryId: number;
  budgetAmount: number;
  currentSpent: number;
  exceedAmount: number;
  exceedPercent: number;
  occurredAt: string;
}

/**
 * 账户余额变更事件负载接口
 */
export interface AccountBalanceChangedPayload {
  accountId: number;
  oldBalance: number;
  newBalance: number;
  changeAmount: number;
  reason: string;
  occurredAt: string;
}

/**
 * 账单删除命令负载接口
 */
export interface DeleteBillPayload {
  billId: number;
  reason: string;
}

// ==================== 常量定义 ====================

// 账单事件类型
export const EVENT_TYPE_BILL_CREATED = 'bill.created';
export const EVENT_TYPE_BILL_UPDATED = 'bill.updated';
export const EVENT_TYPE_BILL_DELETED = 'bill.deleted';
export const EVENT_TYPE_BILL_RESTORED = 'bill.restored';

// 分类事件类型
export const EVENT_TYPE_CATEGORY_CREATED = 'category.created';
export const EVENT_TYPE_CATEGORY_UPDATED = 'category.updated';
export const EVENT_TYPE_CATEGORY_DELETED = 'category.deleted';

// 账户事件类型
export const EVENT_TYPE_ACCOUNT_CREATED = 'account.created';
export const EVENT_TYPE_ACCOUNT_UPDATED = 'account.updated';
export const EVENT_TYPE_ACCOUNT_DELETED = 'account.deleted';
export const EVENT_TYPE_ACCOUNT_BALANCE_CHANGED = 'account.balance_changed';

// 预算事件类型
export const EVENT_TYPE_BUDGET_CREATED = 'budget.created';
export const EVENT_TYPE_BUDGET_UPDATED = 'budget.updated';
export const EVENT_TYPE_BUDGET_DELETED = 'budget.deleted';
export const EVENT_TYPE_BUDGET_EXCEEDED = 'budget.exceeded';

// 用户事件类型
export const EVENT_TYPE_USER_REGISTERED = 'user.registered';
export const EVENT_TYPE_USER_LOGGED_IN = 'user.logged_in';
export const EVENT_TYPE_USER_LOGGED_OUT = 'user.logged_out';
export const EVENT_TYPE_USER_UPDATED = 'user.updated';

// 系统事件类型
export const EVENT_TYPE_SYNC_STARTED = 'sync.started';
export const EVENT_TYPE_SYNC_COMPLETED = 'sync.completed';
export const EVENT_TYPE_SYNC_FAILED = 'sync.failed';
export const EVENT_TYPE_DATA_EXPORTED = 'data.exported';
export const EVENT_TYPE_DATA_IMPORTED = 'data.imported';

// 聚合类型常量
export const AGGREGATE_TYPE_BILL = 'bill';
export const AGGREGATE_TYPE_CATEGORY = 'category';
export const AGGREGATE_TYPE_ACCOUNT = 'account';
export const AGGREGATE_TYPE_BUDGET = 'budget';
export const AGGREGATE_TYPE_USER = 'user';
export const AGGREGATE_TYPE_TAG = 'tag';
export const AGGREGATE_TYPE_LEDGER = 'ledger';

// 命令状态常量
export const COMMAND_STATUS_PENDING = 'pending';
export const COMMAND_STATUS_PROCESSING = 'processing';
export const COMMAND_STATUS_SUCCEEDED = 'succeeded';
export const COMMAND_STATUS_FAILED = 'failed';
export const COMMAND_STATUS_CANCELLED = 'cancelled';

// 快照频率常量
export const SNAPSHOT_FREQUENCY_NEVER = 0;
export const SNAPSHOT_FREQUENCY_EVERY_10 = 10;
export const SNAPSHOT_FREQUENCY_EVERY_50 = 50;
export const SNAPSHOT_FREQUENCY_EVERY_100 = 100;

// 事件来源常量
export const EVENT_SOURCE_APP = 'app';
export const EVENT_SOURCE_API = 'api';
export const EVENT_SOURCE_SYNC = 'sync';
export const EVENT_SOURCE_IMPORT = 'import';
export const EVENT_SOURCE_SYSTEM = 'system';

// 所有事件类型列表
export const ALL_EVENT_TYPES: string[] = [
  EVENT_TYPE_BILL_CREATED,
  EVENT_TYPE_BILL_UPDATED,
  EVENT_TYPE_BILL_DELETED,
  EVENT_TYPE_BILL_RESTORED,
  EVENT_TYPE_CATEGORY_CREATED,
  EVENT_TYPE_CATEGORY_UPDATED,
  EVENT_TYPE_CATEGORY_DELETED,
  EVENT_TYPE_ACCOUNT_CREATED,
  EVENT_TYPE_ACCOUNT_UPDATED,
  EVENT_TYPE_ACCOUNT_DELETED,
  EVENT_TYPE_ACCOUNT_BALANCE_CHANGED,
  EVENT_TYPE_BUDGET_CREATED,
  EVENT_TYPE_BUDGET_UPDATED,
  EVENT_TYPE_BUDGET_DELETED,
  EVENT_TYPE_BUDGET_EXCEEDED,
  EVENT_TYPE_USER_REGISTERED,
  EVENT_TYPE_USER_LOGGED_IN,
  EVENT_TYPE_USER_LOGGED_OUT,
  EVENT_TYPE_USER_UPDATED,
  EVENT_TYPE_SYNC_STARTED,
  EVENT_TYPE_SYNC_COMPLETED,
  EVENT_TYPE_SYNC_FAILED,
  EVENT_TYPE_DATA_EXPORTED,
  EVENT_TYPE_DATA_IMPORTED
];

// 所有聚合类型列表
export const ALL_AGGREGATE_TYPES: string[] = [
  AGGREGATE_TYPE_BILL,
  AGGREGATE_TYPE_CATEGORY,
  AGGREGATE_TYPE_ACCOUNT,
  AGGREGATE_TYPE_BUDGET,
  AGGREGATE_TYPE_USER,
  AGGREGATE_TYPE_TAG,
  AGGREGATE_TYPE_LEDGER
];

// 所有命令状态列表
export const ALL_COMMAND_STATUSES: string[] = [
  COMMAND_STATUS_PENDING,
  COMMAND_STATUS_PROCESSING,
  COMMAND_STATUS_SUCCEEDED,
  COMMAND_STATUS_FAILED,
  COMMAND_STATUS_CANCELLED
];

// CQRS读模型类型
export const READ_MODEL_TYPE_BILL_SUMMARY = 'BillSummary';           // 账单摘要
export const READ_MODEL_TYPE_CATEGORY_STATS = 'CategoryStats';       // 分类统计
export const READ_MODEL_TYPE_MONTHLY_REPORT = 'MonthlyReport';       // 月度报表
export const READ_MODEL_TYPE_BUDGET_STATUS = 'BudgetStatus';         // 预算状态
export const READ_MODEL_TYPE_ACCOUNT_BALANCE = 'AccountBalance';     // 账户余额
export const READ_MODEL_TYPE_USER_ACTIVITY = 'UserActivity';         // 用户活动

// ==================== 接口定义 ====================

/**
 * 事件元数据接口
 */
export interface EventMetadata {
  correlationId: string;         // 关联ID（追踪同一业务流程）
  causationId: string;           // 因果ID（追踪事件链）
  userId: number;
  userAgent: string;
  ipAddress: string;
  deviceId: string;
  sessionId: string;
  source: string;                // 'app' | 'api' | 'sync' | 'import' | 'system'
}

/**
 * 领域事件接口
 */
export interface DomainEventJSON {
  eventId: string;               // UUID
  eventType: string;
  aggregateType: string;
  aggregateId: number;
  userId: number;
  version: number;               // 聚合版本号
  payloadJson: string;           // 事件数据JSON
  metadata: EventMetadata;
  occurredAt: string;            // 事件发生时间
  createdAt: string;
}

/**
 * 命令接口
 */
export interface CommandJSON {
  commandId: string;             // UUID
  commandType: string;           // 如 'CreateBill', 'UpdateCategory'
  aggregateType: string;
  aggregateId: number;           // 0表示新建
  userId: number;
  payloadJson: string;
  status: string;
  metadata: EventMetadata;
  expectedVersion: number;       // 乐观锁版本，0表示无限制
  issuedAt: string;
  processedAt: string;
  errorMessage: string;
}

/**
 * 聚合快照接口
 */
export interface AggregateSnapshotJSON {
  snapshotId: number;
  aggregateType: string;
  aggregateId: number;
  version: number;
  stateJson: string;             // 聚合状态JSON
  createdAt: string;
}

/**
 * 事件类型统计接口
 */
export interface EventTypeStats {
  eventType: string;
  count: number;
}

/**
 * 聚合类型统计接口
 */
export interface AggregateTypeStats {
  aggregateType: string;
  count: number;
}

/**
 * 事件存储统计接口
 */
export interface EventStoreStats {
  totalEvents: number;
  eventsByType: EventTypeStats[];
  eventsByAggregate: AggregateTypeStats[];
  eventsToday: number;
  eventsThisWeek: number;
  eventsThisMonth: number;
  averageEventsPerDay: number;
  oldestEventDate: string;
  newestEventDate: string;
}

/**
 * 读模型接口（CQRS查询侧）
 */
export interface ReadModelJSON {
  modelId: number;
  modelType: string;             // 如 'BillSummary', 'CategoryStats'
  userId: number;
  aggregateId: number;
  version: number;
  lastEventId: string;
  dataJson: string;
  lastEventVersion: number;      // 最后处理的事件版本
  lastUpdatedAt: string;
  createdAt: string;
}

/**
 * 事件变更记录接口
 */
export interface EventChange {
  field: string;
  oldValue: string;
  newValue: string;
}

// ==================== 类实现 ====================

/**
 * 领域事件类
 */
export class DomainEvent {
  static readonly tableName: string = 'domain_events';

  eventId: string = '';
  eventType: string = EVENT_TYPE_BILL_CREATED;
  aggregateType: string = AGGREGATE_TYPE_BILL;
  aggregateId: number = 0;
  userId: number = 0;
  version: number = 1;
  payloadJson: string = '{}';
  metadataJson: string = '{}';
  occurredAt: string = '';
  createdAt: string = '';

  constructor(
    eventId: string = '',
    eventType: string = EVENT_TYPE_BILL_CREATED,
    aggregateType: string = AGGREGATE_TYPE_BILL,
    aggregateId: number = 0,
    userId: number = 0,
    version: number = 1,
    payloadJson: string = '{}',
    metadataJson: string = '{}',
    occurredAt: string = '',
    createdAt: string = ''
  ) {
    this.eventId = eventId !== '' ? eventId : EventSourcingUtils.generateUUID();
    this.eventType = eventType;
    this.aggregateType = aggregateType;
    this.aggregateId = aggregateId;
    this.userId = userId;
    this.version = version;
    this.payloadJson = payloadJson;
    this.metadataJson = metadataJson;
    this.occurredAt = occurredAt !== '' ? occurredAt : new Date().toISOString();
    this.createdAt = createdAt !== '' ? createdAt : new Date().toISOString();
  }

  /**
   * 获取事件数据
   */
  getPayloadAsString(): string {
    return this.payloadJson;
  }

  /**
   * 设置事件数据
   */
  setPayloadFromString(payload: string): void {
    this.payloadJson = payload;
  }

  /**
   * 获取元数据
   */
  getMetadata(): EventMetadata {
    try {
      const parsed = JSON.parse(this.metadataJson) as EventMetadata;
      return parsed;
    } catch (e) {
      return EventSourcingUtils.createDefaultMetadata(this.eventId, this.userId);
    }
  }

  /**
   * 设置元数据
   */
  setMetadata(metadata: EventMetadata): void {
    this.metadataJson = JSON.stringify(metadata);
  }

  toJSON(): DomainEventJSON {
    const result: DomainEventJSON = {
      eventId: this.eventId,
      eventType: this.eventType,
      aggregateType: this.aggregateType,
      aggregateId: this.aggregateId,
      userId: this.userId,
      version: this.version,
      payloadJson: this.payloadJson,
      metadata: this.getMetadata(),
      occurredAt: this.occurredAt,
      createdAt: this.createdAt
    };
    return result;
  }

  static fromJSON(data: DomainEventJSON): DomainEvent {
    return new DomainEvent(
      data.eventId,
      data.eventType,
      data.aggregateType,
      data.aggregateId,
      data.userId,
      data.version,
      data.payloadJson,
      JSON.stringify(data.metadata),
      data.occurredAt,
      data.createdAt
    );
  }

  validate(): boolean {
    let validEventType = false;
    for (let i = 0; i < ALL_EVENT_TYPES.length; i++) {
      if (ALL_EVENT_TYPES[i] === this.eventType) {
        validEventType = true;
        break;
      }
    }

    let validAggregateType = false;
    for (let i = 0; i < ALL_AGGREGATE_TYPES.length; i++) {
      if (ALL_AGGREGATE_TYPES[i] === this.aggregateType) {
        validAggregateType = true;
        break;
      }
    }

    return (
      this.eventId.length > 0 &&
      validEventType &&
      validAggregateType &&
      this.aggregateId > 0 &&
      this.userId > 0 &&
      this.version > 0
    );
  }

  clone(): DomainEvent {
    return DomainEvent.fromJSON(this.toJSON());
  }
}

/**
 * 命令类
 */
export class Command {
  static readonly tableName: string = 'commands';

  commandId: string = '';
  commandType: string = '';
  aggregateType: string = AGGREGATE_TYPE_BILL;
  aggregateId: number = 0;
  userId: number = 0;
  payloadJson: string = '{}';
  status: string = COMMAND_STATUS_PENDING;
  metadataJson: string = '{}';
  expectedVersion: number = 0;
  issuedAt: string = '';
  processedAt: string = '';
  errorMessage: string = '';
  createdAt: string = '';
  updatedAt: string = '';

  constructor(
    commandId: string = '',
    commandType: string = '',
    aggregateType: string = AGGREGATE_TYPE_BILL,
    aggregateId: number = 0,
    userId: number = 0,
    payloadJson: string = '{}',
    status: string = COMMAND_STATUS_PENDING,
    metadataJson: string = '{}',
    expectedVersion: number = 0,
    issuedAt: string = '',
    processedAt: string = '',
    errorMessage: string = '',
    createdAt: string = '',
    updatedAt: string = ''
  ) {
    this.commandId = commandId !== '' ? commandId : EventSourcingUtils.generateUUID();
    this.commandType = commandType;
    this.aggregateType = aggregateType;
    this.aggregateId = aggregateId;
    this.userId = userId;
    this.payloadJson = payloadJson;
    this.status = status;
    this.metadataJson = metadataJson;
    this.expectedVersion = expectedVersion;
    this.issuedAt = issuedAt !== '' ? issuedAt : new Date().toISOString();
    this.processedAt = processedAt;
    this.errorMessage = errorMessage;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  /**
   * 获取命令数据
   */
  getPayloadAsString(): string {
    return this.payloadJson;
  }

  /**
   * 设置命令数据
   */
  setPayloadFromString(payload: string): void {
    this.payloadJson = payload;
  }

  /**
   * 获取元数据
   */
  getMetadata(): EventMetadata {
    try {
      const parsed = JSON.parse(this.metadataJson) as EventMetadata;
      return parsed;
    } catch (e) {
      return EventSourcingUtils.createDefaultMetadata(this.commandId, this.userId);
    }
  }

  /**
   * 设置元数据
   */
  setMetadata(metadata: EventMetadata): void {
    this.metadataJson = JSON.stringify(metadata);
  }

  /**
   * 标记为处理中
   */
  markProcessing(): void {
    this.status = COMMAND_STATUS_PROCESSING;
  }

  /**
   * 标记为成功
   */
  markSucceeded(): void {
    this.status = COMMAND_STATUS_SUCCEEDED;
    this.processedAt = new Date().toISOString();
  }

  /**
   * 标记为失败
   */
  markFailed(errorMessage: string): void {
    this.status = COMMAND_STATUS_FAILED;
    this.errorMessage = errorMessage;
    this.processedAt = new Date().toISOString();
  }

  /**
   * 标记为取消
   */
  markCancelled(): void {
    this.status = COMMAND_STATUS_CANCELLED;
    this.processedAt = new Date().toISOString();
  }

  toJSON(): CommandJSON {
    const result: CommandJSON = {
      commandId: this.commandId,
      commandType: this.commandType,
      aggregateType: this.aggregateType,
      aggregateId: this.aggregateId,
      userId: this.userId,
      payloadJson: this.payloadJson,
      status: this.status,
      metadata: this.getMetadata(),
      expectedVersion: this.expectedVersion,
      issuedAt: this.issuedAt,
      processedAt: this.processedAt,
      errorMessage: this.errorMessage
    };
    return result;
  }

  static fromJSON(data: CommandJSON): Command {
    return new Command(
      data.commandId,
      data.commandType,
      data.aggregateType,
      data.aggregateId,
      data.userId,
      data.payloadJson,
      data.status,
      JSON.stringify(data.metadata),
      data.expectedVersion,
      data.issuedAt,
      data.processedAt,
      data.errorMessage
    );
  }

  validate(): boolean {
    let validAggregateType = false;
    for (let i = 0; i < ALL_AGGREGATE_TYPES.length; i++) {
      if (ALL_AGGREGATE_TYPES[i] === this.aggregateType) {
        validAggregateType = true;
        break;
      }
    }

    return (
      this.commandId.length > 0 &&
      this.commandType.length > 0 &&
      validAggregateType &&
      this.userId > 0
    );
  }

  clone(): Command {
    return Command.fromJSON(this.toJSON());
  }
}

/**
 * 聚合快照类
 */
export class AggregateSnapshot {
  static readonly tableName: string = 'aggregate_snapshots';

  snapshotId: number = 0;
  aggregateType: string = AGGREGATE_TYPE_BILL;
  aggregateId: number = 0;
  version: number = 0;
  stateJson: string = '{}';
  createdAt: string = '';

  constructor(
    snapshotId: number = 0,
    aggregateType: string = AGGREGATE_TYPE_BILL,
    aggregateId: number = 0,
    version: number = 0,
    stateJson: string = '{}',
    createdAt: string = ''
  ) {
    this.snapshotId = snapshotId;
    this.aggregateType = aggregateType;
    this.aggregateId = aggregateId;
    this.version = version;
    this.stateJson = stateJson;
    this.createdAt = createdAt !== '' ? createdAt : new Date().toISOString();
  }

  /**
   * 获取状态
   */
  getStateAsString(): string {
    return this.stateJson;
  }

  /**
   * 设置状态
   */
  setStateFromString(state: string): void {
    this.stateJson = state;
  }

  toJSON(): AggregateSnapshotJSON {
    const result: AggregateSnapshotJSON = {
      snapshotId: this.snapshotId,
      aggregateType: this.aggregateType,
      aggregateId: this.aggregateId,
      version: this.version,
      stateJson: this.stateJson,
      createdAt: this.createdAt
    };
    return result;
  }

  static fromJSON(data: AggregateSnapshotJSON): AggregateSnapshot {
    return new AggregateSnapshot(
      data.snapshotId,
      data.aggregateType,
      data.aggregateId,
      data.version,
      data.stateJson,
      data.createdAt
    );
  }

  validate(): boolean {
    let validAggregateType = false;
    for (let i = 0; i < ALL_AGGREGATE_TYPES.length; i++) {
      if (ALL_AGGREGATE_TYPES[i] === this.aggregateType) {
        validAggregateType = true;
        break;
      }
    }

    return (
      validAggregateType &&
      this.aggregateId > 0 &&
      this.version >= 0
    );
  }

  clone(): AggregateSnapshot {
    return AggregateSnapshot.fromJSON(this.toJSON());
  }
}

/**
 * 读模型类（CQRS查询侧）
 */
export class ReadModel {
  static readonly tableName: string = 'read_models';

  modelId: number = 0;
  modelType: string = '';
  userId: number = 0;
  aggregateId: number = 0;
  version: number = 0;
  lastEventId: string = '';
  dataJson: string = '{}';
  lastEventVersion: number = 0;
  lastUpdatedAt: string = '';
  updatedAt: string = '';
  createdAt: string = '';

  constructor(
    modelId: number = 0,
    modelType: string = '',
    userId: number = 0,
    aggregateId: number = 0,
    version: number = 0,
    lastEventId: string = '',
    dataJson: string = '{}',
    lastEventVersion: number = 0,
    lastUpdatedAt: string = '',
    updatedAt: string = '',
    createdAt: string = ''
  ) {
    this.modelId = modelId;
    this.modelType = modelType;
    this.userId = userId;
    this.aggregateId = aggregateId;
    this.version = version;
    this.lastEventId = lastEventId;
    this.dataJson = dataJson;
    this.lastEventVersion = lastEventVersion;
    this.lastUpdatedAt = lastUpdatedAt;
    this.updatedAt = updatedAt;
    this.createdAt = createdAt;
  }

  /**
   * 获取数据
   */
  getDataAsString(): string {
    return this.dataJson;
  }

  /**
   * 设置数据
   */
  setDataFromString(data: string): void {
    this.dataJson = data;
    this.lastUpdatedAt = new Date().toISOString();
  }

  /**
   * 更新事件版本
   */
  updateEventVersion(version: number): void {
    this.lastEventVersion = version;
    this.lastUpdatedAt = new Date().toISOString();
  }

  toJSON(): ReadModelJSON {
    const result: ReadModelJSON = {
      modelId: this.modelId,
      modelType: this.modelType,
      userId: this.userId,
      aggregateId: this.aggregateId,
      version: this.version,
      lastEventId: this.lastEventId,
      dataJson: this.dataJson,
      lastEventVersion: this.lastEventVersion,
      lastUpdatedAt: this.lastUpdatedAt,
      createdAt: this.createdAt
    };
    return result;
  }

  static fromJSON(data: ReadModelJSON): ReadModel {
    return new ReadModel(
      data.modelId,
      data.modelType,
      data.userId,
      data.aggregateId,
      data.version,
      data.lastEventId,
      data.dataJson,
      data.lastEventVersion,
      data.lastUpdatedAt,
      data.lastUpdatedAt, // Use lastUpdatedAt for updatedAt as well since it's missing in JSON
      data.createdAt
    );
  }

  validate(): boolean {
    return (
      this.modelType.length > 0 &&
      this.userId > 0
    );
  }

  clone(): ReadModel {
    return ReadModel.fromJSON(this.toJSON());
  }
}

/**
 * 事件溯源工具类
 */
export class EventSourcingUtils {

  /**
   * 生成UUID
   */
  static generateUUID(): string {
    const hexChars = '0123456789abcdef';
    let uuid = '';

    for (let i = 0; i < 36; i++) {
      if (i === 8 || i === 13 || i === 18 || i === 23) {
        uuid += '-';
      } else if (i === 14) {
        uuid += '4';
      } else if (i === 19) {
        const random = Math.floor(Math.random() * 4) + 8;
        uuid += hexChars.charAt(random);
      } else {
        const random = Math.floor(Math.random() * 16);
        uuid += hexChars.charAt(random);
      }
    }

    return uuid;
  }

  /**
   * 创建默认元数据
   */
  static createDefaultMetadata(correlationId: string, userId: number): EventMetadata {
    const result: EventMetadata = {
      correlationId: correlationId,
      causationId: '',
      userId: userId,
      userAgent: '',
      ipAddress: '',
      deviceId: '',
      sessionId: '',
      source: EVENT_SOURCE_APP
    };
    return result;
  }

  /**
   * 创建账单创建事件
   */
  static createBillCreatedEvent(
    userId: number,
    billId: number,
    billDataJson: string
  ): DomainEvent {
    const event = new DomainEvent(
      '',
      EVENT_TYPE_BILL_CREATED,
      AGGREGATE_TYPE_BILL,
      billId,
      userId,
      1,
      billDataJson,
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(event.eventId, userId);
    event.setMetadata(metadata);
    return event;
  }

  /**
   * 创建账单更新事件
   */
  static createBillUpdatedEvent(
    userId: number,
    billId: number,
    version: number,
    changesJson: string
  ): DomainEvent {
    const event = new DomainEvent(
      '',
      EVENT_TYPE_BILL_UPDATED,
      AGGREGATE_TYPE_BILL,
      billId,
      userId,
      version,
      changesJson,
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(event.eventId, userId);
    event.setMetadata(metadata);
    return event;
  }

  /**
   * 创建账单删除事件
   */
  static createBillDeletedEvent(
    userId: number,
    billId: number,
    version: number,
    reason: string = ''
  ): DomainEvent {
    const payloadJson = '{"reason":"' + reason + '","deletedAt":"' + new Date().toISOString() + '"}';
    const event = new DomainEvent(
      '',
      EVENT_TYPE_BILL_DELETED,
      AGGREGATE_TYPE_BILL,
      billId,
      userId,
      version,
      payloadJson,
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(event.eventId, userId);
    event.setMetadata(metadata);
    return event;
  }

  /**
   * 检查是否需要创建快照
   */
  static shouldCreateSnapshot(
    currentVersion: number,
    lastSnapshotVersion: number,
    frequency: number
  ): boolean {
    if (frequency === SNAPSHOT_FREQUENCY_NEVER) {
      return false;
    }
    return currentVersion - lastSnapshotVersion >= frequency;
  }

  /**
   * 生成关联ID
   */
  static generateCorrelationId(): string {
    const timestamp = Date.now().toString();
    const random = Math.floor(Math.random() * 1000000000).toString(36);
    return 'corr-' + timestamp + '-' + random;
  }

  /**
   * 创建事件类型统计
   */
  static createEventTypeStats(eventType: string, count: number): EventTypeStats {
    const result: EventTypeStats = {
      eventType: eventType,
      count: count
    };
    return result;
  }

  /**
   * 创建聚合类型统计
   */
  static createAggregateTypeStats(aggregateType: string, count: number): AggregateTypeStats {
    const result: AggregateTypeStats = {
      aggregateType: aggregateType,
      count: count
    };
    return result;
  }

  /**
   * 计算事件存储统计
   */
  static calculateStats(events: DomainEvent[]): EventStoreStats {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekStart = new Date(todayStart.getTime() - 7 * 24 * 60 * 60 * 1000);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    // 统计事件类型
    const typeCountMap: Map<string, number> = new Map<string, number>();
    const aggregateCountMap: Map<string, number> = new Map<string, number>();
    let eventsToday = 0;
    let eventsThisWeek = 0;
    let eventsThisMonth = 0;
    let oldestDate = '';
    let newestDate = '';

    for (let i = 0; i < events.length; i++) {
      const event = events[i];

      // 按类型统计
      const currentTypeCount = typeCountMap.get(event.eventType);
      if (currentTypeCount !== undefined) {
        typeCountMap.set(event.eventType, currentTypeCount + 1);
      } else {
        typeCountMap.set(event.eventType, 1);
      }

      // 按聚合统计
      const currentAggCount = aggregateCountMap.get(event.aggregateType);
      if (currentAggCount !== undefined) {
        aggregateCountMap.set(event.aggregateType, currentAggCount + 1);
      } else {
        aggregateCountMap.set(event.aggregateType, 1);
      }

      // 时间统计
      const eventDate = new Date(event.occurredAt);
      if (eventDate >= todayStart) {
        eventsToday++;
      }
      if (eventDate >= weekStart) {
        eventsThisWeek++;
      }
      if (eventDate >= monthStart) {
        eventsThisMonth++;
      }

      // 日期范围
      if (oldestDate === '' || event.occurredAt < oldestDate) {
        oldestDate = event.occurredAt;
      }
      if (newestDate === '' || event.occurredAt > newestDate) {
        newestDate = event.occurredAt;
      }
    }

    // 转换为数组
    const eventsByType: EventTypeStats[] = [];
    typeCountMap.forEach((count: number, eventType: string) => {
      eventsByType.push(EventSourcingUtils.createEventTypeStats(eventType, count));
    });

    const eventsByAggregate: AggregateTypeStats[] = [];
    aggregateCountMap.forEach((count: number, aggregateType: string) => {
      eventsByAggregate.push(EventSourcingUtils.createAggregateTypeStats(aggregateType, count));
    });

    // 计算平均每天事件数
    let averageEventsPerDay = 0;
    if (oldestDate !== '' && events.length > 0) {
      const oldestDateTime = new Date(oldestDate).getTime();
      const nowTime = now.getTime();
      const daysDiff = Math.max(1, Math.ceil((nowTime - oldestDateTime) / (24 * 60 * 60 * 1000)));
      averageEventsPerDay = Math.round((events.length / daysDiff) * 100) / 100;
    }

    const result: EventStoreStats = {
      totalEvents: events.length,
      eventsByType: eventsByType,
      eventsByAggregate: eventsByAggregate,
      eventsToday: eventsToday,
      eventsThisWeek: eventsThisWeek,
      eventsThisMonth: eventsThisMonth,
      averageEventsPerDay: averageEventsPerDay,
      oldestEventDate: oldestDate,
      newestEventDate: newestDate
    };

    return result;
  }

  /**
   * 创建事件变更记录
   */
  static createEventChange(field: string, oldValue: string, newValue: string): EventChange {
    const result: EventChange = {
      field: field,
      oldValue: oldValue,
      newValue: newValue
    };
    return result;
  }

  /**
   * 创建空的事件存储统计
   */
  static createEmptyStats(): EventStoreStats {
    const result: EventStoreStats = {
      totalEvents: 0,
      eventsByType: [],
      eventsByAggregate: [],
      eventsToday: 0,
      eventsThisWeek: 0,
      eventsThisMonth: 0,
      averageEventsPerDay: 0,
      oldestEventDate: '',
      newestEventDate: ''
    };
    return result;
  }

  // ==================== 核心模型集成方法 ====================

  /**
   * 从Bill对象创建创建事件
   * @param bill 账单对象
   */
  static createEventFromBill(bill: Bill): DomainEvent {
    const billJson = JSON.stringify(bill.toJSON());
    return EventSourcingUtils.createBillCreatedEvent(
      bill.userId,
      bill.billId,
      billJson
    );
  }

  /**
   * 从两个Bill对象创建更新事件（记录变更）
   * @param oldBill 旧账单
   * @param newBill 新账单
   * @param version 版本号
   */
  static createUpdateEventFromBills(
    oldBill: Bill,
    newBill: Bill,
    version: number
  ): DomainEvent {
    const changes: EventChange[] = [];

    if (oldBill.amount !== newBill.amount) {
      changes.push(EventSourcingUtils.createEventChange(
        'amount',
        oldBill.amount.toString(),
        newBill.amount.toString()
      ));
    }

    if (oldBill.categoryId !== newBill.categoryId) {
      changes.push(EventSourcingUtils.createEventChange(
        'categoryId',
        oldBill.categoryId.toString(),
        newBill.categoryId.toString()
      ));
    }

    if (oldBill.accountId !== newBill.accountId) {
      changes.push(EventSourcingUtils.createEventChange(
        'accountId',
        oldBill.accountId.toString(),
        newBill.accountId.toString()
      ));
    }

    if (oldBill.note !== newBill.note) {
      changes.push(EventSourcingUtils.createEventChange(
        'note',
        oldBill.note,
        newBill.note
      ));
    }

    if (oldBill.transactionDate !== newBill.transactionDate) {
      changes.push(EventSourcingUtils.createEventChange(
        'transactionDate',
        oldBill.transactionDate,
        newBill.transactionDate
      ));
    }

    if (oldBill.type !== newBill.type) {
      changes.push(EventSourcingUtils.createEventChange(
        'type',
        oldBill.type,
        newBill.type
      ));
    }

    const changesJson = JSON.stringify(changes);
    return EventSourcingUtils.createBillUpdatedEvent(
      newBill.userId,
      newBill.billId,
      version,
      changesJson
    );
  }

  /**
   * 从Category对象创建事件
   * @param category 分类对象
   * @param eventType 事件类型
   * @param version 版本号
   */
  static createEventFromCategory(
    category: Category,
    eventType: string,
    version: number = 1
  ): DomainEvent {
    const categoryJson = JSON.stringify(category.toJSON());
    const event = new DomainEvent(
      '',
      eventType,
      AGGREGATE_TYPE_CATEGORY,
      category.categoryId,
      category.userId,
      version,
      categoryJson,
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(event.eventId, category.userId);
    event.setMetadata(metadata);
    return event;
  }

  /**
   * 从Account对象创建事件
   * @param account 账户对象
   * @param eventType 事件类型
   * @param version 版本号
   */
  static createEventFromAccount(
    account: Account,
    eventType: string,
    version: number = 1
  ): DomainEvent {
    const accountJson = JSON.stringify(account.toJSON());
    const event = new DomainEvent(
      '',
      eventType,
      AGGREGATE_TYPE_ACCOUNT,
      account.accountId,
      account.userId,
      version,
      accountJson,
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(event.eventId, account.userId);
    event.setMetadata(metadata);
    return event;
  }

  /**
   * 从Budget对象创建事件
   * @param budget 预算对象
   * @param eventType 事件类型
   * @param version 版本号
   */
  static createEventFromBudget(
    budget: Budget,
    eventType: string,
    version: number = 1
  ): DomainEvent {
    const budgetJson = JSON.stringify(budget.toJSON());
    const event = new DomainEvent(
      '',
      eventType,
      AGGREGATE_TYPE_BUDGET,
      budget.budgetId,
      budget.userId,
      version,
      budgetJson,
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(event.eventId, budget.userId);
    event.setMetadata(metadata);
    return event;
  }

  /**
   * 创建预算超支事件
   * @param budget 预算对象
   * @param currentSpent 当前支出
   * @param version 版本号
   */
  static createBudgetExceededEvent(
    budget: Budget,
    currentSpent: number,
    version: number
  ): DomainEvent {
    const exceedAmount = currentSpent - budget.amount;
    const exceedPercent = budget.amount > 0 ? (exceedAmount / budget.amount) * 100 : 0;

    const payloadObj: BudgetExceededPayload = {
      budgetId: budget.budgetId,
      categoryId: budget.categoryId,
      budgetAmount: budget.amount,
      currentSpent: currentSpent,
      exceedAmount: exceedAmount,
      exceedPercent: Math.round(exceedPercent * 100) / 100,
      occurredAt: new Date().toISOString()
    };

    const event = new DomainEvent(
      '',
      EVENT_TYPE_BUDGET_EXCEEDED,
      AGGREGATE_TYPE_BUDGET,
      budget.budgetId,
      budget.userId,
      version,
      JSON.stringify(payloadObj),
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(event.eventId, budget.userId);
    event.setMetadata(metadata);
    return event;
  }

  /**
   * 创建账户余额变更事件
   * @param account 账户对象
   * @param oldBalance 旧余额
   * @param newBalance 新余额
   * @param reason 变更原因
   * @param version 版本号
   */
  static createAccountBalanceChangedEvent(
    account: Account,
    oldBalance: number,
    newBalance: number,
    reason: string,
    version: number
  ): DomainEvent {
    const payloadObj: AccountBalanceChangedPayload = {
      accountId: account.accountId,
      oldBalance: oldBalance,
      newBalance: newBalance,
      changeAmount: newBalance - oldBalance,
      reason: reason,
      occurredAt: new Date().toISOString()
    };

    const event = new DomainEvent(
      '',
      EVENT_TYPE_ACCOUNT_BALANCE_CHANGED,
      AGGREGATE_TYPE_ACCOUNT,
      account.accountId,
      account.userId,
      version,
      JSON.stringify(payloadObj),
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(event.eventId, account.userId);
    event.setMetadata(metadata);
    return event;
  }

  /**
   * 从事件重建Bill对象
   * @param events 事件列表（按版本顺序）
   */
  static rebuildBillFromEvents(events: DomainEvent[]): Bill | null {
    if (events.length === 0) {
      return null;
    }

    let bill: Bill | null = null;

    for (let i = 0; i < events.length; i++) {
      const event = events[i];

      if (event.eventType === EVENT_TYPE_BILL_CREATED) {
        try {
          const billJson = JSON.parse(event.payloadJson) as BillJSON;
          bill = Bill.fromJSON(billJson);
        } catch (e) {
          return null;
        }
      } else if (event.eventType === EVENT_TYPE_BILL_UPDATED && bill !== null) {
        try {
          const changes = JSON.parse(event.payloadJson) as EventChange[];
          for (let j = 0; j < changes.length; j++) {
            const change = changes[j];
            if (change.field === 'amount') {
              bill.amount = parseFloat(change.newValue);
            } else if (change.field === 'categoryId') {
              bill.categoryId = parseInt(change.newValue);
            } else if (change.field === 'accountId') {
              bill.accountId = parseInt(change.newValue);
            } else if (change.field === 'note') {
              bill.note = change.newValue;
            } else if (change.field === 'transactionDate') {
              bill.transactionDate = change.newValue;
            } else if (change.field === 'type') {
              if (change.newValue === 'income' || change.newValue === 'expense') {
                bill.type = change.newValue;
              }
            }
          }
        } catch (e) {
          // 忽略解析错误，继续处理
        }
      } else if (event.eventType === EVENT_TYPE_BILL_DELETED && bill !== null) {
        bill.isDeleted = 1;
      } else if (event.eventType === EVENT_TYPE_BILL_RESTORED && bill !== null) {
        bill.isDeleted = 0;
      }
    }

    return bill;
  }

  /**
   * 创建Bill快照
   * @param bill 账单对象
   * @param version 版本号
   */
  static createBillSnapshot(bill: Bill, version: number): AggregateSnapshot {
    const billJson = JSON.stringify(bill.toJSON());
    return new AggregateSnapshot(
      0,
      AGGREGATE_TYPE_BILL,
      bill.billId,
      version,
      billJson,
      ''
    );
  }

  /**
   * 创建Category快照
   * @param category 分类对象
   * @param version 版本号
   */
  static createCategorySnapshot(category: Category, version: number): AggregateSnapshot {
    const categoryJson = JSON.stringify(category.toJSON());
    return new AggregateSnapshot(
      0,
      AGGREGATE_TYPE_CATEGORY,
      category.categoryId,
      version,
      categoryJson,
      ''
    );
  }

  /**
   * 创建账单创建命令
   * @param userId 用户ID
   * @param billData 账单数据
   */
  static createCreateBillCommand(userId: number, billData: BillJSON): Command {
    const command = new Command(
      '',
      'CreateBill',
      AGGREGATE_TYPE_BILL,
      0,
      userId,
      JSON.stringify(billData),
      COMMAND_STATUS_PENDING,
      '',
      0,
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(command.commandId, userId);
    command.setMetadata(metadata);
    return command;
  }

  /**
   * 创建账单更新命令
   * @param userId 用户ID
   * @param billId 账单ID
   * @param billData 账单数据
   * @param expectedVersion 期望版本号
   */
  static createUpdateBillCommand(
    userId: number,
    billId: number,
    billData: BillJSON,
    expectedVersion: number
  ): Command {
    const command = new Command(
      '',
      'UpdateBill',
      AGGREGATE_TYPE_BILL,
      billId,
      userId,
      JSON.stringify(billData),
      COMMAND_STATUS_PENDING,
      '',
      expectedVersion,
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(command.commandId, userId);
    command.setMetadata(metadata);
    return command;
  }

  /**
   * 创建账单删除命令
   * @param userId 用户ID
   * @param billId 账单ID
   * @param reason 删除原因
   * @param expectedVersion 期望版本号
   */
  static createDeleteBillCommand(
    userId: number,
    billId: number,
    reason: string,
    expectedVersion: number
  ): Command {
    const payloadObj: DeleteBillPayload = {
      billId: billId,
      reason: reason
    };

    const command = new Command(
      '',
      'DeleteBill',
      AGGREGATE_TYPE_BILL,
      billId,
      userId,
      JSON.stringify(payloadObj),
      COMMAND_STATUS_PENDING,
      '',
      expectedVersion,
      '',
      '',
      ''
    );
    const metadata = EventSourcingUtils.createDefaultMetadata(command.commandId, userId);
    command.setMetadata(metadata);
    return command;
  }

  /**
   * 根据聚合类型获取事件列表
   * @param events 所有事件
   * @param aggregateType 聚合类型
   * @param aggregateId 聚合ID
   */
  static filterEventsByAggregate(
    events: DomainEvent[],
    aggregateType: string,
    aggregateId: number
  ): DomainEvent[] {
    const filtered: DomainEvent[] = [];
    for (let i = 0; i < events.length; i++) {
      const event = events[i];
      if (event.aggregateType === aggregateType && event.aggregateId === aggregateId) {
        filtered.push(event);
      }
    }
    // 按版本排序
    filtered.sort((a: DomainEvent, b: DomainEvent) => a.version - b.version);
    return filtered;
  }

  /**
   * 获取用户的所有事件
   * @param events 所有事件
   * @param userId 用户ID
   */
  static filterEventsByUser(events: DomainEvent[], userId: number): DomainEvent[] {
    const filtered: DomainEvent[] = [];
    for (let i = 0; i < events.length; i++) {
      const event = events[i];
      if (event.userId === userId) {
        filtered.push(event);
      }
    }
    return filtered;
  }

  /**
   * 获取指定时间范围内的事件
   * @param events 所有事件
   * @param startDate 开始日期
   * @param endDate 结束日期
   */
  static filterEventsByDateRange(
    events: DomainEvent[],
    startDate: string,
    endDate: string
  ): DomainEvent[] {
    const filtered: DomainEvent[] = [];
    for (let i = 0; i < events.length; i++) {
      const event = events[i];
      if (event.occurredAt >= startDate && event.occurredAt <= endDate) {
        filtered.push(event);
      }
    }
    return filtered;
  }

  /**
   * 获取聚合的当前版本号
   * @param events 事件列表
   * @param aggregateType 聚合类型
   * @param aggregateId 聚合ID
   */
  static getCurrentVersion(
    events: DomainEvent[],
    aggregateType: string,
    aggregateId: number
  ): number {
    let maxVersion = 0;
    for (let i = 0; i < events.length; i++) {
      const event = events[i];
      if (event.aggregateType === aggregateType && event.aggregateId === aggregateId) {
        if (event.version > maxVersion) {
          maxVersion = event.version;
        }
      }
    }
    return maxVersion;
  }
}
