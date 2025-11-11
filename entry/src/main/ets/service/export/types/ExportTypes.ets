/**
 * 导出/备份接口与加密逻辑类型定义
 *
 * 本文件包含导出、备份、加密功能的所有核心数据模型和接口定义
 *
 * @module ExportTypes
 * @version 1.0.0
 * @date 2025-11-10
 */

import { User } from '../../../model/User';
import { Account } from '../../../model/Account';
import { Category } from '../../../model/Category';
import { Bill } from '../../../model/Bill';
import { Budget } from '../../../model/Budget';
import { Tag } from '../../../model/Tag';
import { BillTag } from '../../../model/BillTag';

/**
 * 导出数据内容结构
 * 包含所有需要导出的业务数据
 */
export interface ExportDataContent {
  /** 用户数据 */
  users: Array<User>;
  /** 账户数据 */
  accounts: Array<Account>;
  /** 分类数据 */
  categories: Array<Category>;
  /** 账单数据 */
  bills: Array<Bill>;
  /** 预算数据 */
  budgets: Array<Budget>;
  /** 标签数据 */
  tags: Array<Tag>;
  /** 账单-标签关联数据 */
  billTags: Array<BillTag>;
}

/**
 * 导出数据结构
 * 完整的导出数据格式，包含元数据和实际数据
 */
export interface ExportData {
  /** 数据版本号，用于兼容性检查 */
  version: string;
  /** 导出时间 (ISO 8601格式) */
  exportTime: string;
  /** 用户ID */
  userId: number;
  /** 数据校验和 (SHA-256) */
  checksum: string;
  /** 实际数据内容 */
  data: ExportDataContent;
}

/**
 * 日期范围过滤器
 * 用于指定导出数据的日期范围
 */
export interface DateRangeFilter {
  /** 开始日期 (YYYY-MM-DD格式) */
  startDate: string;
  /** 结束日期 (YYYY-MM-DD格式) */
  endDate: string;
}

/**
 * 导出配置选项
 * 定义导出行为的各种选项
 */
export interface ExportOptions {
  /** 导出格式: 'json' 或 'csv' */
  format: 'json' | 'csv';
  /** 是否加密导出数据 */
  encrypt: boolean;
  /** 加密密码 (当encrypt为true时必需) */
  password?: string;
  /** 是否包含已删除的数据 */
  includeDeleted: boolean;
  /** 日期范围过滤 (可选) */
  dateRange?: DateRangeFilter;
}

/**
 * 导入统计信息
 * 记录各类型数据的导入数量
 */
export interface ImportStatistics {
  /** 导入的用户数量 */
  users: number;
  /** 导入的账户数量 */
  accounts: number;
  /** 导入的分类数量 */
  categories: number;
  /** 导入的账单数量 */
  bills: number;
  /** 导入的预算数量 */
  budgets: number;
  /** 导入的标签数量 */
  tags: number;
}

/**
 * 导入选项
 * 定义导入行为的配置
 */
export interface ImportOptions {
  /** 是否覆盖已存在的数据 */
  overwrite?: boolean;
  /** 是否跳过错误继续导入 */
  skipErrors?: boolean;
}

/**
 * 导入结果
 * 记录导入操作的结果和统计信息
 */
export interface ImportResult {
  /** 导入是否成功 */
  success: boolean;
  /** 导入统计信息 */
  imported: ImportStatistics;
  /** 错误信息列表 */
  errors: Array<string>;
}

/**
 * 备份元数据
 * 记录备份的详细信息
 */
export interface BackupMetadata {
  /** 备份ID (自增主键) */
  backupId?: number;
  /** 用户ID */
  userId: number;
  /** 备份类型: 'full' (完整备份) 或 'incremental' (增量备份) */
  backupType: 'full' | 'incremental';
  /** 备份时间 (ISO 8601格式) */
  backupTime: string;
  /** 备份文件路径 */
  filePath: string;
  /** 文件大小 (字节) */
  fileSize: number;
  /** 文件校验和 (SHA-256) */
  checksum: string;
  /** 是否已加密 */
  isEncrypted: boolean;
  /** 最后修改时间 (ISO 8601格式) */
  lastModifiedTime?: string;
  /** 备份状态 */
  status: 'completed' | 'failed' | 'in_progress';
  /** 创建时间 (ISO 8601格式) */
  createdAt?: string;
}

/**
 * 云端备份文件信息
 * 记录云端存储的备份文件信息
 */
export interface CloudBackupFile {
  /** 文件名 */
  fileName: string;
  /** 远程路径 */
  remotePath: string;
  /** 文件大小 (字节) */
  fileSize: number;
  /** 上传时间 (ISO 8601格式) */
  uploadTime: string;
  /** 文件校验和 (SHA-256) */
  checksum: string;
}

/**
 * 导出/备份错误代码枚举
 * 定义系统中可能出现的各类错误
 */
export enum ExportErrorCode {
  /** 数据库操作错误 */
  DATABASE_ERROR = 'DATABASE_ERROR',
  /** 加密/解密操作错误 */
  ENCRYPTION_ERROR = 'ENCRYPTION_ERROR',
  /** 文件系统操作错误 */
  FILE_SYSTEM_ERROR = 'FILE_SYSTEM_ERROR',
  /** 数据验证错误 */
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  /** 网络操作错误 */
  NETWORK_ERROR = 'NETWORK_ERROR',
  /** 密码强度不足错误 */
  PASSWORD_WEAK_ERROR = 'PASSWORD_WEAK_ERROR',
  /** 未知错误 */
  UNKNOWN_ERROR = 'UNKNOWN_ERROR'
}

/**
 * 导出/备份错误类
 * 统一的错误处理类，包含错误代码和详细信息
 */
export class ExportError extends Error {
  /** 错误代码 */
  code: ExportErrorCode;
  /** 错误详细信息 (可选) */
  details?: Object;

  /**
   * 构造函数
   * @param code 错误代码
   * @param message 错误消息
   * @param details 错误详细信息 (可选)
   */
  constructor(code: ExportErrorCode, message: string, details?: Object) {
    super(message);
    this.code = code;
    this.details = details;
    this.name = 'ExportError';
  }

  /**
   * 转换为JSON格式
   * @returns JSON对象
   */
  toJSON(): Record<string, Object> {
    const result: Record<string, Object> = {
      'name': this.name,
      'code': this.code,
      'message': this.message
    };
    if (this.details !== undefined) {
      result['details'] = this.details as Object;
    }
    if (this.stack !== undefined) {
      result['stack'] = this.stack;
    }
    return result;
  }

  /**
   * 转换为字符串
   * @returns 错误的字符串表示
   */
  toString(): string {
    return `${this.name} [${this.code}]: ${this.message}`;
  }
}

/**
 * 云存储配置
 * 定义云存储服务的配置参数
 */
export interface CloudStorageConfig {
  /** 服务端点 (endpoint) */
  endpoint: string;
  /** 访问密钥 (Access Key) */
  accessKey: string;
  /** 密钥 (Secret Key) */
  secretKey: string;
  /** 存储桶名称 */
  bucketName: string;
  /** 区域 (可选) */
  region?: string;
}

/**
 * 加密参数
 * 定义加密操作的参数
 */
export interface EncryptionParams {
  /** 盐值长度 (字节) */
  saltLength: number;
  /** 初始化向量长度 (字节) */
  ivLength: number;
  /** 认证标签长度 (字节) */
  authTagLength: number;
  /** 密钥长度 (字节) */
  keySize: number;
  /** PBKDF2迭代次数 */
  pbkdf2Iterations: number;
}

/**
 * 默认加密参数
 * AES-256-GCM 推荐参数
 */
export const DEFAULT_ENCRYPTION_PARAMS: EncryptionParams = {
  saltLength: 16,          // 128位盐值
  ivLength: 12,            // GCM推荐12字节IV
  authTagLength: 16,       // 128位认证标签
  keySize: 32,             // 256位密钥 (AES-256)
  pbkdf2Iterations: 100000 // OWASP推荐迭代次数
};

/**
 * 导出版本号
 * 用于数据格式兼容性检查
 */
export const EXPORT_VERSION = '1.0.0';

/**
 * 文件分块大小
 * 用于大文件的分块读写 (1MB)
 */
export const CHUNK_SIZE = 1024 * 1024;
