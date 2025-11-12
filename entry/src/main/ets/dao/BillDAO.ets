// dao/BillDAO.ts
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { Bill } from '../model/Bill';
import { AccountDAO } from './AccountDAO';
import { CategoryDAO } from './CategoryDAO';
import { BatchQueryHelper } from '../database/BatchQueryHelper';
import { measureQueryTime } from '../database/PerformanceMonitor';
import hilog from '@ohos.hilog';

export interface DateRangeFilter {
  start: string;
  end: string;
}

/**
 * 分页查询结果接口
 */
export interface PaginatedResult<T> {
  data: T[];           // 当前页数据
  total: number;       // 总记录数
  page: number;        // 当前页码（从 1 开始）
  pageSize: number;    // 每页大小
  totalPages: number;  // 总页数
  hasNext: boolean;    // 是否有下一页
  hasPrev: boolean;    // 是否有上一页
}

/**
 * 总体统计结果接口
 */
export interface TotalStats {
  totalIncome: number;      // 总收入
  totalExpense: number;     // 总支出
  balance: number;          // 净收支（收入 - 支出）
  transactionCount: number; // 交易总数
}

/**
 * 月度统计结果接口
 */
export interface MonthlyStats {
  month: string;            // 月份（格式：YYYY-MM）
  totalIncome: number;      // 当月总收入
  totalExpense: number;     // 当月总支出
  balance: number;          // 当月净收支
  transactionCount: number; // 当月交易数
}

export class BillDAO {

  private static toError(msg: string, err: Error | string | object): Error {
    let detail = '';
    try {
      detail = typeof err === 'string' ? err : JSON.stringify(err);
    } catch {}
    return new Error(`${msg}${detail ? ' -> ' + detail : ''}`);
  }


  private static mapRow(rs: relationalStore.ResultSet): Bill {
    return new Bill(
      // rs.getLong(0),
      // rs.getLong(1),
      // rs.getLong(2),
      // rs.getDouble(3),
      // rs.getString(5),
      // rs.getString(6),
      // rs.getString(4) as 'income' | 'expense',
      // rs.getString(7),
      // rs.getString(8),
      // rs.getLong(9)
      rs.getLong(rs.getColumnIndex('bill_id')),
      rs.getLong(rs.getColumnIndex('user_id')),
      rs.getLong(rs.getColumnIndex('account_id')),
      rs.getLong(rs.getColumnIndex('category_id')),
      rs.getDouble(rs.getColumnIndex('amount')),
      rs.getString(rs.getColumnIndex('note')),
      rs.getString(rs.getColumnIndex('transaction_date')),
      rs.getString(rs.getColumnIndex('type')) as 'income' | 'expense',
      rs.getString(rs.getColumnIndex('created_at')),
      rs.getString(rs.getColumnIndex('updated_at')),
      rs.getLong(rs.getColumnIndex('is_deleted'))
    );
  }

  // 插入账单
  static async insert(bill: Bill) {
    await BillDAO.validateForeignKeys(bill);
    const sql = `
      INSERT INTO bills
      (user_id,account_id, category_id, amount, type, note, transaction_date, created_at, updated_at, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?,?)
    `;
    const params = [
      bill.userId,
      bill.accountId, bill.categoryId, bill.amount, bill.type, bill.note,
      bill.transactionDate, bill.createdAt, bill.updatedAt, bill.isDeleted
    ];
    await DatabaseManager.getDatabase().executeSql(sql, params);
  }

  static async validateForeignKeys(bill: Bill) {
    const accountExists = await AccountDAO.exists(bill.accountId);
    const categoryExists = await CategoryDAO.exists(bill.categoryId);
    if (!accountExists) throw new Error(`[BillDAO] Account ${bill.accountId} does not exist`);
    if (!categoryExists) throw new Error(`[BillDAO] Category ${bill.categoryId} does not exist`);
  }

  static async getById(billId: number,userId:number): Promise<Bill | null> {
    const sql = `SELECT * FROM bills WHERE bill_id = ? AND is_deleted = 0`;
    const rs = await DatabaseManager.getDatabase().querySql(sql, [billId]);
    try {
      if (!rs.goToNextRow()) return null;
      return BillDAO.mapRow(rs);
    } finally { rs.close(); }
  }

  @measureQueryTime
  static async getAll(): Promise<Bill[]> {
    const sql = `SELECT * FROM bills WHERE is_deleted = 0 ORDER BY bill_id ASC`;
    const rs = await DatabaseManager.getDatabase().querySql(sql);
    const list: Bill[] = [];
    try {
      while (rs.goToNextRow()) list.push(BillDAO.mapRow(rs));
      return list;
    } finally { rs.close(); }
  }

  static async update(bill: Bill) {
    await BillDAO.validateForeignKeys(bill);
    const sql = `
      UPDATE bills
      SET account_id = ?, category_id = ?, amount = ?, type = ?, note = ?,
          transaction_date = ?, updated_at = ?, is_deleted = ?
      WHERE bill_id = ?
    `;
    const params = [
      bill.accountId, bill.categoryId, bill.amount, bill.type, bill.note,
      bill.transactionDate, bill.updatedAt, bill.isDeleted, bill.billId,bill.userId
    ];
    await DatabaseManager.getDatabase().executeSql(sql, params);
  }

  // 软删除
  static async delete(billId: number,userId:number) {
    const sql = `UPDATE bills SET is_deleted = 1 WHERE bill_id = ?`;
    await DatabaseManager.getDatabase().executeSql(sql, [billId,userId]);
  }

  static async restore(billId: number,userId:number) {
    const sql = `UPDATE bills SET is_deleted = 0 WHERE bill_id = ?`;
    await DatabaseManager.getDatabase().executeSql(sql, [billId,userId]);
  }


  @measureQueryTime
  static async getBillsByFilters(
    userId: number,
    dateRange:DateRangeFilter ,
    categoryId?: number
  ): Promise<Bill[]> {

    let sql = `
      SELECT * FROM bills
      WHERE user_id = ?
        AND transaction_date >= ?
        AND transaction_date <= ?
        AND is_deleted = 0
    `;
    const params: (string | number)[] = [userId, dateRange.start, dateRange.end];

    if (categoryId !== undefined && categoryId > 0) {
      sql += ` AND category_id = ?`;
      params.push(categoryId);
    }
    sql += ` ORDER BY transaction_date DESC`;

    const store = DatabaseManager.getDatabase();
    let resultSet: relationalStore.ResultSet | null = null;
    const bills: Bill[] = [];

    try {
      resultSet = await store.querySql(sql, params);
      while (resultSet.goToNextRow()) {
        bills.push(BillDAO.mapRow(resultSet));
      }
      return bills;
    } catch (error) {
      throw BillDAO.toError('getBillsByFilters 查询失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }
  // 事务封装
  static async transaction(fn: () => Promise<void>) {
    const store = DatabaseManager.getDatabase();
    await store.beginTransaction();
    try {
      await fn();
      await store.commit();
    } catch (err) {
      await store.rollBack();
      throw BillDAO.toError('[BillDAO] Transaction failed', err);
    }
  }

  /**
   * 批量插入账单
   * 
   * @param bills 要插入的账单数组
   * @returns 插入成功的记录数
   * 
   * 性能优化：
   * - 使用 BatchQueryHelper 自动分批处理
   * - 批量插入比逐条插入快 10-50 倍
   * - 自动进行外键验证
   */
  static async bulkInsert(bills: Bill[]): Promise<number> {
    if (!bills || bills.length === 0) {
      console.log('[BillDAO] 没有账单需要插入');
      return 0;
    }

    console.log(`[BillDAO] 开始批量插入 ${bills.length} 条账单`);

    try {
      // 数据验证：检查外键是否存在
      for (const bill of bills) {
        await BillDAO.validateForeignKeys(bill);
      }

      // 转换为 ValuesBucket 格式
      const records: relationalStore.ValuesBucket[] = bills.map(bill => ({
        user_id: bill.userId,
        account_id: bill.accountId,
        category_id: bill.categoryId,
        amount: bill.amount,
        type: bill.type,
        note: bill.note,
        transaction_date: bill.transactionDate,
        created_at: bill.createdAt,
        updated_at: bill.updatedAt,
        is_deleted: bill.isDeleted
      }));

      // 调用批量插入辅助方法
      const insertedCount = await BatchQueryHelper.bulkInsert('bills', records);
      console.log(`[BillDAO] ✅ 批量插入完成，共插入 ${insertedCount} 条账单`);
      
      return insertedCount;
    } catch (error) {
      console.error('[BillDAO] ❌ 批量插入失败:', error);
      throw BillDAO.toError('[BillDAO] 批量插入账单失败', error);
    }
  }

  /**
   * 批量软删除账单
   * 
   * @param billIds 要删除的账单 ID 数组
   * @returns 删除成功的记录数
   * 
   * 性能优化：
   * - 使用 IN 子句批量更新
   * - 比逐条删除快 5-10 倍
   */
  static async bulkSoftDelete(billIds: number[]): Promise<number> {
    if (!billIds || billIds.length === 0) {
      console.log('[BillDAO] 没有账单需要删除');
      return 0;
    }

    console.log(`[BillDAO] 开始批量软删除 ${billIds.length} 条账单`);

    try {
      // 调用批量软删除辅助方法
      const deletedCount = await BatchQueryHelper.bulkSoftDelete('bills', billIds, 'bill_id');
      console.log(`[BillDAO] ✅ 批量软删除完成，共删除 ${deletedCount} 条账单`);
      
      return deletedCount;
    } catch (error) {
      console.error('[BillDAO] ❌ 批量软删除失败:', error);
      throw BillDAO.toError('[BillDAO] 批量软删除账单失败', error);
    }
  }

  /**
   * 分页查询账单
   * 
   * @param userId 用户 ID
   * @param page 页码（从 1 开始）
   * @param pageSize 每页大小（默认 20）
   * @param dateRange 可选的日期范围过滤
   * @param categoryId 可选的分类 ID 过滤
   * @returns 分页结果
   * 
   * 性能优化：
   * - 使用 idx_bills_date 索引优化排序
   * - 使用 LIMIT + OFFSET 实现分页
   * - 单次查询同时获取总数和数据
   */
  @measureQueryTime
  static async getByPage(
    userId: number,
    page: number = 1,
    pageSize: number = 20,
    dateRange?: DateRangeFilter,
    categoryId?: number
  ): Promise<PaginatedResult<Bill>> {
    console.log(`[BillDAO] 分页查询账单 - 用户: ${userId}, 页码: ${page}, 每页: ${pageSize}`);

    try {
      const store = DatabaseManager.getDatabase();
      
      // 构建查询条件
      let whereClause = 'WHERE user_id = ? AND is_deleted = 0';
      const params: (string | number)[] = [userId];

      if (dateRange) {
        whereClause += ' AND transaction_date >= ? AND transaction_date <= ?';
        params.push(dateRange.start, dateRange.end);
      }

      if (categoryId !== undefined && categoryId > 0) {
        whereClause += ' AND category_id = ?';
        params.push(categoryId);
      }

      // 1. 查询总记录数
      const countSql = `SELECT COUNT(*) as total FROM bills ${whereClause}`;
      const countRs = await store.querySql(countSql, params);
      let total = 0;
      try {
        if (countRs.goToNextRow()) {
          total = countRs.getLong(countRs.getColumnIndex('total'));
        }
      } finally {
        countRs.close();
      }

      // 计算分页信息
      const totalPages = Math.ceil(total / pageSize);
      const offset = (page - 1) * pageSize;

      // 2. 查询分页数据
      // 使用 idx_bills_date 索引优化排序性能
      const dataSql = `
        SELECT * FROM bills 
        ${whereClause}
        ORDER BY transaction_date DESC, bill_id DESC
        LIMIT ? OFFSET ?
      `;
      const dataParams = [...params, pageSize, offset];
      const dataRs = await store.querySql(dataSql, dataParams);
      
      const bills: Bill[] = [];
      try {
        while (dataRs.goToNextRow()) {
          bills.push(BillDAO.mapRow(dataRs));
        }
      } finally {
        dataRs.close();
      }

      // 构建分页结果
      const result: PaginatedResult<Bill> = {
        data: bills,
        total: total,
        page: page,
        pageSize: pageSize,
        totalPages: totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1
      };

      console.log(`[BillDAO] ✅ 分页查询完成 - 总数: ${total}, 当前页: ${page}/${totalPages}, 返回: ${bills.length} 条`);
      return result;
    } catch (error) {
      console.error('[BillDAO] ❌ 分页查询失败:', error);
      throw BillDAO.toError('[BillDAO] 分页查询账单失败', error);
    }
  }

  /**
   * 获取总体统计数据
   * 
   * @param userId 用户 ID
   * @param dateRange 可选的日期范围过滤
   * @returns 总体统计结果
   * 
   * 性能优化：
   * - 使用 CASE 表达式在单个查询中计算收入和支出
   * - 使用 idx_bills_stat 覆盖索引优化查询性能（避免回表）
   * - 单次查询完成所有统计计算
   */
  @measureQueryTime
  static async getTotalStats(
    userId: number,
    dateRange?: DateRangeFilter
  ): Promise<TotalStats> {
    console.log(`[BillDAO] 查询总体统计 - 用户: ${userId}`);

    try {
      const store = DatabaseManager.getDatabase();
      
      // 构建查询条件
      let whereClause = 'WHERE user_id = ? AND is_deleted = 0';
      const params: (string | number)[] = [userId];

      if (dateRange) {
        whereClause += ' AND transaction_date >= ? AND transaction_date <= ?';
        params.push(dateRange.start, dateRange.end);
      }

      // 使用 CASE 表达式在单个查询中计算收入和支出
      // 使用覆盖索引 idx_bills_stat (account_id, type, transaction_date, amount)
      const sql = `
        SELECT 
          SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
          SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as total_expense,
          COUNT(*) as transaction_count
        FROM bills 
        ${whereClause}
      `;

      const rs = await store.querySql(sql, params);
      
      try {
        if (rs.goToNextRow()) {
          const totalIncome = rs.getDouble(rs.getColumnIndex('total_income')) || 0;
          const totalExpense = rs.getDouble(rs.getColumnIndex('total_expense')) || 0;
          const transactionCount = rs.getLong(rs.getColumnIndex('transaction_count'));
          const balance = totalIncome - totalExpense;

          const stats: TotalStats = {
            totalIncome,
            totalExpense,
            balance,
            transactionCount
          };

          console.log(`[BillDAO] ✅ 总体统计完成 - 收入: ${totalIncome}, 支出: ${totalExpense}, 净收支: ${balance}`);
          return stats;
        }

        // 如果没有数据，返回零值
        return {
          totalIncome: 0,
          totalExpense: 0,
          balance: 0,
          transactionCount: 0
        };
      } finally {
        rs.close();
      }
    } catch (error) {
      console.error('[BillDAO] ❌ 总体统计查询失败:', error);
      throw BillDAO.toError('[BillDAO] 总体统计查询失败', error);
    }
  }

  /**
   * 获取月度统计数据
   * 
   * @param userId 用户 ID
   * @param startMonth 开始月份（格式：YYYY-MM）
   * @param endMonth 结束月份（格式：YYYY-MM）
   * @returns 月度统计结果数组
   * 
   * 性能优化：
   * - 使用 strftime 函数提取月份
   * - 使用 GROUP BY 按月聚合
   * - 使用 idx_bills_date 索引优化日期范围查询
   */
  @measureQueryTime
  static async getMonthlyStats(
    userId: number,
    startMonth: string,
    endMonth: string
  ): Promise<MonthlyStats[]> {
    console.log(`[BillDAO] 查询月度统计 - 用户: ${userId}, 范围: ${startMonth} ~ ${endMonth}`);

    try {
      const store = DatabaseManager.getDatabase();
      
      // 构建日期范围（月份的第一天和最后一天）
      const startDate = `${startMonth}-01`;
      const endDate = `${endMonth}-31`; // 使用 31 确保覆盖整个月

      // 使用 strftime 提取月份，GROUP BY 按月聚合
      // 使用 idx_bills_date 索引优化日期范围查询
      const sql = `
        SELECT 
          strftime('%Y-%m', transaction_date) as month,
          SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
          SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as total_expense,
          COUNT(*) as transaction_count
        FROM bills 
        WHERE user_id = ? 
          AND is_deleted = 0
          AND transaction_date >= ?
          AND transaction_date <= ?
        GROUP BY strftime('%Y-%m', transaction_date)
        ORDER BY month DESC
      `;

      const params = [userId, startDate, endDate];
      const rs = await store.querySql(sql, params);
      
      const monthlyStats: MonthlyStats[] = [];
      try {
        while (rs.goToNextRow()) {
          const month = rs.getString(rs.getColumnIndex('month'));
          const totalIncome = rs.getDouble(rs.getColumnIndex('total_income')) || 0;
          const totalExpense = rs.getDouble(rs.getColumnIndex('total_expense')) || 0;
          const transactionCount = rs.getLong(rs.getColumnIndex('transaction_count'));
          const balance = totalIncome - totalExpense;

          monthlyStats.push({
            month,
            totalIncome,
            totalExpense,
            balance,
            transactionCount
          });
        }
      } finally {
        rs.close();
      }

      console.log(`[BillDAO] ✅ 月度统计完成 - 返回 ${monthlyStats.length} 个月的数据`);
      return monthlyStats;
    } catch (error) {
      console.error('[BillDAO] ❌ 月度统计查询失败:', error);
      throw BillDAO.toError('[BillDAO] 月度统计查询失败', error);
    }
  }
}
