import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from './DatabaseManager';
import { Bill } from '../model/Bill';

/**
 * 查询辅助类 - 提供复杂的组合查询功能
 */
export class QueryHelper {
  /**
   * 组合查询：按分类和标签筛选账单
   * @param userId 用户ID
   * @param categoryIds 分类ID数组（可选）
   * @param tagIds 标签ID数组（可选）
   * @param startDate 开始日期
   * @param endDate 结束日期
   * @returns 账单列表
   */
  static async queryBillsByCategoryAndTags(
    userId: number,
    categoryIds: number[] | null,
    tagIds: number[] | null,
    startDate: string,
    endDate: string
  ): Promise<Bill[]> {
    const store = DatabaseManager.getDatabase();
    
    let sql = `
      SELECT DISTINCT b.* 
      FROM bills b
      INNER JOIN accounts a ON b.account_id = a.account_id
    `;
    
    const params: (number | string)[] = [];
    const conditions: string[] = [];
    
    // 标签条件
    if (tagIds && tagIds.length > 0) {
      sql += `
        INNER JOIN bill_tags bt ON b.bill_id = bt.bill_id
        INNER JOIN tags t ON bt.tag_id = t.tag_id
      `;
      conditions.push(`t.tag_id IN (${tagIds.map(() => '?').join(',')})`);
      params.push(...tagIds);
      conditions.push('t.is_deleted = 0');
    }
    
    // 基础条件
    conditions.push('a.user_id = ?');
    params.push(userId);
    
    conditions.push('b.is_deleted = 0');
    conditions.push('b.transaction_date >= ?');
    params.push(startDate);
    conditions.push('b.transaction_date <= ?');
    params.push(endDate);
    
    // 分类条件
    if (categoryIds && categoryIds.length > 0) {
      conditions.push(`b.category_id IN (${categoryIds.map(() => '?').join(',')})`);
      params.push(...categoryIds);
    }
    
    sql += ` WHERE ${conditions.join(' AND ')} ORDER BY b.transaction_date DESC, b.bill_id DESC`;
    
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, params);
      const bills: Bill[] = [];
      
      while (resultSet.goToNextRow()) {
        bills.push(QueryHelper.mapRowToBill(resultSet));
      }
      
      return bills;
    } catch (error) {
      console.error('[QueryHelper] 组合查询失败: ' + JSON.stringify(error));
      throw QueryHelper.toError('[QueryHelper] 组合查询失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 按分类查询账单（包含子分类）
   * @param userId 用户ID
   * @param categoryId 分类ID
   * @param includeChildren 是否包含子分类
   * @param startDate 开始日期
   * @param endDate 结束日期
   * @returns 账单列表
   */
  static async queryBillsByCategory(
    userId: number,
    categoryId: number,
    includeChildren: boolean,
    startDate: string,
    endDate: string
  ): Promise<Bill[]> {
    const store = DatabaseManager.getDatabase();
    
    let sql: string;
    let params: (number | string)[];
    
    if (includeChildren) {
      // 包含子分类：先查询所有子分类ID
      const categoryIds = await QueryHelper.getCategoryWithChildren(categoryId);
      
      sql = `
        SELECT b.* 
        FROM bills b
        INNER JOIN accounts a ON b.account_id = a.account_id
        WHERE a.user_id = ?
          AND b.category_id IN (${categoryIds.map(() => '?').join(',')})
          AND b.is_deleted = 0
          AND b.transaction_date >= ?
          AND b.transaction_date <= ?
        ORDER BY b.transaction_date DESC, b.bill_id DESC
      `;
      params = [userId, ...categoryIds, startDate, endDate];
    } else {
      // 只查询当前分类
      sql = `
        SELECT b.* 
        FROM bills b
        INNER JOIN accounts a ON b.account_id = a.account_id
        WHERE a.user_id = ?
          AND b.category_id = ?
          AND b.is_deleted = 0
          AND b.transaction_date >= ?
          AND b.transaction_date <= ?
        ORDER BY b.transaction_date DESC, b.bill_id DESC
      `;
      params = [userId, categoryId, startDate, endDate];
    }
    
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, params);
      const bills: Bill[] = [];
      
      while (resultSet.goToNextRow()) {
        bills.push(QueryHelper.mapRowToBill(resultSet));
      }
      
      return bills;
    } catch (error) {
      console.error('[QueryHelper] 按分类查询失败: ' + JSON.stringify(error));
      throw QueryHelper.toError('[QueryHelper] 按分类查询失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 获取分类及其所有子分类的ID
   * @param categoryId 分类ID
   * @returns 分类ID数组（包含自身）
   */
  private static async getCategoryWithChildren(categoryId: number): Promise<number[]> {
    const store = DatabaseManager.getDatabase();
    const categoryIds: number[] = [categoryId];
    
    // 递归查询子分类
    const sql = `SELECT category_id FROM categories WHERE parent_category_id = ? AND is_deleted = 0`;
    let resultSet: relationalStore.ResultSet | null = null;
    
    try {
      resultSet = await store.querySql(sql, [categoryId]);
      const childIds: number[] = [];
      
      while (resultSet.goToNextRow()) {
        childIds.push(resultSet.getLong(resultSet.getColumnIndex('category_id')));
      }
      
      // 递归查询每个子分类的子分类
      for (const childId of childIds) {
        const descendants = await QueryHelper.getCategoryWithChildren(childId);
        categoryIds.push(...descendants);
      }
      
      return categoryIds;
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 统一错误转换
   * @param message 错误消息
   * @param err 错误对象
   * @returns Error 对象
   */
  private static toError(message: string, err: Error | string | Record<string, Object>): Error {
    let details = '';
    try {
      details = typeof err === 'string' ? err : JSON.stringify(err);
    } catch (_) {
      details = '';
    }
    return new Error(`${message}${details ? ' -> ' + details : ''}`);
  }

  /**
   * 将查询结果映射为 Bill 实例
   * @param resultSet 查询结果集
   * @returns Bill 对象
   * @throws
   */
  private static mapRowToBill(resultSet: relationalStore.ResultSet): Bill {
    return new Bill(
      resultSet.getLong(resultSet.getColumnIndex('bill_id')),
      resultSet.getLong(resultSet.getColumnIndex('user_id')),
      resultSet.getLong(resultSet.getColumnIndex('account_id')),
      resultSet.getLong(resultSet.getColumnIndex('category_id')),
      resultSet.getDouble(resultSet.getColumnIndex('amount')),
      resultSet.getString(resultSet.getColumnIndex('note')),
      resultSet.getString(resultSet.getColumnIndex('transaction_date')),
      resultSet.getString(resultSet.getColumnIndex('type')) as 'income' | 'expense',
      resultSet.getString(resultSet.getColumnIndex('created_at')),
      resultSet.getString(resultSet.getColumnIndex('updated_at')),
      resultSet.getLong(resultSet.getColumnIndex('is_deleted'))
    );
  }
}
