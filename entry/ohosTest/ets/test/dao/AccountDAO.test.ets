import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { AccountDAO } from '../../../../src/main/ets/dao/AccountDAO';
import { Account } from '../../../../src/main/ets/model/Account';
import { DatabaseManager } from '../../../../src/main/ets/database/DatabaseManager';
import common from '@ohos.app.ability.common';

// 在测试环境中获取 Context 的辅助函数
function getTestContext(): common.Context {
  // 在 stageMode 中，getContext 是全局函数
  return getContext() as common.Context;
}

export default function AccountDAOTest(): void {
  describe('AccountDAO CRUD', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should insert and get account', 0, async () => {
      const now = new Date().toISOString();
      const acc = new Account(
        0,
        1,
        '测试账户',
        'bank',
        5000.0,
        '#1E90FF',
        now,
        0
      );
      await AccountDAO.insert(acc);
      const retrieved = await AccountDAO.getById(1);
      expect(retrieved !== null).assertTrue();
      if (retrieved) {
        expect(retrieved.name).assertEqual('测试账户');
        expect(retrieved.balance).assertEqual(5000.0);
      }
    });

    it('should get all accounts', 0, async () => {
      const accounts = await AccountDAO.getAll();
      expect(Array.isArray(accounts)).assertTrue();
      expect(accounts.length >= 1).assertTrue();
    });

    it('should update account', 0, async () => {
      const acc = await AccountDAO.getById(1);
      if (acc) {
        acc.balance = 4500.0;
        await AccountDAO.update(acc);
        const updated = await AccountDAO.getById(1);
        expect(updated !== null).assertTrue();
        if (updated) {
          expect(updated.balance).assertEqual(4500.0);
        }
      }
    });

    it('should get accounts by userId', 0, async () => {
      const accounts = await AccountDAO.getByUserId(1);
      expect(Array.isArray(accounts)).assertTrue();
    });
  });
}
