/*
 * Copyright (c) 2023 HarmonyExpense
 * Defines global application theme colors and styles.
 */

export class AppTheme {
  // Primary Brand Colors
  static readonly Primary: string = '#2E65F3';
  static readonly PrimaryLight: string = '#5B86F5';
  
  // Backgrounds
  static readonly Background: string = '#F5F7F9';
  static readonly CardBg: string = '#FFFFFF';
  static readonly InputBg: string = '#F7F8FA';
  
  // Text Colors
  static readonly TextMain: string = '#2D3436';
  static readonly TextSub: string = '#8395A7';
  static readonly TextWhite: string = '#FFFFFF';
  
  // Functional Colors
  static readonly Success: string = '#00C853'; // Green
  static readonly Failure: string = '#D32F2F'; // Red
  static readonly Warning: string = '#FFD600'; // Yellow
  
  // Shadows & Borders
  static readonly Shadow: string = 'rgba(46, 101, 243, 0.15)';
  static readonly Border: string = '#E0E0E0';
  
  // Dark Theme Colors (for Statistics Page)
  static readonly DarkBackground: string = '#000000';
  static readonly DarkCardBg: string = '#1C1C1E';
  static readonly DarkTextMain: string = '#FFFFFF';
  static readonly DarkTextSub: string = '#999999';

  // Chart Colors
  static readonly ChartHighlight: string = '#4D8DFF';
  static readonly ChartInactive: string = '#555555';
}
