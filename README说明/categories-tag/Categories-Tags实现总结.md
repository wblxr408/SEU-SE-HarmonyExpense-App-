# Categories/Tags 功能实现总结
## 功能实现清单

### ✅ 1. 数据库表设计

- [x] Categories 表（包含 sort_order 字段）
- [x] Tags 表
- [x] Bill_Tags 关联表
- [x] 所有必要的索引（包括部分索引）
- [x] 外键约束
- [x] CHECK 约束
- [x] UNIQUE 约束

### ✅ 2. Category 模型功能

- [x] 基础 CRUD 操作
- [x] 批量插入
- [x] 软删除/恢复
- [x] 硬删除
- [x] 按类型查询
- [x] 查询子分类
- [x] 获取分类树结构
- [x] 分类聚合统计
- [x] 数据验证
- [x] JSON 序列化/反序列化

### ✅ 3. Tag 模型功能

- [x] 基础 CRUD 操作
- [x] 批量插入
- [x] 软删除/恢复
- [x] 硬删除（级联删除关联）
- [x] 获取热门标签
- [x] 标签聚合统计
- [x] 使用次数自动更新
- [x] 数据验证
- [x] JSON 序列化/反序列化

### ✅ 4. 账单-标签关联功能

- [x] 添加标签到账单
- [x] 从账单移除标签
- [x] 批量设置账单标签
- [x] 查询账单的所有标签
- [x] 查询标签关联的所有账单
- [x] 获取所有关联记录（用于导出）

### ✅ 5. 查询聚合功能

- [x] 按分类聚合统计（金额、数量、平均值等）
- [x] 按标签聚合统计
- [x] 分类+标签组合查询
- [x] 按分类查询（包含子分类）
- [x] 递归查询子分类
- [x] 构建分类树结构

### ✅ 6. 性能优化

- [x] 复合索引
- [x] 部分索引（WHERE is_deleted = 0）
- [x] 排序索引
- [x] 使用 COALESCE 处理 NULL 值
- [x] 批量操作使用事务
- [x] 查询结果集正确关闭

### ✅ 7. 代码规范

- [x] 符合 ArkTS 语法规范
- [x] 完整的类型定义
- [x] 统一的错误处理
- [x] 详细的注释文档
- [x] 参数验证
- [x] 资源正确释放（ResultSet.close()）
- [x] 事务正确处理（commit/rollback）

## 数据库表结构

### Categories 表

```sql
CREATE TABLE IF NOT EXISTS categories (
  category_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('expense', 'income')),
  icon TEXT DEFAULT '📦',
  color TEXT DEFAULT '#1890FF',
  parent_category_id INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
  UNIQUE (user_id, name, type)
);

-- 索引
CREATE INDEX idx_categories_user_type ON categories (user_id, type) WHERE is_deleted = 0;
CREATE INDEX idx_categories_user_parent ON categories (user_id, parent_category_id) WHERE is_deleted = 0;
CREATE INDEX idx_categories_sort ON categories (user_id, sort_order, category_id);
```

### Tags 表

```sql
CREATE TABLE IF NOT EXISTS tags (
  tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  color TEXT DEFAULT '#52C41A',
  usage_count INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
  UNIQUE (user_id, name)
);

-- 索引
CREATE INDEX idx_tags_user ON tags (user_id) WHERE is_deleted = 0;
CREATE INDEX idx_tags_usage ON tags (user_id, usage_count DESC) WHERE is_deleted = 0;
```

### Bill_Tags 关联表

```sql
CREATE TABLE IF NOT EXISTS bill_tags (
  bill_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  PRIMARY KEY (bill_id, tag_id),
  FOREIGN KEY (bill_id) REFERENCES bills(bill_id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
);

-- 索引
CREATE INDEX idx_bill_tags_bill ON bill_tags (bill_id);
CREATE INDEX idx_bill_tags_tag ON bill_tags (tag_id);
```

## 核心 API 列表

### CategoryDAO

```typescript
// 基础操作
static async insert(category: Category): Promise<void>
static async bulkInsert(categories: Category[]): Promise<void>
static async getById(userId: number, categoryId: number): Promise<Category | null>
static async getAll(userId: number): Promise<Category[]>
static async getByType(userId: number, type: 'expense' | 'income'): Promise<Category[]>
static async getChildren(userId: number, parentId: number): Promise<Category[]>
static async update(category: Category): Promise<void>
static async softDelete(userId: number, categoryId: number): Promise<void>
static async restore(userId: number, categoryId: number): Promise<void>
static async hardDelete(userId: number, categoryId: number): Promise<void>
static async exists(categoryId: number): Promise<boolean>

// 高级查询
static async getCategoryTree(userId: number, type: 'expense' | 'income'): Promise<CategoryTreeNode[]>
static async aggregateByCategory(userId: number, startDate: string, endDate: string): Promise<CategoryAggregation[]>
```

### TagDAO

```typescript
// 基础操作
static async insert(tag: Tag): Promise<void>
static async bulkInsert(tags: Tag[]): Promise<void>
static async getById(userId: number, tagId: number): Promise<Tag | null>
static async getAll(userId: number): Promise<Tag[]>
static async getPopularTags(userId: number, limit: number): Promise<Tag[]>
static async update(tag: Tag): Promise<void>
static async softDelete(userId: number, tagId: number): Promise<void>
static async restore(userId: number, tagId: number): Promise<void>
static async hardDelete(userId: number, tagId: number): Promise<void>
static async exists(tagId: number): Promise<boolean>

// 关联操作
static async addTagToBill(billId: number, tagId: number): Promise<void>
static async removeTagFromBill(billId: number, tagId: number): Promise<void>
static async setTagsForBill(billId: number, tagIds: number[]): Promise<void>
static async getTagsByBillId(billId: number): Promise<BillTag[]>
static async getBillIdsByTagId(tagId: number): Promise<number[]>
static async getAllBillTags(userId: number): Promise<BillTag[]>

// 聚合查询
static async aggregateByTag(userId: number, startDate: string, endDate: string): Promise<TagAggregation[]>
```

### QueryHelper

```typescript
// 组合查询
static async queryBillsByCategoryAndTags(
  userId: number,
  categoryIds: number[] | null,
  tagIds: number[] | null,
  startDate: string,
  endDate: string
): Promise<Bill[]>

static async queryBillsByCategory(
  userId: number,
  categoryId: number,
  includeChildren: boolean,
  startDate: string,
  endDate: string
): Promise<Bill[]>
```

## 类型定义

### CategoryTreeNode

```typescript
interface CategoryTreeNode {
  category: Category;
  children: CategoryTreeNode[];
}
```

### CategoryAggregation

```typescript
interface CategoryAggregation {
  categoryId: number;
  categoryName: string;
  type: 'expense' | 'income';
  icon: string;
  color: string;
  parentCategoryId: number;
  transactionCount: number;
  totalAmount: number;
  avgAmount: number;
  minAmount: number;
  maxAmount: number;
}
```

### TagAggregation

```typescript
interface TagAggregation {
  tagId: number;
  tagName: string;
  color: string;
  billCount: number;
  totalAmount: number;
}
```

## 使用示例

### 创建分类树

```typescript
const expenseTree = await CategoryDAO.getCategoryTree(userId, 'expense');
```

### 获取热门标签

```typescript
const popularTags = await TagDAO.getPopularTags(userId, 10);
```

### 分类统计

```typescript
const stats = await CategoryDAO.aggregateByCategory(userId, '2025-11-01', '2025-11-30');
```

### 组合查询

```typescript
const bills = await QueryHelper.queryBillsByCategoryAndTags(
  userId,
  [1, 2, 3],  // 分类IDs
  [1, 2],     // 标签IDs
  '2025-11-01',
  '2025-11-30'
);
```

## 注意事项

1. **数据一致性**：所有关联操作都使用事务确保数据一致性
2. **软删除**：分类和标签默认使用软删除，避免影响历史数据
3. **唯一性约束**：同一用户下分类名称+类型唯一，标签名称唯一
4. **级联删除**：删除标签时自动清理 bill_tags 关联记录
5. **使用计数**：标签使用次数在添加/删除关联时自动更新
6. **资源释放**：所有 ResultSet 都在 finally 块中正确关闭
7. **错误处理**：统一的错误转换和日志记录
