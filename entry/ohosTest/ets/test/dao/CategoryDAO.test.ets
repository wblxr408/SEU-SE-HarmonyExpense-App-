import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { CategoryDAO } from '../../../../src/main/ets/dao/CategoryDAO';
import { Category } from '../../../../src/main/ets/model/Category';
import { DatabaseManager } from '../../../../src/main/ets/database/DatabaseManager';
import common from '@ohos.app.ability.common';

// 在测试环境中获取 Context 的辅助函数
function getTestContext(): common.Context {
  // 在 stageMode 中，getContext 是全局函数
  return getContext() as common.Context;
}

export default function CategoryDAOTest(): void {
  describe('CategoryDAO CRUD', () => {
    const testUserId: number = 1;

    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should insert and get category', 0, async () => {
      const now = new Date().toISOString();
      const cat = new Category(
        0,
        testUserId,
        '餐饮',
        'expense',
        '🍽️',
        '#FF6B6B',
        0,
        0,
        now,
        now,
        0
      );
      await CategoryDAO.insert(cat);
      const retrieved = await CategoryDAO.getById(testUserId, 1);
      expect(retrieved !== null).assertTrue();
      if (retrieved) {
        expect(retrieved.name).assertEqual('餐饮');
        expect(retrieved.type).assertEqual('expense');
      }
    });

    it('should get all categories', 0, async () => {
      const categories = await CategoryDAO.getAll(testUserId);
      expect(Array.isArray(categories)).assertTrue();
      expect(categories.length >= 1).assertTrue();
    });

    it('should get categories by type', 0, async () => {
      const expenseCats = await CategoryDAO.getByType(testUserId, 'expense');
      expect(Array.isArray(expenseCats)).assertTrue();
    });

    it('should update category', 0, async () => {
      const cat = await CategoryDAO.getById(testUserId, 1);
      if (cat) {
        cat.name = '美食';
        await CategoryDAO.update(cat);
        const updated = await CategoryDAO.getById(testUserId, 1);
        expect(updated !== null).assertTrue();
        if (updated) {
          expect(updated.name).assertEqual('美食');
        }
      }
    });
  });
}
