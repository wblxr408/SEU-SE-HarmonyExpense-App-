# Requirements Document

## Introduction

本需求文档定义了基于 HarmonyOS 关系型数据库的索引优化和批量查询功能。该功能旨在提升应用数据库性能，优化高频查询场景，并提供企业级的批量数据操作能力。系统将为核心业务表（Bills、Accounts、Categories 等）建立科学的索引策略，并实现高效的批量操作接口。

## Glossary

- **Database System**: 基于 HarmonyOS relationalStore 的关系型数据库系统
- **Index Manager**: 负责创建和管理数据库索引的模块
- **Batch Query Module**: 批量查询模块，提供批量插入、更新、删除和查询功能
- **Performance Monitor**: 性能监控模块，用于追踪查询执行时间和性能指标
- **Cache Manager**: 内存缓存管理器，用于缓存高频查询结果
- **Composite Index**: 复合索引，包含多个字段的索引
- **Partial Index**: 部分索引，仅索引满足特定条件的数据行
- **Covering Index**: 覆盖索引，包含查询所需的所有字段

## Requirements

### Requirement 1

**User Story:** 作为开发者，我希望为核心业务表创建优化的索引策略，以便显著提升高频查询性能

#### Acceptance Criteria

1. WHEN Database System 初始化时，THE Index Manager SHALL 为 Bills 表创建包含 transaction_date 和 bill_id 的复合索引用于日期范围查询
2. WHEN Database System 初始化时，THE Index Manager SHALL 为 Bills 表创建包含 account_id、type、transaction_date 和 amount 的覆盖索引用于统计查询
3. WHERE 数据行的 is_deleted 字段等于 0，THE Index Manager SHALL 创建部分索引以减少索引存储空间
4. WHEN Database System 初始化时，THE Index Manager SHALL 为 Accounts 表创建 user_id 和 type 的复合索引
5. WHEN Database System 初始化时，THE Index Manager SHALL 为 Bill_Tags 关联表创建 bill_id 和 tag_id 的双向索引

### Requirement 2

**User Story:** 作为开发者，我希望实现事务性批量数据操作，以便安全高效地处理大量数据

#### Acceptance Criteria

1. WHEN Batch Query Module 接收到超过 1 条记录的插入请求时，THE Database System SHALL 在单个事务中执行所有插入操作
2. WHEN 批量操作的记录数超过 100 条时，THE Batch Query Module SHALL 自动分批处理每批最多 100 条记录
3. IF 批量操作中任何一条记录失败，THEN THE Database System SHALL 回滚整个事务并保持数据一致性
4. WHEN Batch Query Module 执行批量删除时，THE Database System SHALL 使用 IN 子句和参数化查询避免 SQL 注入

### Requirement 3

**User Story:** 作为开发者，我希望实现高效的分页查询机制，以便支持大数据集的流畅展示

#### Acceptance Criteria

1. WHEN Batch Query Module 接收到分页请求时，THE Database System SHALL 在单次数据库连接中执行总数统计和数据查询
2. WHEN 执行分页查询时，THE Database System SHALL 使用索引优化的 ORDER BY 子句配合 LIMIT 和 OFFSET
3. WHEN 分页查询返回结果时，THE Batch Query Module SHALL 包含数据数组、总记录数、当前页码、每页大小和总页数
4. WHEN 查询第一页数据时，THE Database System SHALL 优先使用索引扫描而非全表扫描

### Requirement 4

**User Story:** 作为开发者，我希望实现优化的聚合统计查询，以便快速生成财务报表

#### Acceptance Criteria

1. WHEN Batch Query Module 执行收支统计时，THE Database System SHALL 使用单个 SQL 语句通过 CASE 表达式同时计算收入和支出
2. WHEN 执行月度统计查询时，THE Database System SHALL 使用 strftime 函数和 GROUP BY 子句按月份聚合数据
3. WHEN 统计查询涉及金额计算时，THE Database System SHALL 使用覆盖索引避免访问完整数据行
4. WHEN 聚合查询完成时，THE Batch Query Module SHALL 返回包含时间维度、金额和记录数的结构化数据

### Requirement 5

**User Story:** 作为开发者，我希望实现查询性能监控装饰器，以便自动识别性能瓶颈

#### Acceptance Criteria

1. WHEN Performance Monitor 装饰的方法开始执行时，THE Database System SHALL 记录精确的开始时间戳
2. WHEN 被监控的查询执行时间超过 100 毫秒时，THE Performance Monitor SHALL 输出包含方法名和耗时的警告日志
3. WHEN 被监控的查询执行失败时，THE Performance Monitor SHALL 记录失败时的执行时间和错误堆栈
4. THE Performance Monitor SHALL 支持通过装饰器语法应用于任何异步查询方法

### Requirement 6

**User Story:** 作为开发者，我希望实现轻量级内存缓存，以便减少高频只读查询的数据库压力

#### Acceptance Criteria

1. WHEN Cache Manager 接收到查询请求时，THE Database System SHALL 使用查询键检查缓存并在命中时直接返回缓存数据
2. WHEN 缓存条目的过期时间小于当前时间时，THE Cache Manager SHALL 自动删除该条目并返回 null
3. WHEN 数据发生插入、更新或删除操作时，THE Cache Manager SHALL 使用正则表达式模式清除相关缓存键
4. WHEN 设置缓存条目时，THE Cache Manager SHALL 支持自定义 TTL 参数且默认值为 300000 毫秒

### Requirement 7

**User Story:** 作为开发者，我希望优化数据库引擎配置，以便提升整体读写性能

#### Acceptance Criteria

1. WHEN Database System 初始化时，THE Database System SHALL 执行 PRAGMA journal_mode=WAL 启用写前日志模式
2. WHEN Database System 初始化时，THE Database System SHALL 执行 PRAGMA cache_size=10000 设置约 40MB 的缓存
3. WHEN Database System 初始化时，THE Database System SHALL 执行 PRAGMA synchronous=NORMAL 平衡性能和数据安全
4. WHEN Database System 初始化时，THE Database System SHALL 执行 PRAGMA temp_store=MEMORY 将临时数据存储在内存中
