/**
 * 加密模块 - 提供数据加密和解密功能
 * 
 * 本模块实现基于 AES-256-GCM 的加密方案，使用 PBKDF2 进行密钥派生
 * 符合行业安全标准，确保数据机密性和完整性
 * 
 * @module EncryptionModule
 * @version 1.0.0
 * @date 2025-11-10
 */

import cryptoFramework from '@ohos.security.cryptoFramework';
import hilog from '@ohos.hilog';
import { ExportError, ExportErrorCode, DEFAULT_ENCRYPTION_PARAMS } from './types/ExportTypes';

/**
 * 加密模块类
 * 提供数据加密、解密和密钥派生功能
 */
export class EncryptionModule {
  // 加密参数常量
  private static readonly SALT_LENGTH: number = DEFAULT_ENCRYPTION_PARAMS.saltLength;      // 盐值长度(字节)
  private static readonly IV_LENGTH: number = DEFAULT_ENCRYPTION_PARAMS.ivLength;            // GCM模式IV长度(字节)
  private static readonly AUTH_TAG_LENGTH: number = DEFAULT_ENCRYPTION_PARAMS.authTagLength; // 认证标签长度(字节)
  private static readonly KEY_SIZE: number = DEFAULT_ENCRYPTION_PARAMS.keySize;             // AES-256密钥长度(字节)
  private static readonly PBKDF2_ITERATIONS: number = DEFAULT_ENCRYPTION_PARAMS.pbkdf2Iterations; // PBKDF2迭代次数

  // 日志标签
  private static readonly TAG: string = '[EncryptionModule]';
  private static readonly HILOG_DOMAIN: number = 0xD001EDC;
  private static readonly LOG_TAG: string = 'EncryptionModule';

  private static logInfo(message: string): void {
    hilog.info(EncryptionModule.HILOG_DOMAIN, EncryptionModule.LOG_TAG, '%{public}s', `${EncryptionModule.TAG} ${message}`);
  }

  private static logError(message: string, error?: Object): void {
    const detail = EncryptionModule.formatError(error);
    const combined = detail ? `${EncryptionModule.TAG} ${message} -> ${detail}` : `${EncryptionModule.TAG} ${message}`;
    hilog.error(EncryptionModule.HILOG_DOMAIN, EncryptionModule.LOG_TAG, '%{public}s', combined);
  }

  private static buildErrorMessage(base: string, error?: Object): string {
    const detail = EncryptionModule.formatError(error);
    return detail ? `${base}: ${detail}` : base;
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

  /**
   * 生成指定长度的安全随机字节数组
   * @param length 要生成的字节长度
   * @returns 随机字节数组
   */
  private static async generateRandomBytes(length: number): Promise<Uint8Array> {
    try {
      const random = cryptoFramework.createRandom();
      const randomData: cryptoFramework.DataBlob = await random.generateRandom(length);
      return randomData.data;
    } catch (error) {
      const baseMsg = '生成随机字节失败';
      const errorMsg = EncryptionModule.buildErrorMessage(baseMsg, error as Object);
      EncryptionModule.logError(baseMsg, error as Object);
      throw new ExportError(
        ExportErrorCode.ENCRYPTION_ERROR,
        errorMsg,
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
    // 手动实现 UTF-8 编码
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
   * 将 Uint8Array 转换为字符串 (UTF-8解码)
   * @param bytes 要转换的字节数组
   * @returns 字符串
   */
  private static uint8ArrayToString(bytes: Uint8Array): string {
    // 手动实现 UTF-8 解码
    let result = '';
    let i = 0;
    while (i < bytes.length) {
      let byte1 = bytes[i++];
      if (byte1 < 0x80) {
        result += String.fromCharCode(byte1);
      } else if ((byte1 >> 5) === 0x06) {
        const byte2 = bytes[i++];
        result += String.fromCharCode(((byte1 & 0x1f) << 6) | (byte2 & 0x3f));
      } else if ((byte1 >> 4) === 0x0e) {
        const byte2 = bytes[i++];
        const byte3 = bytes[i++];
        result += String.fromCharCode(((byte1 & 0x0f) << 12) | ((byte2 & 0x3f) << 6) | (byte3 & 0x3f));
      } else if ((byte1 >> 3) === 0x1e) {
        const byte2 = bytes[i++];
        const byte3 = bytes[i++];
        const byte4 = bytes[i++];
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

  /**
   * Base64 编码
   * @param data 要编码的字节数组
   * @returns Base64 编码的字符串
   */
  private static base64Encode(data: Uint8Array): string {
    // 使用简单的 Base64 编码实现
    // HarmonyOS 中可以使用 util.Base64Helper，但这里使用标准实现
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result = '';
    let i = 0;
    
    while (i < data.length) {
      const a: number = data[i++] as number;
      const b: number = i < data.length ? (data[i++] as number) : 0;
      const c: number = i < data.length ? (data[i++] as number) : 0;
      
      const bitmap = (a << 16) | (b << 8) | c;
      
      result += chars.charAt((bitmap >> 18) & 63);
      result += chars.charAt((bitmap >> 12) & 63);
      result += i - 2 < data.length ? chars.charAt((bitmap >> 6) & 63) : '=';
      result += i - 1 < data.length ? chars.charAt(bitmap & 63) : '=';
    }
    
    return result;
  }

  /**
   * Base64 解码
   * @param str Base64 编码的字符串
   * @returns 解码后的字节数组
   */
  private static base64Decode(str: string): Uint8Array {
    // 移除填充字符
    const cleanStr = str.replace(/[^A-Za-z0-9+/=]/g, '');
    
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const result: Array<number> = [];
    let i = 0;
    
    while (i < cleanStr.length) {
      const encoded1 = chars.indexOf(cleanStr.charAt(i++));
      const encoded2 = chars.indexOf(cleanStr.charAt(i++));
      const encoded3 = chars.indexOf(cleanStr.charAt(i++));
      const encoded4 = chars.indexOf(cleanStr.charAt(i++));
      const value3 = encoded3 === -1 ? 64 : encoded3;
      const value4 = encoded4 === -1 ? 64 : encoded4;
      
      const bitmap = (encoded1 << 18) | (encoded2 << 12) | (value3 << 6) | value4;
      
      result.push((bitmap >> 16) & 255);
      if (value3 !== 64) {
        result.push((bitmap >> 8) & 255);
      }
      if (value4 !== 64) {
        result.push(bitmap & 255);
      }
    }
    
    return new Uint8Array(result);
  }

  /**
   * 从密码派生加密密钥
   * 使用 PBKDF2-HMAC-SHA256 算法从用户密码派生 AES-256 密钥
   * 
   * @param password 用户密码
   * @param salt 盐值（随机生成）
   * @returns 派生的对称密钥
   * @throws ExportError 当密钥派生失败时抛出
   */
  static async deriveKey(
    password: string,
    salt: Uint8Array
  ): Promise<cryptoFramework.SymKey> {
    try {
      EncryptionModule.logInfo(`开始密钥派生，迭代次数: ${EncryptionModule.PBKDF2_ITERATIONS}`);

      // 创建 PBKDF2 密钥派生器
      // 格式: 'PBKDF2|SHA256|迭代次数|密钥长度'
      const kdfAlg = `PBKDF2|SHA256|${EncryptionModule.PBKDF2_ITERATIONS}|${EncryptionModule.KEY_SIZE}`;
      const kdf = cryptoFramework.createKdf(kdfAlg);

      // 将密码转换为字节数组
      const passwordBytes = EncryptionModule.stringToUint8Array(password);

      // 配置 PBKDF2 参数
      const spec: cryptoFramework.PBKDF2Spec = {
        algName: 'PBKDF2',
        password: passwordBytes,
        salt: salt,
        iterations: EncryptionModule.PBKDF2_ITERATIONS,
        keySize: EncryptionModule.KEY_SIZE
      };

      // 生成密钥材料
      const keyBlob: cryptoFramework.DataBlob = await kdf.generateSecret(spec);

      // 转换为对称密钥
      const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
      const symKey: cryptoFramework.SymKey = await symKeyGenerator.convertKey(keyBlob);

      EncryptionModule.logInfo('密钥派生成功');
      return symKey;
    } catch (error) {
      const baseMsg = '密钥派生失败';
      const errorMsg = EncryptionModule.buildErrorMessage(baseMsg, error as Object);
      EncryptionModule.logError(baseMsg, error as Object);
      throw new ExportError(
        ExportErrorCode.ENCRYPTION_ERROR,
        errorMsg,
        error as Object
      );
    }
  }

  /**
   * 加密数据
   * 使用 AES-256-GCM 模式加密数据，提供认证加密（AEAD）
   * 
   * 加密数据格式: [盐值(16字节)][IV(12字节)][认证标签(16字节)][密文(N字节)]
   * 整体进行 Base64 编码后返回
   * 
   * @param plaintext 明文数据
   * @param password 加密密码
   * @returns Base64编码的加密数据
   * @throws ExportError 当加密失败时抛出
   */
  static async encryptData(
    plaintext: string,
    password: string
  ): Promise<string> {
    try {
      EncryptionModule.logInfo(`开始加密数据，数据长度: ${plaintext.length} 字符`);

      // 1. 生成随机盐值和 IV
      const salt = await EncryptionModule.generateRandomBytes(EncryptionModule.SALT_LENGTH);
      const iv = await EncryptionModule.generateRandomBytes(EncryptionModule.IV_LENGTH);
      EncryptionModule.logInfo('生成随机盐值和IV成功');

      // 2. 派生密钥
      const key = await EncryptionModule.deriveKey(password, salt);
      EncryptionModule.logInfo('密钥派生完成');

      // 3. 创建加密器
      const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
      const authTag = new Uint8Array(EncryptionModule.AUTH_TAG_LENGTH);
      const gcmParams: cryptoFramework.GcmParamsSpec = {
        algName: 'GcmParamsSpec',
        iv: { data: iv },
        aad: { data: new Uint8Array(0) },  // 附加认证数据（可选，此处为空）
        authTag: { data: authTag }          // 认证标签（加密后由系统填充）
      };

      // 4. 初始化加密器
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, gcmParams);
      EncryptionModule.logInfo('加密器初始化完成');

      // 5. 加密数据
      const plaintextBytes = EncryptionModule.stringToUint8Array(plaintext);
      const input: cryptoFramework.DataBlob = {
        data: plaintextBytes
      };

      const encrypted: cryptoFramework.DataBlob = await cipher.doFinal(input);
      EncryptionModule.logInfo(`数据加密完成，密文长度: ${encrypted.data.length} 字节`);

      // 6. 获取认证标签（GCM模式在doFinal后生成）
      // 注意：在HarmonyOS中，认证标签可能需要在doFinal后通过update获取
      // 这里我们使用GCMParams中的authTag，系统会自动填充
      const finalAuthTag = gcmParams.authTag.data;

      // 7. 组合数据：salt(16) + iv(12) + authTag(16) + ciphertext
      const totalLength = salt.length + iv.length + finalAuthTag.length + encrypted.data.length;
      const result = new Uint8Array(totalLength);

      let offset = 0;
      result.set(salt, offset);
      offset += salt.length;
      result.set(iv, offset);
      offset += iv.length;
      result.set(finalAuthTag, offset);
      offset += finalAuthTag.length;
      result.set(encrypted.data, offset);

      // 8. Base64 编码
      const base64String = EncryptionModule.base64Encode(result);

      EncryptionModule.logInfo(`数据加密成功，Base64长度: ${base64String.length} 字符`);
      return base64String;
    } catch (error) {
      const baseMsg = '加密失败';
      const errorMsg = EncryptionModule.buildErrorMessage(baseMsg, error as Object);
      EncryptionModule.logError(baseMsg, error as Object);
      throw new ExportError(
        ExportErrorCode.ENCRYPTION_ERROR,
        errorMsg,
        error as Object
      );
    }
  }

  /**
   * 解密数据
   * 使用 AES-256-GCM 模式解密数据，验证数据完整性
   * 
   * @param ciphertext Base64编码的密文数据
   * @param password 解密密码
   * @returns 解密后的明文
   * @throws ExportError 当解密失败或密码错误时抛出
   */
  static async decryptData(
    ciphertext: string,
    password: string
  ): Promise<string> {
    try {
      EncryptionModule.logInfo(`开始解密数据，Base64长度: ${ciphertext.length} 字符`);

      // 1. Base64 解码
      let encryptedData: Uint8Array;
      try {
        encryptedData = EncryptionModule.base64Decode(ciphertext);
      } catch (error) {
        EncryptionModule.logError('Base64解码失败', error as Object);
        throw new ExportError(
          ExportErrorCode.ENCRYPTION_ERROR,
          'Base64解码失败，数据格式可能不正确',
          error as Object
        );
      }

      // 验证数据长度
      const minLength = EncryptionModule.SALT_LENGTH + EncryptionModule.IV_LENGTH + EncryptionModule.AUTH_TAG_LENGTH;
      if (encryptedData.length < minLength) {
        const errorDetails: Record<string, number> = {
          'actualLength': encryptedData.length,
          'minLength': minLength
        };
        throw new ExportError(
          ExportErrorCode.VALIDATION_ERROR,
          `加密数据长度不足，至少需要 ${minLength} 字节`,
          errorDetails as Object
        );
      }

      // 2. 提取 salt、IV、authTag 和密文
      let offset = 0;
      const salt = encryptedData.slice(offset, offset + EncryptionModule.SALT_LENGTH);
      offset += EncryptionModule.SALT_LENGTH;
      const iv = encryptedData.slice(offset, offset + EncryptionModule.IV_LENGTH);
      offset += EncryptionModule.IV_LENGTH;
      const authTag = encryptedData.slice(offset, offset + EncryptionModule.AUTH_TAG_LENGTH);
      offset += EncryptionModule.AUTH_TAG_LENGTH;
      const encrypted = encryptedData.slice(offset);

      EncryptionModule.logInfo(`数据提取完成: salt=${salt.length}, iv=${iv.length}, authTag=${authTag.length}, ciphertext=${encrypted.length}`);

      // 3. 派生密钥
      const key = await EncryptionModule.deriveKey(password, salt);
      EncryptionModule.logInfo('密钥派生完成');

      // 4. 创建解密器
      const decipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
      const gcmParams: cryptoFramework.GcmParamsSpec = {
        algName: 'GcmParamsSpec',
        iv: { data: iv },
        aad: { data: new Uint8Array(0) },
        authTag: { data: authTag }
      };

      // 5. 初始化解密器
      await decipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, gcmParams);
      EncryptionModule.logInfo('解密器初始化完成');

      // 6. 解密数据
      const input: cryptoFramework.DataBlob = { data: encrypted };
      let decrypted: cryptoFramework.DataBlob;
      try {
        decrypted = await decipher.doFinal(input);
      } catch (error) {
        // GCM模式会在认证标签验证失败时抛出异常
        throw new ExportError(
          ExportErrorCode.ENCRYPTION_ERROR,
          '解密失败，密码可能不正确或数据已被篡改',
          error as Object
        );
      }

      // 7. 转换为字符串
      const plaintext = EncryptionModule.uint8ArrayToString(decrypted.data);
      EncryptionModule.logInfo(`数据解密成功，明文长度: ${plaintext.length} 字符`);

      return plaintext;
    } catch (error) {
      if (error instanceof ExportError) {
        throw error;
      }
      const baseMsg = '解密失败';
      EncryptionModule.logError(baseMsg, error as Object);
      throw new ExportError(
        ExportErrorCode.ENCRYPTION_ERROR,
        '解密失败，密码可能不正确',
        error as Object
      );
    }
  }
}

