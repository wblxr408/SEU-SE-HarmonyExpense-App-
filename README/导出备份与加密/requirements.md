# 导出备份功能需求文档（MVP简化版）

## 简介

本文档定义了基于ArkTS的HarmonyOS应用数据导出和导入功能的最小可行需求(MVP)。该功能允许用户导出、加密和恢复应用数据，确保数据的完整性和机密性。

**简化说明**: 本版本专注于核心的导出/导入功能，暂不包括增量备份、云存储、CSV格式等高级特性。

## 术语表

- **ExportService**: 导出服务，负责收集、序列化和保存用户数据
- **ImportService**: 导入服务，负责读取、验证和恢复备份数据
- **EncryptionModule**: 加密模块，使用AES-256-GCM算法对数据进行加密和解密
- **BackupFile**: 备份文件，包含用户所有数据的JSON格式文件
- **Checksum**: 校验和，使用SHA-256算法生成的数据完整性验证码
- **PBKDF2**: 基于密码的密钥派生函数，用于从用户密码生成加密密钥

## 核心需求（MVP版本）

### 需求 1: 数据导出功能

**用户故事:** 作为应用用户，我希望能够导出我的所有账单、账户、分类等数据到JSON文件，以便进行数据备份或迁移到其他设备。

#### 验收标准

1. WHEN 用户请求导出数据时，THE ExportService SHALL 收集用户的所有账户、分类、账单、预算、标签和标签关联数据（仅未删除的数据）
2. WHEN 数据收集完成时，THE ExportService SHALL 生成包含版本号、导出时间、用户ID和数据内容的ExportData结构
3. WHEN 数据准备完成时，THE ExportService SHALL 将数据序列化为JSON字符串
4. WHEN 数据序列化完成时，THE ExportService SHALL 使用SHA-256算法生成数据校验和并存储在ExportData中
5. WHEN 校验和生成完成时，THE ExportService SHALL 将JSON数据保存到本地文件并返回文件路径

### 需求 2: 数据加密功能

**用户故事:** 作为注重隐私的用户，我希望导出的数据能够使用密码加密，以防止未授权访问我的财务信息。

#### 验收标准

1. WHEN 用户启用加密选项并提供密码时，THE EncryptionModule SHALL 生成16字节的随机盐值
2. WHEN 盐值生成后，THE EncryptionModule SHALL 使用PBKDF2算法和100000次迭代从密码派生256位AES密钥
3. WHEN 密钥派生完成时，THE EncryptionModule SHALL 生成12字节的随机初始化向量(IV)
4. WHEN IV生成后，THE EncryptionModule SHALL 使用AES-256-GCM模式加密数据并生成16字节认证标签
5. WHEN 加密完成时，THE EncryptionModule SHALL 按照"盐值+IV+认证标签+密文"的顺序组合数据并进行Base64编码

### 需求 3: 备份文件保存功能

**用户故事:** 作为用户，我希望导出的备份文件能够保存到设备的文件系统中，以便我可以手动管理这些备份。

#### 验收标准

1. WHEN 数据准备完成时，THE FileHelper SHALL 在应用文件目录下创建exports子目录
2. WHEN 目录创建完成时，THE FileHelper SHALL 生成包含用户ID和时间戳的唯一文件名（格式: backup_用户ID_时间戳.json 或 .enc）
3. WHERE 数据已加密，THE FileHelper SHALL 使用.enc扩展名保存文件
4. WHERE 数据未加密，THE FileHelper SHALL 使用.json扩展名保存文件
5. WHEN 文件保存完成时，THE FileHelper SHALL 返回完整的文件路径给调用者

### 需求 4: 数据导入功能

**用户故事:** 作为用户，我希望能够导入之前导出的备份文件，以便恢复我的数据或在新设备上使用。

#### 验收标准

1. WHEN 用户提供备份文件路径时，THE FileHelper SHALL 读取文件内容
2. IF 文件扩展名为.enc，THEN THE ImportService SHALL 使用用户提供的密码调用EncryptionModule解密数据
3. WHEN 数据解密或读取完成时，THE ImportService SHALL 解析JSON数据为ExportData结构
4. WHEN 数据解析完成时，THE ChecksumHelper SHALL 重新计算校验和并与文件中的校验和比较
5. IF 校验和不匹配，THEN THE ImportService SHALL 抛出"数据校验失败"错误并终止导入

### 需求 5: 数据库导入功能

**用户故事:** 作为用户，我希望导入的数据能够正确地保存到数据库中，并且在导入失败时能够回滚所有更改。

#### 验收标准

1. WHEN 数据验证通过时，THE ImportService SHALL 通过DatabaseManager开启数据库事务
2. WHEN 事务开启后，THE ImportService SHALL 按照用户、账户、分类、账单、预算、标签、标签关联的顺序导入数据
3. WHEN 导入每条记录时，THE ImportService SHALL 调用相应DAO的insert方法
4. IF 任何记录导入失败，THEN THE ImportService SHALL 记录错误信息到结果对象的errors数组
5. WHEN 所有数据导入完成且无致命错误时，THE ImportService SHALL 提交事务
6. IF 发生致命错误，THEN THE ImportService SHALL 回滚事务并抛出异常

### 需求 6: 数据解密功能

**用户故事:** 作为用户，我希望能够使用正确的密码解密备份文件，如果密码错误则应该收到明确的错误提示。

#### 验收标准

1. WHEN 接收到加密数据时，THE EncryptionModule SHALL 对Base64编码的数据进行解码
2. WHEN 解码完成时，THE EncryptionModule SHALL 从数据中提取16字节盐值、12字节IV、16字节认证标签和密文
3. WHEN 数据提取完成时，THE EncryptionModule SHALL 使用PBKDF2从密码和盐值派生解密密钥
4. WHEN 密钥派生完成时，THE EncryptionModule SHALL 使用AES-256-GCM模式和认证标签解密数据
5. IF 解密失败或认证标签验证失败，THEN THE EncryptionModule SHALL 抛出"解密失败，密码可能不正确"错误

### 需求 7: 错误处理功能

**用户故事:** 作为用户，我希望在导出或导入失败时能够收到清晰的错误提示，帮助我理解问题所在。

#### 验收标准

1. WHEN 任何操作发生错误时，THE System SHALL 使用ExportError类包装错误信息
2. WHEN 捕获异常时，THE System SHALL 包含错误代码（ExportErrorCode）和详细错误信息
3. IF 文件操作失败，THEN THE System SHALL 抛出FILE_SYSTEM_ERROR错误
4. IF 加密解密失败，THEN THE System SHALL 抛出ENCRYPTION_ERROR错误
5. IF 数据验证失败，THEN THE System SHALL 抛出VALIDATION_ERROR错误
6. WHEN 返回错误给用户时，THE System SHALL 提供用户友好的错误消息

---

## 暂不实现的功能（未来版本）

以下功能在MVP版本中不实现，可在后续版本中添加：

- ❌ 增量备份功能
- ❌ 云端同步备份功能
- ❌ CSV格式导出
- ❌ 日期范围过滤
- ❌ 包含已删除数据选项
- ❌ 备份历史记录
- ❌ 自动备份调度
