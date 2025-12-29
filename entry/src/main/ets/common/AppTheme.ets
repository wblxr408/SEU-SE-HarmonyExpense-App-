/*
 * Copyright (c) 2023 HarmonyExpense
 * 定义全局应用主题颜色和样式。
 */

export class AppTheme {
  // 主品牌色
  static readonly Primary: string = '#2E65F3';
  static readonly PrimaryLight: string = '#5B86F5';
  
  // 背景色
  static readonly Background: string = '#F5F7F9';
  static readonly CardBg: string = '#FFFFFF';
  static readonly InputBg: string = '#F7F8FA';
  
  // 文本颜色
  static readonly TextMain: string = '#2D3436';
  static readonly TextSub: string = '#8395A7';
  static readonly TextWhite: string = '#FFFFFF';
  
  // 功能色
  static readonly Success: string = '#00C853'; // 绿色
  static readonly Failure: string = '#D32F2F'; // 红色
  static readonly Warning: string = '#FFD600'; // 黄色
  
  // 阴影与边框
  static readonly Shadow: string = 'rgba(46, 101, 243, 0.15)';
  static readonly Border: string = '#E0E0E0';
  
  // 深色主题颜色（用于统计页面）
  static readonly DarkBackground: string = '#000000';
  static readonly DarkCardBg: string = '#1C1C1E';
  static readonly DarkTextMain: string = '#FFFFFF';
  static readonly DarkTextSub: string = '#999999';

  // 图表颜色
  static readonly ChartHighlight: string = '#4D8DFF';
  static readonly ChartInactive: string = '#555555';
}
