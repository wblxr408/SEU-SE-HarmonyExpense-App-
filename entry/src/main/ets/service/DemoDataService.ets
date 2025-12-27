import { UserSessionService } from './UserSessionService';
import { AccountDAO } from '../dao/AccountDAO';
import { CategoryDAO } from '../dao/CategoryDAO';
import { BillDAO } from '../dao/BillDAO';
import { BudgetDAO } from '../dao/BudgetDAO';
import { TagDAO } from '../dao/TagDAO';
import { ReminderDAO } from '../dao/ReminderDAO';
import { SmartCategoryRuleDAO } from '../dao/SmartCategoryDAO';
import { AnomalyRecordDAO, UserSpendingBaselineDAO } from '../dao/AnomalyDetectionDAO';
import { NotificationDAO } from '../dao/NotificationDAO';
import { Account } from '../model/Account';
import { Bill } from '../model/Bill';
import { Budget } from '../model/Budget';
import { Category } from '../model/Category';
import { Tag } from '../model/Tag';
import { Reminder } from '../model/Reminder';
import { SmartCategoryRule } from '../model/SmartCategory';
import { AnomalyRecord, UserSpendingBaseline, ANOMALY_TYPE_HIGH_AMOUNT, SEVERITY_MEDIUM, ALGORITHM_Z_SCORE } from '../model/AnomalyDetection';
import { Notification, NotificationType } from '../model/Notification';

/**
 * 演示数据服务
 * 用于一键生成演示用户及数据
 */
export class DemoDataService {
  static readonly DEMO_EMAIL = 'demo@example.com';
  static readonly DEMO_PASS = 'demo123';
  static readonly DEMO_NAME = '演示用户';

  /**
   * 设置演示用户（登录或注册，并填充数据）
   */
  static async setupDemoUser(): Promise<boolean> {
    try {
      // 1. 尝试登录
      let result = await UserSessionService.login(DemoDataService.DEMO_EMAIL, DemoDataService.DEMO_PASS);
      
      // 2. 如果登录失败（用户不存在），则注册
      if (!result.success) {
        console.info('[DemoDataService] 演示用户不存在，正在注册...');
        result = await UserSessionService.register(DemoDataService.DEMO_NAME, DemoDataService.DEMO_EMAIL, DemoDataService.DEMO_PASS);
      }

      if (!result.success || !result.session) {
        console.error('[DemoDataService] 无法创建或登录演示用户');
        return false;
      }

      const userId = result.session.userId;
      console.info(`[DemoDataService] 演示用户 ID: ${userId}`);

      // 3. 检查数据是否充足，不足则补充
      const bills = await BillDAO.getByUserId(userId);
      if (bills.length < 20) {
        console.info('[DemoDataService] 检测到演示数据不足，开始生成...');
        await DemoDataService.seedData(userId);
      } else {
        console.info('[DemoDataService] 演示数据已存在，跳过生成');
      }

      // 4. 独立检查共享账本数据 (无论是否有常规账单)
      await DemoDataService.seedSharedLedger(userId);

      return true;
    } catch (e) {
      console.error('[DemoDataService] 设置演示用户失败: ', e);
      return false;
    }
  }

  /**
   * 填充演示数据
   */
  private static async seedData(userId: number) {
    // 1. 确保有分类
    let categories = await CategoryDAO.getAll(userId);
    if (categories.length < 5) {
      await DemoDataService.seedCategories(userId);
      categories = await CategoryDAO.getAll(userId); // 重新获取
    }

    // 2. 确保有账户
    let accounts = await AccountDAO.getByUserId(userId);
    if (accounts.length === 0) {
      const acc1 = new Account(0, userId, '钱包现金', 'cash', 2000, '#FF5722');
      const acc2 = new Account(0, userId, '招商银行', 'bank', 15000, '#E91E63');
      await AccountDAO.insert(acc1);
      await AccountDAO.insert(acc2);
      accounts = await AccountDAO.getByUserId(userId);
    }

    // 映射分类 ID 用于生成账单
    const expenseCats = categories.filter(c => c.type === 'expense');
    const incomeCats = categories.filter(c => c.type === 'income');
    const mainAccount = accounts[0];

    // 3. 生成过去 6 个月的账单
    const now = new Date();
    const bills: Bill[] = [];
    
    // 模拟 6 个月数据
    for (let i = 5; i >= 0; i--) {
       const year = now.getFullYear();
       const month = now.getMonth() - i; 
       // 处理年份回退
       const dateBase = new Date(year, month, 1);
       const daysInMonth = new Date(year, month + 1, 0).getDate();

       // 每月固定收入
       if (incomeCats.length > 0) {
         DemoDataService.addBill(bills, userId, mainAccount.accountId, incomeCats[0].categoryId, 9000, 'income', dateBase, 15, '工资收入');
       }

       // 随机支出生成
       // 餐饮：每月 20-30 笔
       DemoDataService.generateRandomBills(bills, userId, mainAccount.accountId, DemoDataService.findCatId(expenseCats, '餐饮'), 'expense', dateBase, daysInMonth, 20, 20, 100, '午餐/晚餐');
       
       // 交通：每月 10-15 笔
       DemoDataService.generateRandomBills(bills, userId, mainAccount.accountId, DemoDataService.findCatId(expenseCats, '交通'), 'expense', dateBase, daysInMonth, 10, 5, 50, '地铁/打车');

       // 购物：每月 3-5 笔
       DemoDataService.generateRandomBills(bills, userId, mainAccount.accountId, DemoDataService.findCatId(expenseCats, '购物'), 'expense', dateBase, daysInMonth, 4, 100, 800, '生活用品');

       // 住房：固定每月 1 号
       DemoDataService.addBill(bills, userId, mainAccount.accountId, DemoDataService.findCatId(expenseCats, '居住'), 2800, 'expense', dateBase, 1, '房租');
    }

    // 批量插入账单 (BillDAO没有批量插入，循环插入)
    //为了性能，这里我们简单循环插入，实际项目可以用批量接口
    for (const b of bills) {
      await BillDAO.insert(b);
    }

    // 5. 设置预算 (基于当前月份)
    const existingBudgets = await BudgetDAO.getByUserId(userId);
    if (existingBudgets.length === 0) {
      await DemoDataService.seedBudgets(userId, expenseCats);
    }

    // 6. 生成标签数据
    await DemoDataService.seedTags(userId);

    // 7. 生成提醒数据
    await DemoDataService.seedReminders(userId, categories);

    // 8. 生成智能分类规则数据
    await DemoDataService.seedSmartCategoryRules(userId, categories);

    // 9. 生成异常检测数据
    await DemoDataService.seedAnomalyData(userId, categories);

    // 10. 生成通知演示数据
    await DemoDataService.seedNotifications(userId);
  }

  private static findCatId(cats: Category[], keyword: string): number {
    const found = cats.find(c => c.name.includes(keyword));
    return found ? found.categoryId : (cats[0] ? cats[0].categoryId : 0);
  }

  private static generateRandomBills(list: Bill[], userId: number, accountId: number, catId: number, type: 'expense'|'income', baseDate: Date, maxDay: number, count: number, minAmt: number, maxAmt: number, notePrefix: string) {
    if (catId === 0) return;
    for (let k = 0; k < count; k++) {
      const day = Math.floor(Math.random() * maxDay) + 1;
      const amount = Math.floor(Math.random() * (maxAmt - minAmt)) + minAmt;
      DemoDataService.addBill(list, userId, accountId, catId, amount, type, baseDate, day, `${notePrefix} ${k+1}`);
    }
  }

  private static addBill(list: Bill[], userId: number, accountId: number, catId: number, amount: number, type: 'expense'|'income', baseDate: Date, day: number, note: string) {
    const d = new Date(baseDate.getFullYear(), baseDate.getMonth(), day);
    // Add random hour
    d.setHours(Math.floor(Math.random() * 24), Math.floor(Math.random() * 60));
    
    const b = new Bill();
    b.userId = userId;
    b.accountId = accountId;
    b.categoryId = catId;
    b.amount = amount;
    b.type = type;
    b.transactionDate = d.toISOString(); // Use ISO format
    b.note = note;
    
    list.push(b);
  }

  private static async seedCategories(userId: number) {
    const defaultCats: DemoCategoryConfig[] = [
      { name: '餐饮', type: 'expense', icon: 'app.media.ic_type_canyin', color: '#F44336' },
      { name: '交通', type: 'expense', icon: 'app.media.ic_type_jiaotong', color: '#2196F3' },
      { name: '购物', type: 'expense', icon: 'app.media.ic_type_gouwu', color: '#E91E63' },
      { name: '居住', type: 'expense', icon: 'app.media.ic_type_juzhu', color: '#FF9800' },
      { name: '娱乐', type: 'expense', icon: 'app.media.ic_type_yule', color: '#9C27B0' },
      { name: '医疗', type: 'expense', icon: 'app.media.ic_type_yiliao', color: '#00BCD4' },
      { name: '工资', type: 'income', icon: 'app.media.ic_type_gongzi', color: '#4CAF50' },
      { name: '奖金', type: 'income', icon: 'app.media.ic_type_jiangjin', color: '#8BC34A' },
    ];

    for (const c of defaultCats) {
      const cat = new Category();
      cat.userId = userId;
      cat.name = c.name;
      cat.type = c.type as 'expense' | 'income';
      cat.icon = c.icon;
      cat.color = c.color;
      cat.sortOrder = 0;
      await CategoryDAO.insert(cat);
    }
  }

  private static async seedBudgets(userId: number, cats: Category[]) {
    // 餐饮预算
    const foodId = DemoDataService.findCatId(cats, '餐饮');
    if (foodId) await DemoDataService.addBudget(userId, foodId, 2000);
    
    // 交通预算
    const transId = DemoDataService.findCatId(cats, '交通');
    if (transId) await DemoDataService.addBudget(userId, transId, 500);
    
    // 购物预算
    const shopId = DemoDataService.findCatId(cats, '购物');
    if (shopId) await DemoDataService.addBudget(userId, shopId, 1500);
  }

  private static async addBudget(userId: number, catId: number, amount: number) {
      const b = new Budget();
      b.userId = userId;
      b.categoryId = catId;
      b.amount = amount;
      b.period = 'monthly';
      const now = new Date();
      b.startDate = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
      await BudgetDAO.insert(b);
  }

  // ---------------- Tags Seeding ----------------
  private static async seedTags(userId: number) {
    try {
      const existingTags = await TagDAO.getAll(userId);
      if (existingTags.length > 0) {
        console.info('[DemoDataService] 标签数据已存在，跳过生成');
        return;
      }

      const tagNames: string[] = ['日常', '工作', '娱乐', '紧急', '报销', '固定支出'];
      const tagColors: string[] = ['#4CAF50', '#2196F3', '#9C27B0', '#F44336', '#FF9800', '#607D8B'];
      
      for (let i = 0; i < tagNames.length; i++) {
        const tag = new Tag();
        tag.userId = userId;
        tag.name = tagNames[i];
        tag.color = tagColors[i];
        tag.usageCount = Math.floor(Math.random() * 20);
        await TagDAO.insert(tag);
      }



      console.info('[DemoDataService] 标签演示数据生成完成');
    } catch (e) {
      console.error('[DemoDataService] 生成标签数据失败');
    }
  }

  // ---------------- Reminders Seeding ----------------
  private static async seedReminders(userId: number, categories: Category[]) {
    try {
      const existingReminders = await ReminderDAO.getByUserId(userId);
      if (existingReminders.length > 0) {
        console.info('[DemoDataService] 提醒数据已存在，跳过生成');
        return;
      }

      const now = new Date();
      const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

      // 房租提醒 - 每月1号
      const rentReminder = new Reminder();
      rentReminder.userId = userId;
      rentReminder.type = 'bill';
      rentReminder.title = '缴纳房租';
      rentReminder.description = '每月1号记得缴纳房租';
      rentReminder.frequency = 'monthly';
      rentReminder.amount = 2800;
      rentReminder.reminderDate = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
      rentReminder.nextReminderDate = nextMonth.toISOString();
      rentReminder.isActive = 1;
      const housingCat = categories.find(c => c.name.includes('居住'));
      if (housingCat) {
        rentReminder.categoryId = housingCat.categoryId;
      }
      await ReminderDAO.insert(rentReminder);

      // 工资入账提醒 - 每月15号
      const salaryReminder = new Reminder();
      salaryReminder.userId = userId;
      salaryReminder.type = 'bill';
      salaryReminder.title = '工资入账';
      salaryReminder.description = '每月15号查看工资是否到账';
      salaryReminder.frequency = 'monthly';
      salaryReminder.amount = 9000;
      salaryReminder.reminderDate = new Date(now.getFullYear(), now.getMonth(), 15).toISOString();
      salaryReminder.nextReminderDate = new Date(now.getFullYear(), now.getMonth() + 1, 15).toISOString();
      salaryReminder.isActive = 1;
      const salaryCat = categories.find(c => c.name.includes('工资'));
      if (salaryCat) {
        salaryReminder.categoryId = salaryCat.categoryId;
      }
      await ReminderDAO.insert(salaryReminder);

      // 信用卡还款提醒 - 每月20号
      const creditCardReminder = new Reminder();
      creditCardReminder.userId = userId;
      creditCardReminder.type = 'bill';
      creditCardReminder.title = '信用卡还款';
      creditCardReminder.description = '每月20号前记得还信用卡';
      creditCardReminder.frequency = 'monthly';
      creditCardReminder.reminderDate = new Date(now.getFullYear(), now.getMonth(), 20).toISOString();
      creditCardReminder.nextReminderDate = new Date(now.getFullYear(), now.getMonth() + 1, 20).toISOString();
      creditCardReminder.isActive = 1;
      await ReminderDAO.insert(creditCardReminder);

      console.info('[DemoDataService] 提醒演示数据生成完成');
    } catch (e) {
      console.error('[DemoDataService] 生成提醒数据失败');
    }
  }

  // ---------------- Smart Category Rules Seeding ----------------
  private static async seedSmartCategoryRules(userId: number, categories: Category[]) {
    try {
      const existingRules = await SmartCategoryRuleDAO.getByUserId(userId);
      if (existingRules.length > 0) {
        console.info('[DemoDataService] 智能分类规则已存在，跳过生成');
        return;
      }

      const foodCat = categories.find(c => c.name.includes('餐饮'));
      const transCat = categories.find(c => c.name.includes('交通'));
      const shopCat = categories.find(c => c.name.includes('购物'));

      // 餐饮关键词规则
      if (foodCat) {
        const foodRule = new SmartCategoryRule();
        foodRule.userId = userId;
        foodRule.ruleName = '外卖平台识别';
        foodRule.categoryId = foodCat.categoryId;
        foodRule.categoryName = foodCat.name;
        foodRule.ruleType = 'keyword';
        foodRule.keywords = '美团,饿了么,肯德基,麦当劳,星巴克,瑞幸';
        foodRule.priority = 100;
        foodRule.isActive = 1;
        foodRule.accuracy = 0.95;
        foodRule.matchCount = 45;
        await SmartCategoryRuleDAO.insert(foodRule);
      }

      // 交通关键词规则
      if (transCat) {
        const transRule = new SmartCategoryRule();
        transRule.userId = userId;
        transRule.ruleName = '出行平台识别';
        transRule.categoryId = transCat.categoryId;
        transRule.categoryName = transCat.name;
        transRule.ruleType = 'keyword';
        transRule.keywords = '滴滴,高德,嘀嗒,地铁,公交,加油';
        transRule.priority = 100;
        transRule.isActive = 1;
        transRule.accuracy = 0.92;
        transRule.matchCount = 28;
        await SmartCategoryRuleDAO.insert(transRule);
      }

      // 购物关键词规则
      if (shopCat) {
        const shopRule = new SmartCategoryRule();
        shopRule.userId = userId;
        shopRule.ruleName = '电商平台识别';
        shopRule.categoryId = shopCat.categoryId;
        shopRule.categoryName = shopCat.name;
        shopRule.ruleType = 'keyword';
        shopRule.keywords = '淘宝,京东,拼多多,天猫,苏宁,唯品会';
        shopRule.priority = 100;
        shopRule.isActive = 1;
        shopRule.accuracy = 0.88;
        shopRule.matchCount = 35;
        await SmartCategoryRuleDAO.insert(shopRule);

        // 购物金额范围规则
        const shopAmountRule = new SmartCategoryRule();
        shopAmountRule.userId = userId;
        shopAmountRule.ruleName = '购物金额范围';
        shopAmountRule.categoryId = shopCat.categoryId;
        shopAmountRule.categoryName = shopCat.name;
        shopAmountRule.ruleType = 'amount';
        shopAmountRule.amountMin = 100;
        shopAmountRule.amountMax = 2000;
        shopAmountRule.priority = 50;
        shopAmountRule.isActive = 1;
        shopAmountRule.accuracy = 0.75;
        shopAmountRule.matchCount = 20;
        await SmartCategoryRuleDAO.insert(shopAmountRule);
      }

      console.info('[DemoDataService] 智能分类规则演示数据生成完成');
    } catch (e) {
      console.error('[DemoDataService] 生成智能分类规则失败');
    }
  }

  // ---------------- Anomaly Detection Data Seeding ----------------
  private static async seedAnomalyData(userId: number, categories: Category[]) {
    try {
      const existingBaselines = await UserSpendingBaselineDAO.getAllByUser(userId);
      if (existingBaselines.length > 0) {
        console.info('[DemoDataService] 异常检测数据已存在，跳过生成');
        return;
      }

      const now = new Date();
      const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 6, 1);

      // 为餐饮分类创建消费基线
      const foodCat = categories.find(c => c.name.includes('餐饮'));
      if (foodCat) {
        const foodBaseline = new UserSpendingBaseline();
        foodBaseline.userId = userId;
        foodBaseline.categoryId = foodCat.categoryId;
        foodBaseline.period = 'monthly';
        foodBaseline.mean = 1500;
        foodBaseline.median = 1400;
        foodBaseline.stdDev = 300;
        foodBaseline.variance = 90000;
        foodBaseline.min = 800;
        foodBaseline.max = 2200;
        foodBaseline.q1 = 1200;
        foodBaseline.q3 = 1800;
        foodBaseline.iqr = 600;
        foodBaseline.sampleSize = 120;
        foodBaseline.sampleStartDate = sixMonthsAgo.toISOString();
        foodBaseline.sampleEndDate = now.toISOString();
        await UserSpendingBaselineDAO.upsert(foodBaseline);
      }

      // 为交通分类创建消费基线
      const transCat = categories.find(c => c.name.includes('交通'));
      if (transCat) {
        const transBaseline = new UserSpendingBaseline();
        transBaseline.userId = userId;
        transBaseline.categoryId = transCat.categoryId;
        transBaseline.period = 'monthly';
        transBaseline.mean = 350;
        transBaseline.median = 300;
        transBaseline.stdDev = 100;
        transBaseline.variance = 10000;
        transBaseline.min = 150;
        transBaseline.max = 600;
        transBaseline.q1 = 250;
        transBaseline.q3 = 450;
        transBaseline.iqr = 200;
        transBaseline.sampleSize = 60;
        transBaseline.sampleStartDate = sixMonthsAgo.toISOString();
        transBaseline.sampleEndDate = now.toISOString();
        await UserSpendingBaselineDAO.upsert(transBaseline);
      }

      // 创建一条示例异常记录（用于展示功能）
      const anomalyRecord = new AnomalyRecord();
      anomalyRecord.userId = userId;
      anomalyRecord.billId = 0; // 示例记录
      anomalyRecord.anomalyType = ANOMALY_TYPE_HIGH_AMOUNT;
      anomalyRecord.severity = SEVERITY_MEDIUM;
      anomalyRecord.algorithm = ALGORITHM_Z_SCORE;
      anomalyRecord.score = 2.8;
      anomalyRecord.threshold = 2.5;
      anomalyRecord.expectedValue = 50;
      anomalyRecord.actualValue = 180;
      anomalyRecord.deviation = 130;
      anomalyRecord.description = '检测到异常高额消费：餐饮消费 ¥180 超出日常平均水平';
      anomalyRecord.isAcknowledged = 0;
      await AnomalyRecordDAO.insert(anomalyRecord);

      console.info('[DemoDataService] 异常检测演示数据生成完成');
    } catch (e) {
      console.error('[DemoDataService] 生成异常检测数据失败');
    }
  }

  // ---------------- Notifications Seeding ----------------
  private static async seedNotifications(userId: number) {
    try {
      const existingNotifications = await NotificationDAO.getByUserId(userId, 1);
      if (existingNotifications.length > 0) {
        console.info('[DemoDataService] 通知数据已存在，跳过生成');
        return;
      }

      const now = new Date();

      // 系统通知
      const systemNotification1 = new Notification();
      systemNotification1.userId = userId;
      systemNotification1.type = NotificationType.SYSTEM;
      systemNotification1.title = '欢迎使用随手记';
      systemNotification1.content = '感谢您使用随手记！我们致力于帮助您更好地管理个人财务，养成良好的记账习惯。';
      systemNotification1.isRead = 1;
      await NotificationDAO.insert(systemNotification1);

      const systemNotification2 = new Notification();
      systemNotification2.userId = userId;
      systemNotification2.type = NotificationType.SYSTEM;
      systemNotification2.title = '新功能上线通知';
      systemNotification2.content = '智能预算分析功能已上线！现在可以根据您的消费习惯，获取个性化的预算建议。';
      systemNotification2.isRead = 0;
      await NotificationDAO.insert(systemNotification2);

      const systemNotification3 = new Notification();
      systemNotification3.userId = userId;
      systemNotification3.type = NotificationType.SYSTEM;
      systemNotification3.title = '版本更新';
      systemNotification3.content = 'V2.0版本已发布，新增共享账本、OCR识别等功能，快去体验吧！';
      systemNotification3.isRead = 0;
      await NotificationDAO.insert(systemNotification3);

      // 预算警报
      const budgetAlert1 = new Notification();
      budgetAlert1.userId = userId;
      budgetAlert1.type = NotificationType.BUDGET_ALERT;
      budgetAlert1.title = '餐饮预算即将超支';
      budgetAlert1.content = '本月餐饮支出已达到预算的85%（¥1,700/¥2,000），请注意控制消费。';
      budgetAlert1.isRead = 0;
      await NotificationDAO.insert(budgetAlert1);

      const budgetAlert2 = new Notification();
      budgetAlert2.userId = userId;
      budgetAlert2.type = NotificationType.BUDGET_ALERT;
      budgetAlert2.title = '购物预算已超支';
      budgetAlert2.content = '本月购物支出已超出预算 ¥200（实际¥1,700 / 预算¥1,500），建议减少非必要消费。';
      budgetAlert2.isRead = 0;
      await NotificationDAO.insert(budgetAlert2);

      const budgetAlert3 = new Notification();
      budgetAlert3.userId = userId;
      budgetAlert3.type = NotificationType.BUDGET_ALERT;
      budgetAlert3.title = '月度预算执行良好';
      budgetAlert3.content = '恭喜！本月整体支出控制在预算范围内，继续保持良好的消费习惯。';
      budgetAlert3.isRead = 1;
      await NotificationDAO.insert(budgetAlert3);

      // 同步状态
      const syncNotification1 = new Notification();
      syncNotification1.userId = userId;
      syncNotification1.type = NotificationType.SYNC_STATUS;
      syncNotification1.title = '数据同步完成';
      syncNotification1.content = '您的账单数据已成功同步到云端，共同步 156 条记录。';
      syncNotification1.isRead = 1;
      await NotificationDAO.insert(syncNotification1);

      const syncNotification2 = new Notification();
      syncNotification2.userId = userId;
      syncNotification2.type = NotificationType.SYNC_STATUS;
      syncNotification2.title = '共享账本更新';
      syncNotification2.content = '"家庭账本"有新的账单记录：亲爱的 添加了一笔 ¥320 的支出。';
      syncNotification2.isRead = 0;
      await NotificationDAO.insert(syncNotification2);

      // 提醒通知
      const reminder1 = new Notification();
      reminder1.userId = userId;
      reminder1.type = NotificationType.REMINDER;
      reminder1.title = '信用卡还款提醒';
      reminder1.content = '您的信用卡还款日为本月20号，请确保账户余额充足。';
      reminder1.isRead = 0;
      await NotificationDAO.insert(reminder1);

      const reminder2 = new Notification();
      reminder2.userId = userId;
      reminder2.type = NotificationType.REMINDER;
      reminder2.title = '房租缴费提醒';
      reminder2.content = '下个月1号是房租缴费日，金额：¥2,800。';
      reminder2.isRead = 0;
      await NotificationDAO.insert(reminder2);

      const reminder3 = new Notification();
      reminder3.userId = userId;
      reminder3.type = NotificationType.REMINDER;
      reminder3.title = '别忘记记账';
      reminder3.content = '今天还没有记账哦，点击记录今日消费，保持良好的记账习惯！';
      reminder3.isRead = 0;
      await NotificationDAO.insert(reminder3);

      const reminder4 = new Notification();
      reminder4.userId = userId;
      reminder4.type = NotificationType.REMINDER;
      reminder4.title = '月度报告已生成';
      reminder4.content = '您的11月消费报告已生成，总支出 ¥5,680，点击查看详细分析。';
      reminder4.isRead = 1;
      await NotificationDAO.insert(reminder4);

      console.info('[DemoDataService] 通知演示数据生成完成');
    } catch (e) {
      console.error('[DemoDataService] 生成通知数据失败');
    }
  }

  // ---------------- Shared Ledger Seeding ----------------
  private static async seedSharedLedger(userId: number) {
    const daoModule = await import('../dao/SharedLedgerDAO');
    const SharedLedgerDAO = daoModule.SharedLedgerDAO;
    const LedgerMemberDAO = daoModule.LedgerMemberDAO;
    const SharedBillDAO = daoModule.SharedBillDAO;

    const ledgers = await SharedLedgerDAO.getByUserId(userId);
    if (ledgers.length > 0) return;

    // 1. Create a Shared Ledger
    const ledger = new (await import('../model/SharedLedger')).SharedLedger();
    ledger.name = '家庭账本';
    ledger.type = 'family';
    ledger.ownerId = userId;
    ledger.ownerName = DemoDataService.DEMO_NAME;
    ledger.description = '一家人的日常开销';
    ledger.color = '#4CAF50';
    ledger.createdAt = new Date().toISOString();
    
    // SharedLedgerDAO.insert returns number|void, assuming number as per code viewing
    const ledgerId = await SharedLedgerDAO.insert(ledger);

    // 2. Add Owner as Member
    const LedgerMember = (await import('../model/SharedLedger')).LedgerMember;
    const ownerMember = new LedgerMember();
    ownerMember.ledgerId = ledgerId;
    ownerMember.userId = userId;
    ownerMember.role = 'owner';
    ownerMember.username = DemoDataService.DEMO_NAME;
    ownerMember.joinedAt = new Date().toISOString();
    // Correct method: LedgerMemberDAO.insert
    await LedgerMemberDAO.insert(ownerMember);

    // 3. Add a Demo Partner
    const partnerId = 9999; // Dummy ID for partner
    const partnerMember = new LedgerMember();
    partnerMember.ledgerId = ledgerId;
    partnerMember.userId = partnerId;
    partnerMember.role = 'editor'; // Note: Check 'editor' is valid role, default usually 'member', 'admin', 'owner'
    // In SharedLedger.ets: ALL_MEMBER_ROLES = ['owner', 'admin', 'member', 'viewer']
    // 'editor' is not in the list. I should use 'member' or 'admin'. Let's use 'member' with permissions. 
    // Or check if 'editor' was valid in previous context? 'admin' seems safer.
    partnerMember.role = 'member'; 
    partnerMember.username = '亲爱的';
    partnerMember.joinedAt = new Date().toISOString();
    await LedgerMemberDAO.insert(partnerMember);

    // 4. Add Shared Bills
    const SharedBill = (await import('../model/SharedLedger')).SharedBill;
    const now = new Date();
    
    // Bill 1: Supermarket (Owner paid 258.50)
    // Split: Owner 129.25, Partner 129.25
    const b1 = new SharedBill();
    b1.ledgerId = ledgerId;
    b1.creatorId = userId;
    b1.creatorName = DemoDataService.DEMO_NAME;
    b1.amount = 258.50;
    b1.type = 'expense';
    b1.note = '周末超市采购 (AA)';
    b1.transactionDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 2).toISOString();
    b1.splitMethod = 'equal';
    b1.splitsJson = JSON.stringify([
      { memberId: userId, amount: 129.25, percentage: 50 },
      { memberId: partnerId, amount: 129.25, percentage: 50 }
    ]);
    // Correct method: SharedBillDAO.insert
    await SharedBillDAO.insert(b1);

    // Bill 2: Dinner (Partner paid 320.00)
    // Split: Owner 160.00, Partner 160.00
    const b2 = new SharedBill();
    b2.ledgerId = ledgerId;
    b2.creatorId = partnerId;
    b2.creatorName = '亲爱的';
    b2.amount = 320.00;
    b2.type = 'expense';
    b2.note = '纪念日晚餐 (AA)';
    b2.transactionDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 5).toISOString();
    b2.splitMethod = 'equal';
    b2.splitsJson = JSON.stringify([
      { memberId: userId, amount: 160.00, percentage: 50 },
      { memberId: partnerId, amount: 160.00, percentage: 50 }
    ]);
    await SharedBillDAO.insert(b2);
  }
}

interface DemoCategoryConfig {
  name: string;
  type: string;
  icon: string;
  color: string;
}
