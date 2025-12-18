import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { BillDAO } from '../../../../main/ets/dao/BillDAO';
import { AccountDAO } from '../../../../main/ets/dao/AccountDAO';
import { CategoryDAO } from '../../../../main/ets/dao/CategoryDAO';
import { DatabaseManager } from '../../../../main/ets/database/DatabaseManager';
import { Bill } from '../../../../main/ets/model/Bill';
import { Account } from '../../../../main/ets/model/Account';
import { Category } from '../../../../main/ets/model/Category';
import common from '@ohos.app.ability.common';

// 在测试环境中获取 Context 的辅助函数
function getTestContext(): common.Context {
  // 在 stageMode 中，getContext 是全局函数
  return getContext() as common.Context;
}

export default function BillDAOTest(): void {
  describe('BillDAO_CRUD', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      // 使用 DatabaseManager 统一初始化数据库
      await DatabaseManager.initDatabase(ctx);

      // 创建测试用的账户和分类
      const now = new Date().toISOString();
      const testAccount = new Account(0, 1, '测试账户', 'bank', 1000.0, '#1E90FF', now, 0);
      testAccount.updatedAt = now;
      const testCategory = new Category(0, 1, '测试分类', 'expense', '🍽️', '#FF6B6B', 0, 0, now, now, 0);
      
      try {
        await AccountDAO.insert(testAccount);
        await CategoryDAO.insert(testCategory);
      } catch (e) {
        // 如果已存在则忽略
      }
    });

    it('should_insert_and_get_bill', 0, async () => {
      const now = new Date().toISOString();
      const bill = new Bill(
        0,
        1, // userId
        1, // accountId
        1, // categoryId
        100.0,
        '测试账单',
        '2025-11-05',
        'expense',
        now,
        now,
        0
      );
      await BillDAO.insert(bill);
      const retrieved = await BillDAO.getById(1, 1);
      expect(retrieved !== null).assertTrue();
      if (retrieved) {
        expect(retrieved.amount).assertEqual(100.0);
        expect(retrieved.note).assertEqual('测试账单');
      }
    });

    it('should_get_all_bills', 0, async () => {
      const bills = await BillDAO.getAll();
      expect(Array.isArray(bills)).assertTrue();
      expect(bills.length >= 1).assertTrue();
    });

    it('should_update_bill', 0, async () => {
      const bill = await BillDAO.getById(1, 1);
      if (bill) {
        bill.amount = 150.0;
        await BillDAO.update(bill);
        const updated = await BillDAO.getById(1, 1);
        expect(updated !== null).assertTrue();
        if (updated) {
          expect(updated.amount).assertEqual(150.0);
        }
      }
    });

    it('should_soft_delete_bill', 0, async () => {
      await BillDAO.delete(1, 1);
      const deleted = await BillDAO.getById(1, 1);
      expect(deleted === null).assertTrue();
    });
  });
}
