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
  parentCategoryId: number = 0; // 0 表示一级分类
  sortOrder: number = 0; // 排序序号
  createdAt: string = '';
  updatedAt: string = '';
  is_deleted: number = 0;

  constructor(
    categoryId: number = 0,
    userId: number = 0,
    name: string = '',
    type: 'expense' | 'income' = 'expense',
    icon: string = '📦',
    color: string = '#1890FF',
    parentCategoryId: number = 0,
    sortOrder: number = 0,
    createdAt: string = '',
    updatedAt: string = '',
    is_deleted: number = 0
  ) {
    this.categoryId = categoryId;
    this.userId = userId;
    this.name = name;
    this.type = type;
    this.icon = icon;
    this.color = color;
    this.parentCategoryId = parentCategoryId;
    this.sortOrder = sortOrder;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.is_deleted = is_deleted;
  }

  toJSON(): CategoryJSON {
    return {
      categoryId: this.categoryId,
      userId: this.userId,
      name: this.name,
      type: this.type,
      icon: this.icon,
      color: this.color,
      parentCategoryId: this.parentCategoryId,
      sortOrder: this.sortOrder,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      is_deleted: this.is_deleted
    };
  }

  static fromJSON(data: CategoryJSON): Category {
    return new Category(
      data.categoryId,
      data.userId,
      data.name,
      data.type,
      data.icon,
      data.color,
      data.parentCategoryId,
      data.sortOrder,
      data.createdAt,
      data.updatedAt,
      data.is_deleted ?? 0
    );
  }

  validate(): boolean {
    return (
      this.name !== '' &&
      this.name.length <= 50 &&
      ['expense', 'income'].includes(this.type) &&
      (this.is_deleted === 0 || this.is_deleted === 1)
    );
  }

  clone(): Category {
    return new Category(
      this.categoryId,
      this.userId,
      this.name,
      this.type,
      this.icon,
      this.color,
      this.parentCategoryId,
      this.sortOrder,
      this.createdAt,
      this.updatedAt,
      this.is_deleted
    );
  }
}
