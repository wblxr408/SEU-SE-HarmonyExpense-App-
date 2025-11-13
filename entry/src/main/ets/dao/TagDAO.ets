import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { Tag } from '../model/Tag';
import { BillTag } from '../model/BillTag';
import { TagAggregation } from '../model/AggregationTypes';
import { DAOHelper } from '../common/DAOHelper';

/**
 * 标签数据访问对象 - TagDAO
 * 对应表：tags, bill_tags
 * 功能：提供标签数据的增删改查操作，以及账单-标签关联管理
 */
export class TagDAO {
  /**
   * 插入新标签
   * @param tag 标签对象
   */
  static async insert(tag: Tag): Promise<void> {
    if (!tag.validate()) {
      throw new Error('[TagDAO] 无效标签数据');
    }
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `
      INSERT INTO tags
        (user_id, name, color, usage_count, created_at, updated_at, is_deleted)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      tag.userId,
      tag.name,
      tag.color,
      0,
      now,
      now,
      0
    ];
    try {
      await store.executeSql(sql, params);
      console.log(`[TagDAO] 插入成功: ${tag.name}`);
    } catch (error) {
      console.error('[TagDAO] 插入失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 插入失败', error);
    }
  }

  /**
   * 批量插入标签 - 使用 DAOHelper 统一事务处理
   * @param tags 标签数组
   */
  static async bulkInsert(tags: Tag[]): Promise<void> {
    if (tags.length === 0) {
      return;
    }
    
    await DAOHelper.transaction(async () => {
      const now = new Date().toISOString();
      const store = DatabaseManager.getDatabase();
      const sql = `
        INSERT INTO tags
          (user_id, name, color, usage_count, created_at, updated_at, is_deleted)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;
      
      for (const tag of tags) {
        if (!tag.validate()) {
          throw new Error(`[TagDAO] 无效标签数据: ${tag.name}`);
        }
        const params = [
          tag.userId,
          tag.name,
          tag.color,
          0,
          now,
          now,
          0
        ];
        await store.executeSql(sql, params);
      }
    }, '[TagDAO] 批量插入');
    
    console.log(`[TagDAO] 批量插入成功: ${tags.length} 条`);
  }

  /**
   * 根据 ID 查询标签
   * @param userId 用户ID
   * @param tagId 标签ID
   * @returns 标签对象或 null
   */
  static async getById(userId: number, tagId: number): Promise<Tag | null> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT * FROM tags WHERE tag_id = ? AND user_id = ? AND is_deleted = 0`;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [tagId, userId]);
      if (!resultSet.goToNextRow()) {
        return null;
      }
      return TagDAO.mapRowToTag(resultSet);
    } catch (error) {
      console.error('[TagDAO] 查询失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 查询失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 查询用户所有未删除标签
   * @param userId 用户ID
   * @returns 标签数组
   */
  static async getAll(userId: number): Promise<Tag[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT * FROM tags WHERE user_id = ? AND is_deleted = 0 ORDER BY tag_id ASC`;
    const tags: Tag[] = [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId]);
      while (resultSet.goToNextRow()) {
        tags.push(TagDAO.mapRowToTag(resultSet));
      }
      return tags;
    } catch (error) {
      console.error('[TagDAO] 查询全部失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 查询全部失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 获取热门标签（按使用频率排序）
   * @param userId 用户ID
   * @param limit 返回数量限制
   * @returns 热门标签列表
   */
  static async getPopularTags(userId: number, limit: number = 10): Promise<Tag[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `
      SELECT * FROM tags 
      WHERE user_id = ? AND is_deleted = 0 
      ORDER BY usage_count DESC, tag_id DESC 
      LIMIT ?
    `;
    
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId, limit]);
      const tags: Tag[] = [];
      
      while (resultSet.goToNextRow()) {
        tags.push(TagDAO.mapRowToTag(resultSet));
      }
      
      return tags;
    } catch (error) {
      console.error('[TagDAO] 获取热门标签失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 获取热门标签失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 更新标签信息
   * @param tag 标签对象
   */
  static async update(tag: Tag): Promise<void> {
    if (!tag.validate()) {
      throw new Error('[TagDAO] 无效标签数据');
    }
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `
      UPDATE tags
      SET name = ?, color = ?, updated_at = ?, is_deleted = ?
      WHERE tag_id = ? AND user_id = ?
    `;
    const params = [
      tag.name,
      tag.color,
      now,
      tag.is_deleted,
      tag.tagId,
      tag.userId
    ];
    try {
      await store.executeSql(sql, params);
      console.log(`[TagDAO] 更新成功: ${tag.name}`);
    } catch (error) {
      console.error('[TagDAO] 更新失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 更新失败', error);
    }
  }

  /**
   * 软删除标签 - 使用 DAOHelper 统一方法
   * 注意：TagDAO 的软删除需要同时检查 user_id，所以保留自定义实现
   * @param userId 用户ID
   * @param tagId 标签ID
   */
  static async softDelete(userId: number, tagId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `UPDATE tags SET is_deleted = 1, updated_at = ? WHERE tag_id = ? AND user_id = ?`;
    try {
      await store.executeSql(sql, [now, tagId, userId]);
      console.log(`[TagDAO] 软删除成功: tag_id=${tagId}`);
    } catch (error) {
      console.error('[TagDAO] 软删除失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 软删除失败', error);
    }
  }

  /**
   * 恢复已删除标签 - 保留自定义实现（需要检查 user_id）
   * @param userId 用户ID
   * @param tagId 标签ID
   */
  static async restore(userId: number, tagId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `UPDATE tags SET is_deleted = 0, updated_at = ? WHERE tag_id = ? AND user_id = ?`;
    try {
      await store.executeSql(sql, [now, tagId, userId]);
      console.log(`[TagDAO] 恢复成功: tag_id=${tagId}`);
    } catch (error) {
      console.error('[TagDAO] 恢复失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 恢复失败', error);
    }
  }

  /**
   * 真删除标签（慎用）- 使用 DAOHelper 统一事务处理
   * @param userId 用户ID
   * @param tagId 标签ID
   */
  static async hardDelete(userId: number, tagId: number): Promise<void> {
    await DAOHelper.transaction(async () => {
      const store = DatabaseManager.getDatabase();
      // 先删除关联记录
      await store.executeSql(`DELETE FROM bill_tags WHERE tag_id = ?`, [tagId]);
      // 再删除标签
      await store.executeSql(`DELETE FROM tags WHERE tag_id = ? AND user_id = ?`, [tagId, userId]);
    }, '[TagDAO] 硬删除');
    console.log(`[TagDAO] 硬删除成功: tag_id=${tagId}`);
  }

  /**
   * 为账单添加标签
   * @param billId 账单ID
   * @param tagId 标签ID
   */
  static async addTagToBill(billId: number, tagId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const now = new Date().toISOString();
    const sql = `
      INSERT OR IGNORE INTO bill_tags (bill_id, tag_id, created_at)
      VALUES (?, ?, ?)
    `;
    try {
      await store.executeSql(sql, [billId, tagId, now]);
      // 增加标签使用次数
      await TagDAO.incrementUsageCount(tagId);
      console.log(`[TagDAO] 添加标签关联成功: bill_id=${billId}, tag_id=${tagId}`);
    } catch (error) {
      console.error('[TagDAO] 添加标签关联失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 添加标签关联失败', error);
    }
  }

  /**
   * 从账单移除标签
   * @param billId 账单ID
   * @param tagId 标签ID
   */
  static async removeTagFromBill(billId: number, tagId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `DELETE FROM bill_tags WHERE bill_id = ? AND tag_id = ?`;
    try {
      await store.executeSql(sql, [billId, tagId]);
      // 减少标签使用次数
      await TagDAO.decrementUsageCount(tagId);
      console.log(`[TagDAO] 移除标签关联成功: bill_id=${billId}, tag_id=${tagId}`);
    } catch (error) {
      console.error('[TagDAO] 移除标签关联失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 移除标签关联失败', error);
    }
  }

  /**
   * 批量为账单设置标签（替换现有标签）- 使用 DAOHelper 统一事务处理
   * @param billId 账单ID
   * @param tagIds 标签ID数组
   */
  static async setTagsForBill(billId: number, tagIds: number[]): Promise<void> {
    await DAOHelper.transaction(async () => {
      const store = DatabaseManager.getDatabase();
      // 获取当前标签
      const currentTags = await TagDAO.getTagsByBillId(billId);
      const currentTagIds = currentTags.map(bt => bt.tagId);
      
      // 计算需要删除和添加的标签
      const toRemove = currentTagIds.filter(id => !tagIds.includes(id));
      const toAdd = tagIds.filter(id => !currentTagIds.includes(id));
      
      // 删除不需要的标签
      for (const tagId of toRemove) {
        await store.executeSql(`DELETE FROM bill_tags WHERE bill_id = ? AND tag_id = ?`, [billId, tagId]);
        await TagDAO.decrementUsageCount(tagId);
      }
      
      // 添加新标签
      const now = new Date().toISOString();
      for (const tagId of toAdd) {
        await store.executeSql(
          `INSERT OR IGNORE INTO bill_tags (bill_id, tag_id, created_at) VALUES (?, ?, ?)`,
          [billId, tagId, now]
        );
        await TagDAO.incrementUsageCount(tagId);
      }
    }, '[TagDAO] 批量设置标签');
    
    console.log(`[TagDAO] 批量设置标签成功: bill_id=${billId}`);
  }

  /**
   * 获取账单的所有标签
   * @param billId 账单ID
   * @returns 标签数组
   */
  static async getTagsByBillId(billId: number): Promise<BillTag[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT * FROM bill_tags WHERE bill_id = ?`;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [billId]);
      const billTags: BillTag[] = [];
      
      while (resultSet.goToNextRow()) {
        billTags.push(TagDAO.mapRowToBillTag(resultSet));
      }
      
      return billTags;
    } catch (error) {
      console.error('[TagDAO] 查询账单标签失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 查询账单标签失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 获取标签关联的所有账单ID
   * @param tagId 标签ID
   * @returns 账单ID数组
   */
  static async getBillIdsByTagId(tagId: number): Promise<number[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `SELECT bill_id FROM bill_tags WHERE tag_id = ?`;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [tagId]);
      const billIds: number[] = [];
      
      while (resultSet.goToNextRow()) {
        billIds.push(resultSet.getLong(resultSet.getColumnIndex('bill_id')));
      }
      
      return billIds;
    } catch (error) {
      console.error('[TagDAO] 查询标签账单失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 查询标签账单失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 获取所有账单标签关联（用于导出）
   * @param userId 用户ID
   * @returns 账单标签关联数组
   */
  static async getAllBillTags(userId: number): Promise<BillTag[]> {
    const store = DatabaseManager.getDatabase();
    const sql = `
      SELECT bt.* 
      FROM bill_tags bt
      INNER JOIN bills b ON bt.bill_id = b.bill_id
      INNER JOIN accounts a ON b.account_id = a.account_id
      WHERE a.user_id = ? AND b.is_deleted = 0
    `;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId]);
      const billTags: BillTag[] = [];
      
      while (resultSet.goToNextRow()) {
        billTags.push(TagDAO.mapRowToBillTag(resultSet));
      }
      
      return billTags;
    } catch (error) {
      console.error('[TagDAO] 查询所有账单标签失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 查询所有账单标签失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 按标签聚合账单统计
   * @param userId 用户ID
   * @param startDate 开始日期
   * @param endDate 结束日期
   * @returns 标签统计结果
   */
  static async aggregateByTag(
    userId: number,
    startDate: string,
    endDate: string
  ): Promise<TagAggregation[]> {
    const store = DatabaseManager.getDatabase();
    
    const sql = `
      SELECT 
        t.tag_id,
        t.name AS tag_name,
        t.color,
        COUNT(DISTINCT bt.bill_id) AS bill_count,
        COALESCE(SUM(b.amount), 0) AS total_amount
      FROM tags t
      INNER JOIN bill_tags bt ON t.tag_id = bt.tag_id
      INNER JOIN bills b ON bt.bill_id = b.bill_id
      INNER JOIN accounts a ON b.account_id = a.account_id
      WHERE t.user_id = ? 
        AND t.is_deleted = 0
        AND b.is_deleted = 0
        AND a.user_id = ?
        AND b.transaction_date >= ?
        AND b.transaction_date <= ?
      GROUP BY t.tag_id
      ORDER BY total_amount DESC
    `;
    
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId, userId, startDate, endDate]);
      const results: TagAggregation[] = [];
      
      while (resultSet.goToNextRow()) {
        results.push({
          tagId: resultSet.getLong(resultSet.getColumnIndex('tag_id')),
          tagName: resultSet.getString(resultSet.getColumnIndex('tag_name')),
          color: resultSet.getString(resultSet.getColumnIndex('color')),
          billCount: resultSet.getLong(resultSet.getColumnIndex('bill_count')),
          totalAmount: resultSet.getDouble(resultSet.getColumnIndex('total_amount'))
        });
      }
      
      return results;
    } catch (error) {
      console.error('[TagDAO] 标签聚合统计失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 标签聚合统计失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 获取用户的所有账单标签关联
   * @param userId 用户ID
   * @returns 账单标签关联数组
   */
  static async getBillTagsByUserId(userId: number): Promise<Array<BillTag>> {
    const store = DatabaseManager.getDatabase();
    const sql = `
      SELECT bt.*
      FROM bill_tags bt
      INNER JOIN bills b ON bt.bill_id = b.bill_id
      WHERE b.user_id = ? AND b.is_deleted = 0
      ORDER BY bt.created_at DESC
    `;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(sql, [userId]);
      const billTags: Array<BillTag> = [];
      while (resultSet.goToNextRow()) {
        billTags.push(TagDAO.mapRowToBillTag(resultSet));
      }
      console.log(`[TagDAO] 查询用户账单标签关联成功: userId=${userId}, count=${billTags.length}`);
      return billTags;
    } catch (error) {
      console.error('[TagDAO] 查询用户账单标签关联失败: ' + JSON.stringify(error));
      throw DAOHelper.toError('[TagDAO] 查询用户账单标签关联失败', error);
    } finally {
      resultSet?.close();
    }
  }

  /**
   * 增加标签使用次数
   * @param tagId 标签ID
   */
  private static async incrementUsageCount(tagId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `UPDATE tags SET usage_count = usage_count + 1 WHERE tag_id = ?`;
    try {
      await store.executeSql(sql, [tagId]);
    } catch (error) {
      console.error('[TagDAO] 增加使用次数失败: ' + JSON.stringify(error));
    }
  }

  /**
   * 减少标签使用次数
   * @param tagId 标签ID
   */
  private static async decrementUsageCount(tagId: number): Promise<void> {
    const store = DatabaseManager.getDatabase();
    const sql = `UPDATE tags SET usage_count = MAX(0, usage_count - 1) WHERE tag_id = ?`;
    try {
      await store.executeSql(sql, [tagId]);
    } catch (error) {
      console.error('[TagDAO] 减少使用次数失败: ' + JSON.stringify(error));
    }
  }

  /**
   * 检查标签是否存在
   * @param tagId 标签ID
   * @returns 是否存在
   */
  static async exists(tagId: number): Promise<boolean> {
    const sql = `SELECT 1 FROM tags WHERE tag_id = ? AND is_deleted = 0`;
    const store = DatabaseManager.getDatabase();
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.querySql(sql, [tagId]);
      return rs.goToNextRow();
    } finally {
      if (rs) {
        rs.close();
      }
    }
  }

  /**
   * 将查询结果映射为 Tag 实例
   * @param resultSet 查询结果集
   * @returns Tag 对象
   */
  private static mapRowToTag(resultSet: relationalStore.ResultSet): Tag {
    const tag = new Tag();
    tag.tagId = resultSet.getLong(resultSet.getColumnIndex('tag_id'));
    tag.userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
    tag.name = resultSet.getString(resultSet.getColumnIndex('name'));
    tag.color = resultSet.getString(resultSet.getColumnIndex('color'));
    tag.usageCount = resultSet.getLong(resultSet.getColumnIndex('usage_count'));
    tag.createdAt = resultSet.getString(resultSet.getColumnIndex('created_at'));
    tag.updatedAt = resultSet.getString(resultSet.getColumnIndex('updated_at'));
    tag.is_deleted = resultSet.getLong(resultSet.getColumnIndex('is_deleted'));
    return tag;
  }

  /**
   * 将查询结果映射为 BillTag 实例
   * @param resultSet 查询结果集
   * @returns BillTag 对象
   */
  private static mapRowToBillTag(resultSet: relationalStore.ResultSet): BillTag {
    const billTag = new BillTag();
    billTag.billId = resultSet.getLong(resultSet.getColumnIndex('bill_id'));
    billTag.tagId = resultSet.getLong(resultSet.getColumnIndex('tag_id'));
    billTag.createdAt = resultSet.getString(resultSet.getColumnIndex('created_at'));
    return billTag;
  }
}