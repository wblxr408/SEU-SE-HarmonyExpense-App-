/**
 * Tag 模型 - 标签
 */
export interface TagJSON {
  tagId: number;
  userId: number;
  name: string;
  color: string;
  usageCount: number;
  createdAt: string;
  updatedAt: string;
  is_deleted?: number;
}

export class Tag {
  static readonly tableName: string = 'tags';

  tagId: number = 0;
  userId: number = 0;
  name: string = '';
  color: string = '#52C41A';
  usageCount: number = 0;
  createdAt: string = '';
  updatedAt: string = '';
  is_deleted: number = 0;

  constructor(
    tagId: number = 0,
    userId: number = 0,
    name: string = '',
    color: string = '#52C41A',
    usageCount: number = 0,
    createdAt: string = '',
    updatedAt: string = '',
    is_deleted: number = 0
  ) {
    this.tagId = tagId;
    this.userId = userId;
    this.name = name;
    this.color = color;
    this.usageCount = usageCount;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.is_deleted = is_deleted;
  }

  toJSON(): TagJSON {
    return {
      tagId: this.tagId,
      userId: this.userId,
      name: this.name,
      color: this.color,
      usageCount: this.usageCount,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      is_deleted: this.is_deleted
    };
  }

  static fromJSON(data: TagJSON): Tag {
    return new Tag(
      data.tagId,
      data.userId,
      data.name,
      data.color,
      data.usageCount,
      data.createdAt,
      data.updatedAt,
      data.is_deleted ?? 0
    );
  }

  validate(): boolean {
    return (
      this.name !== '' &&
      this.name.length <= 20 &&
      (this.is_deleted === 0 || this.is_deleted === 1)
    );
  }

  clone(): Tag {
    return new Tag(
      this.tagId,
      this.userId,
      this.name,
      this.color,
      this.usageCount,
      this.createdAt,
      this.updatedAt,
      this.is_deleted
    );
  }
}
