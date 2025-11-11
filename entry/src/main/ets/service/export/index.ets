/**
 * 导出备份服务统一入口
 * 
 * 提供所有导出备份相关的服务和类型定义
 * 
 * @module export
 * @version 1.0.0
 * @date 2025-11-11
 */

// 导出核心服务
export { ExportService } from './ExportService';
export { ImportService } from './ImportService';
export { EncryptionModule } from './EncryptionModule';

// 导出工具类
export { FileHelper } from './FileHelper';
export { ChecksumHelper } from './ChecksumHelper';

// 导出所有类型定义
export {
  // 接口
  ExportData,
  ExportDataContent,
  ExportOptions,
  DateRangeFilter,
  ImportResult,
  ImportStatistics,
  ImportOptions,
  BackupMetadata,
  CloudBackupFile,
  CloudStorageConfig,
  EncryptionParams,
  
  // 枚举
  ExportErrorCode,
  
  // 类
  ExportError,
  
  // 常量
  DEFAULT_ENCRYPTION_PARAMS,
  EXPORT_VERSION,
  CHUNK_SIZE
} from './types/ExportTypes';
