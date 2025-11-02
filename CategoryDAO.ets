import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { Category } from '../model/Category';

let db: relationalStore.RdbStore | null = null;

export class CategoryDAO {
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

  static async createTables() {
    const store = CategoryDAO.ensureDb();
    try {
      await store.executeSql(`
      CREATE TABLE IF NOT EXISTS categories (
        category_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        parent_category_id INTEGER NOT NULL,
        created_at TEXT NOT NULL
      );
    `);
    } catch (error) {
      console.error('[CategoryDAO] 创建表失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 创建表失败', error);
    }
  }

  private static ensureDb(): relationalStore.RdbStore {
    if (db === null) {
      throw new Error('[CategoryDAO] Database has not been initialized. Call initDatabase first.');
    }
    return db;
  }

  private static toError(message: string, err: Error | string | Record<string, Object>): Error {
    let details: string = '';
    try {
      details = typeof err === 'string' ? err : JSON.stringify(err);
    } catch (_) {
      details = '';
    }
    return new Error(`${message}${details ? ' -> ' + details : ''}`);
  }

  static async insert(category: Category) {
    const sql = `
      INSERT INTO categories (user_id, name, type, icon, color, parent_category_id, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      category.userId, category.name, category.type, category.icon,
      category.color, category.parentCategoryId, category.createdAt
    ];
    const store = CategoryDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[CategoryDAO] 插入失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 插入失败', error);
    }
  }

  static async getById(categoryId: number): Promise<Category | null> {
    const sql = `SELECT * FROM categories WHERE category_id = ?`;
    const store = CategoryDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [categoryId]);
      if (!resultSet.goToNextRow()) {
        return null;
      }
      const category = new Category();
      category.categoryId = resultSet.getLong(0);
      category.userId = resultSet.getLong(1);
      category.name = resultSet.getString(2);
      category.type = resultSet.getString(3);
      category.icon = resultSet.getString(4);
      category.color = resultSet.getString(5);
      category.parentCategoryId = resultSet.getLong(6);
      category.createdAt = resultSet.getString(7);
      return category;
    } catch (error) {
      console.error('[CategoryDAO] 查询失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 查询失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async getAll(): Promise<Category[]> {
    const sql = `SELECT * FROM categories ORDER BY category_id ASC`;
    const store = CategoryDAO.ensureDb();
    let resultSet: relationalStore.ResultSet | null = null;
    const categories: Category[] = [];
    try {
      resultSet = await store.querySql(sql);
      while (resultSet.goToNextRow()) {
        const item = new Category();
        item.categoryId = resultSet.getLong(0);
        item.userId = resultSet.getLong(1);
        item.name = resultSet.getString(2);
        item.type = resultSet.getString(3);
        item.icon = resultSet.getString(4);
        item.color = resultSet.getString(5);
        item.parentCategoryId = resultSet.getLong(6);
        item.createdAt = resultSet.getString(7);
        categories.push(item);
      }
      return categories;
    } catch (error) {
      console.error('[CategoryDAO] 查询全部失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 查询全部失败', error);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  static async update(category: Category) {
    const sql = `
      UPDATE categories
      SET name = ?, type = ?, icon = ?, color = ?, parent_category_id = ?
      WHERE category_id = ?
    `;
    const params = [
      category.name, category.type, category.icon, category.color,
      category.parentCategoryId, category.categoryId
    ];
    const store = CategoryDAO.ensureDb();
    try {
      await store.executeSql(sql, params);
    } catch (error) {
      console.error('[CategoryDAO] 更新失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 更新失败', error);
    }
  }

  static async delete(categoryId: number) {
    const sql = `DELETE FROM categories WHERE category_id = ?`;
    const store = CategoryDAO.ensureDb();
    try {
      await store.executeSql(sql, [categoryId]);
    } catch (error) {
      console.error('[CategoryDAO] 删除失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 删除失败', error);
    }
  }
}