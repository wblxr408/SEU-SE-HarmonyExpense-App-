// model/Bill.ts
export interface BillJSON {
  billId: number;
  userId:number;
  accountId: number;
  categoryId: number;
  amount: number;
  note: string;
  transactionDate: string;
  type: 'income' | 'expense';
  createdAt: string;
  updatedAt: string;
  isDeleted?: number;
}

export class Bill {
  static readonly tableName: string = 'bills';

  billId: number = 0;
  userId: number = 0;
  accountId: number = 0;   // FK -> Account
  categoryId: number = 0;  // FK -> Category
  amount: number = 0.0;
  note: string = '';
  transactionDate: string = '';
  type: 'income' | 'expense' = 'expense';
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0; // 0 = active, 1 = deleted

  constructor(
    billId: number = 0,
    userId: number = 0,
    accountId: number = 0,
    categoryId: number = 0,
    amount: number = 0.0,
    note: string = '',
    transactionDate: string = '',
    type: 'income' | 'expense' = 'expense',
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.billId = billId;
    this.userId = userId;
    this.accountId = accountId;
    this.categoryId = categoryId;
    this.amount = amount;
    this.note = note;
    this.transactionDate = transactionDate;
    this.type = type;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  toJSON(): BillJSON {
    return {
      billId: this.billId,
      userId :this.userId,
      accountId: this.accountId,
      categoryId: this.categoryId,
      amount: this.amount,
      note: this.note,
      transactionDate: this.transactionDate,
      type: this.type,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
  }

  static fromJSON(data: BillJSON): Bill {
    return new Bill(
      data.billId,
      data.userId,
      data.accountId,
      data.categoryId,
      data.amount,
      data.note,
      data.transactionDate,
      data.type,
      data.createdAt,
      data.updatedAt,
      data.isDeleted ?? 0
    );
  }

  validate(): boolean {
    return (
      this.amount >= 0 &&
        this.userId>0&&
        this.transactionDate !== '' &&
        (this.type === 'income' || this.type === 'expense') &&
        (this.isDeleted === 0 || this.isDeleted === 1)
    );
  }

  clone(): Bill {
    return Bill.fromJSON(this.toJSON());
  }
}
