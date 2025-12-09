import { describe, it, expect } from '@ohos/hypium';
import { BillTag, BillTagJSON } from '../../../../src/main/ets/model/BillTag';

export default function BillTagTest(): void {
  describe('BillTag.validate()', () => {
    it('valid billTag should pass', 0, () => {
      const billTag = new BillTag(
        1,
        2,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertTrue();
    });

    it('invalid billTag should fail (zero billId)', 0, () => {
      const billTag = new BillTag(
        0,
        2,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertFalse();
    });

    it('invalid billTag should fail (negative billId)', 0, () => {
      const billTag = new BillTag(
        -1,
        2,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertFalse();
    });

    it('invalid billTag should fail (zero tagId)', 0, () => {
      const billTag = new BillTag(
        1,
        0,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertFalse();
    });

    it('invalid billTag should fail (negative tagId)', 0, () => {
      const billTag = new BillTag(
        1,
        -1,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertFalse();
    });

    it('valid billTag with valid IDs should pass', 0, () => {
      const billTag = new BillTag(
        100,
        200,
        '2025-11-05T10:00:00'
      );
      expect(billTag.validate()).assertTrue();
    });
  });

  describe('BillTag.toJSON() and fromJSON()', () => {
    it('toJSON should return correct structure', 0, () => {
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

    it('fromJSON should create correct BillTag instance', 0, () => {
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

    it('should handle round-trip conversion', 0, () => {
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

  describe('BillTag default values', () => {
    it('should use default values when not provided', 0, () => {
      const billTag = new BillTag();
      expect(billTag.billId).assertEqual(0);
      expect(billTag.tagId).assertEqual(0);
      expect(billTag.createdAt).assertEqual('');
    });
  });
}

