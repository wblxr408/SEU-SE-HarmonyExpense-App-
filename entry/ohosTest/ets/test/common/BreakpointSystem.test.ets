import { describe, it, expect } from '@ohos/hypium';
import { BreakPointType } from '../../../../src/main/ets/common/BreakpointSystem';

export default function BreakpointSystemTest(): void {
  describe('BreakPointType.getValue()', () => {
    it('should return xs value for xs breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12,
        lg: 16
      });
      const value = breakPoint.getValue('xs');
      expect(value).assertEqual(8);
    });

    it('should return sm value for sm breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12,
        lg: 16
      });
      const value = breakPoint.getValue('sm');
      expect(value).assertEqual(10);
    });

    it('should return md value for md breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12,
        lg: 16
      });
      const value = breakPoint.getValue('md');
      expect(value).assertEqual(12);
    });

    it('should return lg value for lg breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12,
        lg: 16
      });
      const value = breakPoint.getValue('lg');
      expect(value).assertEqual(16);
    });

    it('should return xl value for xl breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12,
        lg: 16,
        xl: 20
      });
      const value = breakPoint.getValue('xl');
      expect(value).assertEqual(20);
    });

    it('should return xxl value for xxl breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12,
        lg: 16,
        xl: 20,
        xxl: 24
      });
      const value = breakPoint.getValue('xxl');
      expect(value).assertEqual(24);
    });

    it('should return undefined for unknown breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12
      });
      const value = breakPoint.getValue('unknown');
      expect(value === undefined).assertTrue();
    });

    it('should handle string values', 0, () => {
      const breakPoint = new BreakPointType({
        xs: '90%',
        sm: '85%',
        md: '80%',
        lg: '70%'
      });
      const value = breakPoint.getValue('md');
      expect(value).assertEqual('80%');
    });

    it('should handle number values', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 14,
        sm: 15,
        md: 16,
        lg: 18
      });
      const value = breakPoint.getValue('lg');
      expect(value).assertEqual(18);
    });

    it('should handle partial breakpoint configuration', 0, () => {
      const breakPoint = new BreakPointType({
        md: 12,
        lg: 16
      });
      const mdValue = breakPoint.getValue('md');
      const lgValue = breakPoint.getValue('lg');
      const xsValue = breakPoint.getValue('xs');
      
      expect(mdValue).assertEqual(12);
      expect(lgValue).assertEqual(16);
      expect(xsValue === undefined).assertTrue();
    });
  });

  describe('BreakPointType with different types', () => {
    it('should work with number type', 0, () => {
      const breakPoint = new BreakPointType<number>({
        xs: 8,
        sm: 10,
        md: 12
      });
      const value = breakPoint.getValue('md');
      expect(typeof value === 'number').assertTrue();
      expect(value).assertEqual(12);
    });

    it('should work with string type', 0, () => {
      const breakPoint = new BreakPointType<string>({
        xs: '90%',
        sm: '85%',
        md: '80%'
      });
      const value = breakPoint.getValue('sm');
      expect(typeof value === 'string').assertTrue();
      expect(value).assertEqual('85%');
    });
  });
}

