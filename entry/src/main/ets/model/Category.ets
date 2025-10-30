/**
 * 分类模型 - 1.0.0版本
 */
export class Category {
  categoryId: number = 0;
  userId: number = 0;
  name: string = '';
  type: string = 'expense'; // 'expense' | 'income'
  icon: string = '📦';
  color: string = '#1890FF';
  parentCategoryId: number = 0; // 0表示一级分类

  constructor() {
  }
}