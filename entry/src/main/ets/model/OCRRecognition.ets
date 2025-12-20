/**
 * 智能票据OCR识别模型
 *
 * 功能：
 * 1. 票据图片识别和解析
 * 2. 结构化数据提取（金额、日期、商家等）
 * 3. 自动填充账单信息
 * 4. 多种票据类型支持
 *
 * 技术方案：
 * - 集成华为ML Kit OCR API
 * - 支持百度/腾讯OCR API备选
 * - NER实体抽取（金额、日期、商家名）
 * - 图像预处理优化
 *
 * @version 2.0.0
 * @author HarmonyExpense Team
 */

// ==================== 常量定义 ====================

// 票据类型常量
export const RECEIPT_TYPE_GENERAL = 'general';           // 通用小票
export const RECEIPT_TYPE_SUPERMARKET = 'supermarket';   // 超市购物
export const RECEIPT_TYPE_RESTAURANT = 'restaurant';     // 餐饮
export const RECEIPT_TYPE_TRANSPORT = 'transport';       // 交通
export const RECEIPT_TYPE_FUEL = 'fuel';                 // 加油
export const RECEIPT_TYPE_MEDICAL = 'medical';           // 医疗
export const RECEIPT_TYPE_HOTEL = 'hotel';               // 酒店
export const RECEIPT_TYPE_ONLINE = 'online';             // 网购
export const RECEIPT_TYPE_BANK = 'bank';                 // 银行回单
export const RECEIPT_TYPE_INVOICE = 'invoice';           // 发票
export const RECEIPT_TYPE_UNKNOWN = 'unknown';           // 未知类型

// OCR提供商常量
export const OCR_PROVIDER_HUAWEI_ML_KIT = 'huawei_ml_kit';  // 华为ML Kit
export const OCR_PROVIDER_BAIDU = 'baidu';                  // 百度OCR
export const OCR_PROVIDER_TENCENT = 'tencent';              // 腾讯OCR
export const OCR_PROVIDER_LOCAL = 'local';                  // 本地处理

// 识别状态常量
export const RECOGNITION_STATUS_PENDING = 'pending';           // 待处理
export const RECOGNITION_STATUS_PROCESSING = 'processing';     // 处理中
export const RECOGNITION_STATUS_SUCCESS = 'success';           // 成功
export const RECOGNITION_STATUS_PARTIAL = 'partial';           // 部分成功
export const RECOGNITION_STATUS_FAILED = 'failed';             // 失败

// 置信度等级常量
export const CONFIDENCE_LEVEL_HIGH = 'high';                 // 高置信度 (>0.9)
export const CONFIDENCE_LEVEL_MEDIUM = 'medium';             // 中置信度 (0.7-0.9)
export const CONFIDENCE_LEVEL_LOW = 'low';                   // 低置信度 (0.5-0.7)
export const CONFIDENCE_LEVEL_VERY_LOW = 'very_low';         // 极低置信度 (<0.5)

// 所有票据类型列表
export const ALL_RECEIPT_TYPES: string[] = [
  RECEIPT_TYPE_GENERAL,
  RECEIPT_TYPE_SUPERMARKET,
  RECEIPT_TYPE_RESTAURANT,
  RECEIPT_TYPE_TRANSPORT,
  RECEIPT_TYPE_FUEL,
  RECEIPT_TYPE_MEDICAL,
  RECEIPT_TYPE_HOTEL,
  RECEIPT_TYPE_ONLINE,
  RECEIPT_TYPE_BANK,
  RECEIPT_TYPE_INVOICE,
  RECEIPT_TYPE_UNKNOWN
];

// 所有OCR提供商列表
export const ALL_OCR_PROVIDERS: string[] = [
  OCR_PROVIDER_HUAWEI_ML_KIT,
  OCR_PROVIDER_BAIDU,
  OCR_PROVIDER_TENCENT,
  OCR_PROVIDER_LOCAL
];

// ==================== 接口定义 ====================

/**
 * 边界框接口
 */
export interface BoundingBox {
  left: number;
  top: number;
  width: number;
  height: number;
}

/**
 * 数值字段接口
 */
export interface NumberField {
  value: number;
  rawText: string;
  confidence: number;
  hasBoundingBox: boolean;
  boundingBoxJson: string;
}

/**
 * 字符串字段接口
 */
export interface StringField {
  value: string;
  rawText: string;
  confidence: number;
  hasBoundingBox: boolean;
  boundingBoxJson: string;
}

/**
 * 日期字段接口
 */
export interface DateField {
  value: string;                 // ISO格式日期
  rawText: string;
  confidence: number;
  hasBoundingBox: boolean;
  boundingBoxJson: string;
  format: string;                // 原始格式
}

/**
 * 商品行项目接口
 */
export interface LineItem {
  name: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  confidence: number;
}

/**
 * 实体位置接口
 */
export interface EntityPosition {
  start: number;
  end: number;
}

/**
 * 抽取的实体接口
 */
export interface ExtractedEntity {
  type: string;  // 'amount' | 'date' | 'time' | 'merchant' | 'phone' | 'card' | 'other'
  value: string;
  normalizedValue: string;
  confidence: number;
  position: EntityPosition;
  hasBoundingBox: boolean;
  boundingBoxJson: string;
}

/**
 * 处理步骤接口
 */
export interface ProcessingStep {
  name: string;
  duration: number;              // 耗时(ms)
  success: boolean;
  details: string;
}

/**
 * 处理详情接口
 */
export interface ProcessingDetails {
  imageWidth: number;
  imageHeight: number;
  preprocessingApplied: string[];
  ocrEngine: string;
  ocrVersion: string;
  languageDetected: string;
  processingSteps: ProcessingStep[];
}

/**
 * 建议的账单数据接口
 */
export interface SuggestedBillData {
  amount: number;
  transactionDate: string;
  note: string;
  suggestedCategoryId: number;
  suggestedCategoryName: string;
  type: string;                  // 'expense' | 'income'
  confidence: number;
  needsReview: boolean;
  reviewReasons: string[];
}

/**
 * 结构化票据数据接口
 */
export interface StructuredReceiptData {
  // 核心字段
  totalAmount: NumberField;      // 总金额
  transactionDate: DateField;    // 交易日期
  transactionTime: StringField;  // 交易时间
  merchantName: StringField;     // 商家名称
  merchantAddress: StringField;  // 商家地址
  merchantPhone: StringField;    // 商家电话

  // 支付信息
  paymentMethod: StringField;    // 支付方式
  cardNumber: StringField;       // 卡号(脱敏)
  transactionId: StringField;    // 交易号

  // 商品明细
  lineItems: LineItem[];

  // 税费信息
  subtotal: NumberField;         // 小计
  tax: NumberField;              // 税费
  discount: NumberField;         // 折扣
  tips: NumberField;             // 小费

  // 其他信息
  receiptNumber: StringField;    // 票据号
  cashier: StringField;          // 收银员
  additionalInfo: StringField;   // 其他信息
}

/**
 * OCR识别结果接口
 */
export interface OCRResult {
  rawText: string;               // 原始识别文本
  structuredData: StructuredReceiptData;
  receiptType: string;
  overallConfidence: number;     // 总体置信度
  extractedEntities: ExtractedEntity[];
  suggestedBill: SuggestedBillData;
  processingDetails: ProcessingDetails;
}

/**
 * OCR识别任务接口
 */
export interface OCRTaskJSON {
  taskId: number;
  userId: number;
  imageUri: string;              // 原始图片URI
  thumbnailUri: string;          // 缩略图URI
  provider: string;
  status: string;
  resultJson: string;
  errorMessage: string;
  processingTime: number;        // 处理耗时(ms)
  retryCount: number;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * 图像预处理选项接口
 */
export interface PreprocessingOptions {
  autoRotate: boolean;           // 自动旋转
  deskew: boolean;               // 校正倾斜
  denoise: boolean;              // 降噪
  enhanceContrast: boolean;      // 增强对比度
  binarize: boolean;             // 二值化
  resize: boolean;               // 调整大小
  maxWidth: number;
  maxHeight: number;
}

/**
 * OCR配置接口
 */
export interface OCRConfig {
  provider: string;
  apiKey: string;
  endpoint: string;
  timeout: number;
  maxRetries: number;
  enablePreprocessing: boolean;
  preprocessingOptions: PreprocessingOptions;
}

/**
 * 分类推荐结果接口
 */
export interface CategorySuggestion {
  categoryId: number;
  categoryName: string;
}

// ==================== 类实现 ====================

/**
 * OCR识别任务类
 */
export class OCRTask {
  static readonly tableName: string = 'ocr_tasks';

  taskId: number = 0;
  userId: number = 0;
  imageUri: string = '';
  thumbnailUri: string = '';
  provider: string = OCR_PROVIDER_HUAWEI_ML_KIT;
  status: string = RECOGNITION_STATUS_PENDING;
  resultJson: string = '';
  errorMessage: string = '';
  processingTime: number = 0;
  retryCount: number = 0;
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    taskId: number = 0,
    userId: number = 0,
    imageUri: string = '',
    thumbnailUri: string = '',
    provider: string = OCR_PROVIDER_HUAWEI_ML_KIT,
    status: string = RECOGNITION_STATUS_PENDING,
    resultJson: string = '',
    errorMessage: string = '',
    processingTime: number = 0,
    retryCount: number = 0,
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.taskId = taskId;
    this.userId = userId;
    this.imageUri = imageUri;
    this.thumbnailUri = thumbnailUri;
    this.provider = provider;
    this.status = status;
    this.resultJson = resultJson;
    this.errorMessage = errorMessage;
    this.processingTime = processingTime;
    this.retryCount = retryCount;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  /**
   * 获取识别结果
   */
  getResult(): OCRResult | null {
    if (this.resultJson === '') {
      return null;
    }
    try {
      const parsed = JSON.parse(this.resultJson) as OCRResult;
      return parsed;
    } catch (e) {
      return null;
    }
  }

  /**
   * 设置识别结果
   */
  setResult(result: OCRResult): void {
    this.resultJson = JSON.stringify(result);
    this.status = RECOGNITION_STATUS_SUCCESS;
    this.updatedAt = new Date().toISOString();
  }

  /**
   * 标记为失败
   */
  markFailed(errorMessage: string): void {
    this.status = RECOGNITION_STATUS_FAILED;
    this.errorMessage = errorMessage;
    this.updatedAt = new Date().toISOString();
  }

  /**
   * 标记为处理中
   */
  markProcessing(): void {
    this.status = RECOGNITION_STATUS_PROCESSING;
    this.updatedAt = new Date().toISOString();
  }

  /**
   * 增加重试次数
   */
  incrementRetry(): boolean {
    this.retryCount += 1;
    this.updatedAt = new Date().toISOString();
    return this.retryCount <= 3; // 最多重试3次
  }

  toJSON(): OCRTaskJSON {
    const result: OCRTaskJSON = {
      taskId: this.taskId,
      userId: this.userId,
      imageUri: this.imageUri,
      thumbnailUri: this.thumbnailUri,
      provider: this.provider,
      status: this.status,
      resultJson: this.resultJson,
      errorMessage: this.errorMessage,
      processingTime: this.processingTime,
      retryCount: this.retryCount,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: OCRTaskJSON): OCRTask {
    return new OCRTask(
      data.taskId,
      data.userId,
      data.imageUri,
      data.thumbnailUri,
      data.provider,
      data.status,
      data.resultJson,
      data.errorMessage,
      data.processingTime,
      data.retryCount,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    let validProvider = false;
    for (let i = 0; i < ALL_OCR_PROVIDERS.length; i++) {
      if (ALL_OCR_PROVIDERS[i] === this.provider) {
        validProvider = true;
        break;
      }
    }
    return (
      this.userId > 0 &&
      this.imageUri.trim().length > 0 &&
      validProvider
    );
  }

  clone(): OCRTask {
    return OCRTask.fromJSON(this.toJSON());
  }
}

/**
 * OCR工具类
 *
 * 提供文本解析和实体抽取的静态方法
 */
export class OCRUtils {

  /**
   * 提取金额
   */
  static extractAmount(text: string): NumberField[] {
    const results: NumberField[] = [];
    const seen: number[] = [];

    // 金额模式1: 带关键词
    const pattern1Matches = OCRUtils.matchAmountWithKeyword(text);
    for (let i = 0; i < pattern1Matches.length; i++) {
      const match = pattern1Matches[i];
      let isDuplicate = false;
      for (let j = 0; j < seen.length; j++) {
        if (seen[j] === match.value) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate && match.value > 0) {
        seen.push(match.value);
        results.push(match);
      }
    }

    // 金额模式2: 带货币符号
    const pattern2Matches = OCRUtils.matchAmountWithSymbol(text);
    for (let i = 0; i < pattern2Matches.length; i++) {
      const match = pattern2Matches[i];
      let isDuplicate = false;
      for (let j = 0; j < seen.length; j++) {
        if (seen[j] === match.value) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate && match.value > 0) {
        seen.push(match.value);
        results.push(match);
      }
    }

    // 按置信度排序
    for (let i = 0; i < results.length - 1; i++) {
      for (let j = i + 1; j < results.length; j++) {
        if (results[j].confidence > results[i].confidence) {
          const temp = results[i];
          results[i] = results[j];
          results[j] = temp;
        }
      }
    }

    return results;
  }

  /**
   * 匹配带关键词的金额
   */
  private static matchAmountWithKeyword(text: string): NumberField[] {
    const results: NumberField[] = [];
    const keywords = ['合计', '总计', '实付', '应付', '金额', '总额', 'Total', 'Amount'];

    for (let k = 0; k < keywords.length; k++) {
      const keyword = keywords[k];
      const idx = text.indexOf(keyword);
      if (idx >= 0) {
        // 在关键词后查找数字
        const afterKeyword = text.substring(idx + keyword.length, idx + keyword.length + 20);
        const numMatch = OCRUtils.extractFirstNumber(afterKeyword);
        if (numMatch > 0) {
          const field: NumberField = {
            value: numMatch,
            rawText: keyword + ' ' + numMatch.toString(),
            confidence: 0.85,
            hasBoundingBox: false,
            boundingBoxJson: ''
          };
          results.push(field);
        }
      }
    }

    return results;
  }

  /**
   * 匹配带货币符号的金额
   */
  private static matchAmountWithSymbol(text: string): NumberField[] {
    const results: NumberField[] = [];
    const symbols = ['¥', '￥', '$', '€'];

    for (let s = 0; s < symbols.length; s++) {
      const symbol = symbols[s];
      let searchIdx = 0;
      while (searchIdx < text.length) {
        const idx = text.indexOf(symbol, searchIdx);
        if (idx < 0) {
          break;
        }
        // 在符号后查找数字
        const afterSymbol = text.substring(idx + 1, idx + 15);
        const numMatch = OCRUtils.extractFirstNumber(afterSymbol);
        if (numMatch > 0) {
          const field: NumberField = {
            value: numMatch,
            rawText: symbol + numMatch.toString(),
            confidence: 0.75,
            hasBoundingBox: false,
            boundingBoxJson: ''
          };
          results.push(field);
        }
        searchIdx = idx + 1;
      }
    }

    return results;
  }

  /**
   * 从字符串中提取第一个数字
   */
  private static extractFirstNumber(text: string): number {
    let numStr = '';
    let hasDecimal = false;
    let started = false;

    for (let i = 0; i < text.length; i++) {
      const char = text.charAt(i);
      if (char >= '0' && char <= '9') {
        numStr += char;
        started = true;
      } else if (char === '.' && started && !hasDecimal) {
        numStr += char;
        hasDecimal = true;
      } else if (char === ',' && started) {
        // 跳过千分位逗号
        continue;
      } else if (started) {
        break;
      }
    }

    if (numStr.length > 0) {
      const parsed = parseFloat(numStr);
      if (!isNaN(parsed)) {
        return parsed;
      }
    }
    return 0;
  }

  /**
   * 提取日期
   */
  static extractDate(text: string): DateField[] {
    const results: DateField[] = [];

    // 模式1: YYYY年MM月DD日 或 YYYY-MM-DD 或 YYYY/MM/DD
    const dateMatches = OCRUtils.findDates(text);
    for (let i = 0; i < dateMatches.length; i++) {
      results.push(dateMatches[i]);
    }

    return results;
  }

  /**
   * 查找日期
   */
  private static findDates(text: string): DateField[] {
    const results: DateField[] = [];

    // 查找 YYYY年MM月DD日 格式
    let i = 0;
    while (i < text.length - 10) {
      // 检查是否可能是年份开始
      if (text.charAt(i) >= '1' && text.charAt(i) <= '2') {
        const potentialYear = text.substring(i, i + 4);
        if (OCRUtils.isNumeric(potentialYear)) {
          const year = parseInt(potentialYear);
          if (year >= 2000 && year <= 2100) {
            // 检查后续字符
            const afterYear = text.charAt(i + 4);
            if (afterYear === '年' || afterYear === '-' || afterYear === '/') {
              const dateResult = OCRUtils.parseDateFromPosition(text, i, afterYear);
              if (dateResult !== null) {
                results.push(dateResult);
              }
            }
          }
        }
      }
      i++;
    }

    return results;
  }

  /**
   * 从指定位置解析日期
   */
  private static parseDateFromPosition(text: string, yearStart: number, separator: string): DateField | null {
    const yearStr = text.substring(yearStart, yearStart + 4);
    const year = parseInt(yearStr);

    let monthStart = yearStart + 5; // 跳过年份和分隔符
    if (separator === '年') {
      monthStart = yearStart + 5;
    }

    if (monthStart >= text.length - 2) {
      return null;
    }

    // 提取月份
    let monthStr = '';
    let idx = monthStart;
    while (idx < text.length && text.charAt(idx) >= '0' && text.charAt(idx) <= '9') {
      monthStr += text.charAt(idx);
      idx++;
      if (monthStr.length >= 2) {
        break;
      }
    }

    if (monthStr.length === 0) {
      return null;
    }

    const month = parseInt(monthStr);
    if (month < 1 || month > 12) {
      return null;
    }

    // 跳过月份分隔符
    if (idx < text.length) {
      const monthSep = text.charAt(idx);
      if (monthSep === '月' || monthSep === '-' || monthSep === '/') {
        idx++;
      }
    }

    // 提取日期
    let dayStr = '';
    while (idx < text.length && text.charAt(idx) >= '0' && text.charAt(idx) <= '9') {
      dayStr += text.charAt(idx);
      idx++;
      if (dayStr.length >= 2) {
        break;
      }
    }

    if (dayStr.length === 0) {
      return null;
    }

    const day = parseInt(dayStr);
    if (day < 1 || day > 31) {
      return null;
    }

    // 验证日期有效性
    if (!OCRUtils.isValidDate(year, month, day)) {
      return null;
    }

    const monthPadded = month < 10 ? '0' + month.toString() : month.toString();
    const dayPadded = day < 10 ? '0' + day.toString() : day.toString();
    const isoDate = year.toString() + '-' + monthPadded + '-' + dayPadded;

    let format = 'YYYY-MM-DD';
    if (separator === '年') {
      format = 'YYYY年MM月DD日';
    } else if (separator === '/') {
      format = 'YYYY/MM/DD';
    }

    const result: DateField = {
      value: isoDate,
      rawText: text.substring(yearStart, idx),
      confidence: 0.9,
      hasBoundingBox: false,
      boundingBoxJson: '',
      format: format
    };

    return result;
  }

  /**
   * 检查字符串是否为数字
   */
  private static isNumeric(str: string): boolean {
    for (let i = 0; i < str.length; i++) {
      const char = str.charAt(i);
      if (char < '0' || char > '9') {
        return false;
      }
    }
    return str.length > 0;
  }

  /**
   * 验证日期有效性
   */
  private static isValidDate(year: number, month: number, day: number): boolean {
    if (year < 2000 || year > 2100) {
      return false;
    }
    if (month < 1 || month > 12) {
      return false;
    }
    if (day < 1 || day > 31) {
      return false;
    }

    // 简单的月份天数验证
    const daysInMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    // 闰年判断
    if (month === 2) {
      const isLeap = (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
      if (isLeap && day > 29) {
        return false;
      }
      if (!isLeap && day > 28) {
        return false;
      }
    } else if (day > daysInMonth[month]) {
      return false;
    }

    return true;
  }

  /**
   * 提取商家名称
   */
  static extractMerchant(text: string): StringField[] {
    const results: StringField[] = [];

    // 查找带关键词的商家名称
    const keywords = ['商户', '店名', '商家', '门店'];
    for (let k = 0; k < keywords.length; k++) {
      const keyword = keywords[k];
      const idx = text.indexOf(keyword);
      if (idx >= 0) {
        // 查找冒号后的内容
        let start = idx + keyword.length;
        while (start < text.length && (text.charAt(start) === ':' || text.charAt(start) === '：' || text.charAt(start) === ' ')) {
          start++;
        }
        // 提取到行尾
        let end = start;
        while (end < text.length && text.charAt(end) !== '\n') {
          end++;
        }
        if (end > start) {
          const value = text.substring(start, end).trim();
          if (value.length >= 2 && value.length <= 50) {
            const field: StringField = {
              value: value,
              rawText: text.substring(idx, end),
              confidence: 0.8,
              hasBoundingBox: false,
              boundingBoxJson: ''
            };
            results.push(field);
          }
        }
      }
    }

    // 查找包含常见后缀的商家名称
    const suffixes = ['超市', '商场', '餐厅', '酒店', '药店', '医院', '银行', '公司', '店', '馆', '厅'];
    const lines = text.split('\n');
    for (let l = 0; l < lines.length; l++) {
      const line = lines[l].trim();
      for (let s = 0; s < suffixes.length; s++) {
        const suffix = suffixes[s];
        if (line.indexOf(suffix) > 0 && line.length >= 4 && line.length <= 30) {
          const field: StringField = {
            value: line,
            rawText: line,
            confidence: 0.7,
            hasBoundingBox: false,
            boundingBoxJson: ''
          };
          results.push(field);
          break;
        }
      }
    }

    // 按置信度排序
    for (let i = 0; i < results.length - 1; i++) {
      for (let j = i + 1; j < results.length; j++) {
        if (results[j].confidence > results[i].confidence) {
          const temp = results[i];
          results[i] = results[j];
          results[j] = temp;
        }
      }
    }

    return results;
  }

  /**
   * 识别票据类型
   */
  static detectReceiptType(text: string, merchantName: string): string {
    const lowerText = (text + ' ' + merchantName).toLowerCase();

    // 超市
    const supermarketKeywords = ['超市', '便利店', '华润', '沃尔玛', '永辉', '大润发', 'mart', 'store'];
    for (let i = 0; i < supermarketKeywords.length; i++) {
      if (lowerText.indexOf(supermarketKeywords[i]) >= 0) {
        return RECEIPT_TYPE_SUPERMARKET;
      }
    }

    // 餐饮
    const restaurantKeywords = ['餐厅', '饭店', '美食', '外卖', '饿了么', '美团', 'restaurant', 'food'];
    for (let i = 0; i < restaurantKeywords.length; i++) {
      if (lowerText.indexOf(restaurantKeywords[i]) >= 0) {
        return RECEIPT_TYPE_RESTAURANT;
      }
    }

    // 交通
    const transportKeywords = ['出租', '滴滴', '地铁', '公交', '高铁', '火车', '飞机', 'taxi', 'uber'];
    for (let i = 0; i < transportKeywords.length; i++) {
      if (lowerText.indexOf(transportKeywords[i]) >= 0) {
        return RECEIPT_TYPE_TRANSPORT;
      }
    }

    // 加油
    const fuelKeywords = ['加油', '石油', '石化', '中石油', '中石化', 'gas', 'fuel', 'petrol'];
    for (let i = 0; i < fuelKeywords.length; i++) {
      if (lowerText.indexOf(fuelKeywords[i]) >= 0) {
        return RECEIPT_TYPE_FUEL;
      }
    }

    // 医疗
    const medicalKeywords = ['医院', '药店', '诊所', '药房', 'hospital', 'pharmacy', 'clinic'];
    for (let i = 0; i < medicalKeywords.length; i++) {
      if (lowerText.indexOf(medicalKeywords[i]) >= 0) {
        return RECEIPT_TYPE_MEDICAL;
      }
    }

    // 酒店
    const hotelKeywords = ['酒店', '宾馆', '旅馆', '民宿', 'hotel', 'inn', 'hostel'];
    for (let i = 0; i < hotelKeywords.length; i++) {
      if (lowerText.indexOf(hotelKeywords[i]) >= 0) {
        return RECEIPT_TYPE_HOTEL;
      }
    }

    // 网购
    const onlineKeywords = ['淘宝', '京东', '拼多多', '天猫', '快递', 'online', 'express'];
    for (let i = 0; i < onlineKeywords.length; i++) {
      if (lowerText.indexOf(onlineKeywords[i]) >= 0) {
        return RECEIPT_TYPE_ONLINE;
      }
    }

    // 银行
    const bankKeywords = ['银行', '转账', '汇款', 'bank', 'transfer'];
    for (let i = 0; i < bankKeywords.length; i++) {
      if (lowerText.indexOf(bankKeywords[i]) >= 0) {
        return RECEIPT_TYPE_BANK;
      }
    }

    // 发票
    const invoiceKeywords = ['发票', '增值税', 'invoice', 'vat'];
    for (let i = 0; i < invoiceKeywords.length; i++) {
      if (lowerText.indexOf(invoiceKeywords[i]) >= 0) {
        return RECEIPT_TYPE_INVOICE;
      }
    }

    return RECEIPT_TYPE_GENERAL;
  }

  /**
   * 根据票据类型推荐分类ID
   */
  static suggestCategoryId(receiptType: string): CategorySuggestion {
    if (receiptType === RECEIPT_TYPE_SUPERMARKET) {
      const result: CategorySuggestion = { categoryId: 1, categoryName: '日常购物' };
      return result;
    } else if (receiptType === RECEIPT_TYPE_RESTAURANT) {
      const result: CategorySuggestion = { categoryId: 2, categoryName: '餐饮美食' };
      return result;
    } else if (receiptType === RECEIPT_TYPE_TRANSPORT) {
      const result: CategorySuggestion = { categoryId: 3, categoryName: '交通出行' };
      return result;
    } else if (receiptType === RECEIPT_TYPE_FUEL) {
      const result: CategorySuggestion = { categoryId: 4, categoryName: '汽车加油' };
      return result;
    } else if (receiptType === RECEIPT_TYPE_MEDICAL) {
      const result: CategorySuggestion = { categoryId: 5, categoryName: '医疗健康' };
      return result;
    } else if (receiptType === RECEIPT_TYPE_HOTEL) {
      const result: CategorySuggestion = { categoryId: 6, categoryName: '住宿酒店' };
      return result;
    } else if (receiptType === RECEIPT_TYPE_ONLINE) {
      const result: CategorySuggestion = { categoryId: 7, categoryName: '网上购物' };
      return result;
    } else if (receiptType === RECEIPT_TYPE_BANK) {
      const result: CategorySuggestion = { categoryId: 8, categoryName: '转账汇款' };
      return result;
    }
    const defaultResult: CategorySuggestion = { categoryId: 0, categoryName: '' };
    return defaultResult;
  }

  /**
   * 生成建议账单数据
   */
  static generateSuggestedBill(structuredData: StructuredReceiptData, receiptType: string): SuggestedBillData {
    const category = OCRUtils.suggestCategoryId(receiptType);
    const reviewReasons: string[] = [];

    // 检查需要人工审核的情况
    if (structuredData.totalAmount.confidence < 0.8) {
      reviewReasons.push('金额识别置信度较低');
    }
    if (structuredData.transactionDate.value === '') {
      reviewReasons.push('未能识别交易日期');
    }
    if (structuredData.merchantName.confidence < 0.7) {
      reviewReasons.push('商家名称识别不确定');
    }

    // 生成备注
    let note = '';
    if (structuredData.merchantName.value !== '') {
      note = structuredData.merchantName.value;
    }
    if (structuredData.lineItems.length > 0) {
      const itemNames: string[] = [];
      const maxItems = structuredData.lineItems.length < 3 ? structuredData.lineItems.length : 3;
      for (let i = 0; i < maxItems; i++) {
        itemNames.push(structuredData.lineItems[i].name);
      }
      if (note !== '') {
        note = note + ' - ' + itemNames.join('、');
      } else {
        note = itemNames.join('、');
      }
    }

    // 获取交易日期，如果没有则使用当天
    let transactionDate = structuredData.transactionDate.value;
    if (transactionDate === '') {
      const now = new Date();
      const year = now.getFullYear();
      const month = now.getMonth() + 1;
      const day = now.getDate();
      const monthStr = month < 10 ? '0' + month.toString() : month.toString();
      const dayStr = day < 10 ? '0' + day.toString() : day.toString();
      transactionDate = year.toString() + '-' + monthStr + '-' + dayStr;
    }

    const result: SuggestedBillData = {
      amount: structuredData.totalAmount.value,
      transactionDate: transactionDate,
      note: note,
      suggestedCategoryId: category.categoryId,
      suggestedCategoryName: category.categoryName,
      type: 'expense',
      confidence: OCRUtils.calculateOverallConfidence(structuredData),
      needsReview: reviewReasons.length > 0,
      reviewReasons: reviewReasons
    };

    return result;
  }

  /**
   * 计算总体置信度
   */
  private static calculateOverallConfidence(data: StructuredReceiptData): number {
    const amountWeight = 0.4;
    const dateWeight = 0.3;
    const merchantWeight = 0.3;

    return (
      data.totalAmount.confidence * amountWeight +
      data.transactionDate.confidence * dateWeight +
      data.merchantName.confidence * merchantWeight
    );
  }

  /**
   * 获取置信度等级
   */
  static getConfidenceLevel(confidence: number): string {
    if (confidence >= 0.9) {
      return CONFIDENCE_LEVEL_HIGH;
    } else if (confidence >= 0.7) {
      return CONFIDENCE_LEVEL_MEDIUM;
    } else if (confidence >= 0.5) {
      return CONFIDENCE_LEVEL_LOW;
    }
    return CONFIDENCE_LEVEL_VERY_LOW;
  }

  /**
   * 创建空的数值字段
   */
  static createEmptyNumberField(): NumberField {
    const result: NumberField = {
      value: 0,
      rawText: '',
      confidence: 0,
      hasBoundingBox: false,
      boundingBoxJson: ''
    };
    return result;
  }

  /**
   * 创建空的字符串字段
   */
  static createEmptyStringField(): StringField {
    const result: StringField = {
      value: '',
      rawText: '',
      confidence: 0,
      hasBoundingBox: false,
      boundingBoxJson: ''
    };
    return result;
  }

  /**
   * 创建空的日期字段
   */
  static createEmptyDateField(): DateField {
    const result: DateField = {
      value: '',
      rawText: '',
      confidence: 0,
      hasBoundingBox: false,
      boundingBoxJson: '',
      format: ''
    };
    return result;
  }

  /**
   * 创建空的结构化票据数据
   */
  static createEmptyStructuredData(): StructuredReceiptData {
    const result: StructuredReceiptData = {
      totalAmount: OCRUtils.createEmptyNumberField(),
      transactionDate: OCRUtils.createEmptyDateField(),
      transactionTime: OCRUtils.createEmptyStringField(),
      merchantName: OCRUtils.createEmptyStringField(),
      merchantAddress: OCRUtils.createEmptyStringField(),
      merchantPhone: OCRUtils.createEmptyStringField(),
      paymentMethod: OCRUtils.createEmptyStringField(),
      cardNumber: OCRUtils.createEmptyStringField(),
      transactionId: OCRUtils.createEmptyStringField(),
      lineItems: [],
      subtotal: OCRUtils.createEmptyNumberField(),
      tax: OCRUtils.createEmptyNumberField(),
      discount: OCRUtils.createEmptyNumberField(),
      tips: OCRUtils.createEmptyNumberField(),
      receiptNumber: OCRUtils.createEmptyStringField(),
      cashier: OCRUtils.createEmptyStringField(),
      additionalInfo: OCRUtils.createEmptyStringField()
    };
    return result;
  }

  /**
   * 创建商品行项目
   */
  static createLineItem(
    name: string,
    quantity: number,
    unitPrice: number,
    totalPrice: number,
    confidence: number
  ): LineItem {
    const result: LineItem = {
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      confidence: confidence
    };
    return result;
  }
}

/**
 * 默认OCR配置
 */
export class OCRConfigUtils {
  /**
   * 获取默认配置
   */
  static getDefaultConfig(): OCRConfig {
    const preprocessingOptions: PreprocessingOptions = {
      autoRotate: true,
      deskew: true,
      denoise: true,
      enhanceContrast: true,
      binarize: false,
      resize: true,
      maxWidth: 1920,
      maxHeight: 1920
    };

    const result: OCRConfig = {
      provider: OCR_PROVIDER_HUAWEI_ML_KIT,
      apiKey: '',
      endpoint: '',
      timeout: 30000,
      maxRetries: 3,
      enablePreprocessing: true,
      preprocessingOptions: preprocessingOptions
    };

    return result;
  }

  /**
   * 获取默认预处理选项
   */
  static getDefaultPreprocessingOptions(): PreprocessingOptions {
    const result: PreprocessingOptions = {
      autoRotate: true,
      deskew: true,
      denoise: true,
      enhanceContrast: true,
      binarize: false,
      resize: true,
      maxWidth: 1920,
      maxHeight: 1920
    };
    return result;
  }
}

/**
 * OCR识别记录JSON接口
 */
export interface OCRRecognitionRecordJSON {
  recordId: number;
  userId: number;
  billId: number | null;
  imagePath: string;
  thumbnailPath: string;
  ocrProvider: string;
  receiptType: string;
  rawText: string;
  merchantName: string;
  totalAmount: number | null;
  transactionDate: string;
  confidenceScore: number;
  structuredDataJson: string;
  suggestedCategoryId: number | null;
  suggestedCategoryName: string;
  isUsed: number;
  recognitionStatus: string;
  errorMessage: string;
  processingTimeMs: number;
  createdAt: string;
  updatedAt: string;
  isDeleted: number;
}

/**
 * OCR识别记录类
 */
export class OCRRecognitionRecord {
  static readonly tableName: string = 'ocr_recognition_records';

  recordId: number = 0;
  userId: number = 0;
  billId: number | null = null;
  imagePath: string = '';
  thumbnailPath: string = '';
  ocrProvider: string = OCR_PROVIDER_HUAWEI_ML_KIT;
  receiptType: string = RECEIPT_TYPE_UNKNOWN;
  rawText: string = '';
  merchantName: string = '';
  totalAmount: number | null = null;
  transactionDate: string = '';
  confidenceScore: number = 0;
  structuredDataJson: string = '';
  suggestedCategoryId: number | null = null;
  suggestedCategoryName: string = '';
  isUsed: number = 0;
  recognitionStatus: string = RECOGNITION_STATUS_PENDING;
  errorMessage: string = '';
  processingTimeMs: number = 0;
  createdAt: string = '';
  updatedAt: string = '';
  isDeleted: number = 0;

  constructor(
    recordId: number = 0,
    userId: number = 0,
    billId: number | null = null,
    imagePath: string = '',
    thumbnailPath: string = '',
    ocrProvider: string = OCR_PROVIDER_HUAWEI_ML_KIT,
    receiptType: string = RECEIPT_TYPE_UNKNOWN,
    rawText: string = '',
    merchantName: string = '',
    totalAmount: number | null = null,
    transactionDate: string = '',
    confidenceScore: number = 0,
    structuredDataJson: string = '',
    suggestedCategoryId: number | null = null,
    suggestedCategoryName: string = '',
    isUsed: number = 0,
    recognitionStatus: string = RECOGNITION_STATUS_PENDING,
    errorMessage: string = '',
    processingTimeMs: number = 0,
    createdAt: string = '',
    updatedAt: string = '',
    isDeleted: number = 0
  ) {
    this.recordId = recordId;
    this.userId = userId;
    this.billId = billId;
    this.imagePath = imagePath;
    this.thumbnailPath = thumbnailPath;
    this.ocrProvider = ocrProvider;
    this.receiptType = receiptType;
    this.rawText = rawText;
    this.merchantName = merchantName;
    this.totalAmount = totalAmount;
    this.transactionDate = transactionDate;
    this.confidenceScore = confidenceScore;
    this.structuredDataJson = structuredDataJson;
    this.suggestedCategoryId = suggestedCategoryId;
    this.suggestedCategoryName = suggestedCategoryName;
    this.isUsed = isUsed;
    this.recognitionStatus = recognitionStatus;
    this.errorMessage = errorMessage;
    this.processingTimeMs = processingTimeMs;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.isDeleted = isDeleted;
  }

  /**
   * 获取结构化数据
   */
  getStructuredData(): StructuredReceiptData | null {
    if (this.structuredDataJson === '') {
      return null;
    }
    try {
      const parsed = JSON.parse(this.structuredDataJson) as StructuredReceiptData;
      return parsed;
    } catch (e) {
      return null;
    }
  }

  /**
   * 设置结构化数据
   */
  setStructuredData(data: StructuredReceiptData): void {
    this.structuredDataJson = JSON.stringify(data);
    this.updatedAt = new Date().toISOString();
  }

  /**
   * 标记为已使用
   */
  markAsUsed(billId: number): void {
    this.isUsed = 1;
    this.billId = billId;
    this.updatedAt = new Date().toISOString();
  }

  /**
   * 标记为失败
   */
  markFailed(errorMessage: string): void {
    this.recognitionStatus = RECOGNITION_STATUS_FAILED;
    this.errorMessage = errorMessage;
    this.updatedAt = new Date().toISOString();
  }

  /**
   * 标记为成功
   */
  markSuccess(): void {
    this.recognitionStatus = RECOGNITION_STATUS_SUCCESS;
    this.errorMessage = '';
    this.updatedAt = new Date().toISOString();
  }

  toJSON(): OCRRecognitionRecordJSON {
    const result: OCRRecognitionRecordJSON = {
      recordId: this.recordId,
      userId: this.userId,
      billId: this.billId,
      imagePath: this.imagePath,
      thumbnailPath: this.thumbnailPath,
      ocrProvider: this.ocrProvider,
      receiptType: this.receiptType,
      rawText: this.rawText,
      merchantName: this.merchantName,
      totalAmount: this.totalAmount,
      transactionDate: this.transactionDate,
      confidenceScore: this.confidenceScore,
      structuredDataJson: this.structuredDataJson,
      suggestedCategoryId: this.suggestedCategoryId,
      suggestedCategoryName: this.suggestedCategoryName,
      isUsed: this.isUsed,
      recognitionStatus: this.recognitionStatus,
      errorMessage: this.errorMessage,
      processingTimeMs: this.processingTimeMs,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      isDeleted: this.isDeleted
    };
    return result;
  }

  static fromJSON(data: OCRRecognitionRecordJSON): OCRRecognitionRecord {
    return new OCRRecognitionRecord(
      data.recordId,
      data.userId,
      data.billId,
      data.imagePath,
      data.thumbnailPath,
      data.ocrProvider,
      data.receiptType,
      data.rawText,
      data.merchantName,
      data.totalAmount,
      data.transactionDate,
      data.confidenceScore,
      data.structuredDataJson,
      data.suggestedCategoryId,
      data.suggestedCategoryName,
      data.isUsed,
      data.recognitionStatus,
      data.errorMessage,
      data.processingTimeMs,
      data.createdAt,
      data.updatedAt,
      data.isDeleted
    );
  }

  validate(): boolean {
    // 验证必填字段
    if (this.userId <= 0) {
      return false;
    }
    if (this.imagePath.trim().length === 0) {
      return false;
    }

    // 验证OCR提供商
    let validProvider = false;
    for (let i = 0; i < ALL_OCR_PROVIDERS.length; i++) {
      if (ALL_OCR_PROVIDERS[i] === this.ocrProvider) {
        validProvider = true;
        break;
      }
    }
    if (!validProvider) {
      return false;
    }

    // 验证票据类型
    let validReceiptType = false;
    for (let i = 0; i < ALL_RECEIPT_TYPES.length; i++) {
      if (ALL_RECEIPT_TYPES[i] === this.receiptType) {
        validReceiptType = true;
        break;
      }
    }
    if (!validReceiptType) {
      return false;
    }

    // 验证置信度分数范围
    if (this.confidenceScore < 0 || this.confidenceScore > 1) {
      return false;
    }

    return true;
  }

  clone(): OCRRecognitionRecord {
    return OCRRecognitionRecord.fromJSON(this.toJSON());
  }
}
