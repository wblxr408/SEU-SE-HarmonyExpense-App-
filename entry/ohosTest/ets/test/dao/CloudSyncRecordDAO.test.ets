import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { CloudSyncRecordDAO } from '../../../../src/main/ets/dao/CloudSyncRecordDAO';
import { CloudSyncRecord } from '../../../../src/main/ets/model/CloudSyncRecord';
import { DatabaseManager } from '../../../../src/main/ets/database/DatabaseManager';
import common from '@ohos.app.ability.common';

function getTestContext(): common.Context {
  return getContext() as common.Context;
}

export default function CloudSyncRecordDAOTest(): void {
  describe('CloudSyncRecordDAO CRUD', () => {
    const testUserId: number = 1;

    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);
    });

    it('should insert and get sync record', 0, async () => {
      const now = new Date().toISOString();
      const record = new CloudSyncRecord(
        0,
        testUserId,
        'incremental',
        'bidirectional',
        'pending',
        ['accounts', 'bills'],
        10,
        now,
        '',
        'huawei',
        now,
        now
      );
      const rowId = await CloudSyncRecordDAO.insert(record);
      expect(rowId > 0).assertTrue();
      
      const retrieved = await CloudSyncRecordDAO.getById(testUserId, rowId);
      expect(retrieved !== null).assertTrue();
      if (retrieved) {
        expect(retrieved.syncType).assertEqual('incremental');
        expect(retrieved.dataTypes.length).assertEqual(2);
      }
    });

    it('should get all sync records by user', 0, async () => {
      const records = await CloudSyncRecordDAO.getByUserId(testUserId);
      expect(Array.isArray(records)).assertTrue();
    });

    it('should update sync record', 0, async () => {
      const records = await CloudSyncRecordDAO.getByUserId(testUserId, 1);
      if (records.length > 0) {
        const record = records[0];
        record.status = 'completed';
        record.endTime = new Date().toISOString();
        await CloudSyncRecordDAO.update(record);
        
        const updated = await CloudSyncRecordDAO.getById(testUserId, record.syncId);
        expect(updated !== null).assertTrue();
        if (updated) {
          expect(updated.status).assertEqual('completed');
        }
      }
    });

    it('should get records by status', 0, async () => {
      const records = await CloudSyncRecordDAO.getByStatus(testUserId, 'pending');
      expect(Array.isArray(records)).assertTrue();
    });
  });
}

