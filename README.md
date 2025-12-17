# HarmonyExpense - 鸿蒙记账应用

## 目录

- [项目概述](#项目概述)
- [功能特性](#功能特性)
- [技术架构](#技术架构)
- [项目结构](#项目结构)
- [环境要求](#环境要求)
- [安装部署](#安装部署)
- [使用说明手册](#使用说明手册)
- [数据库设计](#数据库设计)
- [API接口文档](#api接口文档)
- [测试指南](#测试指南)
- [安全机制](#安全机制)
- [性能优化](#性能优化)
- [版本历史](#版本历史)
- [常见问题](#常见问题)
- [参考资料](#参考资料)

---

## 项目概述

### 基本信息

| 项目属性 | 说明 |
|---------|------|
| 项目名称 | HarmonyExpense (健康记账) |
| 应用包名 | com.example.healthydiet |
| 当前版本 | 1.2.0 |
| 技术栈 | HarmonyOS + ArkTS + RelationalStore |
| 架构模式 | 分层架构 (Layered Architecture) |
| 数据库 | SQLite (通过 RelationalStore API) |
| 测试框架 | Hypium |

### 项目简介

HarmonyExpense是一款基于HarmonyOS平台开发的个人记账应用，采用ArkTS语言和声明式UI框架ArkUI构建。应用提供完整的账单管理、分类管理、预算管理、标签系统、数据统计、数据导出备份及云端同步等功能，帮助用户有效管理个人财务。

### 设计目标

1. **功能完整性**: 提供从记账到统计分析的全流程财务管理功能
2. **数据安全性**: 采用AES-256-GCM加密算法保护用户敏感数据
3. **高性能**: 通过索引优化、缓存机制、批量操作等手段确保应用流畅运行
4. **可扩展性**: 采用分层架构设计，便于功能扩展和维护
5. **代码规范**: 遵循单一职责、依赖倒置等设计原则，确保代码质量

---

## 功能特性

### 核心功能模块

#### 1. 用户管理
- 用户注册与登录
- 用户信息维护
- 密码哈希存储 (SHA-256)
- 会话管理与自动过期机制
- 邮箱唯一性验证

#### 2. 账户管理
- 多账户创建与管理 (现金、银行卡、信用卡等)
- 账户余额实时更新
- 账户类型分类
- 批量操作支持
- 余额范围查询

#### 3. 分类管理
- 支出/收入分类创建
- 树形层级结构 (支持无限层级)
- 分类图标和颜色自定义
- 排序功能
- 软删除与恢复
- 分类聚合统计

#### 4. 账单管理
- 账单CRUD操作
- 按日期范围查询
- 按分类筛选
- 分页查询与游标分页
- 批量操作
- 软删除

#### 5. 预算管理
- 预算创建与编辑
- 周期管理 (月度/年度)
- 预算状态监控
- 预算提醒功能

#### 6. 标签系统
- 标签创建与管理
- 账单-标签多对多关联
- 批量标签设置
- 热门标签查询
- 标签聚合统计

#### 7. 统计分析
- 月度收支统计
- 分类统计报表
- 按分类/标签聚合
- 收支趋势分析

#### 8. 数据导出与备份
- JSON格式数据导出
- AES-256-GCM加密备份
- 数据导入恢复
- SHA-256校验和验证
- 事务化导入保证数据完整性

#### 9. 云端同步 (v1.2.0新增)
- 数据上传至云端
- 云端数据下载
- 双向增量同步
- 同步历史记录
- 可选数据加密

#### 10. 定期提醒 (v1.2.0新增)
- 账单提醒创建
- 预算提醒
- 多种频率支持 (一次性/每日/每周/每月/每年)
- 系统通知集成

---

## 技术架构

### 分层架构设计

项目采用经典的四层架构设计，各层职责明确，依赖关系单向:

```
+--------------------------------------------------+
|           Presentation Layer (表示层)             |
|               pages/ (UI组件)                     |
|          - Index.ets (首页)                       |
|          - AddBill.ets (添加账单)                 |
|          - CategoryManagement.ets (分类管理)      |
+--------------------------------------------------+
                        |
                        v
+--------------------------------------------------+
|          Business Logic Layer (业务层)            |
|               service/ (业务服务)                 |
|          - UserSessionService (会话管理)          |
|          - ExportService (导出服务)               |
|          - ImportService (导入服务)               |
|          - ReminderService (提醒服务)             |
|          - CloudSyncService (云同步服务)          |
|          - EncryptionModule (加密模块)            |
+--------------------------------------------------+
                        |
                        v
+--------------------------------------------------+
|         Data Access Layer (数据访问层)            |
|               dao/ (数据访问对象)                 |
|          - UserDAO, AccountDAO, BillDAO           |
|          - CategoryDAO, BudgetDAO, TagDAO         |
|          - StatisticsDAO, ReminderDAO             |
|          - CloudSyncRecordDAO                     |
+--------------------------------------------------+
                        |
                        v
+--------------------------------------------------+
|       Infrastructure Layer (基础设施层)           |
|          database/ (数据库基础设施)               |
|          - DatabaseManager (数据库管理)           |
|          - IndexManager (索引管理)                |
|          - BatchQueryHelper (批量查询)            |
|          - CacheManager (缓存管理)                |
|          - PerformanceMonitor (性能监控)          |
|          - DatabaseConfigOptimizer (配置优化)     |
|                                                   |
|          model/ (数据模型)                        |
|          - User, Account, Bill, Category          |
|          - Budget, Tag, Statistics, Reminder      |
+--------------------------------------------------+
```

### 架构设计原则

#### 单一职责原则 (SRP)
- DAO层: 仅负责单表的CRUD操作，不包含业务逻辑
- Service层: 处理跨表业务逻辑和复杂操作
- Database层: 专注于数据库连接、事务、索引等基础设施

#### 依赖倒置原则 (DIP)
- 上层依赖下层的抽象接口，而非具体实现
- 所有DAO通过 `DatabaseManager.getDatabase()` 获取数据库实例
- 统一的错误处理和日志记录机制

#### 开闭原则 (OCP)
- 通过继承和组合扩展功能，而非修改现有代码
- 新增DAO只需实现标准接口，无需修改DatabaseManager

---

## 项目结构

```
HarmonyExpense/
|-- AppScope/                          # 应用全局配置
|   |-- app.json5                      # 应用配置文件
|   +-- resources/                     # 全局资源文件
|
|-- entry/                             # 主模块入口
|   |-- src/
|   |   +-- main/
|   |       |-- ets/                   # ArkTS源代码
|   |       |   |-- common/            # 公共模块
|   |       |   |   |-- AppConfig.ets      # 应用配置
|   |       |   |   |-- Constants.ets      # 常量定义
|   |       |   |   |-- BreakpointSystem.ets # 响应式断点
|   |       |   |   +-- DAOHelper.ets      # DAO辅助工具
|   |       |   |
|   |       |   |-- dao/               # 数据访问对象层
|   |       |   |   |-- UserDAO.ets        # 用户数据访问
|   |       |   |   |-- AccountDAO.ets     # 账户数据访问
|   |       |   |   |-- BillDAO.ets        # 账单数据访问
|   |       |   |   |-- CategoryDAO.ets    # 分类数据访问
|   |       |   |   |-- BudgetDAO.ets      # 预算数据访问
|   |       |   |   |-- TagDAO.ets         # 标签数据访问
|   |       |   |   |-- StatisticsDAO.ets  # 统计数据访问
|   |       |   |   |-- ReminderDAO.ets    # 提醒数据访问
|   |       |   |   |-- CloudSyncRecordDAO.ets # 云同步记录
|   |       |   |   +-- index.ets          # 导出索引
|   |       |   |
|   |       |   |-- database/          # 数据库基础设施
|   |       |   |   |-- DatabaseManager.ets    # 数据库管理器
|   |       |   |   |-- IndexManager.ets       # 索引管理器
|   |       |   |   |-- BatchQueryHelper.ets   # 批量查询助手
|   |       |   |   |-- CacheManager.ets       # 缓存管理器
|   |       |   |   |-- PerformanceMonitor.ets # 性能监控
|   |       |   |   |-- DatabaseConfigOptimizer.ets # 配置优化器
|   |       |   |   +-- QueryHelper.ets        # 查询助手
|   |       |   |
|   |       |   |-- model/             # 数据模型层
|   |       |   |   |-- User.ets           # 用户模型
|   |       |   |   |-- Account.ets        # 账户模型
|   |       |   |   |-- Bill.ets           # 账单模型
|   |       |   |   |-- Category.ets       # 分类模型
|   |       |   |   |-- Budget.ets         # 预算模型
|   |       |   |   |-- Tag.ets            # 标签模型
|   |       |   |   |-- BillTag.ets        # 账单标签关联
|   |       |   |   |-- Statistics.ets     # 统计模型
|   |       |   |   |-- Reminder.ets       # 提醒模型
|   |       |   |   |-- CloudSyncRecord.ets # 云同步记录模型
|   |       |   |   |-- AggregationTypes.ets # 聚合类型定义
|   |       |   |   +-- index.ets          # 导出索引
|   |       |   |
|   |       |   |-- pages/             # 页面组件层
|   |       |   |   |-- Index.ets          # 首页
|   |       |   |   |-- AddBill.ets        # 添加账单页
|   |       |   |   +-- CategoryManagement.ets # 分类管理页
|   |       |   |
|   |       |   |-- service/           # 业务服务层
|   |       |   |   |-- UserSessionService.ets # 用户会话服务
|   |       |   |   |-- ReminderService.ets    # 提醒服务
|   |       |   |   |-- CloudSyncService.ets   # 云同步服务
|   |       |   |   |-- export/            # 导出相关
|   |       |   |   |   |-- ExportService.ets  # 导出服务
|   |       |   |   |   |-- ImportService.ets  # 导入服务
|   |       |   |   |   |-- EncryptionModule.ets # 加密模块
|   |       |   |   |   |-- FileHelper.ets     # 文件助手
|   |       |   |   |   |-- ChecksumHelper.ets # 校验和助手
|   |       |   |   |   +-- types/         # 类型定义
|   |       |   |   +-- index.ets          # 导出索引
|   |       |   |
|   |       |   |-- entryability/      # 入口能力
|   |       |   |   +-- EntryAbility.ets   # 应用入口
|   |       |   |
|   |       |   +-- mock/              # 模拟数据
|   |       |       +-- MockData.ets       # 测试数据
|   |       |
|   |       +-- resources/             # 资源文件
|   |
|   +-- ohosTest/                      # 测试目录
|       +-- ets/test/
|           |-- model/                 # 模型层测试
|           |-- dao/                   # DAO层测试
|           |-- pages/                 # 页面层测试
|           +-- services/              # 服务层测试
|
|-- README说明/                        # 项目文档
|   |-- UML图/                         # UML设计图
|   |-- 测试说明/                      # 测试文档
|   |-- 导出备份与加密/                # 导出功能文档
|   |-- 索引优化与批量查询/            # 性能优化文档
|   +-- categories-tag/                # 分类标签文档
|
|-- oh-package.json5                   # 包配置文件
|-- build-profile.json5                # 构建配置
+-- hvigorfile.ts                      # 构建脚本
```

---

## 环境要求

### 开发环境

| 组件 | 版本要求 |
|------|---------|
| DevEco Studio | 4.0及以上 |
| HarmonyOS SDK | API 9及以上 |
| Node.js | 14.x及以上 |
| ohpm | 1.0及以上 |

### 运行环境

| 设备类型 | 系统版本 |
|---------|---------|
| HarmonyOS手机 | HarmonyOS 3.0及以上 |
| HarmonyOS平板 | HarmonyOS 3.0及以上 |
| 模拟器 | DevEco Studio内置模拟器 |

### 依赖项

```json
{
  "dependencies": {},
  "devDependencies": {
    "@ohos/hypium": "1.0.6"
  }
}
```

---

## 安装部署

### 方式一: DevEco Studio打开项目

1. **下载项目源码**
   ```bash
   git clone https://github.com/your-repo/HarmonyExpense.git
   cd HarmonyExpense
   ```

2. **打开DevEco Studio**
   - 启动DevEco Studio
   - 选择 File -> Open -> 选择项目根目录

3. **同步项目依赖**
   - DevEco Studio会自动检测并下载依赖
   - 或手动执行: File -> Sync and Refresh Project

4. **配置签名**
   - 打开 File -> Project Structure -> Signing Configs
   - 配置自动签名或手动配置签名证书

5. **连接设备或启动模拟器**
   - 连接真实HarmonyOS设备，并开启USB调试
   - 或启动DevEco Studio内置模拟器

6. **运行应用**
   - 点击工具栏的运行按钮
   - 或使用快捷键 Shift + F10

### 方式二: 命令行构建

1. **安装ohpm**
   ```bash
   npm install -g @aspect/ohpm
   ```

2. **安装项目依赖**
   ```bash
   cd HarmonyExpense
   ohpm install
   ```

3. **构建项目**
   ```bash
   hvigorw assembleHap
   ```

4. **安装到设备**
   ```bash
   hdc install entry/build/default/outputs/default/entry-default-signed.hap
   ```

---

## 使用说明手册

### 一、首次使用

#### 1.1 应用启动
启动应用后，系统会自动初始化数据库并创建必要的数据表。首次使用时会自动创建一个默认用户用于测试。

#### 1.2 用户登录 (v1.2.0)
```typescript
import { UserSessionService } from '../service/UserSessionService';

// 用户注册
const registerResult = await UserSessionService.register(
  '用户名',
  'email@example.com',
  '密码'
);

// 用户登录
const loginResult = await UserSessionService.login(
  'email@example.com',
  '密码'
);

// 检查登录状态
if (UserSessionService.isLoggedIn()) {
  const userId = UserSessionService.getCurrentUserId();
}

// 用户登出
UserSessionService.logout();
```

### 二、账单管理

#### 2.1 添加账单
1. 在首页点击"记一笔"按钮
2. 选择账单类型 (支出/收入)
3. 输入金额
4. 选择分类
5. 选择账户
6. 添加备注 (可选)
7. 选择日期
8. 点击保存

#### 2.2 查看账单列表
- 首页默认显示当月账单
- 点击月份选择器可切换月份
- 使用分类筛选器可按分类过滤

#### 2.3 编辑/删除账单
- 点击账单项可查看详情
- 在详情页可编辑或删除账单

### 三、分类管理

#### 3.1 查看分类
1. 在首页点击"管理分类"按钮
2. 页面显示所有分类的树形结构

#### 3.2 添加分类
1. 点击添加按钮
2. 输入分类名称
3. 选择分类类型 (支出/收入)
4. 选择父分类 (可选，用于创建子分类)
5. 选择图标和颜色
6. 保存

#### 3.3 编辑/删除分类
- 长按分类项可编辑或删除
- 删除分类为软删除，可恢复

### 四、预算管理

#### 4.1 创建预算
```typescript
import { BudgetDAO } from '../dao/BudgetDAO';
import { Budget } from '../model/Budget';

const budget = new Budget();
budget.userId = userId;
budget.categoryId = categoryId;
budget.amount = 5000;
budget.period = 'monthly';
budget.startDate = '2025-01-01';
budget.isActive = 1;

await BudgetDAO.insert(budget);
```

#### 4.2 查询预算
```typescript
// 获取所有活跃预算
const activeBudgets = await BudgetDAO.getAllActive(userId);

// 获取指定预算
const budget = await BudgetDAO.getById(userId, budgetId);
```

### 五、标签系统

#### 5.1 创建标签
```typescript
import { TagDAO } from '../dao/TagDAO';
import { Tag } from '../model/Tag';

const tag = new Tag();
tag.userId = userId;
tag.name = '必要支出';
tag.color = '#FF6B6B';

await TagDAO.insert(tag);
```

#### 5.2 为账单添加标签
```typescript
// 为账单添加单个标签
await TagDAO.addTagToBill(billId, tagId);

// 批量设置账单标签
await TagDAO.setTagsForBill(billId, [tagId1, tagId2, tagId3]);

// 获取账单的所有标签
const tags = await TagDAO.getTagsByBillId(billId);
```

#### 5.3 标签统计
```typescript
// 获取热门标签
const popularTags = await TagDAO.getPopularTags(userId, 10);

// 按标签聚合统计
const tagStats = await TagDAO.aggregateByTag(userId, startDate, endDate);
```

### 六、数据导出与备份

#### 6.1 导出数据
```typescript
import { ExportService } from '../service/export/ExportService';

// 导出配置
const options = {
  format: 'json',
  encrypt: true,
  password: '用户密码',
  includeDeleted: false,
  dateRange: {
    startDate: '2025-01-01',
    endDate: '2025-12-31'
  }
};

// 执行导出
const filePath = await ExportService.exportUserData(userId, options);
console.log('备份文件已保存:', filePath);
```

#### 6.2 导入数据
```typescript
import { ImportService } from '../service/export/ImportService';

// 导入备份文件
const result = await ImportService.importUserData(
  filePath,
  '解密密码'
);

if (result.success) {
  console.log('导入成功:', result.imported);
} else {
  console.error('导入失败:', result.errors);
}
```

### 七、云端同步 (v1.2.0)

#### 7.1 执行同步
```typescript
import { CloudSyncService } from '../service/CloudSyncService';

// 双向同步
const result = await CloudSyncService.sync({
  userId: userId,
  syncType: 'incremental',
  syncDirection: 'bidirectional',
  dataTypes: ['accounts', 'bills', 'categories', 'budgets']
});

if (result.success) {
  console.log('同步成功，同步记录数:', result.recordCount);
}
```

#### 7.2 同步类型说明

| 同步类型 | 说明 |
|---------|------|
| full | 全量同步，同步所有数据 |
| incremental | 增量同步，仅同步变更数据 |

| 同步方向 | 说明 |
|---------|------|
| upload | 仅上传本地数据到云端 |
| download | 仅从云端下载数据到本地 |
| bidirectional | 双向同步 |

#### 7.3 查看同步历史
```typescript
// 获取同步历史
const history = await CloudSyncService.getSyncHistory(userId, 20);

// 获取最后同步时间
const lastSyncTime = await CloudSyncService.getLastSyncTime(userId);

// 获取同步统计
const stats = await CloudSyncService.getSyncStatistics(userId);
```

### 八、定期提醒 (v1.2.0)

#### 8.1 创建提醒
```typescript
import { ReminderService } from '../service/ReminderService';

// 创建账单提醒
const reminderId = await ReminderService.createReminder({
  userId: userId,
  type: 'bill',
  title: '房租提醒',
  description: '每月1号缴纳房租',
  amount: 3000,
  categoryId: categoryId,
  frequency: 'monthly',
  reminderDate: '2025-01-01T09:00:00.000Z'
});

// 创建预算提醒
const budgetReminderId = await ReminderService.createBudgetReminder(
  userId,
  budgetId,
  '2025-01-01T09:00:00.000Z',
  'monthly'
);
```

#### 8.2 提醒频率

| 频率 | 说明 |
|------|------|
| once | 一次性提醒，触发后自动停用 |
| daily | 每日提醒 |
| weekly | 每周提醒 |
| monthly | 每月提醒 |
| yearly | 每年提醒 |

#### 8.3 管理提醒
```typescript
// 获取活跃提醒
const activeReminders = await ReminderService.getActiveReminders(userId);

// 获取即将到期的提醒 (未来7天)
const upcomingReminders = await ReminderService.getUpcomingReminders(userId, 7);

// 激活/停用提醒
await ReminderService.toggleReminder(reminderId, false); // 停用
await ReminderService.toggleReminder(reminderId, true);  // 激活

// 检查并触发到期提醒
const results = await ReminderService.checkAndTriggerDueReminders(userId);
```

---

## 数据库设计

### 数据库表结构

#### 1. users表 - 用户信息

| 字段名 | 类型 | 约束 | 说明 |
|-------|------|------|------|
| user_id | INTEGER | PRIMARY KEY AUTOINCREMENT | 用户ID |
| username | TEXT | NOT NULL | 用户名 |
| email | TEXT | UNIQUE NOT NULL | 邮箱 |
| password_hash | TEXT | NOT NULL | 密码哈希 |
| created_at | TEXT | NOT NULL | 创建时间 |
| updated_at | TEXT | NOT NULL | 更新时间 |
| is_deleted | INTEGER | DEFAULT 0 | 删除标记 |

#### 2. accounts表 - 账户信息

| 字段名 | 类型 | 约束 | 说明 |
|-------|------|------|------|
| account_id | INTEGER | PRIMARY KEY AUTOINCREMENT | 账户ID |
| user_id | INTEGER | NOT NULL, FK | 用户ID |
| name | TEXT | NOT NULL | 账户名称 |
| type | TEXT | NOT NULL | 账户类型 |
| balance | REAL | NOT NULL DEFAULT 0 | 余额 |
| color | TEXT | NOT NULL DEFAULT '#1890FF' | 颜色 |
| created_at | TEXT | NOT NULL | 创建时间 |
| updated_at | TEXT | NOT NULL | 更新时间 |
| is_deleted | INTEGER | DEFAULT 0 | 删除标记 |

#### 3. categories表 - 分类信息

| 字段名 | 类型 | 约束 | 说明 |
|-------|------|------|------|
| category_id | INTEGER | PRIMARY KEY AUTOINCREMENT | 分类ID |
| user_id | INTEGER | NOT NULL, FK | 用户ID |
| name | TEXT | NOT NULL | 分类名称 |
| type | TEXT | NOT NULL, CHECK IN ('expense','income') | 类型 |
| icon | TEXT | NOT NULL DEFAULT '...' | 图标 |
| color | TEXT | NOT NULL DEFAULT '#1890FF' | 颜色 |
| parent_category_id | INTEGER | DEFAULT 0 | 父分类ID |
| sort_order | INTEGER | DEFAULT 0 | 排序顺序 |
| created_at | TEXT | NOT NULL | 创建时间 |
| updated_at | TEXT | NOT NULL | 更新时间 |
| is_deleted | INTEGER | DEFAULT 0 | 删除标记 |

#### 4. bills表 - 账单记录

| 字段名 | 类型 | 约束 | 说明 |
|-------|------|------|------|
| bill_id | INTEGER | PRIMARY KEY AUTOINCREMENT | 账单ID |
| user_id | INTEGER | NOT NULL, FK | 用户ID |
| account_id | INTEGER | NOT NULL, FK | 账户ID |
| category_id | INTEGER | NOT NULL, FK | 分类ID |
| amount | REAL | NOT NULL | 金额 |
| type | TEXT | NOT NULL | 类型 (expense/income) |
| note | TEXT | | 备注 |
| transaction_date | TEXT | NOT NULL | 交易日期 |
| created_at | TEXT | NOT NULL | 创建时间 |
| updated_at | TEXT | NOT NULL | 更新时间 |
| is_deleted | INTEGER | DEFAULT 0 | 删除标记 |

#### 5. budgets表 - 预算信息

| 字段名 | 类型 | 约束 | 说明 |
|-------|------|------|------|
| budget_id | INTEGER | PRIMARY KEY AUTOINCREMENT | 预算ID |
| user_id | INTEGER | NOT NULL, FK | 用户ID |
| category_id | INTEGER | NOT NULL, FK | 分类ID |
| amount | REAL | NOT NULL | 预算金额 |
| period | TEXT | NOT NULL | 周期 (monthly/yearly) |
| start_date | TEXT | NOT NULL | 开始日期 |
| end_date | TEXT | | 结束日期 |
| is_active | INTEGER | DEFAULT 1 | 是否启用 |
| is_deleted | INTEGER | DEFAULT 0 | 删除标记 |
| created_at | TEXT | NOT NULL | 创建时间 |

#### 6. tags表 - 标签信息

| 字段名 | 类型 | 约束 | 说明 |
|-------|------|------|------|
| tag_id | INTEGER | PRIMARY KEY AUTOINCREMENT | 标签ID |
| user_id | INTEGER | NOT NULL, FK | 用户ID |
| name | TEXT | NOT NULL, UNIQUE(user_id,name) | 标签名称 |
| color | TEXT | DEFAULT '#52C41A' | 颜色 |
| usage_count | INTEGER | DEFAULT 0 | 使用次数 |
| created_at | TEXT | NOT NULL | 创建时间 |
| updated_at | TEXT | NOT NULL | 更新时间 |
| is_deleted | INTEGER | DEFAULT 0 | 删除标记 |

#### 7. bill_tags表 - 账单标签关联

| 字段名 | 类型 | 约束 | 说明 |
|-------|------|------|------|
| bill_id | INTEGER | NOT NULL, PK, FK | 账单ID |
| tag_id | INTEGER | NOT NULL, PK, FK | 标签ID |
| created_at | TEXT | NOT NULL | 创建时间 |

#### 8. reminders表 - 提醒信息 (v1.2.0)

| 字段名 | 类型 | 约束 | 说明 |
|-------|------|------|------|
| reminder_id | INTEGER | PRIMARY KEY AUTOINCREMENT | 提醒ID |
| user_id | INTEGER | NOT NULL, FK | 用户ID |
| type | TEXT | NOT NULL, CHECK IN ('bill','budget') | 类型 |
| title | TEXT | NOT NULL | 标题 |
| description | TEXT | | 描述 |
| amount | REAL | | 金额 |
| category_id | INTEGER | FK | 分类ID |
| account_id | INTEGER | FK | 账户ID |
| budget_id | INTEGER | FK | 预算ID |
| frequency | TEXT | NOT NULL | 频率 |
| reminder_date | TEXT | NOT NULL | 提醒日期 |
| next_reminder_date | TEXT | NOT NULL | 下次提醒日期 |
| is_active | INTEGER | DEFAULT 1 | 是否启用 |
| created_at | TEXT | NOT NULL | 创建时间 |
| updated_at | TEXT | NOT NULL | 更新时间 |
| is_deleted | INTEGER | DEFAULT 0 | 删除标记 |

#### 9. cloud_sync_records表 - 云同步记录 (v1.2.0)

| 字段名 | 类型 | 约束 | 说明 |
|-------|------|------|------|
| sync_id | INTEGER | PRIMARY KEY AUTOINCREMENT | 同步ID |
| user_id | INTEGER | NOT NULL, FK | 用户ID |
| sync_type | TEXT | NOT NULL | 同步类型 |
| sync_direction | TEXT | NOT NULL | 同步方向 |
| status | TEXT | NOT NULL | 状态 |
| data_types | TEXT | NOT NULL | 数据类型 |
| record_count | INTEGER | DEFAULT 0 | 记录数 |
| start_time | TEXT | NOT NULL | 开始时间 |
| end_time | TEXT | | 结束时间 |
| error_message | TEXT | | 错误信息 |
| cloud_provider | TEXT | NOT NULL | 云服务商 |
| last_sync_hash | TEXT | | 同步哈希 |
| created_at | TEXT | NOT NULL | 创建时间 |
| updated_at | TEXT | NOT NULL | 更新时间 |

### ER图

详细的ER图请参考: [README说明/UML图/er.puml](README说明/UML图/er.puml)

---

## API接口文档

### DAO层接口规范

所有DAO类遵循统一的接口规范:

```typescript
class ExampleDAO {
  // 基础CRUD
  static async insert(entity: Entity): Promise<void>
  static async getById(userId: number, entityId: number): Promise<Entity | null>
  static async getAll(userId: number): Promise<Entity[]>
  static async update(entity: Entity): Promise<void>
  static async softDelete(userId: number, entityId: number): Promise<void>

  // 批量操作
  static async bulkInsert(entities: Entity[]): Promise<void>

  // 辅助方法
  static async exists(entityId: number): Promise<boolean>
}
```

### Service层接口

#### UserSessionService

```typescript
class UserSessionService {
  // 用户登录
  static async login(email: string, password: string): Promise<LoginResult>

  // 用户注册
  static async register(username: string, email: string, password: string): Promise<RegisterResult>

  // 获取当前用户ID
  static getCurrentUserId(): number | null

  // 获取当前会话
  static getCurrentSession(): UserSession | null

  // 检查登录状态
  static isLoggedIn(): boolean

  // 用户登出
  static logout(): void
}
```

#### ExportService

```typescript
class ExportService {
  // 导出用户数据
  static async exportUserData(userId: number, options: ExportOptions): Promise<string>
}

interface ExportOptions {
  format: 'json' | 'csv';
  encrypt: boolean;
  password?: string;
  includeDeleted: boolean;
  dateRange?: {
    startDate: string;
    endDate: string;
  };
}
```

#### ImportService

```typescript
class ImportService {
  // 导入用户数据
  static async importUserData(filePath: string, password?: string): Promise<ImportResult>
}

interface ImportResult {
  success: boolean;
  imported: {
    users: number;
    accounts: number;
    categories: number;
    bills: number;
    budgets: number;
    tags: number;
  };
  errors: string[];
}
```

#### CloudSyncService

```typescript
class CloudSyncService {
  // 执行同步
  static async sync(options: SyncOptions): Promise<SyncResult>

  // 获取同步历史
  static async getSyncHistory(userId: number, limit?: number): Promise<CloudSyncRecord[]>

  // 获取最后同步时间
  static async getLastSyncTime(userId: number): Promise<string | null>

  // 取消同步
  static async cancelSync(userId: number): Promise<boolean>
}
```

#### ReminderService

```typescript
class ReminderService {
  // 创建提醒
  static async createReminder(options: ReminderOptions): Promise<number>

  // 创建预算提醒
  static async createBudgetReminder(userId: number, budgetId: number, reminderDate: string, frequency: string): Promise<number>

  // 获取活跃提醒
  static async getActiveReminders(userId: number): Promise<Reminder[]>

  // 获取即将到期提醒
  static async getUpcomingReminders(userId: number, days: number): Promise<Reminder[]>

  // 检查并触发提醒
  static async checkAndTriggerDueReminders(userId: number): Promise<TriggerResult[]>

  // 切换提醒状态
  static async toggleReminder(reminderId: number, isActive: boolean): Promise<void>
}
```

---

## 测试指南

### 测试架构

```
entry/ohosTest/ets/test/
|-- model/             # 模型层测试 (6个)
|   |-- User.test.ets
|   |-- Account.test.ets
|   |-- Category.test.ets
|   |-- Bill.test.ets
|   |-- Budget.test.ets
|   +-- Statistics.test.ets
|
|-- dao/               # DAO层测试 (6个)
|   |-- UserDAO.test.ets
|   |-- AccountDAO.test.ets
|   |-- CategoryDAO.test.ets
|   |-- BillDAO.test.ets
|   |-- BudgetDAO.test.ets
|   +-- StatisticsDAO.test.ets
|
|-- pages/             # UI层测试 (3个)
|   |-- IndexPage.test.ets
|   |-- AddBillPage.test.ets
|   +-- CategoryManagementPage.test.ets
|
+-- services/          # 服务层测试 (1个)
    +-- Transaction.test.ets
```

### 运行测试

#### 方法1: 通过DevEco Studio

1. 在项目结构中找到 `entry/ohosTest` 目录
2. 右键点击目录，选择 **Run 'All Tests'**

#### 方法2: 运行特定测试

1. 展开 `entry/ohosTest/ets/test` 目录
2. 选择要运行的测试文件
3. 右键点击，选择 **Run**

### 测试用例示例

```typescript
import { describe, it, expect, beforeAll } from '@ohos/hypium';
import { DatabaseManager } from '../../main/ets/database/DatabaseManager';
import { UserDAO } from '../../main/ets/dao/UserDAO';
import { User } from '../../main/ets/model/User';
import common from '@ohos.app.ability.common';

export default function UserDAOTest() {
  describe('UserDAO', () => {
    beforeAll(async () => {
      const ctx = getContext() as common.Context;
      await DatabaseManager.initDatabase(ctx);
    });

    it('should insert user successfully', 0, async () => {
      const user = new User();
      user.username = 'testuser';
      user.email = 'test@example.com';
      user.passwordHash = 'hash123';

      await UserDAO.insert(user);

      const result = await UserDAO.getByEmail('test@example.com');
      expect(result).not.toBeNull();
      expect(result?.username).assertEqual('testuser');
    });

    it('should validate email uniqueness', 0, async () => {
      const user1 = new User();
      user1.email = 'unique@example.com';
      await UserDAO.insert(user1);

      const user2 = new User();
      user2.email = 'unique@example.com';

      try {
        await UserDAO.insert(user2);
        expect().assertFail();
      } catch (error) {
        expect(error).not.toBeNull();
      }
    });
  });
}
```

### 测试最佳实践

1. **测试独立性**: 每个测试用例应独立运行，不依赖其他测试的结果
2. **测试数据清理**: 使用 `beforeEach` 或 `afterEach` 清理测试数据
3. **命名规范**: 测试名称应清晰描述测试目的
4. **覆盖全面**: 测试应覆盖正常情况、边界情况和异常情况

---

## 安全机制

### 数据加密

#### AES-256-GCM加密算法

应用采用AES-256-GCM认证加密模式，具有以下特点:

- **机密性**: AES-256对称加密保护数据内容
- **完整性**: GCM模式提供认证标签，防止数据篡改
- **不可预测性**: 随机IV和盐值确保相同明文产生不同密文

#### PBKDF2密钥派生

```typescript
// 密钥派生参数
const spec = {
  algName: 'PBKDF2',
  password: passwordBytes,
  salt: randomSalt,        // 随机16字节盐值
  iterations: 100000,      // 100000次迭代
  keySize: 32              // 256位密钥
};
```

### SQL注入防护

- 所有数据库操作使用参数化查询
- 严格的输入类型检查
- 输入数据验证

### 数据完整性

- 外键约束确保数据关联正确性
- CHECK约束验证数据有效性
- UNIQUE约束防止重复数据
- 事务保证操作原子性

### 密码存储

- 密码使用SHA-256哈希存储
- 不存储明文密码
- 支持密码强度验证

---

## 性能优化

### 数据库层优化

#### 1. WAL模式

```sql
PRAGMA journal_mode=WAL;
```
- 提高并发读写性能
- 减少锁竞争

#### 2. 索引策略

**复合索引**
```sql
CREATE INDEX idx_bills_date
ON bills (transaction_date DESC, bill_id DESC)
WHERE is_deleted = 0;
```

**覆盖索引**
```sql
CREATE INDEX idx_bills_stat
ON bills (account_id, type, transaction_date, amount)
WHERE is_deleted = 0;
```

**部分索引**
```sql
CREATE INDEX idx_categories_user_type
ON categories (user_id, type)
WHERE is_deleted = 0;
```

#### 3. 数据库配置优化

```sql
PRAGMA synchronous=NORMAL;      -- 同步模式
PRAGMA cache_size=10000;        -- 缓存大小约40MB
PRAGMA temp_store=MEMORY;       -- 临时表存储在内存
PRAGMA foreign_keys=ON;         -- 启用外键约束
```

### 应用层优化

#### 1. 缓存机制

```typescript
// CacheManager使用示例
const categories = CacheManager.get<Category[]>(`categories:${userId}`);
if (!categories) {
  categories = await CategoryDAO.getAll(userId);
  CacheManager.set(`categories:${userId}`, categories, 5 * 60 * 1000);
}
```

#### 2. 批量操作

```typescript
// 批量插入优化
await BatchQueryHelper.bulkInsert(bills, async (bill) => {
  await BillDAO.insert(bill);
});
```

#### 3. 分页查询

```typescript
// 游标分页
const bills = await BillDAO.getByPage(userId, {
  pageSize: 20,
  cursor: lastBillId
});
```

### 性能监控

```typescript
// 使用性能监控
const result = await PerformanceMonitor.measure('queryBills', async () => {
  return await BillDAO.getAll(userId);
});

// 获取性能报告
const report = PerformanceMonitor.getReport();
```

---

## 版本历史

### v1.2.0 (2025-12-08)

**新增功能**
- 用户会话管理服务 (UserSessionService)
- 定期账单/预算提醒功能 (ReminderService)
- 数据云端同步功能 (CloudSyncService)

**新增数据表**
- reminders表 - 提醒记录
- cloud_sync_records表 - 云同步记录

**优化改进**
- 新增提醒相关索引
- 新增云同步相关索引
- 代码架构优化

### v1.1.0 (2025-11-12)

**新增功能**
- 数据导出与备份功能
- AES-256-GCM数据加密
- 数据导入恢复
- 校验和验证

**优化改进**
- 数据库索引优化
- 批量查询性能优化
- 缓存机制引入
- 性能监控

### v1.0.0 (2025-11-01)

**初始版本**
- 用户管理基础功能
- 账户管理
- 分类管理 (树形结构)
- 账单管理
- 预算管理
- 标签系统
- 统计功能

---

## 常见问题

### Q1: 应用启动时提示数据库初始化失败

**解决方案**:
1. 检查应用是否有存储权限
2. 确认设备存储空间充足
3. 尝试清除应用数据后重新启动

### Q2: 数据同步失败

**解决方案**:
1. 检查网络连接状态
2. 确认云端服务是否正常
3. 查看同步记录中的错误信息
4. 当前版本云端同步为模拟实现，需要替换为真实API

### Q3: 提醒通知不显示

**解决方案**:
1. 检查应用是否有通知权限
2. 确认提醒处于活跃状态
3. 确认 `checkAndTriggerDueReminders` 方法被定期调用
4. 检查下次提醒时间是否设置正确

### Q4: 导入备份文件失败

**解决方案**:
1. 确认文件格式正确 (JSON)
2. 如果文件已加密，确保输入正确的密码
3. 检查文件是否损坏 (校验和验证)
4. 确认备份文件版本与应用版本兼容

### Q5: 测试运行失败

**解决方案**:
1. 确保在 `beforeAll` 中正确初始化数据库
2. 检查测试设备是否正确连接
3. 使用 `beforeEach` 清理测试数据，避免测试间干扰

---

## 参考资料

### 官方文档

- [HarmonyOS开发者文档](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkts-basic-overview-0000001513958650-V3)
- [ArkTS语言基础](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkts-basic-overview-0000001513958650-V3)
- [ArkUI框架](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkui-overview-0000001474539994-V3)
- [RelationalStore API](https://developer.harmonyos.com/cn/docs/documentation/doc-references-V3/js-apis-data-relationalstore-0000001478261929-V3)
- [Hypium测试框架](https://gitee.com/openharmony/testfwk_arkxtest)

### 项目内部文档

- [项目架构说明文档](README说明/项目架构说明文档.md)
- [高级功能实现文档](README说明/高级功能实现文档.md)
- [高级功能快速开始](README说明/高级功能快速开始.md)
- [测试运行指南](README说明/测试说明/测试运行指南.md)
- [导出备份与加密技术文档](README说明/导出备份与加密/导出备份接口与加密逻辑技术文档.md)
- [索引优化技术文档](README说明/索引优化与批量查询/索引优化与批量查询技术文档.md)
- [分类标签技术文档](README说明/categories-tag/Categories-Tags表及查询聚合技术文档.md)

### UML设计图

- [类图](README说明/UML图/class.puml)
- [用例图](README说明/UML图/usecase.puml)
- [ER图](README说明/UML图/er.puml)
- [架构图](README说明/UML图/architecture.puml)

---

## 许可证

本项目基于 Apache License 2.0 许可证开源。

```
Copyright (c) 2025 SEU-SE Team

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

**文档版本**: v1.2.0
**最后更新**: 2025-12-17
**维护团队**: SEU-SE开发团队
