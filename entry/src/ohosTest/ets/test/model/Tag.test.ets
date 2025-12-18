import { describe, it, expect } from '@ohos/hypium';
import { Tag, TagJSON } from '../../../../main/ets/model/Tag';

export default function TagTest(): void {
  describe('Tag.validate()', () => {
    it('valid_tag_should_pass', 0, () => {
      const tag = new Tag(
        1,
        1,
        '重要',
        '#FF6B6B',
        5,
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        0
      );
      expect(tag.validate()).assertTrue();
    });

    it('invalid_tag_should_fail_(empty_name)', 0, () => {
      const tag = new Tag(
        0,
        1,
        '',
        '#FF6B6B',
        0,
        '',
        '',
        0
      );
      expect(tag.validate()).assertFalse();
    });

    it('invalid_tag_should_fail_(name_too_long)', 0, () => {
      const tag = new Tag(
        0,
        1,
        '这是一个非常非常非常长的标签名称超过了20个字符的限制',
        '#FF6B6B',
        0,
        '',
        '',
        0
      );
      expect(tag.validate()).assertFalse();
    });

    it('invalid_tag_should_fail_(invalid_is_deleted)', 0, () => {
      const tag = new Tag(
        1,
        1,
        '重要',
        '#FF6B6B',
        5,
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        2
      );
      expect(tag.validate()).assertFalse();
    });

    it('valid_tag_with_deleted_flag_should_pass', 0, () => {
      const tag = new Tag(
        1,
        1,
        '已删除标签',
        '#FF6B6B',
        0,
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        1
      );
      expect(tag.validate()).assertTrue();
    });
  });

  describe('Tag.toJSON()_and_fromJSON()', () => {
    it('toJSON_should_return_correct_structure', 0, () => {
      const tag = new Tag(
        1,
        1,
        '工作',
        '#52C41A',
        10,
        '2025-11-05T10:00:00',
        '2025-11-05T11:00:00',
        0
      );
      const json = tag.toJSON();
      expect(json.tagId).assertEqual(1);
      expect(json.userId).assertEqual(1);
      expect(json.name).assertEqual('工作');
      expect(json.color).assertEqual('#52C41A');
      expect(json.usageCount).assertEqual(10);
      expect(json.createdAt).assertEqual('2025-11-05T10:00:00');
      expect(json.updatedAt).assertEqual('2025-11-05T11:00:00');
      expect(json.is_deleted).assertEqual(0);
    });

    it('fromJSON_should_create_correct_Tag_instance', 0, () => {
      const json: TagJSON = {
        tagId: 2,
        userId: 1,
        name: '生活',
        color: '#1890FF',
        usageCount: 3,
        createdAt: '2025-11-05T10:00:00',
        updatedAt: '2025-11-05T11:00:00',
        is_deleted: 0
      };
      const tag = Tag.fromJSON(json);
      expect(tag.tagId).assertEqual(2);
      expect(tag.userId).assertEqual(1);
      expect(tag.name).assertEqual('生活');
      expect(tag.color).assertEqual('#1890FF');
      expect(tag.usageCount).assertEqual(3);
    });

    it('fromJSON_should_handle_missing_is_deleted_field', 0, () => {
      const json: TagJSON = {
        tagId: 3,
        userId: 1,
        name: '测试',
        color: '#FF6B6B',
        usageCount: 0,
        createdAt: '2025-11-05T10:00:00',
        updatedAt: '2025-11-05T11:00:00'
      };
      const tag = Tag.fromJSON(json);
      expect(tag.is_deleted).assertEqual(0);
    });
  });

  describe('Tag.clone()', () => {
    it('clone_should_create_independent_copy', 0, () => {
      const original = new Tag(
        1,
        1,
        '原始标签',
        '#52C41A',
        5,
        '2025-11-05T10:00:00',
        '2025-11-05T11:00:00',
        0
      );
      const cloned = original.clone();
      
      expect(cloned.tagId).assertEqual(original.tagId);
      expect(cloned.userId).assertEqual(original.userId);
      expect(cloned.name).assertEqual(original.name);
      expect(cloned.color).assertEqual(original.color);
      expect(cloned.usageCount).assertEqual(original.usageCount);
      
      // 修改克隆对象不应影响原对象
      cloned.name = '修改后的标签';
      cloned.usageCount = 10;
      expect(original.name).assertEqual('原始标签');
      expect(original.usageCount).assertEqual(5);
    });
  });

  describe('Tag_default_values', () => {
    it('should_use_default_color_when_not_provided', 0, () => {
      const tag = new Tag(0, 1, '测试标签');
      expect(tag.color).assertEqual('#52C41A');
      expect(tag.usageCount).assertEqual(0);
      expect(tag.is_deleted).assertEqual(0);
    });
  });
}

