import { describe, it, expect } from '@ohos/hypium';
import { Category, CategoryJSON } from '../../../../src/main/ets/model/Category';

export default function CategoryTest(): void {
  describe('Category.validate()', () => {
    it('valid category should pass', 0, () => {
      const cat = new Category(
        1,
        1,
        '餐饮',
        'expense',
        '🍽️',
        '#FF6B6B',
        0,
        0,
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        0
      );
      expect(cat.validate()).assertTrue();
    });

    it('invalid category should fail (empty name)', 0, () => {
      const cat = new Category(
        0,
        1,
        '',
        'expense',
        '🍽️',
        '#FF6B6B',
        0,
        0,
        '',
        '',
        0
      );
      expect(cat.validate()).assertFalse();
    });

    it('invalid category should fail (invalid type)', 0, () => {
      const invalidType: string = 'invalid';
      const cat = new Category(
        0,
        1,
        '测试分类',
        invalidType as 'expense' | 'income',
        '🍽️',
        '#FF6B6B',
        0,
        0,
        '',
        '',
        0
      );
      expect(cat.validate()).assertFalse();
    });

    it('valid income category should pass', 0, () => {
      const cat = new Category(
        2,
        1,
        '工资',
        'income',
        '💰',
        '#52C41A',
        0,
        0,
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        0
      );
      expect(cat.validate()).assertTrue();
    });

    it('invalid category should fail (invalid is_deleted)', 0, () => {
      const cat = new Category(
        1,
        1,
        '餐饮',
        'expense',
        '🍽️',
        '#FF6B6B',
        0,
        0,
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        2
      );
      expect(cat.validate()).assertFalse();
    });
  });

  describe('Category.toJSON() and fromJSON()', () => {
    it('toJSON should return correct structure', 0, () => {
      const cat = new Category(
        1,
        1,
        '餐饮',
        'expense',
        '🍽️',
        '#FF6B6B',
        0,
        0,
        '2025-11-05T10:00:00',
        '2025-11-05T11:00:00',
        0
      );
      const json = cat.toJSON();
      expect(json.categoryId).assertEqual(1);
      expect(json.name).assertEqual('餐饮');
      expect(json.type).assertEqual('expense');
    });

    it('fromJSON should create correct Category instance', 0, () => {
      const json: CategoryJSON = {
        categoryId: 2,
        userId: 1,
        name: '交通',
        type: 'expense',
        icon: '🚗',
        color: '#4ECDC4',
        parentCategoryId: 0,
        sortOrder: 0,
        createdAt: '2025-11-05T10:00:00',
        updatedAt: '2025-11-05T11:00:00',
        is_deleted: 0
      };
      const cat = Category.fromJSON(json);
      expect(cat.categoryId).assertEqual(2);
      expect(cat.name).assertEqual('交通');
      expect(cat.type).assertEqual('expense');
    });
  });
}
