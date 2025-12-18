/**
 * 导出服务
 * 提供用户数据导出功能
 * 
 * @module ExportService
 * @version 1.0.0
 * @date 2025-11-11
 */

import { UserDAO } from '../../dao/UserDAO';
import { AccountDAO } from '../../dao/AccountDAO';
import { CategoryDAO } from '../../dao/CategoryDAO';
import { BillDAO } from '../../dao/BillDAO';
import { BudgetDAO } from '../../dao/BudgetDAO';
import { TagDAO } from '../../dao/TagDAO';
import { ExportData, ExportOptions, ExportDataContent, ExportError, ExportErrorCode, EXPORT_VERSION } from './types/ExportTypes';
import { EncryptionModule } from './EncryptionModule';
import { FileHelper } from './FileHelper';
import { ChecksumHelper } from './ChecksumHelper';
import hilog from '@ohos.hilog';

/**
 * 导出服务类
 */
export class ExportService {
  private static readonly TAG: string = '[ExportService]';
  private static readonly HILOG_DOMAIN: number = 0xD001EE1;
  private static readonly LOG_TAG: string = 'ExportService';

  /**
   * 导出用户数据
   * @param userId 用户ID
   * @param options 导出选项
   * @returns 导出文件路径
   */
  static async exportUserData(userId: number, options: ExportOptions): Promise<string> {
    try {
      ExportService.logInfo(`开始导出用户数据: userId=${userId}, format=${options.format}, encrypt=${options.encrypt}`);

      // 1. 收集用户数据
      const dataContent = await ExportService.collectUserData(userId);

      // 2. 生成导出数据结构
      const exportData: ExportData = {
        version: EXPORT_VERSION,
        exportTime: new Date().toISOString(),
        userId: userId,
        checksum: '', // 稍后计算
        data: dataContent
      };

      // 3. 序列化为JSON
      const jsonData = JSON.stringify(exportData.data, null, 2);
      ExportService.logInfo(`数据序列化完成，大小: ${jsonData.length} 字节`);

      // 4. 生成校验和
      exportData.checksum = await ChecksumHelper.generateChecksum(jsonData);

      // 5. 准备最终数据
      let finalData = JSON.stringify(exportData, null, 2);

      // 6. 可选加密
      if (options.encrypt) {
        if (!options.password || options.password.length === 0) {
          throw new ExportError(
            ExportErrorCode.VALIDATION_ERROR,
            '启用加密时必须提供密码'
          );
        }
        ExportService.logInfo('开始加密数据');
        finalData = await EncryptionModule.encryptData(finalData, options.password);
      }

      // 7. 生成文件名
      const fileName = FileHelper.generateFileName(userId, options.format, options.encrypt);

      // 8. 保存到文件
      const filePath = await FileHelper.saveToFile(finalData, fileName);

      ExportService.logInfo(`数据导出成功: ${filePath}`);
      return filePath;
    } catch (error) {
      if (error instanceof ExportError) {
        throw error;
      }
      ExportService.logError('导出数据失败', error as Object);
      const err = error instanceof Error ? error : new Error(String(error));
      throw new ExportError(
        ExportErrorCode.UNKNOWN_ERROR,
        `导出数据失败: ${ExportService.formatError(error as Object)}`,
        err
      );
    }
  }

  /**
   * 收集用户数据
   * @param userId 用户ID
   * @returns 导出数据内容
   */
  private static async collectUserData(userId: number): Promise<ExportDataContent> {
    try {
      ExportService.logInfo(`开始收集用户数据: userId=${userId}`);

      // 并行查询所有数据
      const results = await Promise.all([
        UserDAO.getById(userId),
        AccountDAO.getByUserId(userId),
        CategoryDAO.getAll(userId),
        BillDAO.getAll(),
        BudgetDAO.getAll(),
        TagDAO.getAll(userId),
        TagDAO.getBillTagsByUserId(userId)
      ]);

      const user = results[0];
      const accounts = results[1];
      const categories = results[2];
      const allBills = results[3];
      const allBudgets = results[4];
      const tags = results[5];
      const billTags = results[6];

      if (!user) {
        throw new ExportError(
          ExportErrorCode.VALIDATION_ERROR,
          `用户不存在: userId=${userId}`
        );
      }

      // 过滤只属于该用户的账单和预算
      const bills = allBills.filter(bill => bill.userId === userId);
      const budgets = allBudgets.filter(budget => budget.userId === userId);

      const dataContent: ExportDataContent = {
        users: [user],
        accounts: accounts,
        categories: categories,
        bills: bills,
        budgets: budgets,
        tags: tags,
        billTags: billTags
      };

      ExportService.logInfo(
        `数据收集完成: 账户=${accounts.length}, 分类=${categories.length}, ` +
        `账单=${bills.length}, 预算=${budgets.length}, 标签=${tags.length}, 标签关联=${billTags.length}`
      );

      return dataContent;
    } catch (error) {
      if (error instanceof ExportError) {
        throw error;
      }
      ExportService.logError('收集用户数据失败', error as Object);
      const err = error instanceof Error ? error : new Error(String(error));
      throw new ExportError(
        ExportErrorCode.DATABASE_ERROR,
        `收集用户数据失败: ${ExportService.formatError(error as Object)}`,
        err
      );
    }
  }

  private static logInfo(message: string): void {
    hilog.info(ExportService.HILOG_DOMAIN, ExportService.LOG_TAG, '%{public}s', `${ExportService.TAG} ${message}`);
  }

  private static logError(message: string, error?: Object): void {
    const detail = ExportService.formatError(error);
    const combined = detail ? `${ExportService.TAG} ${message} -> ${detail}` : `${ExportService.TAG} ${message}`;
    hilog.error(ExportService.HILOG_DOMAIN, ExportService.LOG_TAG, '%{public}s', combined);
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
