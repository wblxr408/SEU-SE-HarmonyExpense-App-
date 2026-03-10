# Export 导出备份模块

提供数据导出、导入、加密和备份功能。

---

## 目录结构

```
export/
├── services/                # 核心服务
│   ├── ExportService.ets   # 导出服务
│   └── ImportService.ets   # 导入服务
├── utils/                   # 工具类
│   ├── EncryptionModule.ets # 加密模块
│   ├── ChecksumHelper.ets  # 校验和计算
│   └── FileHelper.ets      # 文件操作辅助
├── types/                   # 类型定义
│   ├── ExportTypes.ets     # 导出相关类型
│   └── index.ets           # 类型统一导出
├── index.ets                # 模块统一导出
└── README.md                # 本文档
```

---

## 核心服务 (services/)

### ExportService.ets
数据导出服务，提供：

#### 主要功能
- **数据选择导出**：按日期范围、分类、标签筛选
- **格式化导出**：JSON 格式，支持压缩
- **加密导出**：AES-256-GCM 加密
- **元数据管理**：记录导出时间、版本、统计信息

#### API
```typescript
class ExportService {
  // 导出数据
  static async exportData(
    userId: number,
    options: ExportOptions
  ): Promise<ExportData>

  // 导出到文件
  static async exportToFile(
    userId: number,
    filePath: string,
    options: ExportOptions
  ): Promise<void>
}
```

### ImportService.ets
数据导入服务，提供：

#### 主要功能
- **文件解析**：JSON 格式解析
- **数据解密**：AES-256-GCM 解密
- **数据验证**：完整性校验、版本兼容性检查
- **冲突处理**：重复数据检测和处理策略

#### API
```typescript
class ImportService {
  // 从文件导入
  static async importFromFile(
    userId: number,
    filePath: string,
    options: ImportOptions
  ): Promise<ImportResult>

  // 验证导入文件
  static async validateImportFile(
    filePath: string
  ): Promise<boolean>
}
```

---

## 工具类 (utils/)

### EncryptionModule.ets
加密解密模块

#### 功能
- **AES-256-GCM 加密**：业界标准加密算法
- **密钥派生**：PBKDF2 密钥派生
- **随机盐值**：每次加密使用新盐值
- **完整性保护**：GCM 模式提供认证

#### API
```typescript
class EncryptionModule {
  // 加密数据
  static async encrypt(
    data: string,
    password: string
  ): Promise<string>

  // 解密数据
  static async decrypt(
    encryptedData: string,
    password: string
  ): Promise<string>

  // 生成密钥
  static async deriveKey(
    password: string,
    salt: Uint8Array
  ): Promise<CryptoKey>
}
```

### ChecksumHelper.ets
数据校验和计算

#### 功能
- SHA-256 哈希计算
- 文件完整性验证
- 数据一致性检查

#### API
```typescript
class ChecksumHelper {
  // 计算校验和
  static async calculateChecksum(data: string): Promise<string>

  // 验证校验和
  static async verifyChecksum(
    data: string,
    expectedChecksum: string
  ): Promise<boolean>
}
```

### FileHelper.ets
文件操作辅助

#### 功能
- 文件读写
- 路径处理
- 权限检查
- 临时文件管理

#### API
```typescript
class FileHelper {
  // 读取文件
  static async readFile(filePath: string): Promise<string>

  // 写入文件
  static async writeFile(
    filePath: string,
    content: string
  ): Promise<void>

  // 检查文件存在
  static async fileExists(filePath: string): Promise<boolean>
}
```

---

## 类型定义 (types/)

### ExportTypes.ets
包含所有导出相关的类型定义：

#### 接口
- `ExportData`：导出数据结构
- `ExportOptions`：导出选项
- `ImportResult`：导入结果
- `ImportOptions`：导入选项
- `EncryptionParams`：加密参数

#### 枚举
- `ExportErrorCode`：错误代码

#### 常量
- `EXPORT_VERSION`：导出格式版本
- `CHUNK_SIZE`：分块大小
- `DEFAULT_ENCRYPTION_PARAMS`：默认加密参数

---

## 使用示例

### 导出数据
```typescript
import { ExportService } from '../service/export';

// 导出最近30天的数据，加密保护
const result = await ExportService.exportToFile(
  userId,
  '/path/to/backup.json',
  {
    dateRange: {
      start: Date.now() - 30 * 24 * 60 * 60 * 1000,
      end: Date.now()
    },
    includeCategories: true,
    includeTags: true,
    encrypt: true,
    password: 'user-password'
  }
);
```

### 导入数据
```typescript
import { ImportService } from '../service/export';

// 从备份文件导入
const result = await ImportService.importFromFile(
  userId,
  '/path/to/backup.json',
  {
    password: 'user-password',
    onDuplicate: 'skip' // 跳过重复数据
  }
);

console.log(`成功导入 ${result.statistics.billsImported} 条账单`);
```

### 数据加密
```typescript
import { EncryptionModule } from '../service/export';

// 加密敏感数据
const encrypted = await EncryptionModule.encrypt(
  JSON.stringify(sensitiveData),
  'password123'
);

// 解密数据
const decrypted = await EncryptionModule.decrypt(
  encrypted,
  'password123'
);
```

---

## 安全考虑

### 加密强度
- **算法**：AES-256-GCM
- **密钥派生**：PBKDF2，100,000 次迭代
- **盐值**：每次加密生成随机 16 字节
- **完整性**：GCM 模式提供认证标签

### 密码要求
- 最小长度：8 字符
- 建议：使用大小写字母、数字、特殊字符

### 数据保护
- 导出文件包含校验和
- 支持元数据完整性验证
- 敏感字段自动加密

---

## 错误处理

### 导出错误
- `EXPORT_NO_DATA`：无数据可导出
- `EXPORT_FILE_ERROR`：文件写入失败
- `EXPORT_ENCRYPTION_ERROR`：加密失败

### 导入错误
- `IMPORT_FILE_NOT_FOUND`：文件不存在
- `IMPORT_INVALID_FORMAT`：格式错误
- `IMPORT_DECRYPTION_ERROR`：解密失败（密码错误）
- `IMPORT_VERSION_MISMATCH`：版本不兼容

---

## 性能优化

### 大文件处理
- 分块读写，避免内存溢出
- 流式处理，减少内存占用

### 批量操作
- 数据库批量插入，提升性能
- 事务管理，确保一致性

---

## 版本兼容

当前版本：**v1.0**

### 版本策略
- 主版本变更：数据格式不兼容
- 次版本变更：向后兼容的功能增强
- 修订版本：Bug 修复

### 迁移指南
- 导出文件包含版本信息
- 导入时自动检测版本
- 不兼容版本会给出明确提示

---

*文档最后更新：2026-03-09*
