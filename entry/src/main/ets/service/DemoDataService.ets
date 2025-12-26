import { UserSessionService } from './UserSessionService';
import { AccountDAO } from '../dao/AccountDAO';
import { CategoryDAO } from '../dao/CategoryDAO';
import { BillDAO } from '../dao/BillDAO';
import { BudgetDAO } from '../dao/BudgetDAO';
import { Account } from '../model/Account';
import { Bill } from '../model/Bill';
import { Budget } from '../model/Budget';
import { Category } from '../model/Category';

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
