/**
 * 云端同步记录模型
 * 用于数据同步云端功能
 */

export interface CloudSyncRecordJSON {
  syncId: number;
  userId: number;
  syncType: 'full' | 'incremental';
  syncDirection: 'upload' | 'download' | 'bidirectional';
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  dataTypes: string[];
  recordCount: number;
  startTime: string;
  endTime: string;
  errorMessage?: string;
  cloudProvider: 'huawei' | 'custom';
  lastSyncHash?: string;
  createdAt: string;
  updatedAt: string;
}

export class CloudSyncRecord {
  static readonly tableName: string = 'cloud_sync_records';

  syncId: number = 0;
  userId: number = 0;
  syncType: 'full' | 'incremental' = 'incremental';
  syncDirection: 'upload' | 'download' | 'bidirectional' = 'bidirectional';
  status: 'pending' | 'in_progress' | 'completed' | 'failed' = 'pending';
  dataTypes: string[] = [];
  recordCount: number = 0;
  startTime: string = '';
  endTime: string = '';
  errorMessage?: string;
  cloudProvider: 'huawei' | 'custom' = 'huawei';
  lastSyncHash?: string;
  createdAt: string = '';
  updatedAt: string = '';

  constructor(
    syncId: number = 0,
    userId: number = 0,
    syncType: 'full' | 'incremental' = 'incremental',
    syncDirection: 'upload' | 'download' | 'bidirectional' = 'bidirectional',
    status: 'pending' | 'in_progress' | 'completed' | 'failed' = 'pending',
    dataTypes: string[] = [],
    recordCount: number = 0,
    startTime: string = '',
    endTime: string = '',
    cloudProvider: 'huawei' | 'custom' = 'huawei',
    createdAt: string = '',
    updatedAt: string = '',
    errorMessage?: string,
    lastSyncHash?: string
  ) {
    this.syncId = syncId;
    this.userId = userId;
    this.syncType = syncType;
    this.syncDirection = syncDirection;
    this.status = status;
    this.dataTypes = dataTypes;
    this.recordCount = recordCount;
    this.startTime = startTime;
    this.endTime = endTime;
    this.errorMessage = errorMessage;
    this.cloudProvider = cloudProvider;
    this.lastSyncHash = lastSyncHash;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  toJSON(): CloudSyncRecordJSON {
    return {
      syncId: this.syncId,
      userId: this.userId,
      syncType: this.syncType,
      syncDirection: this.syncDirection,
      status: this.status,
      dataTypes: this.dataTypes,
      recordCount: this.recordCount,
      startTime: this.startTime,
      endTime: this.endTime,
      errorMessage: this.errorMessage,
      cloudProvider: this.cloudProvider,
      lastSyncHash: this.lastSyncHash,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }

  static fromJSON(data: CloudSyncRecordJSON): CloudSyncRecord {
    return new CloudSyncRecord(
      data.syncId,
      data.userId,
      data.syncType,
      data.syncDirection,
      data.status,
      data.dataTypes,
      data.recordCount,
      data.startTime,
      data.endTime,
      data.cloudProvider,
      data.createdAt,
      data.updatedAt,
      data.errorMessage,
      data.lastSyncHash
    );
  }

  validate(): boolean {
    return (
      this.userId > 0 &&
      ['full', 'incremental'].includes(this.syncType) &&
      ['upload', 'download', 'bidirectional'].includes(this.syncDirection) &&
      ['pending', 'in_progress', 'completed', 'failed'].includes(this.status) &&
      ['huawei', 'custom'].includes(this.cloudProvider)
    );
  }

  clone(): CloudSyncRecord {
    return CloudSyncRecord.fromJSON(this.toJSON());
  }
}
