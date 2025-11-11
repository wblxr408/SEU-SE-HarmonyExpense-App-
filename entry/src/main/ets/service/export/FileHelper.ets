/**
 * 文件操作工具类
 * 提供导出备份文件的读写功能
 * 
 * @module FileHelper
 * @version 1.0.0
 * @date 2025-11-11
 */

import fs from '@ohos.file.fs';
import { ExportError, ExportErrorCode } from './types/ExportTypes';
import hilog from '@ohos.hilog';

/**
 * 文件操作工具类
 */
export class FileHelper {
  private static readonly TAG: string = '[FileHelper]';
  private static readonly HILOG_DOMAIN: number = 0xD001EDF;
  private static readonly LOG_TAG: string = 'FileHelper';
  private static readonly EXPORT_DIR: string = 'exports';

  /**
   * 保存内容到文件
   * @param content 要保存的内容
   * @param fileName 文件名
   * @returns 完整的文件路径
   */
  static async saveToFile(content: string, fileName: string): Promise<string> {
    try {
      FileHelper.logInfo(`开始保存文件: ${fileName}`);

      // 获取导出目录路径
      const exportDir = await FileHelper.getExportDirectory();

      // 构建完整文件路径
      const filePath = `${exportDir}/${fileName}`;

      // 写入文件
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, content);
        FileHelper.logInfo(`文件保存成功: ${filePath}, 大小: ${content.length} 字节`);
      } finally {
        fs.closeSync(file);
      }

      return filePath;
    } catch (error) {
      FileHelper.logError('保存文件失败', error as Object);
      throw new ExportError(
        ExportErrorCode.FILE_SYSTEM_ERROR,
        `保存文件失败: ${FileHelper.formatError(error as Object)}`,
        error as Object
      );
    }
  }

  /**
   * 从文件读取内容
   * @param filePath 文件路径
   * @returns 文件内容
   */
  static async readFromFile(filePath: string): Promise<string> {
    try {
      FileHelper.logInfo(`开始读取文件: ${filePath}`);

      // 检查文件是否存在
      const exists = fs.accessSync(filePath);
      if (!exists) {
        throw new ExportError(
          ExportErrorCode.FILE_SYSTEM_ERROR,
          `文件不存在: ${filePath}`
        );
      }

      // 读取文件
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      try {
        const stat = fs.statSync(filePath);
        const buffer = new ArrayBuffer(stat.size);
        fs.readSync(file.fd, buffer);

        // 转换为字符串
        const uint8Array = new Uint8Array(buffer);
        const content = FileHelper.arrayBufferToString(uint8Array);

        FileHelper.logInfo(`文件读取成功: ${filePath}, 大小: ${content.length} 字节`);
        return content;
      } finally {
        fs.closeSync(file);
      }
    } catch (error) {
      if (error instanceof ExportError) {
        throw error;
      }
      FileHelper.logError('读取文件失败', error as Object);
      throw new ExportError(
        ExportErrorCode.FILE_SYSTEM_ERROR,
        `读取文件失败: ${FileHelper.formatError(error as Object)}`,
        error as Object
      );
    }
  }

  /**
   * 生成文件名
   * @param userId 用户ID
   * @param format 格式（json）
   * @param encrypted 是否加密
   * @returns 文件名
   */
  static generateFileName(userId: number, format: string, encrypted: boolean): string {
    const timestamp = new Date().getTime();
    const extension = encrypted ? 'enc' : format;
    return `backup_${userId}_${timestamp}.${extension}`;
  }

  /**
   * 获取导出目录路径
   * @returns 导出目录路径
   */
  static async getExportDirectory(): Promise<string> {
    try {
      // 获取应用文件目录
      const context = getContext();
      const filesDir = context.filesDir;
      const exportDir = `${filesDir}/${FileHelper.EXPORT_DIR}`;

      // 检查目录是否存在，不存在则创建
      try {
        fs.accessSync(exportDir);
      } catch (e) {
        // 目录不存在，创建目录
        fs.mkdirSync(exportDir);
        FileHelper.logInfo(`创建导出目录: ${exportDir}`);
      }

      return exportDir;
    } catch (error) {
      FileHelper.logError('获取导出目录失败', error as Object);
      throw new ExportError(
        ExportErrorCode.FILE_SYSTEM_ERROR,
        `获取导出目录失败: ${FileHelper.formatError(error as Object)}`,
        error as Object
      );
    }
  }

  /**
   * 将 ArrayBuffer 转换为字符串
   * @param uint8Array 字节数组
   * @returns 字符串
   */
  private static arrayBufferToString(uint8Array: Uint8Array): string {
    let result = '';
    let i = 0;
    while (i < uint8Array.length) {
      const byte1 = uint8Array[i++];
      if (byte1 === undefined) break;

      if (byte1 < 0x80) {
        result += String.fromCharCode(byte1);
      } else if ((byte1 >> 5) === 0x06) {
        const byte2 = uint8Array[i++];
        if (byte2 === undefined) break;
        result += String.fromCharCode(((byte1 & 0x1f) << 6) | (byte2 & 0x3f));
      } else if ((byte1 >> 4) === 0x0e) {
        const byte2 = uint8Array[i++];
        const byte3 = uint8Array[i++];
        if (byte2 === undefined || byte3 === undefined) break;
        result += String.fromCharCode(((byte1 & 0x0f) << 12) | ((byte2 & 0x3f) << 6) | (byte3 & 0x3f));
      } else if ((byte1 >> 3) === 0x1e) {
        const byte2 = uint8Array[i++];
        const byte3 = uint8Array[i++];
        const byte4 = uint8Array[i++];
        if (byte2 === undefined || byte3 === undefined || byte4 === undefined) break;
        const codePoint = ((byte1 & 0x07) << 18) | ((byte2 & 0x3f) << 12) | ((byte3 & 0x3f) << 6) | (byte4 & 0x3f);
        if (codePoint > 0xffff) {
          const surrogate1 = 0xd800 + ((codePoint - 0x10000) >> 10);
          const surrogate2 = 0xdc00 + ((codePoint - 0x10000) & 0x3ff);
          result += String.fromCharCode(surrogate1, surrogate2);
        } else {
          result += String.fromCharCode(codePoint);
        }
      }
    }
    return result;
  }

  private static logInfo(message: string): void {
    hilog.info(FileHelper.HILOG_DOMAIN, FileHelper.LOG_TAG, '%{public}s', `${FileHelper.TAG} ${message}`);
  }

  private static logError(message: string, error?: Object): void {
    const detail = FileHelper.formatError(error);
    const combined = detail ? `${FileHelper.TAG} ${message} -> ${detail}` : `${FileHelper.TAG} ${message}`;
    hilog.error(FileHelper.HILOG_DOMAIN, FileHelper.LOG_TAG, '%{public}s', combined);
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
