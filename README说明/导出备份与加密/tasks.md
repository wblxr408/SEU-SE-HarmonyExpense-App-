# 导出备份功能 - 简化任务列表（MVP版本）

## 任务概述

这是一个最小可运行版本(MVP)的任务列表，专注于核心的导出和导入功能，暂时不包括增量备份、云存储等高级特性。

---

## 已完成任务

- [x] **任务1**: 创建核心数据模型和接口定义
  - ✅ 已创建 `ExportTypes.ets` 文件
  - ✅ 定义了所有核心接口和类型

- [x] **任务2**: 实现加密模块
  - ✅ 已创建 `EncryptionModule.ets` 文件
  - ✅ 实现了 AES-256-GCM 加密/解密功能
  - ✅ 实现了 PBKDF2 密钥派生

---

## 待完成任务（按优先级排序）

### 🔴 高优先级 - 核心功能

#### ✅ 任务3: 实现基础导出服务
**文件**: `entry/src/main/ets/service/export/ExportService.ets`

**功能清单**:
- [x] 实现 `exportUserData(userId: number, options: ExportOptions): Promise<string>` 方法
  - 收集用户的所有数据（账户、分类、账单、预算、标签）
  - 生成 ExportData 结构
  - 计算 SHA-256 校验和
  - 可选加密数据
  - 保存到文件
  - 返回文件路径

**依赖**: 现有的 DAO 类（UserDAO, AccountDAO, CategoryDAO, BillDAO, BudgetDAO, TagDAO）

---

#### ✅ 任务4: 实现基础导入服务
**文件**: `entry/src/main/ets/service/export/ImportService.ets`

**功能清单**:
- [x] 实现 `importUserData(filePath: string, password?: string): Promise<ImportResult>` 方法
  - 读取文件内容
  - 可选解密数据
  - 验证校验和
  - 导入数据到数据库（使用事务）
  - 返回导入统计

**依赖**: 现有的 DAO 类

---

#### ✅ 任务5: 实现文件操作工具
**文件**: `entry/src/main/ets/service/export/FileHelper.ets`

**功能清单**:
- [x] `saveToFile(content: string, fileName: string): Promise<string>` - 保存内容到文件
- [x] `readFromFile(filePath: string): Promise<string>` - 从文件读取内容
- [x] `generateFileName(userId: number, format: string, encrypted: boolean): string` - 生成文件名
- [x] `getExportDirectory(): Promise<string>` - 获取导出目录路径

**依赖**: `@ohos.file.fs`

---

#### ✅ 任务6: 实现校验和工具
**文件**: `entry/src/main/ets/service/export/ChecksumHelper.ets`

**功能清单**:
- [x] `generateChecksum(data: string): Promise<string>` - 生成 SHA-256 校验和
- [x] `verifyChecksum(data: string, expectedChecksum: string): Promise<boolean>` - 验证校验和

**依赖**: `@ohos.security.cryptoFramework`

---

#### ✅ 额外完成: 扩展 TagDAO
**文件**: `entry/src/main/ets/dao/TagDAO.ets`

**功能清单**:
- [x] 添加 `getBillTagsByUserId(userId: number): Promise<Array<BillTag>>` 方法
  - 查询用户的所有账单标签关联
  - 用于导出功能

---

### 🟡 中优先级 - 增强功能

#### ✅ 任务7: 创建统一导出入口
**文件**: `entry/src/main/ets/service/export/index.ets`

**功能清单**:
- [x] 导出 ExportService
- [x] 导出 ImportService
- [x] 导出 EncryptionModule
- [x] 导出 FileHelper 和 ChecksumHelper
- [x] 导出所有类型定义
- [x] 导出常量

---

#### ✅ 任务8: 添加详细的使用示例
**文件**: `README说明/导出备份使用示例.md`

**内容清单**:
- [x] 导出数据示例（无加密）
- [x] 导出数据示例（加密）
- [x] 导入数据示例（无加密）
- [x] 导入数据示例（加密）
- [x] 在UI组件中使用示例
- [x] 错误处理示例
- [x] 密码强度验证示例
- [x] 性能优化建议
- [x] 常见问题解答

---

### 🟢 低优先级 - 可选功能（暂不实现）

#### 任务9: 编写基础测试（可选）
**文件**: `entry/ohosTest/ets/test/service/ExportImport.test.ets`

**说明**: 由于时间限制，测试功能暂不实现。建议在实际使用中进行手动测试。

**测试清单**:
- [ ] 测试导出功能
- [ ] 测试导入功能
- [ ] 测试加密导出导入
- [ ] 测试校验和验证
- [ ] 测试错误处理
- [ ] 测试大数据量场景

---

## 简化的实现方案

### 核心简化点

1. **不实现增量备份** - 只做全量导出
2. **不实现云存储** - 只保存到本地文件系统
3. **不实现CSV格式** - 只支持JSON格式
4. **不实现日期范围过滤** - 导出所有数据
5. **不实现已删除数据选项** - 只导出未删除数据
6. **不创建备份元数据表** - 不记录备份历史

### 数据流程

```
导出流程:
用户数据 → 收集数据 → 生成JSON → [可选加密] → 保存文件 → 返回路径

导入流程:
文件路径 → 读取文件 → [可选解密] → 验证校验和 → 导入数据库 → 返回统计
```

---

## 快速开始指南

### 第一步: 实现 FileHelper（任务5）
这是最基础的工具，其他服务都依赖它。

### 第二步: 实现 ChecksumHelper（任务6）
用于数据完整性验证。

### 第三步: 实现 ExportService（任务3）
核心导出功能。

### 第四步: 实现 ImportService（任务4）
核心导入功能。

### 第五步: 创建统一入口（任务7）
方便使用。

### 第六步: 编写使用示例（任务8）
帮助理解如何使用。

---

## 预计工作量

- **任务3-6**: 每个任务约 1-2 小时
- **任务7-8**: 每个任务约 0.5-1 小时
- **总计**: 约 6-10 小时完成 MVP 版本

---

**版本**: v2.0 (简化版)  
**创建时间**: 2025-11-11  
**目标**: 快速实现可运行的导出备份系统
