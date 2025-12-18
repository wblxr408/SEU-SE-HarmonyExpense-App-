import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { UserDAO } from '../../../../main/ets/dao/UserDAO';
import { User } from '../../../../main/ets/model/User';
import { DatabaseManager } from '../../../../main/ets/database/DatabaseManager';
import common from '@ohos.app.ability.common';

// 在测试环境中获取 Context 的辅助函数
function getTestContext(): common.Context {
  // 在 stageMode 中，getContext 是全局函数
  return getContext() as common.Context;
}

export default function UserDAOTest(): void {
  describe('UserDAO_CRUD', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should_insert_and_get_user', 0, async () => {
      const now = new Date().toISOString();
      const user = new User(
        0,
        'testuser',
        'test@example.com',
        'hashed_password',
        now,
        now,
        0
      );
      await UserDAO.insert(user);
      const retrieved = await UserDAO.getById(1);
      expect(retrieved !== null).assertTrue();
      if (retrieved) {
        expect(retrieved.username).assertEqual('testuser');
        expect(retrieved.email).assertEqual('test@example.com');
      }
    });

    it('should_get_all_users', 0, async () => {
      const users = await UserDAO.getAll();
      expect(Array.isArray(users)).assertTrue();
      expect(users.length >= 1).assertTrue();
    });

    it('should_update_user', 0, async () => {
      const user = await UserDAO.getById(1);
      if (user) {
        user.email = 'updated@example.com';
        await UserDAO.update(user);
        const updated = await UserDAO.getById(1);
        expect(updated !== null).assertTrue();
        if (updated) {
          expect(updated.email).assertEqual('updated@example.com');
        }
      }
    });

    it('should_soft_delete_user', 0, async () => {
      await UserDAO.delete(1);
      const deleted = await UserDAO.getById(1);
      expect(deleted === null).assertTrue();
    });
  });
}
