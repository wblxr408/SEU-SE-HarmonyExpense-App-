/**
 * DAO通用辅助类
 * 提供所有DAO共用的工具方法，减少代码重复
 */
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { Bill } from '../model/Bill';
import { AnomalyRecord, UserSpendingBaseline } from '../model/AnomalyDetection';
import { DomainEvent, Command, AggregateSnapshot, ReadModel } from '../model/EventSourcing';
import {
  SharedLedger,
  LedgerMember,
  LedgerInvitation,
  SharedBill,
  ApprovalRecord,
  MemberActivity
} from '../model/SharedLedger';
import { SmartCategoryTraining, SmartCategoryRule } from '../model/SmartCategory';
import { OCRRecognitionRecord } from '../model/OCRRecognition';

export class DAOHelper {
  /**
   * 统一错误处理
   * 将各种类型的错误转换为标准Error对象
   * 
   * @param message 错误消息前缀
   * @param err 原始错误对象
   * @returns 标准Error对象
   */
  static toError(message: string, err: Error | string | object): Error {
    let details = '';
    try {
      if (typeof err === 'string') {
        details = err;
      } else if (err instanceof Error) {
        details = err.message;
      } else {
        details = JSON.stringify(err);
      }
    } catch (_) {
      details = String(err);
    }
    return new Error(`${message}${details ? ' -> ' + details : ''}`);
  }

  /**
   * 统一事务处理
   * 自动处理事务的开启、提交和回滚
   * 
   * @param fn 要在事务中执行的函数
   * @param errorPrefix 错误消息前缀
   */
  static async transaction(fn: () => Promise<void>, errorPrefix: string = '[DAO]'): Promise<void> {
    const store = DatabaseManager.getDatabase();
    await store.beginTransaction();
    try {
      await fn();
      await store.commit();
    } catch (error) {
      await store.rollBack();
      throw DAOHelper.toError(`${errorPrefix} 事务失败`, error);
    }
  }

  /**
   * 检查记录是否存在
   * 
   * @param tableName 表名
   * @param idColumn 主键列名
   * @param id 主键值
   * @returns 是否存在
   */
  static async exists(tableName: string, idColumn: string, id: number): Promise<boolean> {
    const sql = `SELECT 1 FROM ${tableName} WHERE ${idColumn} = ? AND is_deleted = 0`;
    const store = DatabaseManager.getDatabase();
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.querySql(sql, [id]);
      return rs.goToNextRow();
    } finally {
      rs?.close();
    }
  }

  /**
   * 软删除记录
   * 
   * @param tableName 表名
   * @param idColumn 主键列名
   * @param id 主键值
   * @param errorPrefix 错误消息前缀
   */
  static async softDelete(
    tableName: string,
    idColumn: string,
    id: number,
    errorPrefix: string = '[DAO]'
  ): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `UPDATE ${tableName} SET is_deleted = 1, updated_at = ? WHERE ${idColumn} = ?`;
    try {
      await store.executeSql(sql, [now, id]);
      console.log(`${errorPrefix} 软删除成功: ${idColumn}=${id}`);
    } catch (error) {
      throw DAOHelper.toError(`${errorPrefix} 软删除失败`, error);
    }
  }

  /**
   * 恢复软删除的记录
   * 
   * @param tableName 表名
   * @param idColumn 主键列名
   * @param id 主键值
   * @param errorPrefix 错误消息前缀
   */
  static async restore(
    tableName: string,
    idColumn: string,
    id: number,
    errorPrefix: string = '[DAO]'
  ): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `UPDATE ${tableName} SET is_deleted = 0, updated_at = ? WHERE ${idColumn} = ?`;
    try {
      await store.executeSql(sql, [now, id]);
      console.log(`${errorPrefix} 恢复成功: ${idColumn}=${id}`);
    } catch (error) {
      throw DAOHelper.toError(`${errorPrefix} 恢复失败`, error);
    }
  }

  /**
   * 硬删除记录（物理删除）
   * 
   * @param tableName 表名
   * @param idColumn 主键列名
   * @param id 主键值
   * @param errorPrefix 错误消息前缀
   */
  static async hardDelete(
    tableName: string,
    idColumn: string,
    id: number,
    errorPrefix: string = '[DAO]'
  ): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `DELETE FROM ${tableName} WHERE ${idColumn} = ?`;
    try {
      await store.executeSql(sql, [id]);
      console.log(`${errorPrefix} 硬删除成功: ${idColumn}=${id}`);
    } catch (error) {
      throw DAOHelper.toError(`${errorPrefix} 硬删除失败`, error);
    }
  }

  /**
   * 获取当前时间戳（ISO格式）
   * 
   * @returns ISO格式的时间字符串
   */
  static now(): string {
    return new Date().toISOString();
  }

  /**
   * 安全关闭ResultSet
   * 
   * @param resultSet 结果集
   */
  static closeResultSet(resultSet: relationalStore.ResultSet | null): void {
    try {
      resultSet?.close();
    } catch (error) {
      console.warn('[DAOHelper] 关闭ResultSet失败:', error);
    }
  }

  /**
   * 从ResultSet中安全获取Long值
   * 
   * @param resultSet 结果集
   * @param columnName 列名
   * @param defaultValue 默认值
   * @returns Long值
   */
  static getLong(resultSet: relationalStore.ResultSet, columnName: string, defaultValue: number = 0): number {
    try {
      const index = resultSet.getColumnIndex(columnName);
      return resultSet.getLong(index);
    } catch (error) {
      console.warn(`[DAOHelper] 获取Long值失败: ${columnName}`, error);
      return defaultValue;
    }
  }

  /**
   * 从ResultSet中安全获取String值
   * 
   * @param resultSet 结果集
   * @param columnName 列名
   * @param defaultValue 默认值
   * @returns String值
   */
  static getString(resultSet: relationalStore.ResultSet, columnName: string, defaultValue: string = ''): string {
    try {
      const index = resultSet.getColumnIndex(columnName);
      return resultSet.getString(index);
    } catch (error) {
      console.warn(`[DAOHelper] 获取String值失败: ${columnName}`, error);
      return defaultValue;
    }
  }

  /**
   * 从ResultSet中安全获取Double值
   *
   * @param resultSet 结果集
   * @param columnName 列名
   * @param defaultValue 默认值
   * @returns Double值
   */
  static getDouble(resultSet: relationalStore.ResultSet, columnName: string, defaultValue: number = 0): number {
    try {
      const index = resultSet.getColumnIndex(columnName);
      return resultSet.getDouble(index);
    } catch (error) {
      console.warn(`[DAOHelper] 获取Double值失败: ${columnName}`, error);
      return defaultValue;
    }
  }

  /**
   * 安全获取数字值（兼容null）
   */
  static getNumberValue(resultSet: relationalStore.ResultSet, columnName: string): number {
    try {
      const index = resultSet.getColumnIndex(columnName);
      if (resultSet.isColumnNull(index)) {
        return 0;
      }
      return resultSet.getDouble(index);
    } catch (error) {
      console.warn(`[DAOHelper] 获取数字值失败: ${columnName}`, error);
      return 0;
    }
  }

  /**
   * 安全获取字符串值（兼容null）
   */
  static getStringValue(resultSet: relationalStore.ResultSet, columnName: string): string {
    try {
      const index = resultSet.getColumnIndex(columnName);
      if (resultSet.isColumnNull(index)) {
        return '';
      }
      return resultSet.getString(index);
    } catch (error) {
      console.warn(`[DAOHelper] 获取字符串值失败: ${columnName}`, error);
      return '';
    }
  }

  // ==================== 模型转换方法 ====================

  /**
   * 转换为AnomalyRecord
   */
  static convertToAnomalyRecord(resultSet: relationalStore.ResultSet): AnomalyRecord {
    const record = new AnomalyRecord();
    record.anomalyId = DAOHelper.getNumberValue(resultSet, 'anomaly_id');
    record.userId = DAOHelper.getNumberValue(resultSet, 'user_id');
    record.billId = DAOHelper.getNumberValue(resultSet, 'bill_id');
    record.anomalyType = DAOHelper.getStringValue(resultSet, 'anomaly_type');
    record.severity = DAOHelper.getStringValue(resultSet, 'severity');
    record.algorithm = DAOHelper.getStringValue(resultSet, 'algorithm');
    record.score = DAOHelper.getNumberValue(resultSet, 'score');
    record.threshold = DAOHelper.getNumberValue(resultSet, 'threshold');
    record.expectedValue = DAOHelper.getNumberValue(resultSet, 'expected_value');
    record.actualValue = DAOHelper.getNumberValue(resultSet, 'actual_value');
    record.deviation = DAOHelper.getNumberValue(resultSet, 'deviation');
    record.description = DAOHelper.getStringValue(resultSet, 'description');
    record.isAcknowledged = DAOHelper.getNumberValue(resultSet, 'is_acknowledged');
    record.acknowledgedAt = DAOHelper.getStringValue(resultSet, 'acknowledged_at');
    record.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    record.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    record.isDeleted = DAOHelper.getNumberValue(resultSet, 'is_deleted');
    return record;
  }

  /**
   * 转换为Bill
   */
  static convertToBill(resultSet: relationalStore.ResultSet): Bill {
    const bill = new Bill();
    bill.billId = DAOHelper.getNumberValue(resultSet, 'bill_id');
    bill.userId = DAOHelper.getNumberValue(resultSet, 'user_id');
    bill.accountId = DAOHelper.getNumberValue(resultSet, 'account_id');
    bill.categoryId = DAOHelper.getNumberValue(resultSet, 'category_id');
    bill.amount = DAOHelper.getNumberValue(resultSet, 'amount');
    bill.note = DAOHelper.getStringValue(resultSet, 'note');
    bill.transactionDate = DAOHelper.getStringValue(resultSet, 'transaction_date');
    const typeValue = DAOHelper.getStringValue(resultSet, 'type');
    bill.type = (typeValue === 'income' || typeValue === 'expense') ? typeValue : 'expense';
    bill.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    bill.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    bill.isDeleted = DAOHelper.getNumberValue(resultSet, 'is_deleted');
    return bill;
  }

  /**
   * 转换为UserSpendingBaseline
   */
  static convertToUserSpendingBaseline(resultSet: relationalStore.ResultSet): UserSpendingBaseline {
    const baseline = new UserSpendingBaseline();
    baseline.baselineId = DAOHelper.getNumberValue(resultSet, 'baseline_id');
    baseline.userId = DAOHelper.getNumberValue(resultSet, 'user_id');
    baseline.avgDailySpending = DAOHelper.getNumberValue(resultSet, 'avg_daily_spending');
    baseline.stdDeviation = DAOHelper.getNumberValue(resultSet, 'std_deviation');
    baseline.maxDailySpending = DAOHelper.getNumberValue(resultSet, 'max_daily_spending');
    baseline.minDailySpending = DAOHelper.getNumberValue(resultSet, 'min_daily_spending');
    baseline.avgTransactionFrequency = DAOHelper.getNumberValue(resultSet, 'avg_transaction_frequency');
    baseline.totalTransactions = DAOHelper.getNumberValue(resultSet, 'total_transactions');
    baseline.analysisStartDate = DAOHelper.getStringValue(resultSet, 'analysis_start_date');
    baseline.analysisEndDate = DAOHelper.getStringValue(resultSet, 'analysis_end_date');
    baseline.lastUpdatedAt = DAOHelper.getStringValue(resultSet, 'last_updated_at');
    baseline.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    baseline.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    return baseline;
  }

  /**
   * 转换为DomainEvent
   */
  static convertToDomainEvent(resultSet: relationalStore.ResultSet): DomainEvent {
    const event = new DomainEvent();
    event.eventId = DAOHelper.getStringValue(resultSet, 'event_id');
    event.eventType = DAOHelper.getStringValue(resultSet, 'event_type');
    event.aggregateType = DAOHelper.getStringValue(resultSet, 'aggregate_type');
    event.aggregateId = DAOHelper.getNumberValue(resultSet, 'aggregate_id');
    event.userId = DAOHelper.getNumberValue(resultSet, 'user_id');
    event.version = DAOHelper.getNumberValue(resultSet, 'version');
    event.payloadJson = DAOHelper.getStringValue(resultSet, 'payload_json');
    event.metadataJson = DAOHelper.getStringValue(resultSet, 'metadata_json');
    event.occurredAt = DAOHelper.getStringValue(resultSet, 'occurred_at');
    event.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    return event;
  }

  /**
   * 转换为Command
   */
  static convertToCommand(resultSet: relationalStore.ResultSet): Command {
    const command = new Command();
    command.commandId = DAOHelper.getStringValue(resultSet, 'command_id');
    command.commandType = DAOHelper.getStringValue(resultSet, 'command_type');
    command.aggregateType = DAOHelper.getStringValue(resultSet, 'aggregate_type');
    command.aggregateId = DAOHelper.getNumberValue(resultSet, 'aggregate_id');
    command.userId = DAOHelper.getNumberValue(resultSet, 'user_id');
    command.payloadJson = DAOHelper.getStringValue(resultSet, 'payload_json');
    command.status = DAOHelper.getStringValue(resultSet, 'status');
    command.errorMessage = DAOHelper.getStringValue(resultSet, 'error_message');
    command.issuedAt = DAOHelper.getStringValue(resultSet, 'issued_at');
    command.processedAt = DAOHelper.getStringValue(resultSet, 'processed_at');
    command.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    command.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    return command;
  }

  /**
   * 转换为AggregateSnapshot
   */
  static convertToAggregateSnapshot(resultSet: relationalStore.ResultSet): AggregateSnapshot {
    const snapshot = new AggregateSnapshot();
    snapshot.snapshotId = DAOHelper.getNumberValue(resultSet, 'snapshot_id');
    snapshot.aggregateType = DAOHelper.getStringValue(resultSet, 'aggregate_type');
    snapshot.aggregateId = DAOHelper.getNumberValue(resultSet, 'aggregate_id');
    snapshot.version = DAOHelper.getNumberValue(resultSet, 'version');
    snapshot.stateJson = DAOHelper.getStringValue(resultSet, 'state_json');
    snapshot.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    return snapshot;
  }

  /**
   * 转换为ReadModel
   */
  static convertToReadModel(resultSet: relationalStore.ResultSet): ReadModel {
    const model = new ReadModel();
    model.modelId = DAOHelper.getNumberValue(resultSet, 'model_id');
    model.modelType = DAOHelper.getStringValue(resultSet, 'model_type');
    model.aggregateId = DAOHelper.getNumberValue(resultSet, 'aggregate_id');
    model.version = DAOHelper.getNumberValue(resultSet, 'version');
    model.dataJson = DAOHelper.getStringValue(resultSet, 'data_json');
    model.lastEventId = DAOHelper.getStringValue(resultSet, 'last_event_id');
    model.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    model.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    return model;
  }

  /**
   * 转换为SharedLedger
   */
  static convertToSharedLedger(resultSet: relationalStore.ResultSet): SharedLedger {
    const ledger = new SharedLedger();
    ledger.ledgerId = DAOHelper.getNumberValue(resultSet, 'ledger_id');
    ledger.name = DAOHelper.getStringValue(resultSet, 'name');
    ledger.description = DAOHelper.getStringValue(resultSet, 'description');
    ledger.type = DAOHelper.getStringValue(resultSet, 'type');
    ledger.ownerId = DAOHelper.getNumberValue(resultSet, 'owner_id');
    ledger.ownerName = DAOHelper.getStringValue(resultSet, 'owner_name');
    ledger.currency = DAOHelper.getStringValue(resultSet, 'currency');
    ledger.icon = DAOHelper.getStringValue(resultSet, 'icon');
    ledger.color = DAOHelper.getStringValue(resultSet, 'color');
    ledger.memberCount = DAOHelper.getNumberValue(resultSet, 'member_count');
    ledger.settingsJson = DAOHelper.getStringValue(resultSet, 'settings_json');
    ledger.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    ledger.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    ledger.isDeleted = DAOHelper.getNumberValue(resultSet, 'is_deleted');
    return ledger;
  }

  /**
   * 转换为LedgerMember
   */
  static convertToLedgerMember(resultSet: relationalStore.ResultSet): LedgerMember {
    const member = new LedgerMember();
    member.memberId = DAOHelper.getNumberValue(resultSet, 'member_id');
    member.ledgerId = DAOHelper.getNumberValue(resultSet, 'ledger_id');
    member.userId = DAOHelper.getNumberValue(resultSet, 'user_id');
    member.userName = DAOHelper.getStringValue(resultSet, 'user_name');
    member.role = DAOHelper.getStringValue(resultSet, 'role');
    member.joinedAt = DAOHelper.getStringValue(resultSet, 'joined_at');
    member.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    member.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    member.isDeleted = DAOHelper.getNumberValue(resultSet, 'is_deleted');
    return member;
  }

  /**
   * 转换为LedgerInvitation
   */
  static convertToLedgerInvitation(resultSet: relationalStore.ResultSet): LedgerInvitation {
    const invitation = new LedgerInvitation();
    invitation.invitationId = DAOHelper.getNumberValue(resultSet, 'invitation_id');
    invitation.ledgerId = DAOHelper.getNumberValue(resultSet, 'ledger_id');
    invitation.inviterId = DAOHelper.getNumberValue(resultSet, 'inviter_id');
    invitation.inviterName = DAOHelper.getStringValue(resultSet, 'inviter_name');
    invitation.inviteeId = DAOHelper.getNumberValue(resultSet, 'invitee_id');
    invitation.inviteeName = DAOHelper.getStringValue(resultSet, 'invitee_name');
    invitation.role = DAOHelper.getStringValue(resultSet, 'role');
    invitation.status = DAOHelper.getStringValue(resultSet, 'status');
    invitation.expiresAt = DAOHelper.getStringValue(resultSet, 'expires_at');
    invitation.respondedAt = DAOHelper.getStringValue(resultSet, 'responded_at');
    invitation.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    invitation.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    return invitation;
  }

  /**
   * 转换为SharedBill
   */
  static convertToSharedBill(resultSet: relationalStore.ResultSet): SharedBill {
    const bill = new SharedBill();
    bill.billId = DAOHelper.getNumberValue(resultSet, 'bill_id');
    bill.ledgerId = DAOHelper.getNumberValue(resultSet, 'ledger_id');
    bill.creatorId = DAOHelper.getNumberValue(resultSet, 'creator_id');
    bill.creatorName = DAOHelper.getStringValue(resultSet, 'creator_name');
    bill.amount = DAOHelper.getNumberValue(resultSet, 'amount');
    bill.description = DAOHelper.getStringValue(resultSet, 'description');
    bill.categoryId = DAOHelper.getNumberValue(resultSet, 'category_id');
    bill.categoryName = DAOHelper.getStringValue(resultSet, 'category_name');
    bill.splitMethod = DAOHelper.getStringValue(resultSet, 'split_method');
    bill.splitsJson = DAOHelper.getStringValue(resultSet, 'splits_json');
    bill.attachments = DAOHelper.getStringValue(resultSet, 'attachments');
    bill.status = DAOHelper.getStringValue(resultSet, 'status');
    bill.version = DAOHelper.getNumberValue(resultSet, 'version');
    bill.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    bill.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    bill.isDeleted = DAOHelper.getNumberValue(resultSet, 'is_deleted');
    return bill;
  }

  /**
   * 转换为ApprovalRecord
   */
  static convertToApprovalRecord(resultSet: relationalStore.ResultSet): ApprovalRecord {
    const record = new ApprovalRecord();
    record.recordId = DAOHelper.getNumberValue(resultSet, 'record_id');
    record.billId = DAOHelper.getNumberValue(resultSet, 'bill_id');
    record.approverId = DAOHelper.getNumberValue(resultSet, 'approver_id');
    record.approverName = DAOHelper.getStringValue(resultSet, 'approver_name');
    record.status = DAOHelper.getStringValue(resultSet, 'status');
    record.comments = DAOHelper.getStringValue(resultSet, 'comments');
    record.approvedAt = DAOHelper.getStringValue(resultSet, 'approved_at');
    record.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    record.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    return record;
  }

  /**
   * 转换为MemberActivity
   */
  static convertToMemberActivity(resultSet: relationalStore.ResultSet): MemberActivity {
    const activity = new MemberActivity();
    activity.activityId = DAOHelper.getNumberValue(resultSet, 'activity_id');
    activity.ledgerId = DAOHelper.getNumberValue(resultSet, 'ledger_id');
    activity.userId = DAOHelper.getNumberValue(resultSet, 'user_id');
    activity.userName = DAOHelper.getStringValue(resultSet, 'user_name');
    activity.activityType = DAOHelper.getStringValue(resultSet, 'activity_type');
    activity.description = DAOHelper.getStringValue(resultSet, 'description');
    activity.metadataJson = DAOHelper.getStringValue(resultSet, 'metadata_json');
    activity.occurredAt = DAOHelper.getStringValue(resultSet, 'occurred_at');
    return activity;
  }

  /**
   * 转换为SmartCategoryTraining
   */
  static convertToSmartCategoryTraining(resultSet: relationalStore.ResultSet): SmartCategoryTraining {
    const training = new SmartCategoryTraining();
    training.recordId = DAOHelper.getNumberValue(resultSet, 'record_id');
    training.userId = DAOHelper.getNumberValue(resultSet, 'user_id');
    training.billNote = DAOHelper.getStringValue(resultSet, 'bill_note');
    training.billAmount = DAOHelper.getNumberValue(resultSet, 'bill_amount');
    training.actualCategoryId = DAOHelper.getNumberValue(resultSet, 'actual_category_id');
    training.actualCategoryName = DAOHelper.getStringValue(resultSet, 'actual_category_name');
    training.predictedCategoryId = DAOHelper.getNumberValue(resultSet, 'predicted_category_id');
    training.predictedCategoryName = DAOHelper.getStringValue(resultSet, 'predicted_category_name');
    training.confidence = DAOHelper.getNumberValue(resultSet, 'confidence');
    training.isCorrect = DAOHelper.getNumberValue(resultSet, 'is_correct');
    training.keywordsMatched = DAOHelper.getStringValue(resultSet, 'keywords_matched');
    training.trainingType = DAOHelper.getStringValue(resultSet, 'training_type');
    training.modelVersion = DAOHelper.getStringValue(resultSet, 'model_version');
    training.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    training.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    training.isDeleted = DAOHelper.getNumberValue(resultSet, 'is_deleted');
    return training;
  }

  /**
   * 转换为SmartCategoryRule
   */
  static convertToSmartCategoryRule(resultSet: relationalStore.ResultSet): SmartCategoryRule {
    const rule = new SmartCategoryRule();
    rule.ruleId = DAOHelper.getNumberValue(resultSet, 'rule_id');
    rule.userId = DAOHelper.getNumberValue(resultSet, 'user_id');
    rule.ruleName = DAOHelper.getStringValue(resultSet, 'rule_name');
    rule.categoryId = DAOHelper.getNumberValue(resultSet, 'category_id');
    rule.categoryName = DAOHelper.getStringValue(resultSet, 'category_name');
    rule.ruleType = DAOHelper.getStringValue(resultSet, 'rule_type');
    rule.pattern = DAOHelper.getStringValue(resultSet, 'pattern');
    rule.keywords = DAOHelper.getStringValue(resultSet, 'keywords');
    rule.amountMin = DAOHelper.getNumberValue(resultSet, 'amount_min');
    rule.amountMax = DAOHelper.getNumberValue(resultSet, 'amount_max');
    rule.priority = DAOHelper.getNumberValue(resultSet, 'priority');
    rule.isActive = DAOHelper.getNumberValue(resultSet, 'is_active');
    rule.accuracy = DAOHelper.getNumberValue(resultSet, 'accuracy');
    rule.matchCount = DAOHelper.getNumberValue(resultSet, 'match_count');
    rule.lastMatchedAt = DAOHelper.getStringValue(resultSet, 'last_matched_at');
    rule.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    rule.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    rule.isDeleted = DAOHelper.getNumberValue(resultSet, 'is_deleted');
    return rule;
  }

  /**
   * 转换为OCRRecognitionRecord
   */
  static convertToOCRRecognitionRecord(resultSet: relationalStore.ResultSet): OCRRecognitionRecord {
    const record = new OCRRecognitionRecord();
    record.recordId = DAOHelper.getNumberValue(resultSet, 'record_id');
    record.userId = DAOHelper.getNumberValue(resultSet, 'user_id');
    const billId = DAOHelper.getNumberValue(resultSet, 'bill_id');
    record.billId = billId === 0 ? null : billId;
    record.imagePath = DAOHelper.getStringValue(resultSet, 'image_path');
    record.thumbnailPath = DAOHelper.getStringValue(resultSet, 'thumbnail_path');
    record.ocrProvider = DAOHelper.getStringValue(resultSet, 'ocr_provider');
    record.receiptType = DAOHelper.getStringValue(resultSet, 'receipt_type');
    record.rawText = DAOHelper.getStringValue(resultSet, 'raw_text');
    record.merchantName = DAOHelper.getStringValue(resultSet, 'merchant_name');
    const totalAmount = DAOHelper.getNumberValue(resultSet, 'total_amount');
    record.totalAmount = totalAmount === 0 ? null : totalAmount;
    record.transactionDate = DAOHelper.getStringValue(resultSet, 'transaction_date');
    record.confidenceScore = DAOHelper.getNumberValue(resultSet, 'confidence_score');
    record.structuredDataJson = DAOHelper.getStringValue(resultSet, 'structured_data_json');
    const suggestedCategoryId = DAOHelper.getNumberValue(resultSet, 'suggested_category_id');
    record.suggestedCategoryId = suggestedCategoryId === 0 ? null : suggestedCategoryId;
    record.suggestedCategoryName = DAOHelper.getStringValue(resultSet, 'suggested_category_name');
    record.isUsed = DAOHelper.getNumberValue(resultSet, 'is_used');
    record.recognitionStatus = DAOHelper.getStringValue(resultSet, 'recognition_status');
    record.errorMessage = DAOHelper.getStringValue(resultSet, 'error_message');
    record.processingTimeMs = DAOHelper.getNumberValue(resultSet, 'processing_time_ms');
    record.createdAt = DAOHelper.getStringValue(resultSet, 'created_at');
    record.updatedAt = DAOHelper.getStringValue(resultSet, 'updated_at');
    record.isDeleted = DAOHelper.getNumberValue(resultSet, 'is_deleted');
    return record;
  }
}