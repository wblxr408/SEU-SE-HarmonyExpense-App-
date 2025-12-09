import { describe, it, expect } from '@ohos/hypium';
import { CloudSyncRecord, CloudSyncRecordJSON } from '../../../../src/main/ets/model/CloudSyncRecord';

export default function CloudSyncRecordTest(): void {
  describe('CloudSyncRecord.validate()', () => {
    it('valid record should pass', 0, () => {
      const record = new CloudSyncRecord(
        1,
        1,
        'incremental',
        'bidirectional',
        'pending',
        ['accounts', 'bills'],
        10,
        '2025-11-05T10:00:00',
        '2025-11-05T11:00:00',
        'huawei',
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00'
      );
      expect(record.validate()).assertTrue();
    });

    it('invalid record should fail (zero userId)', 0, () => {
      const record = new CloudSyncRecord(
        0,
        0,
        'incremental',
        'bidirectional',
        'pending',
        [],
        0,
        '',
        '',
        'huawei',
        '',
        ''
      );
      expect(record.validate()).assertFalse();
    });

    it('invalid record should fail (invalid syncType)', 0, () => {
      const record = new CloudSyncRecord();
      record.userId = 1;
      // 通过Object类型来测试无效值
      const invalidValue: Object = 'invalid';
      record.syncType = invalidValue as 'full' | 'incremental';
      expect(record.validate()).assertFalse();
    });

    it('invalid record should fail (invalid syncDirection)', 0, () => {
      const record = new CloudSyncRecord();
      record.userId = 1;
      // 通过Object类型来测试无效值
      const invalidValue: Object = 'invalid';
      record.syncDirection = invalidValue as 'upload' | 'download' | 'bidirectional';
      expect(record.validate()).assertFalse();
    });

    it('invalid record should fail (invalid status)', 0, () => {
      const record = new CloudSyncRecord();
      record.userId = 1;
      // 通过Object类型来测试无效值
      const invalidValue: Object = 'invalid';
      record.status = invalidValue as 'pending' | 'in_progress' | 'completed' | 'failed';
      expect(record.validate()).assertFalse();
    });

    it('invalid record should fail (invalid cloudProvider)', 0, () => {
      const record = new CloudSyncRecord();
      record.userId = 1;
      // 通过Object类型来测试无效值
      const invalidValue: Object = 'invalid';
      record.cloudProvider = invalidValue as 'huawei' | 'custom';
      expect(record.validate()).assertFalse();
    });
  });

  describe('CloudSyncRecord.toJSON() and fromJSON()', () => {
    it('toJSON should return correct structure', 0, () => {
      const record = new CloudSyncRecord(
        1,
        1,
        'full',
        'upload',
        'completed',
        ['accounts'],
        5,
        '2025-11-05T10:00:00',
        '2025-11-05T11:00:00',
        'custom',
        '2025-11-05T10:00:00',
        '2025-11-05T11:00:00',
        'Error message',
        'hash123'
      );
      const json = record.toJSON();
      expect(json.syncId).assertEqual(1);
      expect(json.userId).assertEqual(1);
      expect(json.syncType).assertEqual('full');
      expect(json.syncDirection).assertEqual('upload');
      expect(json.status).assertEqual('completed');
      expect(json.dataTypes.length).assertEqual(1);
      expect(json.errorMessage).assertEqual('Error message');
      expect(json.lastSyncHash).assertEqual('hash123');
    });

    it('fromJSON should create correct instance', 0, () => {
      const json: CloudSyncRecordJSON = {
        syncId: 2,
        userId: 1,
        syncType: 'incremental',
        syncDirection: 'download',
        status: 'in_progress',
        dataTypes: ['bills', 'categories'],
        recordCount: 20,
        startTime: '2025-11-05T10:00:00',
        endTime: '2025-11-05T11:00:00',
        cloudProvider: 'huawei',
        createdAt: '2025-11-05T10:00:00',
        updatedAt: '2025-11-05T11:00:00'
      };
      const record = CloudSyncRecord.fromJSON(json);
      expect(record.syncId).assertEqual(2);
      expect(record.syncType).assertEqual('incremental');
      expect(record.dataTypes.length).assertEqual(2);
    });

    it('should handle round-trip conversion', 0, () => {
      const original = new CloudSyncRecord(
        3,
        1,
        'incremental',
        'bidirectional',
        'pending',
        ['accounts', 'bills', 'categories'],
        15,
        '2025-11-05T10:00:00',
        '',
        'huawei',
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00'
      );
      const json = original.toJSON();
      const restored = CloudSyncRecord.fromJSON(json);
      
      expect(restored.syncId).assertEqual(original.syncId);
      expect(restored.dataTypes.length).assertEqual(original.dataTypes.length);
    });
  });

  describe('CloudSyncRecord.clone()', () => {
    it('clone should create independent copy', 0, () => {
      const original = new CloudSyncRecord(
        1,
        1,
        'incremental',
        'bidirectional',
        'pending',
        ['accounts'],
        10,
        '2025-11-05T10:00:00',
        '',
        'huawei',
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00'
      );
      const cloned = original.clone();
      
      expect(cloned.syncId).assertEqual(original.syncId);
      expect(cloned.dataTypes.length).assertEqual(original.dataTypes.length);
      
      cloned.dataTypes.push('bills');
      expect(original.dataTypes.length).assertEqual(1);
    });
  });
}

