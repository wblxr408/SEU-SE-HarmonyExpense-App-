interface ThemeShadow {
  radius: number;
  color: string;
  offsetY: number;
}

/*
 * Global visual theme constants.
 */
export class AppTheme {
  // Premium monochrome palette
  static readonly Background: string = '#F5F5F7';
  static readonly GlassBackground: string = 'rgba(245, 245, 247, 0.8)';
  static readonly CardBg: string = '#FFFFFF';
  static readonly HeroBg: string = '#1A1A1A';

  // Typography colors
  static readonly TextMain: string = '#1A1A1A';
  static readonly TextSub: string = '#8E8E93';
  static readonly TextWhite: string = '#FFFFFF';

  // Semantic amount colors in monochrome
  static readonly Income: string = '#1A1A1A';
  static readonly Expense: string = '#8E8E93';

  // Borders and separators
  static readonly Border: string = '#E5E5EA';

  // Compatibility tokens used by existing chart/stat pages
  static readonly DarkBackground: string = '#1A1A1A';
  static readonly DarkCardBg: string = '#2C2C2E';
  static readonly DarkTextMain: string = '#FFFFFF';
  static readonly DarkTextSub: string = '#8E8E93';
  static readonly ChartHighlight: string = '#1A1A1A';
  static readonly ChartInactive: string = '#D1D1D6';

  // Shadow tokens
  static readonly CardShadow: ThemeShadow = {
    radius: 40,
    color: 'rgba(0, 0, 0, 0.03)',
    offsetY: 8
  };
  static readonly FabShadow: ThemeShadow = {
    radius: 30,
    color: 'rgba(26, 26, 26, 0.25)',
    offsetY: 12
  };
}
