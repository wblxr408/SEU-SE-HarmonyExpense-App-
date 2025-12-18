import { BillDAO, MonthlyStats } from '../dao/BillDAO';
import { BudgetDAO } from '../dao/BudgetDAO';
import { Budget } from '../model/Budget';

/**
 * Builds the financial context for the LLM
 */
export class ContextBuilder {
  /**
   * Get a summary of the user's financial status for the current month
   * @param userId User ID
   * @returns Formatted string with context
   */
  static async getFinancialSummary(userId: number): Promise<string> {
    const now = new Date();
    const currentMonthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    
    // 1. Get Bill Stats
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

    // 2. Get Budget Info
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

    // 3. Assemble Prompt
    return `
=== 用户财务背景 ===
${billContext}
${budgetContext}
====================
    `.trim();
  }
}
