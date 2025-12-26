import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { CategoryDAO } from '../../../../src/main/ets/dao/CategoryDAO';
import { Category } from '../../../../src/main/ets/model/Category';
import { DatabaseManager } from '../../../../src/main/ets/dao/DatabaseManager';
import common from '@ohos.app.ability.common';

// 在测试环境中获取 Context 的辅助函数
function getTestContext(): common.Context {
  // 在 stageMode 中，getContext 是全局函数
  return getContext() as common.Context;
}

export default function CategoryManagementPageTest(): void {
  describe('CategoryManagement Page', () => {
    const testUserId: number = 1;

    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should load categories successfully', 0, async () => {
      // 测试加载分类列表
      const categories = await CategoryDAO.getAll(testUserId);
      expect(Array.isArray(categories)).assertTrue();
    });

    it('should create new category', 0, async () => {
      // 测试创建新分类
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
      // 测试更新分类
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
      // 测试软删除分类
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
      // 测试按类型筛选分类
      const expenseCategories = await CategoryDAO.getByType(testUserId, 'expense');
      const incomeCategories = await CategoryDAO.getByType(testUserId, 'income');

      expect(Array.isArray(expenseCategories)).assertTrue();
      expect(Array.isArray(incomeCategories)).assertTrue();

      // 验证类型正确
      for (const cat of expenseCategories) {
        expect(cat.type).assertEqual('expense');
      }
      for (const cat of incomeCategories) {
        expect(cat.type).assertEqual('income');
      }
    });

    it('should validate category name is required', 0, () => {
      // 测试分类名称验证
      const invalidCategory = new Category(
        0,
        testUserId,
        '', // 空名称
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
      // 测试分类克隆功能
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

      // 修改克隆对象不应影响原对象
      cloned.name = '修改后的分类';
      expect(original.name).assertEqual('原始分类');
    });
  });
}
