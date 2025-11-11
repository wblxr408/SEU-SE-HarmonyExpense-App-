/**
 * 聚合查询类型定义
 */
import { Category } from './Category';

/**
 * 分类树节点
 */
export interface CategoryTreeNode {
  category: Category;
  children: CategoryTreeNode[];
}

/**
 * 分类聚合统计结果
 */
export interface CategoryAggregation {
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

/**
 * 标签聚合统计结果
 */
export interface TagAggregation {
  tagId: number;
  tagName: string;
  color: string;
  billCount: number;
  totalAmount: number;
}
