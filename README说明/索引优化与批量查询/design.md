# Design Document

## Overview

本设计文档描述了数据库索引优化和批量查询功能的技术架构。系统采用分层设计，包括索引管理层、批量操作层、性能监控层和缓存层。核心设计理念是在保证数据一致性的前提下，通过科学的索引策略和批量操作优化，显著提升数据库查询和写入性能。

## Architecture

### 系统分层架构

```
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                    │
│              (DAO Classes: BillDAO, etc.)               │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                  Optimization Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Batch      │  │ Performance  │  │    Cache     │   │
│  │   Query      │  │   Monitor    │  │   Manager    │   │
│  │   Module     │  │              │  │              │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                   Database Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │    Index     │  │  Transaction │  │   Config     │   │
│  │   Manager    │  │   Manager    │  │  Optimizer   │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│            HarmonyOS RelationalStore API                │
└─────────────────────────────────────────────────────────┘
```

### 核心模块职责

1. **Index Manager**: 负责创建和管理所有表的索引策略
2. **Batch Query Module**: 提供批量插入、更新、删除和查询接口
3. **Performance Monitor**: 监控查询性能并记录慢查询
4. **Cache Manager**: 管理内存缓存，减少数据库访问
5. **Transaction Manager**: 确保批量操作的事务一致性
6. **Config Optimizer**: 优化数据库引擎配置参数

## Components and Interfaces

### 1. Index Manager

#### 职责
- 在数据库初始化时创建所有必要的索引
- 支持复合索引、部分索引和覆盖索引
- 提供索引维护和重建功能

#### 接口设计

```typescript
export class IndexManager {
  /**
   * 创建所有表的索引
   */
  static async createAllIndexes(): Promise<void>
  
  /**
   * 创建 Bills 表索引
   */
  private static async createBillsIndexes(): Promise<void>
  
  /**
   * 创建 Accounts 表索引
   */
  private static async createAccountsIndexes(): Promise<void>
  
  /**
   * 创建 Categories 表索引
   */
  private static async createCategoriesIndexes(): Promise<void>
  
  /**
   * 创建 Bill_Tags 表索引
   */
  private static async createBillTagsIndexes(): Promise<void>
  
  /**
   * 重建所有索引
   */
  static async rebuildIndexes(): Promise<void>
}
```

#### 索引策略（⭐ 企业级亮点）

**Bills 表核心索引**:
- `idx_bills_date`: (transaction_date DESC, bill_id DESC) WHERE is_deleted = 0
  - 用途: 日期范围查询
  - 类型: 部分索引（只索引未删除数据）
  
- `idx_bills_stat`: (account_id, type, transaction_date, amount) WHERE is_deleted = 0
  - ⭐ **用途**: 统计查询的覆盖索引（避免回表）
  - ⭐ **亮点**: 包含查询所需的所有字段，性能提升 3-5 倍
  
- `idx_bills_account_date`: (account_id, transaction_date DESC, type) WHERE is_deleted = 0
  - 用途: 账户流水查询
  - 类型: 复合索引

**Accounts 表核心索引**:
- `idx_accounts_user_type`: (user_id, type) WHERE is_deleted = 0
  - 用途: 按类型查询用户账户

**Bill_Tags 表核心索引**:
- `idx_bill_tags_bill`: (bill_id) - 账单查标签
- `idx_bill_tags_tag`: (tag_id) - 标签查账单

**亮点说明**:
- 覆盖索引是数据库优化的高级技巧
- 部分索引减少存储空间和维护成本
- 展示了对索引原理的深入理解

### 2. Batch Query Module

#### 职责
- 提供批量插入、更新、删除功能
- 自动分批处理大数据集
- 管理事务边界

#### 接口设计

```typescript
export class BatchQueryHelper {
  /**
   * 批量插入（自动分批）
   * @param tableName 表名
   * @param records 记录数组
   * @param batchSize 每批大小，默认 100
   */
  static async bulkInsert<T>(
    tableName: string,
    records: T[],
    batchSize?: number
  ): Promise<void>
  
  /**
   * 批量更新
   * @param tableName 表名
   * @param records 记录数组
   * @param updateFields 需要更新的字段
   * @param whereField 条件字段（通常是主键）
   */
  static async bulkUpdate<T>(
    tableName: string,
    records: T[],
    updateFields: string[],
    whereField: string
  ): Promise<void>
  
  /**
   * 批量软删除
   * @param tableName 表名
   * @param ids ID 数组
   * @param idField ID 字段名
   */
  static async bulkSoftDelete(
    tableName: string,
    ids: number[],
    idField: string
  ): Promise<void>
  
  /**
   * 批量查询（IN 子句）
   * @param tableName 表名
   * @param ids ID 数组
   * @param idField ID 字段名
   */
  static async bulkQuery<T>(
    tableName: string,
    ids: number[],
    idField: string
  ): Promise<T[]>
}
```

#### 批量插入实现策略

```typescript
// 伪代码示例
async bulkInsert(records) {
  if (records.length === 0) return;
  
  const BATCH_SIZE = 100;
  await beginTransaction();
  
  try {
    for (let i = 0; i < records.length; i += BATCH_SIZE) {
      const batch = records.slice(i, i + BATCH_SIZE);
      
      // 构建多行 VALUES 语句
      const placeholders = batch.map(() => '(?, ?, ?)').join(', ');
      const sql = `INSERT INTO table VALUES ${placeholders}`;
      
      // 展平参数数组
      const params = batch.flatMap(r => [r.field1, r.field2, r.field3]);
      
      await executeSql(sql, params);
    }
    
    await commit();
  } catch (error) {
    await rollback();
    throw error;
  }
}
```

### 3. Performance Monitor（⭐ 企业级亮点）

#### 职责
- 监控查询执行时间
- 记录慢查询日志（> 100ms）
- 使用装饰器模式实现 AOP

#### 接口设计

```typescript
export class PerformanceMonitor {
  /**
   * 查询性能监控装饰器（⭐ 核心亮点）
   * 使用方式: @measureQueryTime
   * 
   * 示例:
   * @measureQueryTime
   * static async getByDateRange(...) { ... }
   */
  static measureQueryTime(
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ): PropertyDescriptor
}
```

#### 装饰器实现（⭐ 设计模式应用）

```typescript
function measureQueryTime(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
  const originalMethod = descriptor.value;
  
  descriptor.value = async function (...args: any[]) {
    const startTime = Date.now();
    try {
      const result = await originalMethod.apply(this, args);
      const duration = Date.now() - startTime;
      
      // 慢查询警告
      if (duration > 100) {
        console.warn(`[Performance] ${propertyKey} took ${duration}ms`);
      }
      
      return result;
    } catch (error) {
      const duration = Date.now() - startTime;
      console.error(`[Performance] ${propertyKey} failed after ${duration}ms`);
      throw error;
    }
  };
  
  return descriptor;
}
```

**亮点说明**:
- 装饰器模式体现了 AOP（面向切面编程）思想
- 无侵入式性能监控，不修改业务代码
- 展示了 TypeScript 高级特性的实际应用
- 代码简洁（约 30 行）但设计优雅

### 4. Cache Manager（⭐ 企业级亮点）

#### 职责
- 管理内存缓存
- 自动过期清理（TTL 机制）
- 模式匹配清除（正则表达式）

#### 接口设计

```typescript
interface CacheEntry {
  value: any;
  expireAt: number;
}

export class CacheManager {
  private static cache: Map<string, CacheEntry> = new Map();
  private static readonly DEFAULT_TTL = 300000; // 5分钟
  
  /**
   * 获取缓存（自动清理过期）
   * @param key 缓存键
   * @returns 缓存值或 null
   */
  static get<T>(key: string): T | null
  
  /**
   * 设置缓存
   * @param key 缓存键
   * @param value 缓存值
   * @param ttl 过期时间（毫秒）
   */
  static set<T>(key: string, value: T, ttl?: number): void
  
  /**
   * 清除缓存（支持正则模式）
   * @param pattern 正则表达式模式（可选）
   * 示例: clear('categories:.*') 清除所有分类缓存
   */
  static clear(pattern?: string): void
}
```

#### 缓存键设计规范（简化版）

```
categories:{userId}              // 用户分类列表
accounts:{userId}                // 用户账户列表
```

**亮点说明**: 
- TTL 自动过期机制体现了缓存设计思维
- 正则模式匹配清除展示了灵活的缓存失效策略
- 实现简单（约 50 行）但概念完整

### 5. Database Config Optimizer

#### 职责
- 优化数据库引擎配置
- 设置性能参数

#### 接口设计

```typescript
export class DatabaseConfigOptimizer {
  /**
   * 应用所有优化配置
   */
  static async applyOptimizations(): Promise<void>
  
  /**
   * 启用 WAL 模式
   */
  private static async enableWAL(): Promise<void>
  
  /**
   * 设置缓存大小
   */
  private static async setCacheSize(): Promise<void>
  
  /**
   * 设置同步模式
   */
  private static async setSynchronousMode(): Promise<void>
  
  /**
   * 设置临时存储
   */
  private static async setTempStore(): Promise<void>
}
```

#### 配置参数

```typescript
const DB_CONFIG = {
  JOURNAL_MODE: 'WAL',           // 写前日志
  CACHE_SIZE: 10000,             // 10000 页 ≈ 40MB
  SYNCHRONOUS: 'NORMAL',         // 平衡性能和安全
  TEMP_STORE: 'MEMORY',          // 临时数据存内存
  FOREIGN_KEYS: 'ON'             // 启用外键约束
};
```

## Data Models

### 分页结果模型

```typescript
interface PaginatedResult<T> {
  data: T[];              // 数据数组
  total: number;          // 总记录数
  page: number;           // 当前页码
  pageSize: number;       // 每页大小
  totalPages: number;     // 总页数
}
```

### 游标分页结果模型

```typescript
interface CursorResult<T> {
  data: T[];              // 数据数组
  nextCursor: number | null;  // 下一页游标
  hasMore: boolean;       // 是否有更多数据
}
```

### 统计结果模型

```typescript
interface TotalStats {
  totalExpense: number;   // 总支出
  totalIncome: number;    // 总收入
  expenseCount: number;   // 支出笔数
  incomeCount: number;    // 收入笔数
}

interface MonthlyStats {
  month: string;          // 月份 (YYYY-MM)
  expense: number;        // 支出
  income: number;         // 收入
  count: number;          // 记录数
}
```

## Error Handling

### 错误分类

1. **事务错误**: 批量操作失败时自动回滚
2. **参数错误**: 验证输入参数，抛出明确错误信息
3. **性能错误**: 慢查询警告，不中断执行
4. **缓存错误**: 缓存失败降级到数据库查询

### 错误处理策略

```typescript
// 批量操作错误处理
try {
  await beginTransaction();
  // 批量操作...
  await commit();
} catch (error) {
  await rollback();
  console.error('[BatchQuery] Operation failed:', error);
  throw new Error(`批量操作失败: ${error.message}`);
}

// 缓存错误处理（降级）
try {
  const cached = CacheManager.get(key);
  if (cached) return cached;
} catch (error) {
  console.warn('[Cache] Cache read failed, fallback to DB');
}

// 查询数据库
return await queryFromDatabase();
```

## Validation Strategy

### 功能验证

1. **IndexManager 验证**
   - 通过日志确认索引创建成功
   - 使用 SQLite 工具查看索引列表

2. **BatchQueryHelper 验证**
   - 插入数据后查询数据库确认记录数
   - 观察控制台日志确认批次处理

3. **CacheManager 验证**
   - 第一次查询观察数据库访问日志
   - 第二次查询观察缓存命中日志

4. **PerformanceMonitor 验证**
   - 观察控制台输出的性能日志
   - 确认慢查询警告正常触发

### 性能验证

通过控制台日志观察性能提升效果：
- 批量插入 vs 单条插入的耗时对比
- 有索引 vs 无索引的查询耗时对比
- 缓存命中 vs 数据库查询的耗时对比

## Performance Targets

### 性能指标

| 操作类型 | 数据量 | 目标耗时 | 备注 |
|---------|--------|---------|------|
| 批量插入 | 100 条 | < 50ms | 单批次 |
| 批量插入 | 1000 条 | < 500ms | 自动分批 |
| 分页查询 | 20 条/页 | < 30ms | 使用索引 |
| 月度统计 | 全年数据 | < 100ms | 覆盖索引 |
| 缓存读取 | 任意 | < 1ms | 内存访问 |

### 优化效果预期

- 日期范围查询性能提升: 5-10倍
- 统计查询性能提升: 3-5倍
- 批量插入性能提升: 10-20倍
- 缓存命中场景性能提升: 50-100倍

## Implementation Notes

### 开发优先级与复杂度

#### 核心实现（必须完成，中等复杂度）
1. **IndexManager**: 索引创建和管理（约 150 行代码）
   - 为 Bills、Accounts 表创建 3-4 个关键索引
   - 简单的索引创建逻辑，无需复杂算法

2. **BatchQueryHelper**: 批量操作（约 200 行代码）
   - 批量插入和删除功能
   - 基础的事务管理
   - 自动分批逻辑（简单循环）

#### 企业级亮点（展示技术深度）
3. **PerformanceMonitor**: 装饰器模式性能监控（约 80 行代码）
   - ⭐ **亮点**: TypeScript 装饰器的实际应用
   - ⭐ **亮点**: AOP（面向切面编程）思想
   - 实现简单但展示了设计模式理解

4. **CacheManager**: 内存缓存（约 100 行代码）
   - ⭐ **亮点**: TTL 过期机制
   - ⭐ **亮点**: 正则表达式模式匹配清除
   - 代码量少但体现了缓存设计思维

#### 可选实现（时间充裕时）
5. **DatabaseConfigOptimizer**: 数据库配置优化（约 50 行代码）
   - 简单的 PRAGMA 语句执行
   - 展示对数据库调优的理解

### 技术亮点总结

**对于学生作业，以下 3 点最能体现技术水平**:

1. **装饰器模式的性能监控** - 展示设计模式应用能力
2. **覆盖索引优化** - 展示数据库优化理解
3. **自动分批 + 事务管理** - 展示工程实践能力

### 实现建议

- **总代码量**: 约 600-800 行（不含测试）
- **开发时间**: 2-3 天
- **核心难点**: 装饰器实现、事务管理
- **展示重点**: 在文档和注释中说明设计思路

### 技术约束

- SQLite 参数数量限制: 999 个（因此批次大小设为 100）
- HarmonyOS RelationalStore API 限制
- 内存缓存大小建议不超过 50MB

### 简化策略

**相比企业级实现，我们简化了**:
- ❌ 不实现复杂的缓存淘汰算法（LRU/LFU）
- ❌ 不实现查询计划分析（EXPLAIN）
- ❌ 不实现游标分页（只实现基础分页）
- ❌ 不实现索引自动推荐
- ✅ 保留装饰器监控（亮点）
- ✅ 保留覆盖索引（亮点）
- ✅ 保留批量事务（亮点）

---

**文档版本**: v1.0  
**最后更新**: 2025-11-11
