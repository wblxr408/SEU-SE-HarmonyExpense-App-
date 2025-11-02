export interface AccountJSON {
  accountId: number;
  userId: number;
  name: string;
  type: 'cash' | 'bank' | 'credit_card' | 'other';
  balance: number;
  color: string;
  createdAt: string;
  updatedAt: string;
  is_deleted?: number;
}


export class Account {
  static readonly tableName: string = 'accounts';

  accountId: number = 0;
  userId: number = 0;

  name: string = '';
  type: 'cash' | 'bank' | 'credit_card' | 'other' = 'cash';
  balance: number = 0.0;
  color: string = '#1890FF';

  //时间戳
  createdAt: string = '';
  updatedAt: string = '';

  is_deleted: number = 0; // 默认未删除
  constructor(
    accountId: number = 0,
    userId: number = 0,
    name: string = '',
    type: 'cash' | 'bank' | 'credit_card' | 'other' = 'cash',
    balance: number = 0.0,
    color: string = '#1890FF',
    createdAt: string = '',
    is_deleted: number = 0  // 新增
  ) {
    this.accountId = accountId;
    this.userId = userId;
    this.name = name;
    this.type = type;
    this.balance = balance;
    this.color = color;
    this.createdAt = createdAt;
    this.is_deleted = is_deleted; // 初始化
  }


  // 序列化
  toJSON(): AccountJSON {
    return {
      accountId: this.accountId,
      userId: this.userId,
      name: this.name,
      type: this.type,
      balance: this.balance,
      color: this.color,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      is_deleted: this.is_deleted  // 新增
    };
  }

  // 反序列化
  static fromJSON(data: AccountJSON): Account {
    return new Account(
      data.accountId,
      data.userId,
      data.name,
      data.type,
      data.balance,
      data.color,
      data.createdAt,
      data.is_deleted ?? 0
    );
  }


  // 数据验证
  validate(): boolean {
    return (
      this.name !== '' &&
        this.balance >= 0 &&
      ['cash', 'bank', 'credit_card', 'other'].includes(this.type) &&
        (this.is_deleted === 0 || this.is_deleted === 1) // 新增检查
    );
  }


  // 克隆
  clone(): Account {
    return new Account(
      this.accountId,
      this.userId,
      this.name,
      this.type,
      this.balance,
      this.color,
      this.createdAt
    );
  }
}
