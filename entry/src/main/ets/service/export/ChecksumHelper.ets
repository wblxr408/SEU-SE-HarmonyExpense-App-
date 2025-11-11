/**
 * 校验和工具类
 * 提供数据完整性验证功能
 * 
 * @module ChecksumHelper
 * @version 1.0.0
 * @date 2025-11-11
 */

import cryptoFramework from '@ohos.security.cryptoFramework';
import { ExportError, ExportErrorCode } from './types/ExportTypes';
import hilog from '@ohos.hilog';

/**
 * 校验和工具类
 */
export class ChecksumHelper {
  private static readonly TAG: string = '[ChecksumHelper]';
  private static readonly HILOG_DOMAIN: number = 0xD001EE0;
  private static readonly LOG_TAG: string = 'ChecksumHelper';

  /**
   * 生成 SHA-256 校验和
   * @param data 要计算校验和的数据
   * @returns 十六进制格式的校验和字符串
   */
  static async generateChecksum(data: string): Promise<string> {
    try {
      ChecksumHelper.logInfo(`开始生成校验和，数据长度: ${data.length} 字节`);

      // 创建 SHA-256 消息摘要
      const md = cryptoFramework.createMd('SHA256');

      // 将字符串转换为字节数组
      const dataBytes = ChecksumHelper.stringToUint8Array(data);

      // 更新数据
      await md.update({ data: dataBytes });

      // 计算摘要
      const digest: cryptoFramework.DataBlob = await md.digest();

      // 转换为十六进制字符串
      const checksum = ChecksumHelper.bytesToHex(digest.data);

      ChecksumHelper.logInfo(`校验和生成成功: ${checksum}`);
      return checksum;
    } catch (error) {
      ChecksumHelper.logError('生成校验和失败', error as Object);
      throw new ExportError(
        ExportErrorCode.VALIDATION_ERROR,
        `生成校验和失败: ${ChecksumHelper.formatError(error as Object)}`,
        error as Object
      );
    }
  }

  /**
   * 验证校验和
   * @param data 要验证的数据
   * @param expectedChecksum 期望的校验和
   * @returns 是否匹配
   */
  static async verifyChecksum(data: string, expectedChecksum: string): Promise<boolean> {
    try {
      ChecksumHelper.logInfo(`开始验证校验和`);

      // 计算实际校验和
      const actualChecksum = await ChecksumHelper.generateChecksum(data);

      // 比较校验和（不区分大小写）
      const isValid = actualChecksum.toLowerCase() === expectedChecksum.toLowerCase();

      if (isValid) {
        ChecksumHelper.logInfo('校验和验证成功');
      } else {
        ChecksumHelper.logError(`校验和验证失败: 期望=${expectedChecksum}, 实际=${actualChecksum}`);
      }

      return isValid;
    } catch (error) {
      ChecksumHelper.logError('验证校验和失败', error as Object);
      throw new ExportError(
        ExportErrorCode.VALIDATION_ERROR,
        `验证校验和失败: ${ChecksumHelper.formatError(error as Object)}`,
        error as Object
      );
    }
  }

  /**
   * 将字符串转换为 Uint8Array (UTF-8编码)
   * @param str 要转换的字符串
   * @returns 字节数组
   */
  private static stringToUint8Array(str: string): Uint8Array {
    const utf8: Array<number> = [];
    for (let i = 0; i < str.length; i++) {
      let charCode = str.charCodeAt(i);
      if (charCode < 0x80) {
        utf8.push(charCode);
      } else if (charCode < 0x800) {
        utf8.push(0xc0 | (charCode >> 6), 0x80 | (charCode & 0x3f));
      } else if ((charCode & 0xfc00) === 0xd800 && i + 1 < str.length && (str.charCodeAt(i + 1) & 0xfc00) === 0xdc00) {
        // 代理对
        charCode = 0x10000 + (((charCode & 0x03ff) << 10) | (str.charCodeAt(++i) & 0x03ff));
        utf8.push(0xf0 | (charCode >> 18), 0x80 | ((charCode >> 12) & 0x3f), 0x80 | ((charCode >> 6) & 0x3f), 0x80 | (charCode & 0x3f));
      } else {
        utf8.push(0xe0 | (charCode >> 12), 0x80 | ((charCode >> 6) & 0x3f), 0x80 | (charCode & 0x3f));
      }
    }
    return new Uint8Array(utf8);
  }

  /**
   * 将字节数组转换为十六进制字符串
   * @param bytes 字节数组
   * @returns 十六进制字符串
   */
  private static bytesToHex(bytes: Uint8Array): string {
    const hexChars: Array<string> = [];
    for (let i = 0; i < bytes.length; i++) {
      const byte = bytes[i] as number;
      hexChars.push(((byte >> 4) & 0x0f).toString(16));
      hexChars.push((byte & 0x0f).toString(16));
    }
    return hexChars.join('');
  }

  private static logInfo(message: string): void {
    hilog.info(ChecksumHelper.HILOG_DOMAIN, ChecksumHelper.LOG_TAG, '%{public}s', `${ChecksumHelper.TAG} ${message}`);
  }

  private static logError(message: string, error?: Object): void {
    const detail = ChecksumHelper.formatError(error);
    const combined = detail ? `${ChecksumHelper.TAG} ${message} -> ${detail}` : `${ChecksumHelper.TAG} ${message}`;
    hilog.error(ChecksumHelper.HILOG_DOMAIN, ChecksumHelper.LOG_TAG, '%{public}s', combined);
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
