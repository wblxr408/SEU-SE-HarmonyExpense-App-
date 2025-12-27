# Categories/Tags 功能使用示例

本文档提供 Categories 和 Tags 功能的完整使用示例代码。

## 1. 分类管理示例

### 1.1 创建分类

```typescript
import { Category } from '../model/Category';
import { CategoryDAO } from '../dao/CategoryDAO';

// 创建一级分类
const category = new Category();
category.userId = 1;
category.name = '餐饮';
category.type = 'expense';
category.icon = '🍔';
category.color = '#FF6B6B';
category.parentCategoryId = 0;  // 0 表示一级分类
category.sortOrder = 1;

await CategoryDAO.insert(category);

// 创建子分类
const subCategory = new Category();
subCategory.userId = 1;
subCategory.name = '快餐';
subCategory.type = 'expense';
subCategory.icon = '🍟';
subCategory.color = '#FF8787';
subCategory.parentCategoryId = 1;  // 父分类ID
subCategory.sortOrder = 1;

await CategoryDAO.insert(subCategory);
```

### 1.2 批量创建分类

```typescript
const categories: Category[] = [
  new Category(0, 1, '交通', 'expense', '🚗', '#4ECDC4', 0, 2),
  new Category(0, 1, '购物', 'expense', '🛍️', '#95E1D3', 0, 3),
  new Category(0, 1, '娱乐', 'expense', '🎮', '#F38181', 0, 4),
  new Category(0, 1, '工资', 'income', '💰', '#52C41A', 0, 1),
  new Category(0, 1, '奖金', 'income', '🎁', '#73D13D', 0, 2)
];

await CategoryDAO.bulkInsert(categories);
```

### 1.3 查询分类

```typescript
// 查询所有分类
const allCategories = await CategoryDAO.getAll(userId);
console.log(`共有 ${allCategories.length} 个分类`);

// 按类型查询
const expenseCategories = await CategoryDAO.getByType(userId, 'expense');
const incomeCategories = await CategoryDAO.getByType(userId, 'income');

// 查询子分类
const children = await CategoryDAO.getChildren(userId, parentCategoryId);
console.log(`子分类数量: ${children.length}`);

// 查询单个分类
const category = await CategoryDAO.getById(userId, categoryId);
if (category) {
  console.log(`分类名称: ${category.name}`);
}
```

### 1.4 获取分类树

```typescript
import { CategoryTreeNode } from '../model/AggregationTypes';

// 获取支出分类树
const expenseTree = await CategoryDAO.getCategoryTree(userId, 'expense');

// 递归遍历分类树
function printTree(nodes: CategoryTreeNode[], level: number = 0) {
  for (const node of nodes) {
    const indent = '  '.repeat(level);
    console.log(`${indent}${node.category.icon} ${node.category.name}`);
    
    if (node.children.length > 0) {
      printTree(node.children, level + 1);
    }
  }
}

printTree(expenseTree);
```

### 1.5 更新分类

```typescript
const category = await CategoryDAO.getById(userId, categoryId);
if (category) {
  category.name = '餐饮美食';
  category.icon = '🍽️';
  category.sortOrder = 10;
  
  await CategoryDAO.update(category);
}
```

### 1.6 删除分类

```typescript
// 软删除（推荐）
await CategoryDAO.softDelete(userId, categoryId);

// 恢复已删除的分类
await CategoryDAO.restore(userId, categoryId);

// 硬删除（慎用，会永久删除）
await CategoryDAO.hardDelete(userId, categoryId);
```

## 2. 标签管理示例

### 2.1 创建标签

```typescript
import { Tag } from '../model/Tag';
import { TagDAO } from '../dao/TagDAO';

const tag = new Tag();
tag.userId = 1;
tag.name = '报销';
tag.color = '#52C41A';

await TagDAO.insert(tag);
```

### 2.2 批量创建标签

```typescript
const tags: Tag[] = [
  new Tag(0, 1, '紧急', '#FF4D4F'),
  new Tag(0, 1, '旅游', '#1890FF'),
  new Tag(0, 1, '工作', '#722ED1'),
  new Tag(0, 1, '家庭', '#FA8C16')
];

await TagDAO.bulkInsert(tags);
```

### 2.3 查询标签

```typescript
// 查询所有标签
const allTags = await TagDAO.getAll(userId);

// 查询热门标签（按使用频率排序）
const popularTags = await TagDAO.getPopularTags(userId, 10);
console.log('热门标签:');
popularTags.forEach(tag => {
  console.log(`${tag.name} (使用 ${tag.usageCount} 次)`);
});

// 查询单个标签
const tag = await TagDAO.getById(userId, tagId);
```

### 2.4 为账单添加标签

```typescript
// 添加单个标签
await TagDAO.addTagToBill(billId, tagId);

// 批量设置标签（替换现有标签）
const tagIds = [1, 2, 3];  // 标签ID数组
await TagDAO.setTagsForBill(billId, tagIds);

// 移除标签
await TagDAO.removeTagFromBill(billId, tagId);
```

### 2.5 查询账单的标签

```typescript
// 获取账单的所有标签
const billTags = await TagDAO.getTagsByBillId(billId);
console.log(`账单有 ${billTags.length} 个标签`);

// 获取标签关联的所有账单ID
const billIds = await TagDAO.getBillIdsByTagId(tagId);
console.log(`标签关联了 ${billIds.length} 个账单`);
```

### 2.6 更新和删除标签

```typescript
// 更新标签
const tag = await TagDAO.getById(userId, tagId);
if (tag) {
  tag.name = '可报销';
  tag.color = '#73D13D';
  await TagDAO.update(tag);
}

// 软删除
await TagDAO.softDelete(userId, tagId);

// 恢复
await TagDAO.restore(userId, tagId);

// 硬删除（会同时删除所有关联记录）
await TagDAO.hardDelete(userId, tagId);
```

## 3. 聚合查询示例

### 3.1 按分类统计

```typescript
import { CategoryAggregation } from '../model/AggregationTypes';

// 查询本月分类统计
const startDate = '2025-11-01';
const endDate = '2025-11-30';

const categoryStats = await CategoryDAO.aggregateByCategory(
  userId,
  startDate,
  endDate
);

console.log('分类统计:');
categoryStats.forEach(stat => {
  console.log(`${stat.icon} ${stat.categoryName}:`);
  console.log(`  总金额: ¥${stat.totalAmount.toFixed(2)}`);
  console.log(`  交易次数: ${stat.transactionCount}`);
  console.log(`  平均金额: ¥${stat.avgAmount.toFixed(2)}`);
  console.log(`  最小金额: ¥${stat.minAmount.toFixed(2)}`);
  console.log(`  最大金额: ¥${stat.maxAmount.toFixed(2)}`);
});
```

### 3.2 按标签统计

```typescript
import { TagAggregation } from '../model/AggregationTypes';

const tagStats = await TagDAO.aggregateByTag(
  userId,
  startDate,
  endDate
);

console.log('标签统计:');
tagStats.forEach(stat => {
  console.log(`${stat.tagName}:`);
  console.log(`  总金额: ¥${stat.totalAmount.toFixed(2)}`);
  console.log(`  账单数: ${stat.billCount}`);
});
```

## 4. 组合查询示例

### 4.1 按分类和标签筛选账单

```typescript
import { QueryHelper } from '../dao/QueryHelper';

// 查询指定分类和标签的账单
const categoryIds = [1, 2, 3];  // 餐饮、交通、购物
const tagIds = [1, 2];          // 报销、紧急

const bills = await QueryHelper.queryBillsByCategoryAndTags(
  userId,
  categoryIds,
  tagIds,
  '2025-11-01',
  '2025-11-30'
);

console.log(`找到 ${bills.length} 条符合条件的账单`);
```

### 4.2 按分类查询（包含子分类）

```typescript
// 查询餐饮分类及其所有子分类的账单
const bills = await QueryHelper.queryBillsByCategory(
  userId,
  categoryId,
  true,  // 包含子分类
  '2025-11-01',
  '2025-11-30'
);

console.log(`餐饮及子分类共有 ${bills.length} 条账单`);
```

## 5. 完整使用场景示例

### 5.1 创建账单并添加标签

```typescript
import { Bill } from '../model/Bill';
import { BillDAO } from '../dao/BillDAO';

// 创建账单
const bill = new Bill();
bill.userId = 1;
bill.accountId = 1;
bill.categoryId = 1;  // 餐饮
bill.amount = 58.50;
bill.type = 'expense';
bill.note = '午餐';
bill.transactionDate = '2025-11-10';

await BillDAO.insert(bill);

// 为账单添加标签
const tagIds = [1, 3];  // 报销、工作
await TagDAO.setTagsForBill(bill.billId, tagIds);
```

### 5.2 生成月度报表

```typescript
async function generateMonthlyReport(userId: number, month: string) {
  const startDate = `${month}-01`;
  const endDate = `${month}-31`;
  
  // 获取分类统计
  const categoryStats = await CategoryDAO.aggregateByCategory(
    userId,
    startDate,
    endDate
  );
  
  // 获取标签统计
  const tagStats = await TagDAO.aggregateByTag(
    userId,
    startDate,
    endDate
  );
  
  // 计算总支出和总收入
  let totalExpense = 0;
  let totalIncome = 0;
  
  categoryStats.forEach(stat => {
    if (stat.type === 'expense') {
      totalExpense += stat.totalAmount;
    } else {
      totalIncome += stat.totalAmount;
    }
  });
  
  console.log(`=== ${month} 月度报表 ===`);
  console.log(`总收入: ¥${totalIncome.toFixed(2)}`);
  console.log(`总支出: ¥${totalExpense.toFixed(2)}`);
  console.log(`结余: ¥${(totalIncome - totalExpense).toFixed(2)}`);
  console.log('');
  
  console.log('支出分类 TOP 5:');
  categoryStats
    .filter(s => s.type === 'expense')
    .slice(0, 5)
    .forEach((stat, index) => {
      console.log(`${index + 1}. ${stat.categoryName}: ¥${stat.totalAmount.toFixed(2)}`);
    });
  
  console.log('');
  console.log('热门标签:');
  tagStats.slice(0, 5).forEach((stat, index) => {
    console.log(`${index + 1}. ${stat.tagName}: ¥${stat.totalAmount.toFixed(2)} (${stat.billCount}笔)`);
  });
}

// 使用
await generateMonthlyReport(1, '2025-11');
```

### 5.3 搜索功能

```typescript
async function searchBills(
  userId: number,
  keyword: string,
  categoryIds: number[] | null,
  tagIds: number[] | null,
  startDate: string,
  endDate: string
) {
  // 先按分类和标签筛选
  let bills = await QueryHelper.queryBillsByCategoryAndTags(
    userId,
    categoryIds,
    tagIds,
    startDate,
    endDate
  );
  
  // 再按关键词过滤
  if (keyword) {
    bills = bills.filter(bill => 
      bill.note.includes(keyword)
    );
  }
  
  return bills;
}

// 使用：搜索包含"午餐"的餐饮类账单
const results = await searchBills(
  1,
  '午餐',
  [1],  // 餐饮分类
  null,
  '2025-11-01',
  '2025-11-30'
);
```

## 6. 性能优化建议

### 6.1 使用缓存

```typescript
class CategoryCache {
  private static cache: Map<number, Category[]> = new Map();
  private static cacheTime: Map<number, number> = new Map();
  private static readonly CACHE_TTL = 5 * 60 * 1000; // 5分钟
  
  static async getAll(userId: number): Promise<Category[]> {
    const now = Date.now();
    const lastUpdate = this.cacheTime.get(userId) || 0;
    
    // 检查缓存是否有效
    if (now - lastUpdate < this.CACHE_TTL && this.cache.has(userId)) {
      return this.cache.get(userId)!;
    }
    
    // 从数据库查询
    const categories = await CategoryDAO.getAll(userId);
    
    // 更新缓存
    this.cache.set(userId, categories);
    this.cacheTime.set(userId, now);
    
    return categories;
  }
  
  static clear(userId: number) {
    this.cache.delete(userId);
    this.cacheTime.delete(userId);
  }
}
```

### 6.2 批量操作

```typescript
// 批量为多个账单添加相同标签
async function batchAddTagToBills(billIds: number[], tagId: number) {
  const store = DatabaseManager.getDatabase();
  await store.beginTransaction();
  
  try {
    for (const billId of billIds) {
      await TagDAO.addTagToBill(billId, tagId);
    }
    await store.commit();
  } catch (error) {
    await store.rollBack();
    throw error;
  }
}
```

## 7. 错误处理

```typescript
try {
  const category = new Category();
  category.userId = 1;
  category.name = '餐饮';
  category.type = 'expense';
  
  await CategoryDAO.insert(category);
  console.log('分类创建成功');
} catch (error) {
  if (error.message.includes('UNIQUE constraint failed')) {
    console.error('分类名称已存在');
  } else {
    console.error('创建失败:', error.message);
  }
}
```

---

**文档版本**: v1.0  
**最后更新**: 2025-11-10  
**适用平台**: HarmonyOS (ArkTS)
