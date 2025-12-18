/**
 * DAO通用辅助类
 * 提供所有DAO共用的工具方法，减少代码重复
 */
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';

export class DAOHelper {
  /**
   * 统一错误处理
   * 将各种类型的错误转换为标准Error对象
   * 
   * @param message 错误消息前缀
   * @param err 原始错误对象
   * @returns 标准Error对象
   */
  static toError(message: string, err: Error | string | object): Error {
    let details = '';
    try {
      if (typeof err === 'string') {
        details = err;
      } else if (err instanceof Error) {
        details = err.message;
      } else {
        details = JSON.stringify(err);
      }
    } catch (_) {
      details = String(err);
    }
    return new Error(`${message}${details ? ' -> ' + details : ''}`);
  }

  /**
   * 统一事务处理
   * 自动处理事务的开启、提交和回滚
   * 
   * @param fn 要在事务中执行的函数
   * @param errorPrefix 错误消息前缀
   */
  static async transaction(fn: () => Promise<void>, errorPrefix: string = '[DAO]'): Promise<void> {
    const store = DatabaseManager.getDatabase();
    await store.beginTransaction();
    try {
      await fn();
      await store.commit();
    } catch (error) {
      await store.rollBack();
      throw DAOHelper.toError(`${errorPrefix} 事务失败`, error);
    }
  }

  /**
   * 检查记录是否存在
   * 
   * @param tableName 表名
   * @param idColumn 主键列名
   * @param id 主键值
   * @returns 是否存在
   */
  static async exists(tableName: string, idColumn: string, id: number): Promise<boolean> {
    const sql = `SELECT 1 FROM ${tableName} WHERE ${idColumn} = ? AND is_deleted = 0`;
    const store = DatabaseManager.getDatabase();
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.querySql(sql, [id]);
      return rs.goToNextRow();
    } finally {
      rs?.close();
    }
  }

  /**
   * 软删除记录
   * 
   * @param tableName 表名
   * @param idColumn 主键列名
   * @param id 主键值
   * @param errorPrefix 错误消息前缀
   */
  static async softDelete(
    tableName: string,
    idColumn: string,
    id: number,
    errorPrefix: string = '[DAO]'
  ): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `UPDATE ${tableName} SET is_deleted = 1, updated_at = ? WHERE ${idColumn} = ?`;
    try {
      await store.executeSql(sql, [now, id]);
      console.log(`${errorPrefix} 软删除成功: ${idColumn}=${id}`);
    } catch (error) {
      throw DAOHelper.toError(`${errorPrefix} 软删除失败`, error);
    }
  }

  /**
   * 恢复软删除的记录
   * 
   * @param tableName 表名
   * @param idColumn 主键列名
   * @param id 主键值
   * @param errorPrefix 错误消息前缀
   */
  static async restore(
    tableName: string,
    idColumn: string,
    id: number,
    errorPrefix: string = '[DAO]'
  ): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `UPDATE ${tableName} SET is_deleted = 0, updated_at = ? WHERE ${idColumn} = ?`;
    try {
      await store.executeSql(sql, [now, id]);
      console.log(`${errorPrefix} 恢复成功: ${idColumn}=${id}`);
    } catch (error) {
      throw DAOHelper.toError(`${errorPrefix} 恢复失败`, error);
    }
  }

  /**
   * 硬删除记录（物理删除）
   * 
   * @param tableName 表名
   * @param idColumn 主键列名
   * @param id 主键值
   * @param errorPrefix 错误消息前缀
   */
  static async hardDelete(
    tableName: string,
    idColumn: string,
    id: number,
    errorPrefix: string = '[DAO]'
  ): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `DELETE FROM ${tableName} WHERE ${idColumn} = ?`;
    try {
      await store.executeSql(sql, [id]);
      console.log(`${errorPrefix} 硬删除成功: ${idColumn}=${id}`);
    } catch (error) {
      throw DAOHelper.toError(`${errorPrefix} 硬删除失败`, error);
    }
  }

  /**
   * 获取当前时间戳（ISO格式）
   * 
   * @returns ISO格式的时间字符串
   */
  static now(): string {
    return new Date().toISOString();
  }

  /**
   * 安全关闭ResultSet
   * 
   * @param resultSet 结果集
   */
  static closeResultSet(resultSet: relationalStore.ResultSet | null): void {
    try {
      resultSet?.close();
    } catch (error) {
      console.warn('[DAOHelper] 关闭ResultSet失败:', error);
    }
  }

  /**
   * 从ResultSet中安全获取Long值
   * 
   * @param resultSet 结果集
   * @param columnName 列名
   * @param defaultValue 默认值
   * @returns Long值
   */
  static getLong(resultSet: relationalStore.ResultSet, columnName: string, defaultValue: number = 0): number {
    try {
      const index = resultSet.getColumnIndex(columnName);
      return resultSet.getLong(index);
    } catch (error) {
      console.warn(`[DAOHelper] 获取Long值失败: ${columnName}`, error);
      return defaultValue;
    }
  }

  /**
   * 从ResultSet中安全获取String值
   * 
   * @param resultSet 结果集
   * @param columnName 列名
   * @param defaultValue 默认值
   * @returns String值
   */
  static getString(resultSet: relationalStore.ResultSet, columnName: string, defaultValue: string = ''): string {
    try {
      const index = resultSet.getColumnIndex(columnName);
      return resultSet.getString(index);
    } catch (error) {
      console.warn(`[DAOHelper] 获取String值失败: ${columnName}`, error);
      return defaultValue;
    }
  }

  /**
   * 从ResultSet中安全获取Double值
   * 
   * @param resultSet 结果集
   * @param columnName 列名
   * @param defaultValue 默认值
   * @returns Double值
   */
  static getDouble(resultSet: relationalStore.ResultSet, columnName: string, defaultValue: number = 0): number {
    try {
      const index = resultSet.getColumnIndex(columnName);
      return resultSet.getDouble(index);
    } catch (error) {
      console.warn(`[DAOHelper] 获取Double值失败: ${columnName}`, error);
      return defaultValue;
    }
  }
}