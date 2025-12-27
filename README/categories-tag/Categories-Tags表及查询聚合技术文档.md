# Categories/Tags 表及查询聚合技术文档

## 1. 概述

本文档详细说明基于 ArkTS 的 Categories 和 Tags 表设计、查询聚合策略以及实现方案。适用于 HarmonyOS 应用开发中的分类和标签管理功能。

## 2. 数据库表设计

### 2.1 Categories 表（分类表）

#### 表结构
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
```

#### 字段说明
- `category_id`: 分类唯一标识（主键，自增）
- `user_id`: 用户ID（外键关联 users 表）
- `name`: 分类名称（如"餐饮"、"交通"）
- `type`: 分类类型（expense=支出，income=收入）
- `icon`: 分类图标（Emoji 或图标名称）
- `color`: 分类颜色（十六进制色值）
- `parent_category_id`: 父分类ID（0表示一级分类，支持多级分类）
- `sort_order`: 排序序号（用于自定义排序）
- `created_at`: 创建时间（ISO 8601 格式）
- `updated_at`: 更新时间（ISO 8601 格式）
- `is_deleted`: 软删除标记（0=正常，1=已删除）

#### 索引设计
```sql
-- 用户+类型复合索引（高频查询）
CREATE INDEX IF NOT EXISTS idx_categories_user_type 
ON categories (user_id, type) WHERE is_deleted = 0;

-- 用户+父分类复合索引（层级查询）
CREATE INDEX IF NOT EXISTS idx_categories_user_parent 
ON categories (user_id, parent_category_id) WHERE is_deleted = 0;

-- 排序索引
CREATE INDEX IF NOT EXISTS idx_categories_sort 
ON categories (user_id, sort_order, category_id);
```

### 2.2 Tags 表（标签表）

#### 表结构
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
```

#### 字段说明
- `tag_id`: 标签唯一标识（主键，自增）
- `user_id`: 用户ID（外键关联 users 表）
- `name`: 标签名称（如"报销"、"紧急"、"旅游"）
- `color`: 标签颜色（十六进制色值）
- `usage_count`: 使用次数（用于热门标签统计）
- `created_at`: 创建时间
- `updated_at`: 更新时间
- `is_deleted`: 软删除标记

#### 索引设计
```sql
-- 用户索引
CREATE INDEX IF NOT EXISTS idx_tags_user 
ON tags (user_id) WHERE is_deleted = 0;

-- 使用频率索引（热门标签查询）
CREATE INDEX IF NOT EXISTS idx_tags_usage 
ON tags (user_id, usage_count DESC) WHERE is_deleted = 0;
```

### 2.3 Bill_Tags 关联表（账单-标签多对多关系）

#### 表结构
```sql
CREATE TABLE IF NOT EXISTS bill_tags (
  bill_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  PRIMARY KEY (bill_id, tag_id),
  FOREIGN KEY (bill_id) REFERENCES bills(bill_id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
);
```

#### 索引设计
```sql
-- 账单查询标签
CREATE INDEX IF NOT EXISTS idx_bill_tags_bill 
ON bill_tags (bill_id);

-- 标签查询账单
CREATE INDEX IF NOT EXISTS idx_bill_tags_tag 
ON bill_tags (tag_id);
```

## 3. ArkTS 数据模型定义

### 3.1 Category 模型

```typescript
export interface CategoryJSON {
  categoryId: number;
  userId: number;
  name: string;
  type: 'expense' | 'income';
  icon: string;
  color: string;
  parentCategoryId: number;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
  is_deleted?: number;
}

export class Category {
  static readonly tableName: string = 'categories';

  categoryId: number = 0;
  userId: number = 0;
  name: string = '';
  type: 'expense' | 'income' = 'expense';
  icon: string = '📦';
  color: string = '#1890FF';
  parentCategoryId: number = 0;
  sortOrder: number = 0;
  createdAt: string = '';
  updatedAt: string = '';
  is_deleted: number = 0;

  // 构造函数、验证方法、序列化方法等...
  
  validate(): boolean {
    return (
      this.name !== '' &&
      this.name.length <= 50 &&
      ['expense', 'income'].includes(this.type) &&
      (this.is_deleted === 0 || this.is_deleted === 1)
    );
  }
}
```

### 3.2 Tag 模型

```typescript
export interface TagJSON {
  tagId: number;
  userId: number;
  name: string;
  color: string;
  usageCount: number;
  createdAt: string;
  updatedAt: string;
  is_deleted?: number;
}

export class Tag {
  static readonly tableName: string = 'tags';

  tagId: number = 0;
  userId: number = 0;
  name: string = '';
  color: string = '#52C41A';
  usageCount: number = 0;
  createdAt: string = '';
  updatedAt: string = '';
  is_deleted: number = 0;

  validate(): boolean {
    return (
      this.name !== '' &&
      this.name.length <= 20 &&
      (this.is_deleted === 0 || this.is_deleted === 1)
    );
  }
}
```

## 4. 查询聚合策略

### 4.1 分类层级查询

#### 场景：获取用户的分类树结构

```typescript
/**
 * 获取分类树（包含子分类）
 * @param userId 用户ID
 * @param type 分类类型
 * @returns 分类树结构
 */
static async getCategoryTree(
  userId: number, 
  type: 'expense' | 'income'
): Promise<CategoryTreeNode[]> {
  const store = DatabaseManager.getDatabase();
  
  // 查询所有分类
  const sql = `
    SELECT * FROM categories 
    WHERE user_id = ? AND type = ? AND is_deleted = 0 
    ORDER BY sort_order ASC, category_id ASC
  `;
  
  let resultSet: relationalStore.ResultSet | null = null;
  try {
    resultSet = await store.querySql(sql, [userId, type]);
    const allCategories: Category[] = [];
    
    while (resultSet.goToNextRow()) {
      allCategories.push(this.mapRowToCategory(resultSet));
    }
    
    // 构建树结构
    return this.buildCategoryTree(allCategories);
  } finally {
    resultSet?.close();
  }
}

/**
 * 构建分类树结构
 */
private static buildCategoryTree(categories: Category[]): CategoryTreeNode[] {
  const map = new Map<number, CategoryTreeNode>();
  const roots: CategoryTreeNode[] = [];
  
  // 初始化节点
  categories.forEach(cat => {
    map.set(cat.categoryId, {
      category: cat,
      children: []
    });
  });
  
  // 构建父子关系
  categories.forEach(cat => {
    const node = map.get(cat.categoryId)!;
    if (cat.parentCategoryId === 0) {
      roots.push(node);
    } else {
      const parent = map.get(cat.parentCategoryId);
      if (parent) {
        parent.children.push(node);
      }
    }
  });
  
  return roots;
}
```

### 4.2 分类统计聚合

#### 场景：按分类统计账单金额和数量

```typescript
/**
 * 按分类聚合统计
 * @param userId 用户ID
 * @param startDate 开始日期
 * @param endDate 结束日期
 * @returns 分类统计结果
 */
static async aggregateByCategory(
  userId: number,
  startDate: string,
  endDate: string
): Promise<CategoryAggregation[]> {
  const store = DatabaseManager.getDatabase();
  
  const sql = `
    SELECT 
      c.category_id,
      c.name AS category_name,
      c.type,
      c.icon,
      c.color,
      c.parent_category_id,
      COUNT(b.bill_id) AS transaction_count,
      SUM(b.amount) AS total_amount,
      AVG(b.amount) AS avg_amount,
      MIN(b.amount) AS min_amount,
      MAX(b.amount) AS max_amount
    FROM categories c
    LEFT JOIN bills b ON c.category_id = b.category_id 
      AND b.is_deleted = 0
      AND b.transaction_date >= ?
      AND b.transaction_date <= ?
    WHERE c.user_id = ? AND c.is_deleted = 0
    GROUP BY c.category_id
    ORDER BY total_amount DESC
  `;
  
  let resultSet: relationalStore.ResultSet | null = null;
  try {
    resultSet = await store.querySql(sql, [startDate, endDate, userId]);
    const results: CategoryAggregation[] = [];
    
    while (resultSet.goToNextRow()) {
      results.push({
        categoryId: resultSet.getLong(resultSet.getColumnIndex('category_id')),
        categoryName: resultSet.getString(resultSet.getColumnIndex('category_name')),
        type: resultSet.getString(resultSet.getColumnIndex('type')) as 'expense' | 'income',
        icon: resultSet.getString(resultSet.getColumnIndex('icon')),
        color: resultSet.getString(resultSet.getColumnIndex('color')),
        parentCategoryId: resultSet.getLong(resultSet.getColumnIndex('parent_category_id')),
        transactionCount: resultSet.getLong(resultSet.getColumnIndex('transaction_count')),
        totalAmount: resultSet.getDouble(resultSet.getColumnIndex('total_amount')),
        avgAmount: resultSet.getDouble(resultSet.getColumnIndex('avg_amount')),
        minAmount: resultSet.getDouble(resultSet.getColumnIndex('min_amount')),
        maxAmount: resultSet.getDouble(resultSet.getColumnIndex('max_amount'))
      });
    }
    
    return results;
  } finally {
    resultSet?.close();
  }
}
```

### 4.3 标签聚合查询

#### 场景：获取热门标签及使用统计

```typescript
/**
 * 获取热门标签（按使用频率排序）
 * @param userId 用户ID
 * @param limit 返回数量限制
 * @returns 热门标签列表
 */
static async getPopularTags(userId: number, limit: number = 10): Promise<Tag[]> {
  const store = DatabaseManager.getDatabase();
  
  const sql = `
    SELECT * FROM tags 
    WHERE user_id = ? AND is_deleted = 0 
    ORDER BY usage_count DESC, tag_id DESC 
    LIMIT ?
  `;
  
  let resultSet: relationalStore.ResultSet | null = null;
  try {
    resultSet = await store.querySql(sql, [userId, limit]);
    const tags: Tag[] = [];
    
    while (resultSet.goToNextRow()) {
      tags.push(this.mapRowToTag(resultSet));
    }
    
    return tags;
  } finally {
    resultSet?.close();
  }
}

/**
 * 按标签聚合账单统计
 * @param userId 用户ID
 * @param startDate 开始日期
 * @param endDate 结束日期
 * @returns 标签统计结果
 */
static async aggregateByTag(
  userId: number,
  startDate: string,
  endDate: string
): Promise<TagAggregation[]> {
  const store = DatabaseManager.getDatabase();
  
  const sql = `
    SELECT 
      t.tag_id,
      t.name AS tag_name,
      t.color,
      COUNT(DISTINCT bt.bill_id) AS bill_count,
      SUM(b.amount) AS total_amount
    FROM tags t
    INNER JOIN bill_tags bt ON t.tag_id = bt.tag_id
    INNER JOIN bills b ON bt.bill_id = b.bill_id
    WHERE t.user_id = ? 
      AND t.is_deleted = 0
      AND b.is_deleted = 0
      AND b.transaction_date >= ?
      AND b.transaction_date <= ?
    GROUP BY t.tag_id
    ORDER BY total_amount DESC
  `;
  
  let resultSet: relationalStore.ResultSet | null = null;
  try {
    resultSet = await store.querySql(sql, [userId, startDate, endDate]);
    const results: TagAggregation[] = [];
    
    while (resultSet.goToNextRow()) {
      results.push({
        tagId: resultSet.getLong(resultSet.getColumnIndex('tag_id')),
        tagName: resultSet.getString(resultSet.getColumnIndex('tag_name')),
        color: resultSet.getString(resultSet.getColumnIndex('color')),
        billCount: resultSet.getLong(resultSet.getColumnIndex('bill_count')),
        totalAmount: resultSet.getDouble(resultSet.getColumnIndex('total_amount'))
      });
    }
    
    return results;
  } finally {
    resultSet?.close();
  }
}
```

### 4.4 组合查询（分类+标签）

#### 场景：按分类和标签组合筛选账单

```typescript
/**
 * 组合查询：按分类和标签筛选账单
 * @param userId 用户ID
 * @param categoryIds 分类ID数组（可选）
 * @param tagIds 标签ID数组（可选）
 * @param startDate 开始日期
 * @param endDate 结束日期
 * @returns 账单列表
 */
static async queryBillsByCategoryAndTags(
  userId: number,
  categoryIds: number[] | null,
  tagIds: number[] | null,
  startDate: string,
  endDate: string
): Promise<Bill[]> {
  const store = DatabaseManager.getDatabase();
  
  let sql = `
    SELECT DISTINCT b.* 
    FROM bills b
    INNER JOIN accounts a ON b.account_id = a.account_id
  `;
  
  const params: (number | string)[] = [];
  const conditions: string[] = [];
  
  // 标签条件
  if (tagIds && tagIds.length > 0) {
    sql += `
      INNER JOIN bill_tags bt ON b.bill_id = bt.bill_id
      INNER JOIN tags t ON bt.tag_id = t.tag_id
    `;
    conditions.push(`t.tag_id IN (${tagIds.map(() => '?').join(',')})`);
    params.push(...tagIds);
  }
  
  // 基础条件
  conditions.push('a.user_id = ?');
  params.push(userId);
  
  conditions.push('b.is_deleted = 0');
  conditions.push('b.transaction_date >= ?');
  params.push(startDate);
  conditions.push('b.transaction_date <= ?');
  params.push(endDate);
  
  // 分类条件
  if (categoryIds && categoryIds.length > 0) {
    conditions.push(`b.category_id IN (${categoryIds.map(() => '?').join(',')})`);
    params.push(...categoryIds);
  }
  
  sql += ` WHERE ${conditions.join(' AND ')} ORDER BY b.transaction_date DESC`;
  
  let resultSet: relationalStore.ResultSet | null = null;
  try {
    resultSet = await store.querySql(sql, params);
    const bills: Bill[] = [];
    
    while (resultSet.goToNextRow()) {
      bills.push(this.mapRowToBill(resultSet));
    }
    
    return bills;
  } finally {
    resultSet?.close();
  }
}
```

## 5. 性能优化建议

### 5.1 索引优化
- 为高频查询字段创建复合索引
- 使用部分索引（WHERE is_deleted = 0）减少索引大小
- 定期分析查询计划，优化慢查询

### 5.2 查询优化
- 避免 SELECT *，只查询需要的字段
- 使用 LIMIT 限制结果集大小
- 合理使用 JOIN，避免笛卡尔积
- 对大数据量使用分页查询

### 5.3 缓存策略
- 缓存热门分类和标签列表
- 使用内存缓存减少数据库访问
- 设置合理的缓存过期时间

### 5.4 批量操作
- 使用事务批量插入/更新
- 减少数据库往返次数
- 合并多个小查询为一个大查询

## 6. 使用示例

### 6.1 创建分类

```typescript
const category = new Category();
category.userId = 1;
category.name = '餐饮';
category.type = 'expense';
category.icon = '🍔';
category.color = '#FF6B6B';
category.sortOrder = 1;

await CategoryDAO.insert(category);
```

### 6.2 创建标签并关联账单

```typescript
// 创建标签
const tag = new Tag();
tag.userId = 1;
tag.name = '报销';
tag.color = '#52C41A';

await TagDAO.insert(tag);

// 关联账单
await TagDAO.addTagToBill(billId, tag.tagId);
```

### 6.3 查询分类统计

```typescript
const stats = await CategoryDAO.aggregateByCategory(
  userId,
  '2025-01-01',
  '2025-01-31'
);

stats.forEach(stat => {
  console.log(`${stat.categoryName}: ¥${stat.totalAmount}`);
});
```

## 7. 注意事项

1. **数据一致性**：使用事务确保关联表数据一致性
2. **软删除**：分类和标签使用软删除，避免影响历史数据
3. **唯一性约束**：同一用户下分类名称+类型唯一，标签名称唯一
4. **级联删除**：删除标签时自动清理 bill_tags 关联记录
5. **使用计数**：标签使用次数需要在添加/删除关联时同步更新

## 8. 扩展功能

### 8.1 分类排序
支持用户自定义分类排序，通过 sort_order 字段实现

### 8.2 分类图标库
预置常用分类图标，支持自定义上传

### 8.3 智能标签推荐
基于历史数据推荐常用标签组合

### 8.4 分类预算关联
分类与预算功能联动，实时显示预算使用情况

---

**文档版本**: v1.0  
**最后更新**: 2025-11-10  
**适用平台**: HarmonyOS (ArkTS)
