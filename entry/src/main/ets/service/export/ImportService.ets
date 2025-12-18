/**
 * 导入服务
 * 提供用户数据导入功能
 * 
 * @module ImportService
 * @version 1.0.0
 * @date 2025-11-11
 */

import { UserDAO } from '../../dao/UserDAO';
import { AccountDAO } from '../../dao/AccountDAO';
import { CategoryDAO } from '../../dao/CategoryDAO';
import { BillDAO } from '../../dao/BillDAO';
import { BudgetDAO } from '../../dao/BudgetDAO';
import { TagDAO } from '../../dao/TagDAO';
import { DatabaseManager } from '../../database/DatabaseManager';
import {
  ExportData,
  ImportResult,
  ImportStatistics,
  ImportOptions,
  ExportError,
  ExportErrorCode,
  EXPORT_VERSION
} from './types/ExportTypes';
import { EncryptionModule } from './EncryptionModule';
import { FileHelper } from './FileHelper';
import { ChecksumHelper } from './ChecksumHelper';
import hilog from '@ohos.hilog';

/**
 * 导入服务类
 */
export class ImportService {
  private static readonly TAG: string = '[ImportService]';
  private static readonly HILOG_DOMAIN: number = 0xD001EE2;
  private static readonly LOG_TAG: string = 'ImportService';

  /**
   * 导入用户数据
   * @param filePath 备份文件路径
   * @param password 解密密码（如果文件已加密）
   * @param options 导入选项
   * @returns 导入结果
   */
  static async importUserData(
    filePath: string,
    password?: string,
    options?: ImportOptions
  ): Promise<ImportResult> {
    const errors: Array<string> = [];
    const statistics: ImportStatistics = {
      users: 0,
      accounts: 0,
      categories: 0,
      bills: 0,
      budgets: 0,
      tags: 0
    };

    try {
      ImportService.logInfo(`开始导入数据: ${filePath}`);

      // 1. 读取文件
      let fileContent = await FileHelper.readFromFile(filePath);

      // 2. 判断是否需要解密
      if (filePath.endsWith('.enc')) {
        if (!password || password.length === 0) {
          throw new ExportError(
            ExportErrorCode.ENCRYPTION_ERROR,
            '加密文件需要提供密码'
          );
        }
        ImportService.logInfo('开始解密数据');
        fileContent = await EncryptionModule.decryptData(fileContent, password);
      }

      // 3. 解析JSON
      const exportData: ExportData = JSON.parse(fileContent);

      // 4. 验证版本
      if (exportData.version !== EXPORT_VERSION) {
        ImportService.logInfo(`版本不匹配: 文件版本=${exportData.version}, 当前版本=${EXPORT_VERSION}`);
        // 可以选择继续或中止
      }

      // 5. 验证校验和
      const dataJson = JSON.stringify(exportData.data, null, 2);
      const isValid = await ChecksumHelper.verifyChecksum(dataJson, exportData.checksum);
      if (!isValid) {
        throw new ExportError(
          ExportErrorCode.VALIDATION_ERROR,
          '数据校验失败，文件可能已损坏或被篡改'
        );
      }

      // 6. 导入数据到数据库
      await ImportService.importToDatabase(exportData, statistics, errors, options);

      ImportService.logInfo(
        `数据导入完成: 用户=${statistics.users}, 账户=${statistics.accounts}, ` +
        `分类=${statistics.categories}, 账单=${statistics.bills}, ` +
        `预算=${statistics.budgets}, 标签=${statistics.tags}, 错误=${errors.length}`
      );

      return {
        success: errors.length === 0,
        imported: statistics,
        errors: errors
      };
    } catch (error) {
      if (error instanceof ExportError) {
        throw error;
      }
      ImportService.logError('导入数据失败', error as Object);
      const exportError = new ExportError(
        ExportErrorCode.UNKNOWN_ERROR,
        `导入数据失败: ${ImportService.formatError(error as Object)}`,
        error as Object
      );
      throw exportError;
    }
  }

  /**
   * 导入数据到数据库
   * @param exportData 导出数据
   * @param statistics 统计信息
   * @param errors 错误列表
   * @param options 导入选项
   */
  private static async importToDatabase(
    exportData: ExportData,
    statistics: ImportStatistics,
    errors: Array<string>,
    options?: ImportOptions
  ): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const skipErrors = options?.skipErrors ?? false;

    try {
      // 开启事务
      await store.beginTransaction();

      try {
        // 按顺序导入数据
        // 注意：用户数据通常不导入，因为用户已存在
        // 这里只是记录统计信息
        statistics.users = exportData.data.users.length;

        // 导入账户
        for (const account of exportData.data.accounts) {
          try {
            await AccountDAO.insert(account);
            statistics.accounts++;
          } catch (error) {
            const errorMsg = `导入账户失败: ${account.name} - ${ImportService.formatError(error as Object)}`;
            errors.push(errorMsg);
            if (!skipErrors) {
              throw new ExportError(ExportErrorCode.DATABASE_ERROR, errorMsg, error as Object);
            }
          }
        }

        // 导入分类
        for (const category of exportData.data.categories) {
          try {
            await CategoryDAO.insert(category);
            statistics.categories++;
          } catch (error) {
            const errorMsg = `导入分类失败: ${category.name} - ${ImportService.formatError(error as Object)}`;
            errors.push(errorMsg);
            if (!skipErrors) {
              throw new ExportError(ExportErrorCode.DATABASE_ERROR, errorMsg, error as Object);
            }
          }
        }

        // 导入账单
        for (const bill of exportData.data.bills) {
          try {
            await BillDAO.insert(bill);
            statistics.bills++;
          } catch (error) {
            const errorMsg = `导入账单失败: ${bill.note} - ${ImportService.formatError(error as Object)}`;
            errors.push(errorMsg);
            if (!skipErrors) {
              throw new ExportError(ExportErrorCode.DATABASE_ERROR, errorMsg, error as Object);
            }
          }
        }

        // 导入预算
        for (const budget of exportData.data.budgets) {
          try {
            await BudgetDAO.insert(budget);
            statistics.budgets++;
          } catch (error) {
            const errorMsg = `导入预算失败: ${budget.categoryId} - ${ImportService.formatError(error as Object)}`;
            errors.push(errorMsg);
            if (!skipErrors) {
              throw new ExportError(ExportErrorCode.DATABASE_ERROR, errorMsg, error as Object);
            }
          }
        }

        // 导入标签
        for (const tag of exportData.data.tags) {
          try {
            await TagDAO.insert(tag);
            statistics.tags++;
          } catch (error) {
            const errorMsg = `导入标签失败: ${tag.name} - ${ImportService.formatError(error as Object)}`;
            errors.push(errorMsg);
            if (!skipErrors) {
              throw new ExportError(ExportErrorCode.DATABASE_ERROR, errorMsg, error as Object);
            }
          }
        }

        // 导入账单标签关联
        for (const billTag of exportData.data.billTags) {
          try {
            await TagDAO.addTagToBill(billTag.billId, billTag.tagId);
          } catch (error) {
            const errorMsg = `导入账单标签关联失败: billId=${billTag.billId}, tagId=${billTag.tagId} - ${ImportService.formatError(error as Object)}`;
            errors.push(errorMsg);
            if (!skipErrors) {
              throw new ExportError(ExportErrorCode.DATABASE_ERROR, errorMsg, error as Object);
            }
          }
        }

        // 提交事务
        await store.commit();
        ImportService.logInfo('数据库事务提交成功');
      } catch (error) {
        // 回滚事务
        await store.rollBack();
        ImportService.logError('数据库事务回滚', error as Object);
        if (error instanceof Error) {
          throw error;
        } else {
          throw new ExportError(
            ExportErrorCode.DATABASE_ERROR,
            `数据库操作失败: ${ImportService.formatError(error as Object)}`,
            error as Object
          );
        }
      }
    } catch (error) {
      if (error instanceof ExportError) {
        throw error;
      }
      const exportError = new ExportError(
        ExportErrorCode.DATABASE_ERROR,
        `数据库操作失败: ${ImportService.formatError(error as Object)}`,
        error as Object
      );
      throw exportError;
    }
  }

  private static logInfo(message: string): void {
    hilog.info(ImportService.HILOG_DOMAIN, ImportService.LOG_TAG, '%{public}s', `${ImportService.TAG} ${message}`);
  }

  private static logError(message: string, error?: Object): void {
    const detail = ImportService.formatError(error);
    const combined = detail ? `${ImportService.TAG} ${message} -> ${detail}` : `${ImportService.TAG} ${message}`;
    hilog.error(ImportService.HILOG_DOMAIN, ImportService.LOG_TAG, '%{public}s', combined);
  }

  private static formatError(error?: Object): string {
    if (error === undefined || error === null) {
      return '';
    }
    if (error instanceof Error) {
      return error.stack ? `${error.message} | ${error.stack}` : error.message;
    }
    try {
      return JSON.stringify(error);
    } catch (e) {
      return '' + error;
    }
  }
}
