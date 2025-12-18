import { describe, it, expect } from '@ohos/hypium';
import { BreakPointType } from '../../../../main/ets/common/BreakpointSystem';

export default function BreakpointSystemTest(): void {
  describe('BreakPointType.getValue()', () => {
    it('should_return_xs_value_for_xs_breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12,
        lg: 16
      });
      const value = breakPoint.getValue('xs');
      expect(value).assertEqual(8);
    });

    it('should_return_sm_value_for_sm_breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12,
        lg: 16
      });
      const value = breakPoint.getValue('sm');
      expect(value).assertEqual(10);
    });

    it('should_return_md_value_for_md_breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12,
        lg: 16
      });
      const value = breakPoint.getValue('md');
      expect(value).assertEqual(12);
    });

    it('should_return_lg_value_for_lg_breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12,
        lg: 16
      });
      const value = breakPoint.getValue('lg');
      expect(value).assertEqual(16);
    });

    it('should_return_xl_value_for_xl_breakpoint', 0, () => {
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

    it('should_return_xxl_value_for_xxl_breakpoint', 0, () => {
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

    it('should_return_undefined_for_unknown_breakpoint', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 8,
        sm: 10,
        md: 12
      });
      const value = breakPoint.getValue('unknown');
      expect(value === undefined).assertTrue();
    });

    it('should_handle_string_values', 0, () => {
      const breakPoint = new BreakPointType({
        xs: '90%',
        sm: '85%',
        md: '80%',
        lg: '70%'
      });
      const value = breakPoint.getValue('md');
      expect(value).assertEqual('80%');
    });

    it('should_handle_number_values', 0, () => {
      const breakPoint = new BreakPointType({
        xs: 14,
        sm: 15,
        md: 16,
        lg: 18
      });
      const value = breakPoint.getValue('lg');
      expect(value).assertEqual(18);
    });

    it('should_handle_partial_breakpoint_configuration', 0, () => {
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

  describe('BreakPointType_with_different_types', () => {
    it('should_work_with_number_type', 0, () => {
      const breakPoint = new BreakPointType<number>({
        xs: 8,
        sm: 10,
        md: 12
      });
      const value = breakPoint.getValue('md');
      expect(typeof value === 'number').assertTrue();
      expect(value).assertEqual(12);
    });

    it('should_work_with_string_type', 0, () => {
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

