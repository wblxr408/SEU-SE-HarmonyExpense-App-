import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { CategoryDAO } from '../../../../src/main/ets/dao/CategoryDAO';
import { Category } from '../../../../src/main/ets/model/Category';
import { DatabaseManager } from '../../../../src/main/ets/database/DatabaseManager';
import common from '@ohos.app.ability.common';

// 在测试环境中获取 Context 的辅助函数
function getTestContext(): common.Context {
  return getContext() as common.Context;
}

// 验证结果接口
interface ValidationResult {
  valid: boolean;
  message: string;
}

// 模拟CategoryManagement页面的保存验证逻辑
function validateCategoryForSave(category: Category | null): ValidationResult {
  if (!category) {
    const result: ValidationResult = { valid: false, message: '分类对象为空' };
    return result;
  }
  if (!category.name || category.name.trim() === '') {
    const result: ValidationResult = { valid: false, message: '分类名称不能为空' };
    return result;
  }
  const result: ValidationResult = { valid: true, message: '' };
  return result;
}

export default function CategoryManagementPageTest(): void {
  describe('CategoryManagement Page', () => {
    const testUserId: number = 1;

    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should load categories successfully', 0, async () => {
      const categories = await CategoryDAO.getAll(testUserId);
      expect(Array.isArray(categories)).assertTrue();
    });

    it('should create new category', 0, async () => {
      const now = new Date().toISOString();
      const newCategory = new Category(
        0,
        testUserId,
        '测试分类',
        'expense',
        '🧪',
        '#FF6B6B',
        0,
        0,
        now,
        now,
        0
      );

      await CategoryDAO.insert(newCategory);
      const categories = await CategoryDAO.getAll(testUserId);
      const found = categories.find(c => c.name === '测试分类');
      expect(found !== undefined).assertTrue();
    });

    it('should update category', 0, async () => {
      const categories = await CategoryDAO.getAll(testUserId);
      if (categories.length > 0) {
        const category = categories[0];
        const originalName = category.name;
        category.name = '更新后的分类';
        await CategoryDAO.update(category);

        const updated = await CategoryDAO.getById(testUserId, category.categoryId);
        expect(updated !== null).assertTrue();
        if (updated) {
          expect(updated.name).assertEqual('更新后的分类');
        }

        // 恢复原名称
        category.name = originalName;
        await CategoryDAO.update(category);
      }
    });

    it('should delete category (soft delete)', 0, async () => {
      const now = new Date().toISOString();
      const tempCategory = new Category(
        0,
        testUserId,
        '临时分类',
        'expense',
        '🗑️',
        '#999999',
        0,
        0,
        now,
        now,
        0
      );

      await CategoryDAO.insert(tempCategory);
      const categories = await CategoryDAO.getAll(testUserId);
      const found = categories.find(c => c.name === '临时分类');

      if (found) {
        await CategoryDAO.softDelete(testUserId, found.categoryId);
        const afterDelete = await CategoryDAO.getById(testUserId, found.categoryId);
        expect(afterDelete === null).assertTrue();
      }
    });

    it('should filter categories by type', 0, async () => {
      const expenseCategories = await CategoryDAO.getByType(testUserId, 'expense');
      const incomeCategories = await CategoryDAO.getByType(testUserId, 'income');

      expect(Array.isArray(expenseCategories)).assertTrue();
      expect(Array.isArray(incomeCategories)).assertTrue();

      for (const cat of expenseCategories) {
        expect(cat.type).assertEqual('expense');
      }
      for (const cat of incomeCategories) {
        expect(cat.type).assertEqual('income');
      }
    });

    it('should validate category name is required', 0, () => {
      const invalidCategory = new Category(
        0,
        testUserId,
        '',
        'expense',
        '🧪',
        '#FF6B6B',
        0,
        0,
        '',
        '',
        0
      );

      expect(invalidCategory.validate()).assertFalse();
    });

    it('should clone category correctly', 0, () => {
      const original = new Category(
        1,
        testUserId,
        '原始分类',
        'expense',
        '🧪',
        '#FF6B6B',
        0,
        0,
        '2025-11-08',
        '2025-11-08',
        0
      );

      const cloned = original.clone();
      expect(cloned.categoryId).assertEqual(original.categoryId);
      expect(cloned.name).assertEqual(original.name);
      expect(cloned.type).assertEqual(original.type);

      cloned.name = '修改后的分类';
      expect(original.name).assertEqual('原始分类');
    });
  });

  describe('CategoryManagement Page Save Validation', () => {
    it('should validate category name is required', 0, () => {
      const category = new Category(0, 1, '', 'expense', '🧪', '#FF6B6B', 0, 0, '', '', 0);
      const validation = validateCategoryForSave(category);
      expect(validation.valid).assertFalse();
      expect(validation.message.includes('名称')).assertTrue();
    });

    it('should pass validation for valid category', 0, () => {
      const category = new Category(0, 1, '有效分类', 'expense', '🧪', '#FF6B6B', 0, 0, '', '', 0);
      const validation = validateCategoryForSave(category);
      expect(validation.valid).assertTrue();
    });

    it('should reject null category', 0, () => {
      const validation = validateCategoryForSave(null);
      expect(validation.valid).assertFalse();
    });

    it('should reject category with whitespace-only name', 0, () => {
      const category = new Category(0, 1, '   ', 'expense', '🧪', '#FF6B6B', 0, 0, '', '', 0);
      const validation = validateCategoryForSave(category);
      expect(validation.valid).assertFalse();
    });
  });

  describe('CategoryManagement Page State Management', () => {
    it('should handle create vs update mode', 0, () => {
      // 新建模式：categoryId === 0
      const newCategory = new Category(0, 1, '新分类', 'expense', '🧪', '#FF6B6B', 0, 0, '', '', 0);
      const isCreate = newCategory.categoryId === 0;
      expect(isCreate).assertTrue();

      // 编辑模式：categoryId > 0
      const existingCategory = new Category(1, 1, '现有分类', 'expense', '🧪', '#FF6B6B', 0, 0, '', '', 0);
      const isUpdate = existingCategory.categoryId > 0;
      expect(isUpdate).assertTrue();
    });

    it('should set timestamps correctly for create', 0, () => {
      const now = new Date().toISOString();
      const category = new Category(0, 1, '新分类', 'expense', '🧪', '#FF6B6B', 0, 0, '', '', 0);
      category.createdAt = now;
      category.updatedAt = now;
      expect(category.createdAt).assertEqual(now);
      expect(category.updatedAt).assertEqual(now);
    });

    it('should update timestamp for update', 0, () => {
      const category = new Category(1, 1, '现有分类', 'expense', '🧪', '#FF6B6B', 0, 0, '2025-11-01', '2025-11-01', 0);
      const newUpdatedAt = new Date().toISOString();
      category.updatedAt = newUpdatedAt;
      expect(category.updatedAt).assertEqual(newUpdatedAt);
      expect(category.createdAt).assertEqual('2025-11-01'); // 创建时间不变
    });
  });
}
