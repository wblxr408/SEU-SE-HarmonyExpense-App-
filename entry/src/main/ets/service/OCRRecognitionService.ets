/**
 * OCR识别服务 - 业务逻辑层
 *
 * 功能：
 * 1. 票据图片OCR识别
 * 2. 结构化数据提取
 * 3. 智能账单生成
 * 4. 识别历史管理
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

import { OCRRecognitionRecordDAO } from '../dao/OCRRecognitionDAO';
import { OCRRecognitionRecord } from '../model/OCRRecognition';
import { SmartCategoryService } from './SmartCategoryService';
import { CategoryDAO } from '../dao/CategoryDAO';

/**
 * OCR识别参数接口
 */
export interface OCRRecognitionParams {
  userId: number;
  imagePath: string;
  thumbnailPath?: string;
  provider?: 'huawei_ml_kit' | 'baidu' | 'tencent' | 'local';
}

/**
 * OCR识别结果接口
 */
export interface OCRRecognitionResult {
  success: boolean;
  recordId: number;
  receiptType: string;
  merchantName: string;
  totalAmount: number;
  transactionDate: string;
  confidenceScore: number;
  suggestedCategoryId: number;
  suggestedCategoryName: string;
  structuredData: Record<string, Object>;
  error?: string;
}

/**
 * 建议账单数据接口
 */
export interface SuggestedBillData {
  amount: number;
  type: 'expense' | 'income';
  categoryId: number;
  categoryName: string;
  note: string;
  transactionDate: string;
  confidence: number;
  needsReview: boolean;
  reviewReasons: string[];
}

/**
 * OCR执行结果接口
 */
export interface OCRPerformResult {
  success: boolean;
  rawText: string;
  error?: string;
}

/**
 * 票据项目接口
 */
export interface ReceiptItem {
  name: string;
  quantity: number;
  unitPrice: number;
  amount: number;
}

/**
 * 提取的结构化数据接口
 */
export interface ExtractedData {
  merchantName: string;
  totalAmount: number;
  transactionDate: string;
  confidence: number;
  items: ReceiptItem[];
}

/**
 * 分类映射结果接口
 */
export interface CategoryMapping {
  id: number;
  name: string;
}

/**
 * 分类建议接口
 */
export interface CategorySuggestion {
  categoryId: number;
  categoryName: string;
}

/**
 * OCR识别服务类
 */
export class OCRRecognitionService {

  // ==================== OCR识别 ====================

  /**
   * 识别票据图片
   * @param params 识别参数
   * @returns 识别结果
   */
  static async recognizeReceipt(params: OCRRecognitionParams): Promise<OCRRecognitionResult> {
    try {
      // 1. 创建识别记录
      const record = new OCRRecognitionRecord();
      record.userId = params.userId;
      record.imagePath = params.imagePath;
      record.thumbnailPath = params.thumbnailPath || '';
      record.ocrProvider = params.provider || 'huawei_ml_kit';
      record.recognitionStatus = 'processing';

      const recordId = await OCRRecognitionRecordDAO.insert(record);

      // 2. 执行OCR识别
      const startTime = Date.now();
      const ocrResult = await OCRRecognitionService.performOCR(params.imagePath, params.provider || 'huawei_ml_kit');
      const processingTime = Date.now() - startTime;

      if (!ocrResult.success) {
        // 识别失败
        await OCRRecognitionRecordDAO.updateStatus(recordId, 'failed', ocrResult.error);

        return {
          success: false,
          recordId: recordId,
          receiptType: 'unknown',
          merchantName: '',
          totalAmount: 0,
          transactionDate: '',
          confidenceScore: 0,
          suggestedCategoryId: 0,
          suggestedCategoryName: '',
          structuredData: {},
          error: ocrResult.error
        };
      }

      // 3. 提取结构化数据
      const structuredData = OCRRecognitionService.extractStructuredData(ocrResult.rawText);

      // 4. 识别票据类型
      const receiptType = OCRRecognitionService.detectReceiptType(ocrResult.rawText, structuredData.merchantName);

      // 5. 推荐分类
      const suggestedCategory = await OCRRecognitionService.suggestCategory(
        params.userId,
        receiptType,
        structuredData.merchantName,
        structuredData.totalAmount
      );

      // 6. 更新识别记录
      record.recordId = recordId;
      record.rawText = ocrResult.rawText;
      record.merchantName = structuredData.merchantName;
      record.totalAmount = structuredData.totalAmount;
      record.transactionDate = structuredData.transactionDate;
      record.receiptType = receiptType;
      record.confidenceScore = structuredData.confidence;
      record.structuredDataJson = JSON.stringify(structuredData);
      record.suggestedCategoryId = suggestedCategory.categoryId;
      record.suggestedCategoryName = suggestedCategory.categoryName;
      record.recognitionStatus = 'success';
      record.processingTimeMs = processingTime;

      await OCRRecognitionRecordDAO.update(record);

      // 将 ExtractedData 转换为 Record<string, Object>
      const structuredDataRecord: Record<string, Object> = {};
      structuredDataRecord['merchantName'] = structuredData.merchantName;
      structuredDataRecord['totalAmount'] = structuredData.totalAmount;
      structuredDataRecord['transactionDate'] = structuredData.transactionDate;
      structuredDataRecord['confidence'] = structuredData.confidence;
      structuredDataRecord['items'] = structuredData.items;

      return {
        success: true,
        recordId: recordId,
        receiptType: receiptType,
        merchantName: structuredData.merchantName,
        totalAmount: structuredData.totalAmount,
        transactionDate: structuredData.transactionDate,
        confidenceScore: structuredData.confidence,
        suggestedCategoryId: suggestedCategory.categoryId,
        suggestedCategoryName: suggestedCategory.categoryName,
        structuredData: structuredDataRecord
      };
    } catch (error) {
      console.error('[OCRRecognitionService] 识别票据失败:', error);
      return {
        success: false,
        recordId: 0,
        receiptType: 'unknown',
        merchantName: '',
        totalAmount: 0,
        transactionDate: '',
        confidenceScore: 0,
        suggestedCategoryId: 0,
        suggestedCategoryName: '',
        structuredData: {},
        error: String(error)
      };
    }
  }

  /**
   * 执行OCR识别（模拟实现）
   */
  private static async performOCR(
    _imagePath: string,
    _provider: string
  ): Promise<OCRPerformResult> {
    try {
      // TODO: 实际项目中需要集成真实的OCR API
      // 这里提供模拟实现

      // 模拟OCR识别延迟
      await new Promise<void>((resolve) => setTimeout(resolve, 500));

      // 模拟识别结果
      const mockResult = `
华润万家超市
地址：深圳市南山区科技园
电话：0755-12345678
--------------------------------
商品名称      数量  单价    金额
牛奶          2    15.00   30.00
面包          1    8.50    8.50
水果          1    25.00   25.00
--------------------------------
小计：                     63.50
优惠：                     -3.50
合计：                     60.00
支付方式：微信支付
交易时间：2024-01-15 14:23:56
收银员：001
谢谢惠顾！
      `.trim();

      return {
        success: true,
        rawText: mockResult
      };
    } catch (error) {
      console.error('[OCRRecognitionService] OCR识别失败:', error);
      return {
        success: false,
        rawText: '',
        error: String(error)
      };
    }
  }

  /**
   * 提取结构化数据
   */
  private static extractStructuredData(rawText: string): ExtractedData {
    const result: ExtractedData = {
      merchantName: '',
      totalAmount: 0,
      transactionDate: '',
      confidence: 0.8,
      items: []
    };

    // 提取商家名称（第一行非空内容）
    const lines = rawText.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (line.length > 0 && line.length < 50) {
        result.merchantName = line;
        break;
      }
    }

    // 提取金额（查找"合计"、"总计"等关键词）
    const amountKeywords = ['合计', '总计', '实付', '应付', 'Total', 'Amount'];
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      for (let j = 0; j < amountKeywords.length; j++) {
        const keyword = amountKeywords[j];
        if (line.indexOf(keyword) >= 0) {
          const amount = OCRRecognitionService.extractAmountFromLine(line);
          if (amount > 0) {
            result.totalAmount = amount;
            break;
          }
        }
      }
      if (result.totalAmount > 0) break;
    }

    // 提取日期
    const datePattern = /(\d{4})[年\-\/](\d{1,2})[月\-\/](\d{1,2})/;
    for (let i = 0; i < lines.length; i++) {
      const match = lines[i].match(datePattern);
      if (match) {
        const year = match[1];
        const month = match[2].padStart(2, '0');
        const day = match[3].padStart(2, '0');
        result.transactionDate = `${year}-${month}-${day}`;
        break;
      }
    }

    // 如果没有提取到日期，使用当前日期
    if (!result.transactionDate) {
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      result.transactionDate = `${year}-${month}-${day}`;
    }

    // 计算置信度
    let confidenceScore = 0;
    if (result.merchantName) confidenceScore += 0.3;
    if (result.totalAmount > 0) confidenceScore += 0.5;
    if (result.transactionDate) confidenceScore += 0.2;
    result.confidence = confidenceScore;

    return result;
  }

  /**
   * 从文本行中提取金额
   */
  private static extractAmountFromLine(line: string): number {
    // 匹配金额格式：123.45 或 ¥123.45 或 123,456.78
    const amountPattern = /[\¥￥]?\s*(\d{1,}(?:,\d{3})*(?:\.\d{1,2})?)/;
    const match = line.match(amountPattern);

    if (match) {
      const amountStr = match[1].replace(/,/g, ''); // 移除千分位逗号
      const amount = parseFloat(amountStr);
      if (!isNaN(amount) && amount > 0) {
        return amount;
      }
    }

    return 0;
  }

  /**
   * 识别票据类型
   */
  private static detectReceiptType(rawText: string, merchantName: string): string {
    const text = (rawText + ' ' + merchantName).toLowerCase();

    // 超市
    if (text.indexOf('超市') >= 0 || text.indexOf('便利店') >= 0 || text.indexOf('华润') >= 0 ||
        text.indexOf('沃尔玛') >= 0 || text.indexOf('mart') >= 0) {
      return 'supermarket';
    }

    // 餐饮
    if (text.indexOf('餐厅') >= 0 || text.indexOf('饭店') >= 0 || text.indexOf('美食') >= 0 ||
        text.indexOf('外卖') >= 0 || text.indexOf('restaurant') >= 0) {
      return 'restaurant';
    }

    // 交通
    if (text.indexOf('出租') >= 0 || text.indexOf('滴滴') >= 0 || text.indexOf('地铁') >= 0 ||
        text.indexOf('公交') >= 0 || text.indexOf('taxi') >= 0) {
      return 'transport';
    }

    // 加油
    if (text.indexOf('加油') >= 0 || text.indexOf('石油') >= 0 || text.indexOf('石化') >= 0 ||
        text.indexOf('fuel') >= 0) {
      return 'fuel';
    }

    // 医疗
    if (text.indexOf('医院') >= 0 || text.indexOf('药店') >= 0 || text.indexOf('诊所') >= 0 ||
        text.indexOf('pharmacy') >= 0) {
      return 'medical';
    }

    // 酒店
    if (text.indexOf('酒店') >= 0 || text.indexOf('宾馆') >= 0 || text.indexOf('hotel') >= 0) {
      return 'hotel';
    }

    return 'general';
  }

  /**
   * 推荐分类
   */
  private static async suggestCategory(
    userId: number,
    receiptType: string,
    merchantName: string,
    amount: number
  ): Promise<CategorySuggestion> {
    try {
      // 1. 先尝试使用智能分类服务
      const recommendations = await SmartCategoryService.recommendCategory(
        userId,
        merchantName,
        amount,
        1
      );

      if (recommendations.length > 0 && recommendations[0].confidence > 0.7) {
        return {
          categoryId: recommendations[0].categoryId,
          categoryName: recommendations[0].categoryName
        };
      }

      // 2. 根据票据类型从数据库查询对应分类
      const categories = await CategoryDAO.getByType(userId, 'expense');

      // 定义票据类型到分类名称的映射
      const typeToNameMap: Record<string, string> = {
        'supermarket': '日常购物',
        'restaurant': '餐饮美食',
        'transport': '交通出行',
        'fuel': '汽车加油',
        'medical': '医疗健康',
        'hotel': '住宿酒店',
        'general': '其他'
      };

      const targetCategoryName = typeToNameMap[receiptType] || '其他';

      // 在用户的分类中查找匹配的分类
      const matchedCategory = categories.find(c =>
        c.name === targetCategoryName || c.name.indexOf(targetCategoryName) >= 0
      );

      if (matchedCategory) {
        return {
          categoryId: matchedCategory.categoryId,
          categoryName: matchedCategory.name
        };
      }

      // 3. 如果没有找到匹配的，返回第一个支出分类或默认值
      if (categories.length > 0) {
        return {
          categoryId: categories[0].categoryId,
          categoryName: categories[0].name
        };
      }

      // 4. 兜底返回0（表示未找到）
      return {
        categoryId: 0,
        categoryName: '未分类'
      };
    } catch (error) {
      console.error('[OCRRecognitionService] 推荐分类失败:', error);
      return {
        categoryId: 0,
        categoryName: '其他'
      };
    }
  }

  // ==================== 账单生成 ====================

  /**
   * 根据OCR结果生成建议账单
   */
  static async generateSuggestedBill(recordId: number): Promise<SuggestedBillData | null> {
    try {
      const record = await OCRRecognitionRecordDAO.getById(recordId);
      if (!record) {
        throw new Error('识别记录不存在');
      }

      const reviewReasons: string[] = [];

      // 检查需要人工审核的情况
      if (record.confidenceScore < 0.8) {
        reviewReasons.push('识别置信度较低');
      }
      if (!record.totalAmount || record.totalAmount === 0) {
        reviewReasons.push('未能识别金额');
      }
      if (!record.transactionDate) {
        reviewReasons.push('未能识别日期');
      }

      const suggestedBill: SuggestedBillData = {
        amount: record.totalAmount || 0,
        type: 'expense',
        categoryId: record.suggestedCategoryId || 0,
        categoryName: record.suggestedCategoryName || '其他',
        note: record.merchantName || '未识别商家',
        transactionDate: record.transactionDate || new Date().toISOString().substring(0, 10),
        confidence: record.confidenceScore,
        needsReview: reviewReasons.length > 0,
        reviewReasons: reviewReasons
      };

      return suggestedBill;
    } catch (error) {
      console.error('[OCRRecognitionService] 生成建议账单失败:', error);
      return null;
    }
  }

  /**
   * 标记识别记录为已使用
   */
  static async markAsUsed(recordId: number, billId: number): Promise<boolean> {
    try {
      return await OCRRecognitionRecordDAO.markAsUsed(recordId, billId);
    } catch (error) {
      console.error('[OCRRecognitionService] 标记为已使用失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  // ==================== 历史管理 ====================

  /**
   * 获取用户的识别历史
   */
  static async getRecognitionHistory(
    userId: number,
    limit: number = 20,
    offset: number = 0
  ): Promise<OCRRecognitionRecord[]> {
    try {
      return await OCRRecognitionRecordDAO.getByUserId(userId, limit, offset);
    } catch (error) {
      console.error('[OCRRecognitionService] 获取识别历史失败:', error);
      return [];
    }
  }

  /**
   * 获取未使用的识别记录
   */
  static async getUnusedRecognitions(userId: number): Promise<OCRRecognitionRecord[]> {
    try {
      return await OCRRecognitionRecordDAO.getUnused(userId, 20);
    } catch (error) {
      console.error('[OCRRecognitionService] 获取未使用记录失败:', error);
      return [];
    }
  }

  /**
   * 获取高置信度未使用记录
   */
  static async getHighConfidenceUnused(userId: number): Promise<OCRRecognitionRecord[]> {
    try {
      return await OCRRecognitionRecordDAO.getHighConfidenceUnused(userId, 0.85, 10);
    } catch (error) {
      console.error('[OCRRecognitionService] 获取高置信度记录失败:', error);
      return [];
    }
  }

  /**
   * 搜索识别记录
   */
  static async searchRecognitions(
    userId: number,
    keyword: string,
    limit: number = 30
  ): Promise<OCRRecognitionRecord[]> {
    try {
      return await OCRRecognitionRecordDAO.search(userId, keyword, limit);
    } catch (error) {
      console.error('[OCRRecognitionService] 搜索识别记录失败:', error);
      return [];
    }
  }

  /**
   * 删除识别记录
   */
  static async deleteRecognition(recordId: number): Promise<boolean> {
    try {
      return await OCRRecognitionRecordDAO.softDelete(recordId);
    } catch (error) {
      console.error('[OCRRecognitionService] 删除识别记录失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  // ==================== 统计分析 ====================

  /**
   * 获取识别统计
   */
  static async getStatistics(userId: number) {
    try {
      return await OCRRecognitionRecordDAO.getStatistics(userId);
    } catch (error) {
      console.error('[OCRRecognitionService] 获取识别统计失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 按票据类型统计
   */
  static async getStatisticsByReceiptType(userId: number) {
    try {
      return await OCRRecognitionRecordDAO.getStatisticsByReceiptType(userId);
    } catch (error) {
      console.error('[OCRRecognitionService] 按票据类型统计失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 按提供商统计
   */
  static async getStatisticsByProvider(userId: number) {
    try {
      return await OCRRecognitionRecordDAO.getStatisticsByProvider(userId);
    } catch (error) {
      console.error('[OCRRecognitionService] 按提供商统计失败:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 清理旧记录
   */
  static async cleanupOldRecords(userId: number, keepCount: number = 100): Promise<number> {
    try {
      return await OCRRecognitionRecordDAO.cleanupOldRecords(userId, keepCount);
    } catch (error) {
      console.error('[OCRRecognitionService] 清理旧记录失败:', error);
      return 0;
    }
  }

  /**
   * 清理失败记录
   */
  static async cleanupFailedRecords(userId: number, olderThanDays: number = 30): Promise<number> {
    try {
      return await OCRRecognitionRecordDAO.cleanupFailedRecords(userId, olderThanDays);
    } catch (error) {
      console.error('[OCRRecognitionService] 清理失败记录失败:', error);
      return 0;
    }
  }
}
