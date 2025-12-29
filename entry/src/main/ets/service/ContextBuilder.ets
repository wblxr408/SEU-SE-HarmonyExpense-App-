import { BillDAO, MonthlyStats } from '../dao/BillDAO';
import { BudgetDAO } from '../dao/BudgetDAO';
import { Budget } from '../model/Budget';

/**
 * 构建 LLM 的财务上下文
 */
export class ContextBuilder {
  /**
   * 获取用户当月的财务状况摘要
   * @param userId 用户ID
   * @returns 带有上下文的格式化字符串
   */
  static async getFinancialSummary(userId: number): Promise<string> {
    const now = new Date();
    const currentMonthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    
    // 1. 获取账单统计
    let billContext = "暂无本月收支数据。";
    try {
      const stats: MonthlyStats[] = await BillDAO.getMonthlyStats(userId, currentMonthStr, currentMonthStr);
      if (stats.length > 0) {
        const currentStats = stats[0];
        billContext = `本月（${currentMonthStr}）数据：\n- 总收入：${currentStats.totalIncome.toFixed(2)}\n- 总支出：${currentStats.totalExpense.toFixed(2)}\n- 结余：${currentStats.balance.toFixed(2)}`;
      }
    } catch (e) {
      console.error('[ContextBuilder] Failed to get bill stats', e);
    }

    // 2. 获取预算信息
    let budgetContext = "暂无预算数据。";
    try {
      const budgets: Budget[] = await BudgetDAO.getByUserId(userId);
      const activeBudgets = budgets.filter(b => b.isDeleted === 0);
      
      if (activeBudgets.length > 0) {
        const totalBudget = activeBudgets.reduce((sum, b) => sum + b.amount, 0);
        budgetContext = `当前活跃预算总额：${totalBudget.toFixed(2)}`;
      }
    } catch (e) {
      console.error('[ContextBuilder] Failed to get budgets', e);
    }

    // 3. 组装 Prompt
    return `
=== 用户财务背景 ===
${billContext}
${budgetContext}
====================
    `.trim();
  }
}
