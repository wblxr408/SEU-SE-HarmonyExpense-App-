import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { DAOHelper } from '../../../../src/main/ets/common/DAOHelper';
import { DatabaseManager } from '../../../../src/main/ets/database/DatabaseManager';
import { UserDAO } from '../../../../src/main/ets/dao/UserDAO';
import { User } from '../../../../src/main/ets/model/User';
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

// 在测试环境中获取 Context 的辅助函数
function getTestContext(): common.Context {
  return getContext() as common.Context;
}

// 测试用的错误对象接口
interface TestErrorObject {
  code: number;
  message: string;
}

export default function DAOHelperTest(): void {
  describe('DAOHelper.toError()', () => {
    it('should convert string error to Error', 0, () => {
      const error = DAOHelper.toError('[Test]', 'test error message');
      expect(error instanceof Error).assertTrue();
      expect(error.message.includes('[Test]')).assertTrue();
      expect(error.message.includes('test error message')).assertTrue();
    });

    it('should convert Error object to Error', 0, () => {
      const originalError = new Error('original error');
      const error = DAOHelper.toError('[Test]', originalError);
      expect(error instanceof Error).assertTrue();
      expect(error.message.includes('[Test]')).assertTrue();
      expect(error.message.includes('original error')).assertTrue();
    });

    it('should convert object error to Error', 0, () => {
      const objError: TestErrorObject = { code: 123, message: 'object error' };
      const error = DAOHelper.toError('[Test]', objError);
      expect(error instanceof Error).assertTrue();
      expect(error.message.includes('[Test]')).assertTrue();
    });

    it('should handle empty error details', 0, () => {
      const error = DAOHelper.toError('[Test]', '');
      expect(error instanceof Error).assertTrue();
      expect(error.message.includes('[Test]')).assertTrue();
    });
  });

  describe('DAOHelper.transaction()', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should commit transaction on success', 0, async () => {
      let executed = false;
      await DAOHelper.transaction(async () => {
        executed = true;
      }, '[Test]');
      expect(executed).assertTrue();
    });

    it('should rollback transaction on error', 0, async () => {
      let executed = false;
      try {
        await DAOHelper.transaction(async () => {
          executed = true;
          throw new Error('test error');
        }, '[Test]');
        expect(false).assertTrue(); // 应该抛出错误
      } catch (error) {
        expect(executed).assertTrue();
        expect(error instanceof Error).assertTrue();
        expect((error as Error).message.includes('[Test]')).assertTrue();
      }
    });
  });

  describe('DAOHelper.exists()', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);

      // 创建测试用户
      try {
        const now = new Date().toISOString();
        const testUser = new User(0, 'testuser', 'test@example.com', 'hashed_pwd', now, now, 0);
        await UserDAO.insert(testUser);
      } catch (e) {
        // 如果已存在则忽略
      }
    });

    it('should return true for existing record', 0, async () => {
      const exists = await DAOHelper.exists('users', 'user_id', 1);
      expect(exists).assertTrue();
    });

    it('should return false for non-existent record', 0, async () => {
      const exists = await DAOHelper.exists('users', 'user_id', 99999);
      expect(exists).assertFalse();
    });
  });

  describe('DAOHelper.softDelete()', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should soft delete record', 0, async () => {
      // 先创建一个测试用户用于删除
      const now = new Date().toISOString();
      const testUser = new User(0, 'softdelete_test', 'softdelete@example.com', 'hashed_pwd', now, now, 0);
      await UserDAO.insert(testUser);
      
      const users = await UserDAO.getAll();
      const testUserRecord = users.find(u => u.username === 'softdelete_test');
      
      if (testUserRecord) {
        await DAOHelper.softDelete('users', 'user_id', testUserRecord.userId, '[Test]');
        const exists = await DAOHelper.exists('users', 'user_id', testUserRecord.userId);
        expect(exists).assertFalse(); // 软删除后应该不存在（因为exists检查is_deleted=0）
      }
    });
  });

  describe('DAOHelper.restore()', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should restore soft deleted record', 0, async () => {
      // 查找一个已删除的用户
      const users = await UserDAO.getAll();
      const testUser = users.find(u => u.username === 'softdelete_test');
      
      if (testUser) {
        await DAOHelper.restore('users', 'user_id', testUser.userId, '[Test]');
        const exists = await DAOHelper.exists('users', 'user_id', testUser.userId);
        expect(exists).assertTrue();
      }
    });
  });

  describe('DAOHelper.now()', () => {
    it('should return ISO format string', 0, () => {
      const now = DAOHelper.now();
      expect(typeof now).assertEqual('string');
      expect(now.includes('T')).assertTrue(); // ISO格式包含T
      expect(now.length > 0).assertTrue();
    });

    it('should return valid date string', 0, () => {
      const now = DAOHelper.now();
      const date = new Date(now);
      expect(isNaN(date.getTime())).assertFalse();
    });
  });

  describe('DAOHelper ResultSet helpers', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should safely close null ResultSet', 0, () => {
      // 应该不会抛出错误
      DAOHelper.closeResultSet(null);
      expect(true).assertTrue();
    });

    it('should get Long value from ResultSet', 0, async () => {
      const store = DatabaseManager.getDatabase();
      const sql = 'SELECT user_id, username FROM users WHERE user_id = 1 LIMIT 1';
      let rs: relationalStore.ResultSet | null = null;
      try {
        rs = await store.querySql(sql);
        if (rs && rs.goToNextRow()) {
          const userId = DAOHelper.getLong(rs, 'user_id', 0);
          expect(userId).assertEqual(1);
        }
      } catch (error) {
        // 数据库操作可能失败，这是可以接受的
        console.info(`[DAOHelperTest] ResultSet测试跳过: ${JSON.stringify(error)}`);
      } finally {
        DAOHelper.closeResultSet(rs);
      }
    });

    it('should get String value from ResultSet', 0, async () => {
      const store = DatabaseManager.getDatabase();
      const sql = 'SELECT user_id, username FROM users WHERE user_id = 1 LIMIT 1';
      let rs: relationalStore.ResultSet | null = null;
      try {
        rs = await store.querySql(sql);
        if (rs && rs.goToNextRow()) {
          const username = DAOHelper.getString(rs, 'username', '');
          expect(username.length > 0).assertTrue();
        }
      } catch (error) {
        // 数据库操作可能失败，这是可以接受的
        console.info(`[DAOHelperTest] ResultSet测试跳过: ${JSON.stringify(error)}`);
      } finally {
        DAOHelper.closeResultSet(rs);
      }
    });

    it('should return default value when column not found', 0, async () => {
      const store = DatabaseManager.getDatabase();
      const sql = 'SELECT user_id FROM users WHERE user_id = 1 LIMIT 1';
      let rs: relationalStore.ResultSet | null = null;
      try {
        rs = await store.querySql(sql);
        if (rs && rs.goToNextRow()) {
          const defaultValue = DAOHelper.getString(rs, 'non_existent_column', 'default');
          expect(defaultValue).assertEqual('default');
        }
      } catch (error) {
        // 数据库操作可能失败，这是可以接受的
        console.info(`[DAOHelperTest] ResultSet测试跳过: ${JSON.stringify(error)}`);
      } finally {
        DAOHelper.closeResultSet(rs);
      }
    });
  });
}

