# 导出备份接口与加密逻辑设计文档

## 概述

本设计文档详细描述了基于ArkTS的HarmonyOS应用数据导出、备份和加密功能的技术实现方案。该系统提供完整的数据导出、加密、备份、导入和恢复能力，确保用户数据的安全性、完整性和可迁移性。

### 设计目标

- 提供安全可靠的数据导出和导入机制
- 实现符合行业标准的数据加密方案(AES-256-GCM)
- 支持完整备份和增量备份两种模式
- 提供云端同步备份能力
- 确保数据完整性验证(SHA-256校验)
- 支持多种导出格式(JSON/CSV)

### 技术栈

- **开发语言**: ArkTS (TypeScript for HarmonyOS)
- **数据库**: RelationalStore (HarmonyOS关系型数据库)
- **加密算法**: AES-256-GCM, PBKDF2, SHA-256
- **加密框架**: @ohos.security.cryptoFramework
- **文件系统**: @ohos.file.fs
- **网络请求**: @ohos.request (用于云端上传)

## 架构设计

### 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        应用层 (UI)                           │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                     服务层 (Services)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ExportService │  │ImportService │  │CloudStorage  │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│  ┌──────▼──────────────────▼──────────────────▼───────┐    │
│  │         EncryptionModule (加密/解密)               │    │
│  └──────────────────────────────────────────────────────┘    │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                  数据访问层 (DAO Layer)                      │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│  │UserDAO  │ │BillDAO  │ │TagDAO   │ │...      │          │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘          │
└───────┼──────────┼──────────┼──────────┼──────────────────┘
        │          │          │          │
┌───────▼──────────▼──────────▼──────────▼──────────────────┐
│              DatabaseManager (数据库管理)                   │
│                  RelationalStore                            │
└─────────────────────────────────────────────────────────────┘
```


### 模块职责

#### ExportService (导出服务)
- 收集用户的所有数据(账户、分类、账单、预算、标签等)
- 生成ExportData结构并序列化为JSON/CSV格式
- 计算数据校验和(SHA-256)
- 调用EncryptionModule进行数据加密
- 保存备份文件到本地文件系统

#### ImportService (导入服务)
- 读取备份文件内容
- 调用EncryptionModule进行数据解密
- 验证数据完整性(校验和比对)
- 解析数据并导入到数据库
- 提供事务支持确保数据一致性

#### EncryptionModule (加密模块)
- 实现PBKDF2密钥派生算法
- 实现AES-256-GCM加密和解密
- 生成随机盐值和初始化向量(IV)
- 处理认证标签验证

#### IncrementalBackupService (增量备份服务)
- 查询自上次备份后变更的数据
- 记录备份元数据到backup_metadata表
- 支持增量备份和完整备份切换

#### CloudStorageProvider (云存储接口)
- 定义云存储操作的统一接口
- 支持上传、下载、列表和删除操作
- HuaweiCloudStorage实现华为云OBS集成

## 组件和接口设计

### 核心数据模型

#### ExportData (导出数据结构)

```typescript
export interface ExportData {
  version: string;              // 数据版本号，用于兼容性检查
  exportTime: string;           // 导出时间 (ISO 8601格式)
  userId: number;               // 用户ID
  checksum: string;             // SHA-256校验和
  data: ExportDataContent;      // 实际数据内容
}

export interface ExportDataContent {
  users: User[];
  accounts: Account[];
  categories: Category[];
  bills: Bill[];
  budgets: Budget[];
  tags: Tag[];
  billTags: BillTag[];
}
```

#### ExportOptions (导出配置)

```typescript
export interface ExportOptions {
  format: 'json' | 'csv';       // 导出格式
  encrypt: boolean;             // 是否加密
  password?: string;            // 加密密码
  includeDeleted: boolean;      // 是否包含已删除数据
  dateRange?: DateRangeFilter;  // 日期范围过滤
}

export interface DateRangeFilter {
  startDate: string;            // 开始日期 (YYYY-MM-DD)
  endDate: string;              // 结束日期 (YYYY-MM-DD)
}
```


#### ImportResult (导入结果)

```typescript
export interface ImportResult {
  success: boolean;             // 导入是否成功
  imported: ImportStatistics;   // 导入统计信息
  errors: string[];             // 错误信息列表
}

export interface ImportStatistics {
  users: number;
  accounts: number;
  categories: number;
  bills: number;
  budgets: number;
  tags: number;
}
```

#### BackupMetadata (备份元数据)

```typescript
export interface BackupMetadata {
  backupId: number;
  userId: number;
  backupType: 'full' | 'incremental';
  backupTime: string;
  filePath: string;
  fileSize: number;
  checksum: string;
  isEncrypted: boolean;
  lastModifiedTime?: string;
  status: 'completed' | 'failed' | 'in_progress';
}
```

### ExportService 接口设计

```typescript
export class ExportService {
  private static readonly EXPORT_VERSION = '1.0.0';
  private static readonly CHUNK_SIZE = 1024 * 1024; // 1MB分块大小
  
  /**
   * 导出用户所有数据
   * @param userId 用户ID
   * @param options 导出配置选项
   * @returns 备份文件路径
   */
  static async exportAllData(
    userId: number,
    options: ExportOptions
  ): Promise<string>;
  
  /**
   * 收集用户数据
   * @param userId 用户ID
   * @param options 导出配置
   * @returns 导出数据结构
   */
  private static async collectUserData(
    userId: number,
    options: ExportOptions
  ): Promise<ExportData>;
  
  /**
   * 生成数据校验和
   * @param data 数据内容
   * @returns SHA-256校验和(十六进制字符串)
   */
  static async generateChecksum(data: ExportDataContent): Promise<string>;
  
  /**
   * 转换为CSV格式
   * @param exportData 导出数据
   * @returns CSV格式字符串
   */
  private static async convertToCSV(exportData: ExportData): Promise<string>;
  
  /**
   * 保存到文件
   * @param content 文件内容
   * @param userId 用户ID
   * @param options 导出选项
   * @returns 文件路径
   */
  private static async saveToFile(
    content: string,
    userId: number,
    options: ExportOptions
  ): Promise<string>;
}
```


### EncryptionModule 接口设计

```typescript
export class EncryptionModule {
  private static readonly SALT_LENGTH = 16;      // 盐值长度(字节)
  private static readonly IV_LENGTH = 12;        // GCM模式IV长度(字节)
  private static readonly AUTH_TAG_LENGTH = 16;  // 认证标签长度(字节)
  private static readonly KEY_SIZE = 32;         // AES-256密钥长度(字节)
  private static readonly PBKDF2_ITERATIONS = 100000; // PBKDF2迭代次数
  
  /**
   * 从密码派生加密密钥
   * @param password 用户密码
   * @param salt 盐值
   * @returns 派生的对称密钥
   */
  static async deriveKey(
    password: string,
    salt: Uint8Array
  ): Promise<cryptoFramework.SymKey>;
  
  /**
   * 加密数据
   * @param plaintext 明文数据
   * @param password 加密密码
   * @returns Base64编码的加密数据
   */
  static async encryptData(
    plaintext: string,
    password: string
  ): Promise<string>;
  
  /**
   * 解密数据
   * @param ciphertext Base64编码的密文
   * @param password 解密密码
   * @returns 解密后的明文
   */
  static async decryptData(
    ciphertext: string,
    password: string
  ): Promise<string>;
  
  /**
   * 生成随机字节
   * @param length 字节长度
   * @returns 随机字节数组
   */
  private static generateRandomBytes(length: number): Uint8Array;
}
```

### ImportService 接口设计

```typescript
export class ImportService {
  /**
   * 导入数据
   * @param filePath 备份文件路径
   * @param password 解密密码(可选)
   * @param options 导入选项
   * @returns 导入结果
   */
  static async importData(
    filePath: string,
    password?: string,
    options?: ImportOptions
  ): Promise<ImportResult>;
  
  /**
   * 读取文件内容
   * @param filePath 文件路径
   * @returns 文件内容字符串
   */
  private static async readFile(filePath: string): Promise<string>;
  
  /**
   * 验证数据完整性
   * @param exportData 导出数据
   * @returns 是否验证通过
   */
  private static async validateData(exportData: ExportData): Promise<boolean>;
  
  /**
   * 导入到数据库
   * @param exportData 导出数据
   * @param options 导入选项
   * @returns 导入结果
   */
  private static async importToDatabase(
    exportData: ExportData,
    options?: ImportOptions
  ): Promise<ImportResult>;
}
```


### IncrementalBackupService 接口设计

```typescript
export class IncrementalBackupService {
  /**
   * 执行增量备份
   * @param userId 用户ID
   * @param lastBackupTime 上次备份时间
   * @param options 导出选项
   * @returns 备份文件路径
   */
  static async performIncrementalBackup(
    userId: number,
    lastBackupTime: string,
    options: ExportOptions
  ): Promise<string>;
  
  /**
   * 获取变更数据
   * @param userId 用户ID
   * @param lastBackupTime 上次备份时间
   * @returns 变更的数据内容
   */
  private static async getChangedData(
    userId: number,
    lastBackupTime: string
  ): Promise<ExportDataContent>;
  
  /**
   * 保存增量备份
   * @param exportData 导出数据
   * @param options 导出选项
   * @returns 文件路径
   */
  private static async saveIncrementalBackup(
    exportData: ExportData,
    options: ExportOptions
  ): Promise<string>;
  
  /**
   * 记录备份元数据
   * @param userId 用户ID
   * @param filePath 文件路径
   * @param backupType 备份类型
   */
  private static async recordBackupMetadata(
    userId: number,
    filePath: string,
    backupType: 'full' | 'incremental'
  ): Promise<void>;
  
  /**
   * 获取上次备份时间
   * @param userId 用户ID
   * @returns 上次备份时间或null
   */
  static async getLastBackupTime(userId: number): Promise<string | null>;
}
```

### CloudStorageProvider 接口设计

```typescript
export interface CloudStorageProvider {
  /**
   * 上传备份文件
   * @param filePath 本地文件路径
   * @param remotePath 远程路径
   * @returns 远程文件URL
   */
  upload(filePath: string, remotePath: string): Promise<string>;
  
  /**
   * 下载备份文件
   * @param remotePath 远程路径
   * @param localPath 本地保存路径
   */
  download(remotePath: string, localPath: string): Promise<void>;
  
  /**
   * 列出备份文件
   * @param userId 用户ID
   * @returns 云端备份文件列表
   */
  list(userId: number): Promise<CloudBackupFile[]>;
  
  /**
   * 删除备份文件
   * @param remotePath 远程路径
   */
  delete(remotePath: string): Promise<void>;
}

export interface CloudBackupFile {
  fileName: string;
  remotePath: string;
  fileSize: number;
  uploadTime: string;
  checksum: string;
}
```


## 数据模型设计

### backup_metadata 表结构

用于记录备份历史和元数据信息。

```sql
CREATE TABLE IF NOT EXISTS backup_metadata (
  backup_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  backup_type TEXT NOT NULL CHECK (backup_type IN ('full', 'incremental')),
  backup_time TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  checksum TEXT NOT NULL,
  is_encrypted INTEGER DEFAULT 0,
  last_modified_time TEXT,
  status TEXT DEFAULT 'completed' CHECK (status IN ('completed', 'failed', 'in_progress')),
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE INDEX IF NOT EXISTS idx_backup_user_time 
ON backup_metadata(user_id, backup_time DESC);
```

### 数据导出格式示例

#### JSON格式

```json
{
  "version": "1.0.0",
  "exportTime": "2025-11-10T08:30:00.000Z",
  "userId": 1,
  "checksum": "a3f5b8c9d2e1f4a7b6c5d8e9f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0",
  "data": {
    "users": [
      {
        "userId": 1,
        "username": "张三",
        "email": "zhangsan@example.com",
        "passwordHash": "hashed_password",
        "createdAt": "2025-01-01T00:00:00.000Z",
        "updatedAt": "2025-11-10T08:30:00.000Z",
        "is_deleted": 0
      }
    ],
    "accounts": [
      {
        "accountId": 1,
        "userId": 1,
        "name": "现金账户",
        "type": "cash",
        "balance": 5000.00,
        "color": "#1890FF",
        "createdAt": "2025-01-01T00:00:00.000Z",
        "updatedAt": "2025-11-10T08:30:00.000Z",
        "is_deleted": 0
      }
    ],
    "categories": [...],
    "bills": [...],
    "budgets": [...],
    "tags": [...],
    "billTags": [...]
  }
}
```


## 加密方案设计

### 加密流程

```
用户密码 + 随机盐值(16字节)
         ↓
    PBKDF2 (100000次迭代)
         ↓
    AES-256密钥(32字节)
         ↓
    AES-256-GCM加密
         ↓
盐值(16) + IV(12) + 认证标签(16) + 密文
         ↓
    Base64编码
         ↓
    加密文件
```

### 加密数据格式

加密后的数据按以下格式组织:

```
[盐值 16字节][IV 12字节][认证标签 16字节][密文 N字节]
```

整体进行Base64编码后保存到文件。

### 密钥派生参数

- **算法**: PBKDF2-HMAC-SHA256
- **迭代次数**: 100,000 (符合OWASP推荐)
- **盐值长度**: 16字节 (128位)
- **输出密钥长度**: 32字节 (256位)

### 加密参数

- **算法**: AES-256-GCM
- **密钥长度**: 256位
- **IV长度**: 12字节 (GCM推荐)
- **认证标签长度**: 16字节 (128位)
- **填充模式**: PKCS7

### 安全考虑

1. **盐值随机性**: 每次加密使用新的随机盐值，防止彩虹表攻击
2. **IV唯一性**: 每次加密使用新的随机IV，确保相同明文产生不同密文
3. **认证加密**: GCM模式提供认证加密(AEAD)，同时保证机密性和完整性
4. **密钥不存储**: 密钥从用户密码实时派生，不在设备上持久化存储
5. **迭代次数**: 100,000次PBKDF2迭代增加暴力破解难度

## 错误处理设计

### 错误类型定义

```typescript
export enum ExportErrorCode {
  DATABASE_ERROR = 'DATABASE_ERROR',
  ENCRYPTION_ERROR = 'ENCRYPTION_ERROR',
  FILE_SYSTEM_ERROR = 'FILE_SYSTEM_ERROR',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  NETWORK_ERROR = 'NETWORK_ERROR'
}

export class ExportError extends Error {
  code: ExportErrorCode;
  details?: any;
  
  constructor(code: ExportErrorCode, message: string, details?: any) {
    super(message);
    this.code = code;
    this.details = details;
    this.name = 'ExportError';
  }
}
```


### 错误处理策略

#### ExportService 错误处理

- **数据收集失败**: 记录错误日志，抛出DATABASE_ERROR
- **校验和生成失败**: 记录错误日志，抛出ENCRYPTION_ERROR
- **加密失败**: 记录错误日志，抛出ENCRYPTION_ERROR
- **文件保存失败**: 记录错误日志，抛出FILE_SYSTEM_ERROR

#### ImportService 错误处理

- **文件读取失败**: 抛出FILE_SYSTEM_ERROR，提示文件不存在或无权限
- **解密失败**: 抛出ENCRYPTION_ERROR，提示密码错误
- **校验和不匹配**: 抛出VALIDATION_ERROR，提示文件已损坏
- **数据库导入失败**: 回滚事务，抛出DATABASE_ERROR

#### EncryptionModule 错误处理

- **密钥派生失败**: 抛出ENCRYPTION_ERROR，记录详细错误信息
- **加密/解密失败**: 抛出ENCRYPTION_ERROR，提示操作失败原因
- **认证标签验证失败**: 抛出ENCRYPTION_ERROR，提示数据被篡改或密码错误

### 日志记录策略

```typescript
export class Logger {
  private static readonly TAG = '[ExportBackup]';
  
  static info(module: string, message: string, data?: any): void {
    console.log(`${this.TAG}[${module}] ${message}`, data || '');
  }
  
  static error(module: string, message: string, error: any): void {
    console.error(`${this.TAG}[${module}] ${message}`, this.formatError(error));
  }
  
  private static formatError(error: any): string {
    if (error instanceof Error) {
      return `${error.message}\n${error.stack}`;
    }
    return JSON.stringify(error);
  }
}
```

## 测试策略

### 单元测试

#### ExportService 测试用例

1. **测试数据收集**: 验证能正确收集所有用户数据
2. **测试校验和生成**: 验证SHA-256校验和计算正确
3. **测试JSON序列化**: 验证数据能正确序列化为JSON
4. **测试CSV转换**: 验证数据能正确转换为CSV格式
5. **测试文件保存**: 验证文件能正确保存到指定路径

#### EncryptionModule 测试用例

1. **测试密钥派生**: 验证PBKDF2能从密码生成正确长度的密钥
2. **测试加密**: 验证数据能正确加密
3. **测试解密**: 验证加密后的数据能正确解密
4. **测试加解密一致性**: 验证加密后解密能还原原始数据
5. **测试错误密码**: 验证使用错误密码解密会失败
6. **测试数据篡改检测**: 验证修改密文后解密会失败

#### ImportService 测试用例

1. **测试文件读取**: 验证能正确读取备份文件
2. **测试数据验证**: 验证校验和验证功能正常
3. **测试数据导入**: 验证数据能正确导入到数据库
4. **测试事务回滚**: 验证导入失败时能正确回滚
5. **测试错误处理**: 验证各种错误情况能正确处理


### 集成测试

1. **完整导出导入流程**: 测试导出后能成功导入并恢复所有数据
2. **加密导出导入流程**: 测试加密导出后能使用正确密码导入
3. **增量备份流程**: 测试增量备份能正确识别变更数据
4. **云端同步流程**: 测试备份文件能成功上传和下载

### 性能测试

1. **大数据量导出**: 测试10000+账单记录的导出性能
2. **加密性能**: 测试不同数据量下的加密耗时
3. **导入性能**: 测试大文件导入的性能和内存占用
4. **并发测试**: 测试多个导出/导入任务的并发处理

## 性能优化方案

### 数据收集优化

```typescript
// 使用批量查询减少数据库访问次数
private static async collectUserData(
  userId: number,
  options: ExportOptions
): Promise<ExportData> {
  // 并行查询所有表，减少总耗时
  const [users, accounts, categories, bills, budgets, tags, billTags] = 
    await Promise.all([
      UserDAO.getById(userId),
      AccountDAO.getByUserId(userId),
      CategoryDAO.getByUserId(userId),
      this.getBillsWithFilter(userId, options),
      BudgetDAO.getByUserId(userId),
      TagDAO.getByUserId(userId),
      TagDAO.getBillTagsByUserId(userId)
    ]);
  
  return {
    version: this.EXPORT_VERSION,
    exportTime: new Date().toISOString(),
    userId: userId,
    checksum: '',
    data: {
      users: users ? [users] : [],
      accounts,
      categories,
      bills,
      budgets,
      tags,
      billTags
    }
  };
}
```

### 文件分块处理

```typescript
// 大文件分块写入，避免内存溢出
private static async saveToFile(
  content: string,
  userId: number,
  options: ExportOptions
): Promise<string> {
  const filePath = this.generateFilePath(userId, options);
  const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
  
  try {
    // 分块写入
    const buffer = Buffer.from(content, 'utf-8');
    let offset = 0;
    
    while (offset < buffer.length) {
      const chunk = buffer.slice(offset, offset + this.CHUNK_SIZE);
      fs.writeSync(file.fd, chunk.toString());
      offset += this.CHUNK_SIZE;
    }
    
    return filePath;
  } finally {
    fs.closeSync(file);
  }
}
```


### 增量备份优化

```typescript
// 使用索引优化变更数据查询
private static async getChangedData(
  userId: number,
  lastBackupTime: string
): Promise<ExportDataContent> {
  const store = DatabaseManager.getDatabase();
  
  // 利用 updated_at 索引快速查询变更记录
  const changedAccounts = await store.querySql(
    `SELECT * FROM accounts 
     WHERE user_id = ? AND updated_at > ? 
     ORDER BY updated_at ASC`,
    [userId, lastBackupTime]
  );
  
  // 其他表类似处理...
  
  return {
    users: [],
    accounts: this.mapAccounts(changedAccounts),
    categories: [],
    bills: [],
    budgets: [],
    tags: [],
    billTags: []
  };
}
```

## 安全最佳实践

### 密码管理

1. **不存储密码**: 加密密码仅在内存中使用，不持久化
2. **密码强度验证**: 要求密码至少8位，包含字母和数字
3. **密码输入保护**: UI层使用密码输入框，防止肩窥攻击

```typescript
export class PasswordValidator {
  static validate(password: string): boolean {
    if (password.length < 8) {
      throw new Error('密码长度至少8位');
    }
    if (!/[a-zA-Z]/.test(password)) {
      throw new Error('密码必须包含字母');
    }
    if (!/[0-9]/.test(password)) {
      throw new Error('密码必须包含数字');
    }
    return true;
  }
}
```

### 文件权限控制

```typescript
// 设置备份文件权限，仅应用可访问
private static async saveToFile(
  content: string,
  userId: number,
  options: ExportOptions
): Promise<string> {
  const context = getContext(this);
  const filesDir = context.filesDir; // 应用私有目录
  const exportDir = `${filesDir}/exports`;
  
  // 确保目录存在
  await fs.mkdir(exportDir, true);
  
  const filePath = `${exportDir}/${this.generateFileName(userId, options)}`;
  
  // 写入文件
  const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
  fs.writeSync(file.fd, content);
  fs.closeSync(file);
  
  return filePath;
}
```

### 传输安全

```typescript
// 云端上传使用HTTPS和签名认证
export class HuaweiCloudStorage implements CloudStorageProvider {
  async upload(filePath: string, remotePath: string): Promise<string> {
    const uploadConfig: request.UploadConfig = {
      url: `https://${this.endpoint}/${this.bucketName}/${remotePath}`, // HTTPS
      header: this.generateAuthHeaders('PUT', remotePath), // 签名认证
      method: 'PUT',
      files: [{
        filename: 'backup',
        name: 'file',
        uri: `internal://cache/${filePath}`,
        type: 'file'
      }],
      data: []
    };
    
    const uploadTask = await request.uploadFile(getContext(this), uploadConfig);
    
    return new Promise((resolve, reject) => {
      uploadTask.on('complete', () => resolve(remotePath));
      uploadTask.on('fail', (err) => reject(new ExportError(
        ExportErrorCode.NETWORK_ERROR,
        '上传失败',
        err
      )));
    });
  }
}
```


## 使用流程设计

### 导出流程

```
用户触发导出
    ↓
选择导出选项(格式、加密、日期范围等)
    ↓
[如果加密] 输入加密密码
    ↓
ExportService.exportAllData()
    ↓
收集用户数据 → 生成校验和 → 序列化数据
    ↓
[如果加密] EncryptionModule.encryptData()
    ↓
保存到文件系统
    ↓
返回文件路径
    ↓
显示成功提示
```

### 导入流程

```
用户选择备份文件
    ↓
[如果加密] 输入解密密码
    ↓
ImportService.importData()
    ↓
读取文件 → [如果加密] 解密数据
    ↓
解析JSON → 验证校验和
    ↓
开启数据库事务
    ↓
逐表导入数据
    ↓
[成功] 提交事务 / [失败] 回滚事务
    ↓
返回导入结果
    ↓
显示导入统计或错误信息
```

### 增量备份流程

```
用户触发增量备份
    ↓
查询上次备份时间
    ↓
[无历史备份] 执行完整备份
    ↓
[有历史备份] 查询变更数据
    ↓
生成增量备份文件
    ↓
记录备份元数据
    ↓
返回文件路径
```

### 云端同步流程

```
用户触发云端备份
    ↓
执行本地导出
    ↓
生成远程路径
    ↓
CloudStorage.upload()
    ↓
生成认证签名 → 创建上传任务
    ↓
监听上传进度
    ↓
[成功] 返回远程URL / [失败] 重试或报错
    ↓
显示同步结果
```

## 依赖关系

### 模块依赖图

```
ExportService
    ├── DatabaseManager
    ├── EncryptionModule
    ├── UserDAO
    ├── AccountDAO
    ├── CategoryDAO
    ├── BillDAO
    ├── BudgetDAO
    └── TagDAO

ImportService
    ├── DatabaseManager
    ├── EncryptionModule
    ├── UserDAO
    ├── AccountDAO
    ├── CategoryDAO
    ├── BillDAO
    ├── BudgetDAO
    └── TagDAO

EncryptionModule
    └── @ohos.security.cryptoFramework

IncrementalBackupService
    ├── DatabaseManager
    ├── ExportService
    └── BackupMetadataDAO

CloudStorageProvider
    └── @ohos.request
```


### 外部依赖

- **@ohos.data.relationalStore**: 关系型数据库操作
- **@ohos.security.cryptoFramework**: 加密算法实现
- **@ohos.file.fs**: 文件系统操作
- **@ohos.request**: 网络请求和文件上传
- **@ohos.app.ability.common**: 应用上下文

## 实现注意事项

### ArkTS编码规范

1. **类型安全**: 所有函数参数和返回值必须明确类型
2. **空值检查**: 使用可选链(?.)和空值合并(??)处理可能为空的值
3. **错误处理**: 使用try-catch捕获异常，不允许异常向上传播
4. **资源释放**: 及时关闭文件句柄和数据库结果集
5. **异步操作**: 使用async/await处理异步操作，避免回调地狱

### 数据库操作规范

1. **事务使用**: 批量操作必须使用事务，确保原子性
2. **结果集关闭**: 查询后必须调用resultSet.close()释放资源
3. **参数化查询**: 使用参数化查询防止SQL注入
4. **索引优化**: 在updated_at等常用查询字段上创建索引

### 加密操作规范

1. **随机数生成**: 使用cryptoFramework.createRandom()生成安全随机数
2. **密钥不复用**: 每次加密使用新的盐值和IV
3. **认证标签验证**: GCM模式必须验证认证标签
4. **敏感数据清理**: 加密完成后及时清理内存中的明文数据

### 文件操作规范

1. **路径安全**: 使用应用私有目录，避免路径遍历攻击
2. **异常处理**: 文件操作必须捕获异常并提供友好错误信息
3. **资源释放**: 使用try-finally确保文件句柄被正确关闭
4. **权限检查**: 操作前检查文件读写权限

## 扩展性设计

### 支持新的导出格式

通过策略模式支持扩展新的导出格式:

```typescript
interface ExportFormatter {
  format(data: ExportData): string;
}

class JSONFormatter implements ExportFormatter {
  format(data: ExportData): string {
    return JSON.stringify(data, null, 2);
  }
}

class CSVFormatter implements ExportFormatter {
  format(data: ExportData): string {
    // CSV格式化逻辑
  }
}

class ExportService {
  private static formatters: Map<string, ExportFormatter> = new Map([
    ['json', new JSONFormatter()],
    ['csv', new CSVFormatter()]
  ]);
  
  static registerFormatter(format: string, formatter: ExportFormatter): void {
    this.formatters.set(format, formatter);
  }
}
```

### 支持新的云存储提供商

通过接口抽象支持多种云存储:

```typescript
// 新增阿里云OSS支持
class AliyunOSSStorage implements CloudStorageProvider {
  async upload(filePath: string, remotePath: string): Promise<string> {
    // 阿里云OSS上传实现
  }
  
  async download(remotePath: string, localPath: string): Promise<void> {
    // 阿里云OSS下载实现
  }
  
  // 其他方法实现...
}

// 使用工厂模式创建云存储实例
class CloudStorageFactory {
  static create(provider: 'huawei' | 'aliyun'): CloudStorageProvider {
    switch (provider) {
      case 'huawei':
        return new HuaweiCloudStorage(config);
      case 'aliyun':
        return new AliyunOSSStorage(config);
      default:
        throw new Error('不支持的云存储提供商');
    }
  }
}
```

---

**文档版本**: v1.0  
**最后更新**: 2025-11-10  
**作者**: Kiro AI Assistant
