import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { Category } from '../model/Category';
import { CategoryTreeNode, CategoryAggregation } from '../model/AggregationTypes';

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
          sort_order INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_deleted INTEGER DEFAULT 0 CHECK (is_deleted IN (0, 1)),
          UNIQUE (user_id, name, type)
        );
      `);
      // 索引
      await store.executeSql(`CREATE INDEX IF NOT EXISTS idx_categories_user_type ON categories (user_id, type) WHERE is_deleted = 0;`);
      await store.executeSql(`CREATE INDEX IF NOT EXISTS idx_categories_user_parent ON categories (user_id, parent_category_id) WHERE is_deleted = 0;`);
      await store.executeSql(`CREATE INDEX IF NOT EXISTS idx_categories_sort ON categories (user_id, sort_order, category_id);`);
      console.log('[CategoryDAO] 分类表和索引创建完成');
    } catch (error) {
      console.error('[CategoryDAO] 创建表或索引失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 创建表或索引失败', error);
    }
  }

  /** 插入新分类 */
  static async insert(category: Category): Promise<void> {
    if (!category.validate()) {
      throw new Error('[CategoryDAO] 无效分类数据');
    }
    const store = CategoryDAO.ensureDb();
    const now = new Date().toISOString();
    const sql = `
      INSERT INTO categories
        (user_id, name, type, icon, color, parent_category_id, sort_order, created_at, updated_at, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      category.userId,
      category.name,
      category.type,
      category.icon,
      category.color,
      category.parentCategoryId,
      category.sortOrder,
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
  static async bulkInsert(categories: Category[]): Promise<void> {
    if (categories.length === 0) {
      return;
    }
    const store = CategoryDAO.ensureDb();
    await store.beginTransaction();
    try {
      const now = new Date().toISOString();
      const sql = `
        INSERT INTO categories
          (user_id, name, type, icon, color, parent_category_id, sort_order, created_at, updated_at, is_deleted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      
      for (const category of categories) {
        if (!category.validate()) {
          throw new Error(`[CategoryDAO] 无效分类数据: ${category.name}`);
        }
        const params = [
          category.userId,
          category.name,
          category.type,
          category.icon,
          category.color,
          category.parentCategoryId,
          category.sortOrder,
          now,
          now,
          0
        ];
        await store.executeSql(sql, params);
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
    const sql = `SELECT * FROM categories WHERE user_id = ? AND is_deleted = 0 ORDER BY sort_order ASC, category_id ASC`;
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
    const sql = `SELECT * FROM categories WHERE user_id = ? AND type = ? AND is_deleted = 0 ORDER BY sort_order ASC, category_id ASC`;
    const categories: Category[] = [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId, type]);
      while (resultSet.goToNextRow()) {
        categories.push(CategoryDAO.mapRowToCategory(resultSet));
      }
      return categories;
    } catch (error) {
      console.error('[CategoryDAO] 按类型查询失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 按类型查询失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /** 获取某个父分类的子分类 */
  static async getChildren(userId: number, parentId: number): Promise<Category[]> {
    const store = CategoryDAO.ensureDb();
    const sql = `SELECT * FROM categories WHERE user_id = ? AND parent_category_id = ? AND is_deleted = 0 ORDER BY sort_order ASC, category_id ASC`;
    const categories: Category[] = [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId, parentId]);
      while (resultSet.goToNextRow()) {
        categories.push(CategoryDAO.mapRowToCategory(resultSet));
      }
      return categories;
    } catch (error) {
      console.error('[CategoryDAO] 查询子分类失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 查询子分类失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /** 更新分类信息 */
  static async update(category: Category): Promise<void> {
    if (!category.validate()) {
      throw new Error('[CategoryDAO] 无效分类数据');
    }
    const store = CategoryDAO.ensureDb();
    const now = new Date().toISOString();
    const sql = `
      UPDATE categories
      SET name = ?, type = ?, icon = ?, color = ?, parent_category_id = ?, sort_order = ?, updated_at = ?, is_deleted = ?
      WHERE category_id = ? AND user_id = ?
    `;
    const params = [
      category.name,
      category.type,
      category.icon,
      category.color,
      category.parentCategoryId,
      category.sortOrder,
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
  static async softDelete(userId: number, categoryId: number): Promise<void> {
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
  static async restore(userId: number, categoryId: number): Promise<void> {
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
  static async hardDelete(userId: number, categoryId: number): Promise<void> {
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

  /**
   * 获取分类树（包含子分类）
   * @param userId 用户ID
   * @param type 分类类型
   * @returns 分类树结构
   */
  static async getCategoryTree(userId: number, type: 'expense' | 'income'): Promise<CategoryTreeNode[]> {
    const store = CategoryDAO.ensureDb();
    const sql = `
      SELECT * FROM categories 
      WHERE user_id = ? AND type = ? AND is_deleted = 0 
      ORDER BY sort_order ASC, category_id ASC
    `;
    
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId, type]);
      const allCategories: Category[] = [];
      
      while (resultSet.goToNextRow()) {
        allCategories.push(CategoryDAO.mapRowToCategory(resultSet));
      }
      
      // 构建树结构
      return CategoryDAO.buildCategoryTree(allCategories);
    } catch (error) {
      console.error('[CategoryDAO] 获取分类树失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 获取分类树失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 构建分类树结构
   * @param categories 分类列表
   * @returns 分类树节点数组
   */
  private static buildCategoryTree(categories: Category[]): CategoryTreeNode[] {
    const map = new Map<number, CategoryTreeNode>();
    const roots: CategoryTreeNode[] = [];
    
    // 初始化节点
    categories.forEach(cat => {
      map.set(cat.categoryId, {
        category: cat,
        children: []
      });
    });
    
    // 构建父子关系
    categories.forEach(cat => {
      const node = map.get(cat.categoryId);
      if (node) {
        if (cat.parentCategoryId === 0) {
          roots.push(node);
        } else {
          const parent = map.get(cat.parentCategoryId);
          if (parent) {
            parent.children.push(node);
          }
        }
      }
    });
    
    return roots;
  }

  /**
   * 按分类聚合统计
   * @param userId 用户ID
   * @param startDate 开始日期
   * @param endDate 结束日期
   * @returns 分类统计结果
   */
  static async aggregateByCategory(
    userId: number,
    startDate: string,
    endDate: string
  ): Promise<CategoryAggregation[]> {
    const store = CategoryDAO.ensureDb();
    
    const sql = `
      SELECT 
        c.category_id,
        c.name AS category_name,
        c.type,
        c.icon,
        c.color,
        c.parent_category_id,
        COUNT(b.bill_id) AS transaction_count,
        COALESCE(SUM(b.amount), 0) AS total_amount,
        COALESCE(AVG(b.amount), 0) AS avg_amount,
        COALESCE(MIN(b.amount), 0) AS min_amount,
        COALESCE(MAX(b.amount), 0) AS max_amount
      FROM categories c
      LEFT JOIN bills b ON c.category_id = b.category_id 
        AND b.is_deleted = 0
        AND b.transaction_date >= ?
        AND b.transaction_date <= ?
      INNER JOIN accounts a ON b.account_id = a.account_id
      WHERE c.user_id = ? AND c.is_deleted = 0 AND a.user_id = ?
      GROUP BY c.category_id
      ORDER BY total_amount DESC
    `;
    
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [startDate, endDate, userId, userId]);
      const results: CategoryAggregation[] = [];
      
      while (resultSet.goToNextRow()) {
        results.push({
          categoryId: resultSet.getLong(resultSet.getColumnIndex('category_id')),
          categoryName: resultSet.getString(resultSet.getColumnIndex('category_name')),
          type: resultSet.getString(resultSet.getColumnIndex('type')) as 'expense' | 'income',
          icon: resultSet.getString(resultSet.getColumnIndex('icon')),
          color: resultSet.getString(resultSet.getColumnIndex('color')),
          parentCategoryId: resultSet.getLong(resultSet.getColumnIndex('parent_category_id')),
          transactionCount: resultSet.getLong(resultSet.getColumnIndex('transaction_count')),
          totalAmount: resultSet.getDouble(resultSet.getColumnIndex('total_amount')),
          avgAmount: resultSet.getDouble(resultSet.getColumnIndex('avg_amount')),
          minAmount: resultSet.getDouble(resultSet.getColumnIndex('min_amount')),
          maxAmount: resultSet.getDouble(resultSet.getColumnIndex('max_amount'))
        });
      }
      
      return results;
    } catch (error) {
      console.error('[CategoryDAO] 分类聚合统计失败: ' + JSON.stringify(error));
      throw CategoryDAO.toError('[CategoryDAO] 分类聚合统计失败', error);
    } finally {
      resultSet?.close();
    }
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
    category.sortOrder = resultSet.getLong(resultSet.getColumnIndex('sort_order'));
    category.createdAt = resultSet.getString(resultSet.getColumnIndex('created_at'));
    category.updatedAt = resultSet.getString(resultSet.getColumnIndex('updated_at'));
    category.is_deleted = resultSet.getLong(resultSet.getColumnIndex('is_deleted'));
    return category;
  }
}
