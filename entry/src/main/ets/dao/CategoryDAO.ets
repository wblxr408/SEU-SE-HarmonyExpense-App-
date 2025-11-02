import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { Category } from '../model/Category';

let db: relationalStore.RdbStore | null = null;

/**
 * 分类数据访问对象 - CategoryDAO
 * 对应表：categories
 * 功能：提供分类（收入/支出）数据的增删改查操作
 */
export class CategoryDAO {
  /** 初始化数据库连接 */
  static async initDatabase(context: common.Context) {
    const storeConfig: relationalStore.StoreConfig = {
      name: 'harmony_expense.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    try {
      db = await relationalStore.getRdbStore(context, storeConfig);
      console.log('[CategoryDAO] 数据库已初始化');
      await CategoryDAO.createTables();
    } catch (error) {
      console.error('[CategoryDAO] 初始化数据库失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 初始化数据库失败', error);
    }
  }

  /** 创建分类表和索引（若不存在） */
  static async createTables() {
    const store = CategoryDAO.ensureDb();
    try {
      await store.executeSql(`
        CREATE TABLE IF NOT EXISTS categories (
          category_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL CHECK (type IN ('expense', 'income')),
          icon TEXT DEFAULT '📦',
          color TEXT DEFAULT '#1890FF',
          parent_category_id INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          UNIQUE (user_id, name, type)
        );
      `);
      // 索引
      await store.executeSql(`CREATE INDEX IF NOT EXISTS idx_categories_user_type ON categories (user_id, type);`);
      await store.executeSql(`CREATE INDEX IF NOT EXISTS idx_categories_user_parent ON categories (user_id, parent_category_id);`);
      console.log('[CategoryDAO] 分类表和索引创建完成');
    } catch (error) {
      console.error('[CategoryDAO] 创建表或索引失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 创建表或索引失败', error);
    }
  }

  /** 插入新分类 */
  static async insert(category: Category) {
    if (!category.validate()) {
      throw new Error('[CategoryDAO] 无效分类数据');
    }
    const store = CategoryDAO.ensureDb();
    const now = new Date().toISOString();
    const sql = `
      INSERT INTO categories
        (user_id, name, type, icon, color, parent_category_id, created_at, updated_at, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      category.userId,
      category.name,
      category.type,
      category.icon,
      category.color,
      category.parentCategoryId,
      now,
      now,
      0
    ];
    try {
      await store.executeSql(sql, params);
      console.log(`[CategoryDAO] 插入成功: ${category.name}`);
    } catch (error) {
      console.error('[CategoryDAO] 插入失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 插入失败', error);
    }
  }

  /** 批量插入分类 */
  static async bulkInsert(categories: Category[]) {
    const store = CategoryDAO.ensureDb();
    await store.beginTransaction();
    try {
      for (const category of categories) {
        await CategoryDAO.insert(category);
      }
      await store.commit();
      console.log(`[CategoryDAO] 批量插入成功: ${categories.length} 条`);
    } catch (error) {
      await store.rollBack();
      console.error('[CategoryDAO] 批量插入失败: ' + JSON.stringify(error));
      throw error instanceof Error ? error : new Error(String(error));
    }
  }



  /** 根据 ID 查询分类（只返回未删除） */
  static async getById(userId: number, categoryId: number): Promise<Category | null> {
    const store = CategoryDAO.ensureDb();
    const sql = `SELECT * FROM categories WHERE category_id = ? AND user_id = ? AND is_deleted = 0`;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [categoryId, userId]);
      if (!resultSet.goToNextRow()) return null;
      return CategoryDAO.mapRowToCategory(resultSet);
    } catch (error) {
      console.error('[CategoryDAO] 查询失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 查询失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /** 查询用户所有未删除分类 */
  static async getAll(userId: number): Promise<Category[]> {
    const store = CategoryDAO.ensureDb();
    const sql = `SELECT * FROM categories WHERE user_id = ? AND is_deleted = 0 ORDER BY category_id ASC`;
    const categories: Category[] = [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId]);
      while (resultSet.goToNextRow()) {
        categories.push(CategoryDAO.mapRowToCategory(resultSet));
      }
      return categories;
    } catch (error) {
      console.error('[CategoryDAO] 查询全部失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 查询全部失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /** 按类型查询（收入/支出） */
  static async getByType(userId: number, type: 'expense' | 'income'): Promise<Category[]> {
    const store = CategoryDAO.ensureDb();
    const sql = `SELECT * FROM categories WHERE user_id = ? AND type = ? AND is_deleted = 0 ORDER BY category_id ASC`;
    const categories: Category[] = [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId, type]);
      while (resultSet.goToNextRow()) {
        categories.push(CategoryDAO.mapRowToCategory(resultSet));
      }
      return categories;
    } finally {
      resultSet?.close();
    }
  }

  /** 获取某个父分类的子分类 */
  static async getChildren(userId: number, parentId: number): Promise<Category[]> {
    const store = CategoryDAO.ensureDb();
    const sql = `SELECT * FROM categories WHERE user_id = ? AND parent_category_id = ? AND is_deleted = 0 ORDER BY category_id ASC`;
    const categories: Category[] = [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId, parentId]);
      while (resultSet.goToNextRow()) {
        categories.push(CategoryDAO.mapRowToCategory(resultSet));
      }
      return categories;
    } finally {
      resultSet?.close();
    }
  }

  /** 更新分类信息 */
  static async update(category: Category) {
    if (!category.validate()) {
      throw new Error('[CategoryDAO] 无效分类数据');
    }
    const store = CategoryDAO.ensureDb();
    const now = new Date().toISOString();
    const sql = `
      UPDATE categories
      SET name = ?, type = ?, icon = ?, color = ?, parent_category_id = ?, updated_at = ?, is_deleted = ?
      WHERE category_id = ? AND user_id = ?
    `;
    const params = [
      category.name,
      category.type,
      category.icon,
      category.color,
      category.parentCategoryId,
      now,
      category.is_deleted,
      category.categoryId,
      category.userId
    ];
    try {
      await store.executeSql(sql, params);
      console.log(`[CategoryDAO] 更新成功: ${category.name}`);
    } catch (error) {
      console.error('[CategoryDAO] 更新失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 更新失败', error);
    }
  }

  /** 软删除分类 */
  static async softDelete(userId: number, categoryId: number) {
    const store = CategoryDAO.ensureDb();
    const now = new Date().toISOString();
    const sql = `UPDATE categories SET is_deleted = 1, updated_at = ? WHERE category_id = ? AND user_id = ?`;
    try {
      await store.executeSql(sql, [now, categoryId, userId]);
      console.log(`[CategoryDAO] 软删除成功: category_id=${categoryId}`);
    } catch (error) {
      console.error('[CategoryDAO] 软删除失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 软删除失败', error);
    }
  }

  /** 恢复已删除分类 */
  static async restore(userId: number, categoryId: number) {
    const store = CategoryDAO.ensureDb();
    const now = new Date().toISOString();
    const sql = `UPDATE categories SET is_deleted = 0, updated_at = ? WHERE category_id = ? AND user_id = ?`;
    try {
      await store.executeSql(sql, [now, categoryId, userId]);
      console.log(`[CategoryDAO] 恢复成功: category_id=${categoryId}`);
    } catch (error) {
      console.error('[CategoryDAO] 恢复失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 恢复失败', error);
    }
  }

  /** 真删除分类（慎用） */
  static async hardDelete(userId: number, categoryId: number) {
    const store = CategoryDAO.ensureDb();
    const sql = `DELETE FROM categories WHERE category_id = ? AND user_id = ?`;
    try {
      await store.executeSql(sql, [categoryId, userId]);
      console.log(`[CategoryDAO] 硬删除成功: category_id=${categoryId}`);
    } catch (error) {
      console.error('[CategoryDAO] 删除失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 删除失败', error);
    }
  }


  /** 确保数据库已初始化 */
  private static ensureDb(): relationalStore.RdbStore {
    if (!db) {
      throw new Error('[CategoryDAO] Database has not been initialized. Call initDatabase first.');
    }
    return db;
  }

  /** 统一错误转换 */
  private static toError(message: string, err: Error | string | Record<string, Object>): Error {
    let details = '';
    try {
      details = typeof err === 'string' ? err : JSON.stringify(err);
    } catch (_) {
      details = '';
    }
    return new Error(`${message}${details ? ' -> ' + details : ''}`);
  }

  /** 将查询结果映射为 Category 实例 */
  private static mapRowToCategory(resultSet: relationalStore.ResultSet): Category {
    const category = new Category();
    category.categoryId = resultSet.getLong(resultSet.getColumnIndex('category_id'));
    category.userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
    category.name = resultSet.getString(resultSet.getColumnIndex('name'));
    category.type = resultSet.getString(resultSet.getColumnIndex('type')) as 'expense' | 'income';
    category.icon = resultSet.getString(resultSet.getColumnIndex('icon'));
    category.color = resultSet.getString(resultSet.getColumnIndex('color'));
    category.parentCategoryId = resultSet.getLong(resultSet.getColumnIndex('parent_category_id'));
    category.createdAt = resultSet.getString(resultSet.getColumnIndex('created_at'));
    category.updatedAt = resultSet.getString(resultSet.getColumnIndex('updated_at'));
    category.is_deleted = resultSet.getLong(resultSet.getColumnIndex('is_deleted'));
    return category;
  }

  static async exists(categoryId: number): Promise<boolean> {
    const sql = `SELECT 1 FROM categories WHERE category_id = ? AND is_deleted = 0`;
    const store = CategoryDAO.ensureDb();
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.querySql(sql, [categoryId]);
      return rs.goToNextRow();
    } finally {
      if (rs) rs.close();
    }
  }

}
