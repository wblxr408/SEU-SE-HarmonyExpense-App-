/**
 * 建议反馈 DAO（简化实现）
 */
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../database/DatabaseManager';
import { AdviceFeedback } from '../model/AdviceFeedback';

export class AdviceFeedbackDAO {
  static async insert(feedback: AdviceFeedback): Promise<number> {
    const store = DatabaseManager.getDatabase();
    const vb: relationalStore.ValuesBucket = {/* minimal */};
    const id = await store.insert(AdviceFeedback.tableName, vb);
    return id;
  }

  static async getAcceptanceRateByType(userId: number, adviceType: string): Promise<number> {
    const store = DatabaseManager.getDatabase();
    // 简化实现：查询接受率平均值
    try {
      const sql = `SELECT AVG(CASE WHEN feedback_status = 'accepted' THEN 1.0 ELSE 0 END) as rate FROM ${AdviceFeedback.tableName} WHERE user_id = ? AND advice_type = ?`;
      const rs = await store.querySql(sql, [userId.toString(), adviceType]);
      if (rs.rowCount > 0) {
        rs.goToFirstRow();
        const rate = rs.getDouble(rs.getColumnIndex('rate')) || 0;
        rs.close();
        return rate;
      }
      rs.close();
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
