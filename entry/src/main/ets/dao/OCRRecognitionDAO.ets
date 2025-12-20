/**
 * OCR识别DAO - 数据访问层
 *
 * 功能：
 * 1. OCR识别记录管理
 * 2. 识别历史查询
 * 3. 识别统计分析
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { OCRRecognitionRecord } from '../model/OCRRecognition';
import { DAOHelper } from '../common/DAOHelper';

/**
 * OCR识别统计接口
 */
export interface OCRStatistics {
  totalRecords: number;
  successCount: number;
  failedCount: number;
  partialCount: number;
  avgConfidence: number;
  avgProcessingTime: number;
  totalAmount: number;
  lastRecognitionAt: string;
}

/**
 * 按票据类型统计接口
 */
export interface ReceiptTypeStatistics {
  receiptType: string;
  count: number;
  avgConfidence: number;
  totalAmount: number;
}

/**
 * 按提供商统计接口
 */
export interface ProviderStatistics {
  provider: string;
  count: number;
  successRate: number;
  avgProcessingTime: number;
}

// ==================== OCR识别记录DAO ====================

/**
 * OCR识别记录DAO
 */
export class OCRRecognitionRecordDAO {
  /**
   * 插入识别记录
   */
  static async insert(record: OCRRecognitionRecord): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const now = new Date().toISOString();
      record.createdAt = now;
      record.updatedAt = now;

      const values: relationalStore.ValuesBucket = {
        user_id: record.userId,
        bill_id: record.billId || null,
        image_path: record.imagePath,
        thumbnail_path: record.thumbnailPath || null,
        ocr_provider: record.ocrProvider,
        receipt_type: record.receiptType,
        raw_text: record.rawText,
        merchant_name: record.merchantName || null,
        total_amount: record.totalAmount || null,
        transaction_date: record.transactionDate || null,
        confidence_score: record.confidenceScore,
        structured_data_json: record.structuredDataJson || null,
        suggested_category_id: record.suggestedCategoryId || null,
        suggested_category_name: record.suggestedCategoryName || null,
        is_used: record.isUsed,
        recognition_status: record.recognitionStatus,
        error_message: record.errorMessage || null,
        processing_time_ms: record.processingTimeMs,
        created_at: record.createdAt,
        updated_at: record.updatedAt,
        is_deleted: record.isDeleted
      };

      const rowId = await store.insert(OCRRecognitionRecord.tableName, values);
      return rowId;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 插入识别记录失败', error);
    }
  }

  /**
   * 根据ID查询识别记录
   */
  static async getById(recordId: number): Promise<OCRRecognitionRecord | null> {
    try {
      const store = DatabaseManager.getDatabase();
      const predicates = new relationalStore.RdbPredicates(OCRRecognitionRecord.tableName);
      predicates.equalTo('record_id', recordId).and().equalTo('is_deleted', 0);

      const resultSet = await store.query(predicates);
      if (!resultSet || resultSet.rowCount === 0) {
        resultSet?.close();
        return null;
      }

      resultSet.goToFirstRow();
      const record = DAOHelper.convertToOCRRecognitionRecord(resultSet);
      resultSet.close();
      return record;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 查询识别记录失败', error);
    }
  }

  /**
   * 根据用户ID查询识别记录列表
   */
  static async getByUserId(
    userId: number,
    limit: number = 50,
    offset: number = 0
  ): Promise<OCRRecognitionRecord[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ? AND is_deleted = 0
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
      `;
      const resultSet = await store.querySql(sql, [userId, limit, offset]);

      const records: OCRRecognitionRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToOCRRecognitionRecord(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 查询用户识别记录失败', error);
    }
  }

  /**
   * 根据账单ID查询识别记录
   */
  static async getByBillId(billId: number): Promise<OCRRecognitionRecord[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${OCRRecognitionRecord.tableName}
        WHERE bill_id = ? AND is_deleted = 0
        ORDER BY created_at DESC
      `;
      const resultSet = await store.querySql(sql, [billId]);

      const records: OCRRecognitionRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToOCRRecognitionRecord(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 按账单查询识别记录失败', error);
    }
  }

  /**
   * 查询未使用的识别记录
   */
  static async getUnused(userId: number, limit: number = 20): Promise<OCRRecognitionRecord[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ?
          AND is_used = 0
          AND recognition_status = 'success'
          AND is_deleted = 0
        ORDER BY created_at DESC
        LIMIT ?
      `;
      const resultSet = await store.querySql(sql, [userId, limit]);

      const records: OCRRecognitionRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToOCRRecognitionRecord(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 查询未使用记录失败', error);
    }
  }

  /**
   * 根据票据类型查询
   */
  static async getByReceiptType(
    userId: number,
    receiptType: string,
    limit: number = 30
  ): Promise<OCRRecognitionRecord[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ? AND receipt_type = ? AND is_deleted = 0
        ORDER BY created_at DESC
        LIMIT ?
      `;
      const resultSet = await store.querySql(sql, [userId, receiptType, limit]);

      const records: OCRRecognitionRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToOCRRecognitionRecord(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 按票据类型查询失败', error);
    }
  }

  /**
   * 根据识别状态查询
   */
  static async getByStatus(
    userId: number,
    status: 'pending' | 'processing' | 'success' | 'partial' | 'failed',
    limit: number = 30
  ): Promise<OCRRecognitionRecord[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ? AND recognition_status = ? AND is_deleted = 0
        ORDER BY created_at DESC
        LIMIT ?
      `;
      const resultSet = await store.querySql(sql, [userId, status, limit]);

      const records: OCRRecognitionRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToOCRRecognitionRecord(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 按状态查询失败', error);
    }
  }

  /**
   * 按时间范围查询
   */
  static async getByTimeRange(
    userId: number,
    startDate: string,
    endDate: string
  ): Promise<OCRRecognitionRecord[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ?
          AND created_at >= ?
          AND created_at <= ?
          AND is_deleted = 0
        ORDER BY created_at DESC
      `;
      const resultSet = await store.querySql(sql, [userId, startDate, endDate]);

      const records: OCRRecognitionRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToOCRRecognitionRecord(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 按时间范围查询失败', error);
    }
  }

  /**
   * 搜索识别记录（按商家名称或原始文本）
   */
  static async search(
    userId: number,
    keyword: string,
    limit: number = 30
  ): Promise<OCRRecognitionRecord[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const searchPattern = `%${keyword}%`;
      const sql = `
        SELECT *
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ?
          AND (merchant_name LIKE ? OR raw_text LIKE ?)
          AND is_deleted = 0
        ORDER BY created_at DESC
        LIMIT ?
      `;
      const resultSet = await store.querySql(sql, [userId, searchPattern, searchPattern, limit]);

      const records: OCRRecognitionRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToOCRRecognitionRecord(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 搜索识别记录失败', error);
    }
  }

  /**
   * 更新识别记录
   */
  static async update(record: OCRRecognitionRecord): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      record.updatedAt = new Date().toISOString();

      const values: relationalStore.ValuesBucket = {
        bill_id: record.billId || null,
        image_path: record.imagePath,
        thumbnail_path: record.thumbnailPath || null,
        ocr_provider: record.ocrProvider,
        receipt_type: record.receiptType,
        raw_text: record.rawText,
        merchant_name: record.merchantName || null,
        total_amount: record.totalAmount || null,
        transaction_date: record.transactionDate || null,
        confidence_score: record.confidenceScore,
        structured_data_json: record.structuredDataJson || null,
        suggested_category_id: record.suggestedCategoryId || null,
        suggested_category_name: record.suggestedCategoryName || null,
        is_used: record.isUsed,
        recognition_status: record.recognitionStatus,
        error_message: record.errorMessage || null,
        processing_time_ms: record.processingTimeMs,
        updated_at: record.updatedAt
      };

      const predicates = new relationalStore.RdbPredicates(OCRRecognitionRecord.tableName);
      predicates.equalTo('record_id', record.recordId);

      const rows = await store.update(values, predicates);
      return rows > 0;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 更新识别记录失败', error);
    }
  }

  /**
   * 标记为已使用
   */
  static async markAsUsed(recordId: number, billId: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        is_used: 1,
        bill_id: billId,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(OCRRecognitionRecord.tableName);
      predicates.equalTo('record_id', recordId);

      const rows = await store.update(values, predicates);
      return rows > 0;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 标记为已使用失败', error);
    }
  }

  /**
   * 更新识别状态
   */
  static async updateStatus(
    recordId: number,
    status: 'pending' | 'processing' | 'success' | 'partial' | 'failed',
    errorMessage?: string
  ): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        recognition_status: status,
        error_message: errorMessage || null,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(OCRRecognitionRecord.tableName);
      predicates.equalTo('record_id', recordId);

      const rows = await store.update(values, predicates);
      return rows > 0;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 更新识别状态失败', error);
    }
  }

  /**
   * 获取识别统计
   */
  static async getStatistics(userId: number): Promise<OCRStatistics> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT
          COUNT(*) as total_records,
          SUM(CASE WHEN recognition_status = 'success' THEN 1 ELSE 0 END) as success_count,
          SUM(CASE WHEN recognition_status = 'failed' THEN 1 ELSE 0 END) as failed_count,
          SUM(CASE WHEN recognition_status = 'partial' THEN 1 ELSE 0 END) as partial_count,
          AVG(confidence_score) as avg_confidence,
          AVG(processing_time_ms) as avg_processing_time,
          SUM(CASE WHEN total_amount IS NOT NULL THEN total_amount ELSE 0 END) as total_amount,
          MAX(created_at) as last_recognition_at
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ? AND is_deleted = 0
      `;
      const resultSet = await store.querySql(sql, [userId]);

      let stats: OCRStatistics = {
        totalRecords: 0,
        successCount: 0,
        failedCount: 0,
        partialCount: 0,
        avgConfidence: 0,
        avgProcessingTime: 0,
        totalAmount: 0,
        lastRecognitionAt: ''
      };

      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        stats = {
          totalRecords: DAOHelper.getNumberValue(resultSet, 'total_records'),
          successCount: DAOHelper.getNumberValue(resultSet, 'success_count'),
          failedCount: DAOHelper.getNumberValue(resultSet, 'failed_count'),
          partialCount: DAOHelper.getNumberValue(resultSet, 'partial_count'),
          avgConfidence: DAOHelper.getNumberValue(resultSet, 'avg_confidence'),
          avgProcessingTime: DAOHelper.getNumberValue(resultSet, 'avg_processing_time'),
          totalAmount: DAOHelper.getNumberValue(resultSet, 'total_amount'),
          lastRecognitionAt: DAOHelper.getStringValue(resultSet, 'last_recognition_at')
        };
      }
      resultSet?.close();
      return stats;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 获取识别统计失败', error);
    }
  }

  /**
   * 按票据类型统计
   */
  static async getStatisticsByReceiptType(userId: number): Promise<ReceiptTypeStatistics[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT
          receipt_type,
          COUNT(*) as count,
          AVG(confidence_score) as avg_confidence,
          SUM(CASE WHEN total_amount IS NOT NULL THEN total_amount ELSE 0 END) as total_amount
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ? AND is_deleted = 0
        GROUP BY receipt_type
        ORDER BY count DESC
      `;
      const resultSet = await store.querySql(sql, [userId]);

      const stats: ReceiptTypeStatistics[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const stat: ReceiptTypeStatistics = {
            receiptType: DAOHelper.getStringValue(resultSet, 'receipt_type'),
            count: DAOHelper.getNumberValue(resultSet, 'count'),
            avgConfidence: DAOHelper.getNumberValue(resultSet, 'avg_confidence'),
            totalAmount: DAOHelper.getNumberValue(resultSet, 'total_amount')
          };
          stats.push(stat);
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return stats;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 按票据类型统计失败', error);
    }
  }

  /**
   * 按提供商统计
   */
  static async getStatisticsByProvider(userId: number): Promise<ProviderStatistics[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT
          ocr_provider as provider,
          COUNT(*) as count,
          AVG(CASE WHEN recognition_status = 'success' THEN 1.0 ELSE 0.0 END) as success_rate,
          AVG(processing_time_ms) as avg_processing_time
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ? AND is_deleted = 0
        GROUP BY ocr_provider
        ORDER BY count DESC
      `;
      const resultSet = await store.querySql(sql, [userId]);

      const stats: ProviderStatistics[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const stat: ProviderStatistics = {
            provider: DAOHelper.getStringValue(resultSet, 'provider'),
            count: DAOHelper.getNumberValue(resultSet, 'count'),
            successRate: DAOHelper.getNumberValue(resultSet, 'success_rate'),
            avgProcessingTime: DAOHelper.getNumberValue(resultSet, 'avg_processing_time')
          };
          stats.push(stat);
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return stats;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 按提供商统计失败', error);
    }
  }

  /**
   * 软删除识别记录
   */
  static async softDelete(recordId: number): Promise<boolean> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        is_deleted: 1,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(OCRRecognitionRecord.tableName);
      predicates.equalTo('record_id', recordId);

      const rows = await store.update(values, predicates);
      return rows > 0;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 软删除识别记录失败', error);
    }
  }

  /**
   * 批量删除用户的识别记录
   */
  static async deleteByUserId(userId: number): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();
      const values: relationalStore.ValuesBucket = {
        is_deleted: 1,
        updated_at: new Date().toISOString()
      };

      const predicates = new relationalStore.RdbPredicates(OCRRecognitionRecord.tableName);
      predicates.equalTo('user_id', userId);

      const rows = await store.update(values, predicates);
      return rows;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 批量删除用户识别记录失败', error);
    }
  }

  /**
   * 清理旧的识别记录（保留最近N条）
   */
  static async cleanupOldRecords(userId: number, keepCount: number = 100): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();

      // 查找要保留的最早记录的时间
      const sql = `
        SELECT created_at
        FROM ${OCRRecognitionRecord.tableName}
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
        UPDATE ${OCRRecognitionRecord.tableName}
        SET is_deleted = 1, updated_at = ?
        WHERE user_id = ? AND created_at < ? AND is_deleted = 0
      `;
      const now = new Date().toISOString();
      await store.executeSql(deleteSql, [now, userId, cutoffTime]);

      // 返回删除的记录数（executeSql不返回影响行数，这里返回0表示成功）
      return 0;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 清理旧识别记录失败', error);
    }
  }

  /**
   * 清理失败的识别记录
   */
  static async cleanupFailedRecords(userId: number, olderThanDays: number = 30): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();

      // 计算截止日期
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);
      const cutoffTime = cutoffDate.toISOString();

      const sql = `
        UPDATE ${OCRRecognitionRecord.tableName}
        SET is_deleted = 1, updated_at = ?
        WHERE user_id = ?
          AND recognition_status = 'failed'
          AND created_at < ?
          AND is_deleted = 0
      `;
      const now = new Date().toISOString();
      await store.executeSql(sql, [now, userId, cutoffTime]);

      // 返回删除的记录数（executeSql不返回影响行数，这里返回0表示成功）
      return 0;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 清理失败记录失败', error);
    }
  }

  /**
   * 获取高置信度未使用记录
   */
  static async getHighConfidenceUnused(
    userId: number,
    confidenceThreshold: number = 0.85,
    limit: number = 10
  ): Promise<OCRRecognitionRecord[]> {
    try {
      const store = DatabaseManager.getDatabase();
      const sql = `
        SELECT *
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ?
          AND is_used = 0
          AND recognition_status = 'success'
          AND confidence_score >= ?
          AND is_deleted = 0
        ORDER BY confidence_score DESC, created_at DESC
        LIMIT ?
      `;
      const resultSet = await store.querySql(sql, [userId, confidenceThreshold, limit]);

      const records: OCRRecognitionRecord[] = [];
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          records.push(DAOHelper.convertToOCRRecognitionRecord(resultSet));
        } while (resultSet.goToNextRow());
      }
      resultSet?.close();
      return records;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 查询高置信度未使用记录失败', error);
    }
  }

  /**
   * 统计按月识别次数
   */
  static async getMonthlyRecognitionCount(
    userId: number,
    year: number,
    month: number
  ): Promise<number> {
    try {
      const store = DatabaseManager.getDatabase();

      // 构造月份的开始和结束日期
      const monthStr = month < 10 ? '0' + month.toString() : month.toString();
      const startDate = `${year}-${monthStr}-01`;

      let nextMonth = month + 1;
      let nextYear = year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear = year + 1;
      }
      const nextMonthStr = nextMonth < 10 ? '0' + nextMonth.toString() : nextMonth.toString();
      const endDate = `${nextYear}-${nextMonthStr}-01`;

      const sql = `
        SELECT COUNT(*) as count
        FROM ${OCRRecognitionRecord.tableName}
        WHERE user_id = ?
          AND created_at >= ?
          AND created_at < ?
          AND is_deleted = 0
      `;
      const resultSet = await store.querySql(sql, [userId, startDate, endDate]);

      let count = 0;
      if (resultSet && resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        count = DAOHelper.getNumberValue(resultSet, 'count');
      }
      resultSet?.close();
      return count;
    } catch (error) {
      throw DAOHelper.toError('[OCRRecognitionRecordDAO] 统计月度识别次数失败', error);
    }
  }
}
