# Database 数据库模块

数据库管理、配置、优化和性能监控。

---

## 文件列表

### 核心管理
- **DatabaseManager.ets**：数据库管理器
  - 数据库初始化
  - 表创建和迁移
  - 连接管理
  - 生命周期管理

### 性能优化
- **DatabaseConfigOptimizer.ets**：数据库配置优化
  - PRAGMA 优化配置
  - WAL 模式启用
  - 缓存大小调优
  - 同步模式配置

- **IndexManager.ets**：索引管理
  - 索引创建和维护
  - 复合索引优化
  - 索引使用分析

- **CacheManager.ets**：缓存管理
  - LRU 缓存实现
  - 热点数据缓存
  - 缓存失效策略

- **PerformanceMonitor.ets**：性能监控
  - 查询耗时统计
  - 慢查询检测
  - 性能指标收集

### 查询辅助
- **QueryHelper.ets**：查询辅助工具
  - SQL 构建器
  - 参数绑定
  - 结果集处理

- **BatchQueryHelper.ets**：批量查询辅助
  - 批量查询封装
  - 分页查询支持
  - 结果合并

---

## 核心功能

### 1. DatabaseManager
数据库核心管理器

#### 初始化
```typescript
class DatabaseManager {
  // 初始化数据库
  static async initDatabase(): Promise<void>

  // 获取数据库实例
  static getStore(): relationalStore.RdbStore

  // 关闭数据库
  static async closeDatabase(): Promise<void>
}
```

#### 表管理
```typescript
// 创建所有表
static async createAllTables(): Promise<void>

// 按依赖顺序创建
// users → accounts → categories → bills → ...
```

#### 版本迁移
```typescript
// 数据库版本升级
static async migrateDatabase(
  oldVersion: number,
  newVersion: number
): Promise<void>
```

---

### 2. DatabaseConfigOptimizer
数据库性能优化配置

#### 优化策略
```typescript
class DatabaseConfigOptimizer {
  // 应用所有优化
  static async applyOptimizations(): Promise<void>
}
```

#### PRAGMA 配置
```sql
PRAGMA journal_mode=WAL;        -- 写前日志，提升并发
PRAGMA synchronous=NORMAL;      -- 平衡性能和安全
PRAGMA cache_size=10000;        -- 约40MB缓存
PRAGMA temp_store=MEMORY;       -- 临时表内存存储
PRAGMA foreign_keys=ON;         -- 启用外键约束
```

---

### 3. IndexManager
索引管理和优化

#### 索引创建
```typescript
class IndexManager {
  // 创建所有索引
  static async createAllIndexes(): Promise<void>

  // 创建复合索引
  static async createCompositeIndex(
    table: string,
    columns: string[]
  ): Promise<void>
}
```

#### 索引策略
- **单列索引**：高频查询字段
- **复合索引**：联合查询场景
- **覆盖索引**：避免回表查询

---

### 4. CacheManager
智能缓存管理

#### 缓存策略
```typescript
class CacheManager {
  // 设置缓存
  static set(key: string, value: any, ttl?: number): void

  // 获取缓存
  static get<T>(key: string): T | null

  // 清除缓存
  static clear(pattern?: string): void
}
```

#### 特性
- LRU 淘汰策略
- TTL 过期机制
- 内存限制保护
- 命中率统计

---

### 5. PerformanceMonitor
性能监控和分析

#### 监控指标
```typescript
class PerformanceMonitor {
  // 记录查询性能
  static recordQuery(
    sql: string,
    duration: number
  ): void

  // 获取性能报告
  static getReport(): PerformanceReport

  // 检测慢查询
  static getSlowQueries(
    threshold: number
  ): Array<QueryLog>
}
```

---

## 性能优化建议

### 查询优化
1. **使用索引**：为 WHERE、JOIN、ORDER BY 字段建索引
2. **避免SELECT ***：只查询需要的字段
3. **批量操作**：使用事务批量处理
4. **分页查询**：避免一次加载大量数据

### 索引优化
1. **合理创建**：不要过度索引
2. **复合索引**：注意列的顺序
3. **定期维护**：重建或优化索引

### 缓存优化
1. **热点数据**：缓存频繁访问的数据
2. **合理TTL**：根据数据特性设置过期时间
3. **缓存预热**：应用启动时加载常用数据

---

## 数据库配置

### 基础配置
```typescript
const DB_CONFIG = {
  name: 'harmony_expense.db',
  version: 1,
  encrypt: false,
  journalMode: 'WAL',
  synchronous: 'NORMAL'
};
```

### 性能参数
```typescript
const PERF_CONFIG = {
  cacheSize: 10000,       // 页缓存大小
  tempStore: 'MEMORY',    // 临时表存储位置
  maxConnections: 4,      // 最大连接数
  busyTimeout: 5000       // 锁超时时间(ms)
};
```

---

## 错误处理

### 常见错误
- `DATABASE_INIT_ERROR`：初始化失败
- `TABLE_CREATE_ERROR`：表创建失败
- `MIGRATION_ERROR`：版本迁移失败
- `CONNECTION_ERROR`：连接异常

### 错误恢复
```typescript
try {
  await DatabaseManager.initDatabase();
} catch (error) {
  // 尝试恢复
  await DatabaseManager.repairDatabase();
  // 重新初始化
  await DatabaseManager.initDatabase();
}
```

---

## 最佳实践

### 1. 事务管理
```typescript
await rdbStore.beginTransaction();
try {
  // 执行多个操作
  await operation1();
  await operation2();
  await rdbStore.commit();
} catch (error) {
  await rdbStore.rollback();
  throw error;
}
```

### 2. 连接管理
```typescript
// 获取单例连接
const store = DatabaseManager.getStore();

// 使用完毕无需关闭（由管理器统一管理）
```

### 3. 批量操作
```typescript
// 使用 BatchQueryHelper
const results = await BatchQueryHelper.batchInsert(
  'bills',
  billArray,
  100  // 每批100条
);
```

---

## 监控与维护

### 性能监控
```typescript
// 启用监控
PerformanceMonitor.enable();

// 定期获取报告
const report = PerformanceMonitor.getReport();
console.log(`平均查询耗时: ${report.avgDuration}ms`);
console.log(`慢查询数量: ${report.slowQueries.length}`);
```

### 缓存监控
```typescript
// 查看缓存统计
const stats = CacheManager.getStats();
console.log(`缓存命中率: ${stats.hitRate}%`);
console.log(`缓存大小: ${stats.size}`);
```

---

*文档最后更新：2026-03-09*
