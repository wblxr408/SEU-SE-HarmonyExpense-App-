import { describe, it, expect } from '@ohos/hypium';
import { BillTag, BillTagJSON } from '../../../../main/ets/model/BillTag';

export default function BillTagTest(): void {
  describe('BillTag.validate()', () => {
    it('valid_billTag_should_pass', 0, () => {
      const billTag = new BillTag(
        1,
        2,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertTrue();
    });

    it('invalid_billTag_should_fail_(zero_billId)', 0, () => {
      const billTag = new BillTag(
        0,
        2,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertFalse();
    });

    it('invalid_billTag_should_fail_(negative_billId)', 0, () => {
      const billTag = new BillTag(
        -1,
        2,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertFalse();
    });

    it('invalid_billTag_should_fail_(zero_tagId)', 0, () => {
      const billTag = new BillTag(
        1,
        0,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertFalse();
    });

    it('invalid_billTag_should_fail_(negative_tagId)', 0, () => {
      const billTag = new BillTag(
        1,
        -1,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertFalse();
    });

    it('valid_billTag_with_valid_IDs_should_pass', 0, () => {
      const billTag = new BillTag(
        100,
        200,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertTrue();
    });
  });

  describe('BillTag.toJSON()_and_fromJSON()', () => {
    it('toJSON_should_return_correct_structure', 0, () => {
      const billTag = new BillTag(
        1,
        2,
        '2025-11-05T10:00:00'
      );
      const json = billTag.toJSON();
      expect(json.billId).assertEqual(1);
      expect(json.tagId).assertEqual(2);
      expect(json.createdAt).assertEqual('2025-11-05T10:00:00');
    });

    it('fromJSON_should_create_correct_BillTag_instance', 0, () => {
      const json: BillTagJSON = {
        billId: 3,
        tagId: 4,
        createdAt: '2025-11-05T11:00:00'
      };
      const billTag = BillTag.fromJSON(json);
      expect(billTag.billId).assertEqual(3);
      expect(billTag.tagId).assertEqual(4);
      expect(billTag.createdAt).assertEqual('2025-11-05T11:00:00');
    });

    it('should_handle_round-trip_conversion', 0, () => {
      const original = new BillTag(
        5,
        6,
        '2025-11-05T12:00:00'
      );
      const json = original.toJSON();
      const restored = BillTag.fromJSON(json);
      
      expect(restored.billId).assertEqual(original.billId);
      expect(restored.tagId).assertEqual(original.tagId);
      expect(restored.createdAt).assertEqual(original.createdAt);
    });
  });

  describe('BillTag_default_values', () => {
    it('should_use_default_values_when_not_provided', 0, () => {
      const billTag = new BillTag();
      expect(billTag.billId).assertEqual(0);
      expect(billTag.tagId).assertEqual(0);
      expect(billTag.createdAt).assertEqual('');
    });
  });
}

