/**
 * BillTag 模型 - 账单标签关联
 */
export interface BillTagJSON {
  billId: number;
  tagId: number;
  createdAt: string;
}

export class BillTag {
  static readonly tableName: string = 'bill_tags';

  billId: number = 0;
  tagId: number = 0;
  createdAt: string = '';

  constructor(
    billId: number = 0,
    tagId: number = 0,
    createdAt: string = ''
  ) {
    this.billId = billId;
    this.tagId = tagId;
    this.createdAt = createdAt;
  }

  toJSON(): BillTagJSON {
    return {
      billId: this.billId,
      tagId: this.tagId,
      createdAt: this.createdAt
    };
  }

  static fromJSON(data: BillTagJSON): BillTag {
    return new BillTag(
      data.billId,
      data.tagId,
      data.createdAt
    );
  }

  validate(): boolean {
    return (
      this.billId > 0 &&
      this.tagId > 0
    );
  }
}
