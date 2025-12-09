import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { CloudSyncService, SyncOptions } from '../../../../src/main/ets/service/CloudSyncService';
import { DatabaseManager } from '../../../../src/main/ets/database/DatabaseManager';
import common from '@ohos.app.ability.common';

function getTestContext(): common.Context {
  return getContext() as common.Context;
}

export default function CloudSyncServiceTest(): void {
  describe('CloudSyncService Basic Tests', () => {
    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should create sync options', 0, () => {
      const options = new SyncOptions(1, 'incremental', 'bidirectional', ['accounts', 'bills']);
      expect(options.userId).assertEqual(1);
      expect(options.syncType).assertEqual('incremental');
      expect(options.dataTypes.length).assertEqual(2);
    });

    it('should handle sync options with encryption', 0, () => {
      const options = new SyncOptions(1, 'full', 'upload', ['accounts'], 'huawei', true, 'password123');
      expect(options.encryptData).assertTrue();
      expect(options.password).assertEqual('password123');
    });

    // 注意：实际的同步操作需要云服务支持，在测试环境中可能无法完全测试
    it('should validate sync options', 0, () => {
      const options = new SyncOptions(1);
      expect(options.userId > 0).assertTrue();
    });
  });
}

