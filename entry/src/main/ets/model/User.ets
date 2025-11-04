export interface UserJSON {
  userId: number;
  username: string;
  email: string;
  passwordHash: string;
  createdAt: string;
  updatedAt: string;
  is_deleted?: number;
}

export class User {
  static readonly tableName: string = 'users';

  userId: number = 0;
  username: string = '';
  email: string = '';
  passwordHash: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  is_deleted: number = 0; // 0=未删除, 1=已删除

  constructor(
    userId: number = 0,
    username: string = '',
    email: string = '',
    passwordHash: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    is_deleted: number = 0
  ) {
    this.userId = userId;
    this.username = username;
    this.email = email;
    this.passwordHash = passwordHash;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.is_deleted = is_deleted;
  }

  // 序列化
  toJSON(): UserJSON {
    return {
      userId: this.userId,
      username: this.username,
      email: this.email,
      passwordHash: this.passwordHash,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      is_deleted: this.is_deleted
    };
  }

  // 反序列化
  static fromJSON(data: UserJSON): User {
    return new User(
      data.userId,
      data.username,
      data.email,
      data.passwordHash,
      data.createdAt,
      data.updatedAt,
      data.is_deleted ?? 0
    );
  }

  // 数据验证
  validate(): boolean {
    return (
      this.username !== '' &&
        this.email !== '' &&
        this.passwordHash !== '' &&
        (this.is_deleted === 0 || this.is_deleted === 1)
    );
  }

  // 克隆
  clone(): User {
    return new User(
      this.userId,
      this.username,
      this.email,
      this.passwordHash,
      this.createdAt,
      this.updatedAt,
      this.is_deleted
    );
  }
}
