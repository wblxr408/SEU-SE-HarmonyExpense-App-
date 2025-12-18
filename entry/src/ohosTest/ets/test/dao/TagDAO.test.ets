import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { TagDAO } from '../../../../main/ets/dao/TagDAO';
import { Tag } from '../../../../main/ets/model/Tag';
import { DatabaseManager } from '../../../../main/ets/database/DatabaseManager';
import { BillDAO } from '../../../../main/ets/dao/BillDAO';
import { AccountDAO } from '../../../../main/ets/dao/AccountDAO';
import { CategoryDAO } from '../../../../main/ets/dao/CategoryDAO';
import { Bill } from '../../../../main/ets/model/Bill';
import { Account } from '../../../../main/ets/model/Account';
import { Category } from '../../../../main/ets/model/Category';
import common from '@ohos.app.ability.common';

// 在测试环境中获取 Context 的辅助函数
function getTestContext(): common.Context {
  return getContext() as common.Context;
}

export default function TagDAOTest(): void {
  describe('TagDAO_CRUD', () => {
    const testUserId: number = 1;

    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);

      // 创建测试用的账户和分类（用于账单标签关联测试）
      const now = new Date().toISOString();
      try {
        const testAccount = new Account(0, testUserId, '测试账户', 'bank', 1000.0, '#1E90FF', now, 0);
        testAccount.updatedAt = now;
        const testCategory = new Category(0, testUserId, '测试分类', 'expense', '🍽️', '#FF6B6B', 0, 0, now, now, 0);
        await AccountDAO.insert(testAccount);
        await CategoryDAO.insert(testCategory);
      } catch (e) {
        // 如果已存在则忽略
      }
    });

    it('should_insert_and_get_tag', 0, async () => {
      const now = new Date().toISOString();
      const tag = new Tag(
        0,
        testUserId,
        '工作',
        '#52C41A',
        0,
        now,
        now,
        0
      );
      await TagDAO.insert(tag);
      const retrieved = await TagDAO.getById(testUserId, 1);
      expect(retrieved !== null).assertTrue();
      if (retrieved) {
        expect(retrieved.name).assertEqual('工作');
        expect(retrieved.color).assertEqual('#52C41A');
        expect(retrieved.userId).assertEqual(testUserId);
      }
    });

    it('should_get_all_tags', 0, async () => {
      const tags = await TagDAO.getAll(testUserId);
      expect(Array.isArray(tags)).assertTrue();
      expect(tags.length >= 1).assertTrue();
    });

    it('should_update_tag', 0, async () => {
      const tag = await TagDAO.getById(testUserId, 1);
      if (tag) {
        tag.name = '重要工作';
        tag.color = '#FF6B6B';
        await TagDAO.update(tag);
        const updated = await TagDAO.getById(testUserId, 1);
        expect(updated !== null).assertTrue();
        if (updated) {
          expect(updated.name).assertEqual('重要工作');
          expect(updated.color).assertEqual('#FF6B6B');
        }
      }
    });

    it('should_soft_delete_tag', 0, async () => {
      // 先创建一个标签用于删除测试
      const now = new Date().toISOString();
      const tag = new Tag(0, testUserId, '临时标签', '#999999', 0, now, now, 0);
      await TagDAO.insert(tag);
      
      const tags = await TagDAO.getAll(testUserId);
      const tempTag = tags.find(t => t.name === '临时标签');
      if (tempTag) {
        await TagDAO.softDelete(testUserId, tempTag.tagId);
        const deleted = await TagDAO.getById(testUserId, tempTag.tagId);
        expect(deleted === null).assertTrue();
      }
    });

    it('should_restore_deleted_tag', 0, async () => {
      // 查找一个已删除的标签
      const tags = await TagDAO.getAll(testUserId);
      const tempTag = tags.find(t => t.name === '临时标签');
      if (tempTag) {
        await TagDAO.restore(testUserId, tempTag.tagId);
        const restored = await TagDAO.getById(testUserId, tempTag.tagId);
        expect(restored !== null).assertTrue();
      }
    });

    it('should_bulk_insert_tags', 0, async () => {
      const now = new Date().toISOString();
      const tags: Tag[] = [
        new Tag(0, testUserId, '标签1', '#FF6B6B', 0, now, now, 0),
        new Tag(0, testUserId, '标签2', '#52C41A', 0, now, now, 0),
        new Tag(0, testUserId, '标签3', '#1890FF', 0, now, now, 0)
      ];
      await TagDAO.bulkInsert(tags);
      const allTags = await TagDAO.getAll(testUserId);
      const insertedTags = allTags.filter(t => t.name.startsWith('标签'));
      expect(insertedTags.length >= 3).assertTrue();
    });
  });

  describe('TagDAO_Bill-Tag_Association', () => {
    const testUserId: number = 1;
    let testBillId: number = 0;
    let testTagId: number = 0;

    beforeAll(async () => {
      const ctx: common.Context = getTestContext();
      await DatabaseManager.initDatabase(ctx);

      // 创建测试账单
      const now = new Date().toISOString();
      const bill = new Bill(
        0,
        testUserId,
        1, // accountId
        1, // categoryId
        100.0,
        '测试账单',
        '2025-11-05',
        'expense',
        now,
        now,
        0
      );
      await BillDAO.insert(bill);
      const bills = await BillDAO.getAll();
      testBillId = bills.length > 0 ? bills[bills.length - 1].billId : 1;

      // 创建测试标签
      const tag = new Tag(0, testUserId, '关联测试标签', '#52C41A', 0, now, now, 0);
      await TagDAO.insert(tag);
      const tags = await TagDAO.getAll(testUserId);
      testTagId = tags.length > 0 ? tags[tags.length - 1].tagId : 1;
    });

    it('should_add_tag_to_bill', 0, async () => {
      await TagDAO.addTagToBill(testBillId, testTagId);
      const billTags = await TagDAO.getTagsByBillId(testBillId);
      expect(billTags.length >= 1).assertTrue();
      const found = billTags.find(bt => bt.tagId === testTagId);
      expect(found !== undefined).assertTrue();
    });

    it('should_get_tags_by_bill_id', 0, async () => {
      const billTags = await TagDAO.getTagsByBillId(testBillId);
      expect(Array.isArray(billTags)).assertTrue();
      expect(billTags.length >= 1).assertTrue();
    });

    it('should_get_bill_ids_by_tag_id', 0, async () => {
      const billIds = await TagDAO.getBillIdsByTagId(testTagId);
      expect(Array.isArray(billIds)).assertTrue();
      expect(billIds.includes(testBillId)).assertTrue();
    });

    it('should_remove_tag_from_bill', 0, async () => {
      await TagDAO.removeTagFromBill(testBillId, testTagId);
      const billTags = await TagDAO.getTagsByBillId(testBillId);
      const found = billTags.find(bt => bt.tagId === testTagId);
      expect(found === undefined).assertTrue();
    });

    it('should_set_tags_for_bill_(replace_existing)', 0, async () => {
      // 创建多个标签
      const now = new Date().toISOString();
      const tag1 = new Tag(0, testUserId, '标签A', '#FF6B6B', 0, now, now, 0);
      const tag2 = new Tag(0, testUserId, '标签B', '#52C41A', 0, now, now, 0);
      await TagDAO.insert(tag1);
      await TagDAO.insert(tag2);
      
      const allTags = await TagDAO.getAll(testUserId);
      const tagA = allTags.find(t => t.name === '标签A');
      const tagB = allTags.find(t => t.name === '标签B');
      
      if (tagA && tagB) {
        // 设置多个标签
        await TagDAO.setTagsForBill(testBillId, [tagA.tagId, tagB.tagId]);
        const billTags = await TagDAO.getTagsByBillId(testBillId);
        expect(billTags.length).assertEqual(2);
        
        // 替换为单个标签
        await TagDAO.setTagsForBill(testBillId, [tagA.tagId]);
        const billTagsAfter = await TagDAO.getTagsByBillId(testBillId);
        expect(billTagsAfter.length).assertEqual(1);
        expect(billTagsAfter[0].tagId).assertEqual(tagA.tagId);
      }
    });

    it('should_increment_usage_count_when_adding_tag', 0, async () => {
      const now = new Date().toISOString();
      const tag = new Tag(0, testUserId, '使用计数测试', '#1890FF', 0, now, now, 0);
      await TagDAO.insert(tag);
      const tags = await TagDAO.getAll(testUserId);
      const testTag = tags.find(t => t.name === '使用计数测试');
      
      if (testTag) {
        const initialCount = testTag.usageCount;
        await TagDAO.addTagToBill(testBillId, testTag.tagId);
        const updated = await TagDAO.getById(testUserId, testTag.tagId);
        if (updated) {
          expect(updated.usageCount).assertEqual(initialCount + 1);
        }
      }
    });
  });

  describe('TagDAO_Popular_Tags', () => {
    const testUserId: number = 1;

    it('should_get_popular_tags', 0, async () => {
      const popularTags = await TagDAO.getPopularTags(testUserId, 5);
      expect(Array.isArray(popularTags)).assertTrue();
      expect(popularTags.length <= 5).assertTrue();
    });

    it('should_return_empty_array_when_no_tags_exist', 0, async () => {
      // 测试不存在的用户
      const tags = await TagDAO.getPopularTags(99999, 10);
      expect(Array.isArray(tags)).assertTrue();
      expect(tags.length).assertEqual(0);
    });
  });
}

