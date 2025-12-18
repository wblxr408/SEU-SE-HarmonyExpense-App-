import router from '@ohos.router'
import { Bill } from '../model/Bill'
import { BillDAO } from '../dao/BillDAO'
// 2. 导入 promptAction 用于显示 Toast 提示
import { promptAction } from '@kit.ArkUI';
import type { BusinessError } from '@ohos.base';
import { Account } from '../model/Account' //
import { AccountDAO } from '../dao/AccountDAO' //
import { Category } from '../model/Category' //
import { CategoryDAO } from '../dao/CategoryDAO' //
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BreakPointType } from '../common/BreakpointSystem';
import { UserSessionService } from '../service/UserSessionService';
const HILOG_DOMAIN = 0x0001
const LOG_TAG = 'AddBill'

class SelectOption {
  value: string; // 'value' 是 Select 组件要求必须有的

  constructor(value: string) {
    this.value = value;
  }
}
@Entry
@Component
struct AddBill{
  @State amount: string = '';
  @State selectedDate: Date = new Date(); // 默认为当前日期
  @State notes: string = '';
  @State billType: 'expense' | 'income' = 'expense'; // 支出或收入
  // 2. 新增用于存储列表和当前选项
  @State allCategories: Array<Category> = [];
  @State allAccounts: Array<Account> = [];

  @State selectedCategoryId: number = 1;
  @State selectedAccountId: number = 1;

  @State categoryOptions: SelectOption[] = [];
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'md';
  
  // 响应式配置
  private inputFontSize = new BreakPointType({ xs: 20, sm: 22, md: 24, lg: 28, xl: 32, xxl: 36 });
  private labelFontSize = new BreakPointType({ xs: 14, sm: 15, md: 16, lg: 18, xl: 20, xxl: 22 });
  private buttonWidth = new BreakPointType({ xs: '95%', sm: '92%', md: '90%', lg: '80%', xl: '70%', xxl: '60%' });
  private contentPadding = new BreakPointType({ xs: 10, sm: 12, md: 15, lg: 18, xl: 20, xxl: 24 });
  //创建onPageShow 在页面显示的时候执行
  onPageShow(){
    this.loadData();
  }

  async loadData(){
    try{
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) {
         promptAction.showToast({ message: '请先登录' });
         return;
      }
      hilog.info(HILOG_DOMAIN, LOG_TAG, `开始加载数据，类型: ${this.billType}`);
      //添加支出分裂
      const accounts = await AccountDAO.getByUserId(userId);
      const categories = await CategoryDAO.getByType(userId,this.billType);


      this.allCategories = categories;
      this.allAccounts = accounts;
     // tOption 数组
      this.categoryOptions = categories.map(cat => new SelectOption(cat.name));

      //设置默认选中项
      if (categories.length > 0) {
        this.selectedCategoryId = categories[0].categoryId;
      }
      if (accounts.length > 0) {
        this.selectedAccountId = accounts[0].accountId;
      }
      if (accounts.length === 0) {
        promptAction.showToast({ message: '请先创建至少一个账户' });
        // 延时跳转
        setTimeout(() => {
           router.pushUrl({ url: 'pages/AccountManagementPage' });
        }, 1000);
        return;
      }
      
      this.selectedAccountId = accounts[0].accountId; // 确保默认选中
      hilog.info(0x0000, 'AddBill', '分类和账户加载成功');

    }catch(error){
      hilog.error(0x0000, 'AddBill', '加载数据失败: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '加载分类/账户列表失败' });
    }

  }
  //创建一个辅助函数:将Date对象转换成相应的格式
private formatDate(date:Date):string{
  return date.toISOString().split('T')[0];
}

  build() {

    Navigation() {
      // --- 支出/收入 切换器 ---
      Tabs({ index: this.billType === 'expense' ? 0 : 1 }) {
        TabContent().tabBar('支出')
        TabContent().tabBar('收入')
      }
      .barMode(BarMode.Fixed)
      .width('60%')
      .height(40)
      .margin(10)
      .onChange((index: number) => {
        this.billType = (index === 0) ? 'expense' : 'income';
        // 切换 Tab 时，必须重新调用 loadData
        this.loadData();
      })

      Column({ space: 15 }) {
        TextInput({ placeholder: '0.00' })
          .type(InputType.Number) // 使用数字输入法
          .fontSize(this.inputFontSize.getValue(this.currentBreakpoint) as number)
          .fontWeight(FontWeight.Bold)
          .onChange((value) => {
            this.amount = value;
          })
          .margin({ top: 20 })
        //画一条分割线
        Divider()


        Row() {
          Text('分类')
            .fontSize(this.labelFontSize.getValue(this.currentBreakpoint) as number)
            .fontWeight(FontWeight.Bold)
            // 使用Spacer()来填充剩余空间
            .padding(10)
          //使用Select组件

          Select(this.categoryOptions)
            .value(this.allCategories.find(c => c.categoryId === this.selectedCategoryId)?.name ?? '请选择分类')
            .onSelect((index: number) => {
              this.selectedCategoryId = this.allCategories[index].categoryId;
            })
            .fontColor(Color.Gray)



        }
        .width('100%')
        .padding(10)
        .backgroundColor(Color.White)

        // 日期选择器
        DatePicker({
          start: new Date('2020-01-01'),
          end: new Date('2030-12-31'),
          selected: this.selectedDate
        })
          .onChange((value: DatePickerResult) => {
            //使用空值合并??,来排除value.year当中的未定义的情况
            const now  = new Date();
            const year = value.year ?? now.getFullYear();
            const month = value.month??now.getMonth();
            const day = value.day??now.getDate();

            //这样就可以保证year,month,day是纯数字
            this.selectedDate = new Date(year,month,day);

          })

        //备注
        TextArea({placeholder:'点击添加备注...'})
          .onChange((value:string)=>{
            this.notes = value;
          })
          .layoutWeight(1)  //占据剩余空间
          .backgroundColor(Color.White)

        //保存按钮
        Button('保存')
          .width(this.buttonWidth.getValue(this.currentBreakpoint) as string)
          .height(50)
          .type(ButtonType.Capsule)
          .margin(15)
          .onClick(async () => {
            const userId = UserSessionService.getCurrentUserId();
            if (!userId) {
              promptAction.showToast({ message: '登录失效' });
              return;
            }
            const finalAmount = parseFloat(this.amount);
            if (isNaN(finalAmount) || finalAmount <= 0) {
              promptAction.showToast({ message: '请输入有效的金额' });
              return;
            }
            if (!this.selectedCategoryId ||this.selectedCategoryId <= 0){
              promptAction.showToast({ message: '请选择分类' });
              return;
            }
            if (!this.selectedAccountId ||this.selectedAccountId <= 0){
              promptAction.showToast({ message: '请选择账户' });
              return;
            }


            //创建账单对象
            const now = new Date().toISOString();
            const newBill = new Bill();

            // 使用 @State 中的真实数据
            newBill.userId = userId;
            newBill.accountId = this.selectedAccountId;
            newBill.categoryId = this.selectedCategoryId;
            newBill.type = this.billType;

            // 从表单获取的数据
            newBill.amount = finalAmount;
            newBill.type = this.billType;
            newBill.note = this.notes;
            newBill.transactionDate = this.formatDate(this.selectedDate); // 'YYYY-MM-DD'
            newBill.createdAt = now;
            newBill.updatedAt = now;
            newBill.isDeleted = 0;
            //调用接口插入数据
            // 余额检查与更新
            try {
               const account = await AccountDAO.getById(this.selectedAccountId);
               if (!account) {
                 promptAction.showToast({ message: '账户不存在' });
                 return;
               }
               
               if (this.billType === 'expense') {
                  if (account.balance < finalAmount) {
                     // 余额不足提醒
                     promptAction.showToast({ message: `余额不足！当前: ${account.balance}` });
                     // 可选择是否阻止保存，或者仅提示。一般记账允许负债，但用户要求提醒。
                     // Let's assume we allow it but show warning, OR block it.
                     // User said: "当余额不足的时候也会提醒用户"
                     // We will alert and ASK to continue? Or just alert. Let's alert and continue for now, updating balance to negative?
                     // Or block. Typically apps block or warn. 
                     // Let's block for safety unless confirmed. But dialogs are async.
                     // Simple implementation: Block.
                     // return; 
                     // Wait, better UX: promptAction toast is already shown. Let's allowing it but valid balance update.
                  }
                  account.balance -= finalAmount;
               } else {
                  account.balance += finalAmount;
               }
               
               // 更新账户余额
               await AccountDAO.update(account);
               
            } catch (err) {
               console.error('Account update failed: ', err);
            }

            try{
              await BillDAO.insert(newBill);
              promptAction.showToast({ message: '保存成功，余额已更新' });

              // TODO: Sprint 1 任务，通知首页刷新
              // (目前先直接返回)
              router.back();
            }catch (error){
              console.error('[添加账单] 保存失败: %{public}s', JSON.stringify(error));
              promptAction.showToast({ message: `保存失败: ${error.message}` });
            }
          })
      }
      .padding(this.contentPadding.getValue(this.currentBreakpoint) as number)
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.point_color_checked'))
    }
    .title('记一笔')
    .titleMode(NavigationTitleMode.Mini)
  }
}

function Spacer() {
  throw new Error('Function not implemented.');
}
