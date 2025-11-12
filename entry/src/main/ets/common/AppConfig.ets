/**
 * 应用配置常量
 * 统一管理所有魔法数字和配置参数
 */

/**
 * 数据库配置
 */
export class DatabaseConfig {
  /** 数据库名称 */
  static readonly DB_NAME = 'harmony_expense.db';
  
  /** 数据库版本 */
  static readonly DB_VERSION = 1;
  
  /** 批量操作的批次大小 */
  static readonly BATCH_SIZE = 100;
  
  /** SQLite参数数量限制 */
  static readonly MAX_SQL_PARAMS = 999;
}

/**
 * 缓存配置
 */
export class CacheConfig {
  /** 默认缓存过期时间（毫秒）- 5分钟 */
  static readonly DEFAULT_TTL = 5 * 60 * 1000;
  
  /** 分类缓存过期时间（毫秒）- 10分钟 */
  static readonly CATEGORY_TTL = 10 * 60 * 1000;
  
  /** 用户信息缓存过期时间（毫秒）- 30分钟 */
  static readonly USER_TTL = 30 * 60 * 1000;
  
  /** 最大缓存条目数 */
  static readonly MAX_CACHE_SIZE = 1000;
}

/**
 * 性能监控配置
 */
export class PerformanceConfig {
  /** 慢查询阈值（毫秒） */
  static readonly SLOW_QUERY_THRESHOLD = 100;
  
  /** 超慢查询阈值（毫秒） */
  static readonly VERY_SLOW_QUERY_THRESHOLD = 500;
  
  /** 性能日志采样率（0-1） */
  static readonly PERFORMANCE_LOG_SAMPLE_RATE = 0.1;
}

/**
 * 分页配置
 */
export class PaginationConfig {
  /** 默认每页大小 */
  static readonly DEFAULT_PAGE_SIZE = 20;
  
  /** 最大每页大小 */
  static readonly MAX_PAGE_SIZE = 100;
  
  /** 最小每页大小 */
  static readonly MIN_PAGE_SIZE = 10;
}

/**
 * 加密配置
 */
export class EncryptionConfig {
  /** 盐值长度（字节）- 128位 */
  static readonly SALT_LENGTH = 16;
  
  /** 初始化向量长度（字节）- GCM推荐12字节 */
  static readonly IV_LENGTH = 12;
  
  /** 认证标签长度（字节）- 128位 */
  static readonly AUTH_TAG_LENGTH = 16;
  
  /** 密钥长度（字节）- 256位 (AES-256) */
  static readonly KEY_SIZE = 32;
  
  /** PBKDF2迭代次数 - OWASP推荐 */
  static readonly PBKDF2_ITERATIONS = 100000;
}

/**
 * 文件配置
 */
export class FileConfig {
  /** 文件分块大小（字节）- 1MB */
  static readonly CHUNK_SIZE = 1024 * 1024;
  
  /** 最大文件大小（字节）- 100MB */
  static readonly MAX_FILE_SIZE = 100 * 1024 * 1024;
  
  /** 导出文件版本号 */
  static readonly EXPORT_VERSION = '1.0.0';
}

/**
 * 日志配置
 */
export class LogConfig {
  /** 日志标签 */
  static readonly TAG = 'HarmonyExpense';
  
  /** 日志域 */
  static readonly DOMAIN = 0x0000;
  
  /** 是否启用调试日志 */
  static readonly DEBUG_ENABLED = true;
}

/**
 * 业务规则配置
 */
export class BusinessConfig {
  /** 最大分类层级深度 */
  static readonly MAX_CATEGORY_DEPTH = 5;
  
  /** 最大标签数量（每个账单） */
  static readonly MAX_TAGS_PER_BILL = 10;
  
  /** 密码最小长度 */
  static readonly MIN_PASSWORD_LENGTH = 6;
  
  /** 用户名最小长度 */
  static readonly MIN_USERNAME_LENGTH = 3;
  
  /** 用户名最大长度 */
  static readonly MAX_USERNAME_LENGTH = 50;
}
