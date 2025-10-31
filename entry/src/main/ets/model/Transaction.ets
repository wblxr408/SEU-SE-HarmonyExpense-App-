export class Transaction {
  id: number;
  amount: number; //账号名称
  type: 'expense' | 'income';
  date: string; //日期
  notes: string; //备注

  constructor(
    id: number,
    amount: number,
    type: 'expense' | 'income',
    notes: string,
    date: string
  ) {
    this.id = id;
    this.amount = amount;
    this.type = type;
    this.notes = notes;
    this.date = date;
  }
}