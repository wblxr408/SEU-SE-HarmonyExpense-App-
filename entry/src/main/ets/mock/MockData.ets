//模拟后端向前端发送数据

import { Transaction } from '../model/Transaction'

export const MOCK_TRANSACTIONS: Array<Transaction> = [
  new Transaction(1, 100, 'income', 'none', '2020-01-01'),
  new Transaction(2, 100, 'income', 'none', '2020-01-02'),
  new Transaction(3, 100, 'income', 'none', '2020-01-03'),
  new Transaction(4, 100, 'income', 'none', '2020-01-04'),
  new Transaction(5, 100, 'income', 'none', '2020-01-05'),
  new Transaction(6, 100, 'income', 'none', '2020-01-06'),
  new Transaction(7, 100, 'income', 'none', '2020-01-07'),
  new Transaction(8, 100, 'income', 'none', '2020-01-08'),
  new Transaction(9, 100, 'income', 'none', '2020-01-09'),
  new Transaction(10, 100, 'income', 'none', '2020-01-10'),
]
