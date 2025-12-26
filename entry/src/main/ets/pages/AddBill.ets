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
import { AnomalyDetectionService, AnomalyDetectionResult } from '../service/AnomalyDetectionService';
import { AnomalyRecord } from '../model/AnomalyDetection';
import { SmartCategoryService, CategoryRecommendation } from '../service/SmartCategoryService';

const HILOG_DOMAIN = 0x0001
const LOG_TAG = 'AddBill'

class SelectOption {
  value: string; // 'value' 是 Select 组件要求必须有的

  constructor(value: string) {
    this.value = value;
  }
}

@CustomDialog
struct AnomalyAlertDialog {
  controller: CustomDialogController;
  anomalies: AnomalyDetectionResult[] = [];
  onConfirm: () => void = () => {};

  build() {
    Column() {
      Text('⚠️ 异常消费提醒')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Red)
        .margin({ bottom: 15 })

      List() {
        ForEach(this.anomalies, (item: AnomalyDetectionResult) => {
          ListItem() {
            Column() {
              Text(this.getAnomalyTitle(item.anomalyType))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 5 })
              Text(item.description)
                .fontSize(14)
                .fontColor(Color.Gray)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(10)
            .backgroundColor('#FFF5F5')
            .borderRadius(8)
            .margin({ bottom: 8 })
          }
        })
      }
      .width('100%')
      .constraintSize({ maxHeight: 200 })

      Button('我知道了')
        .type(ButtonType.Capsule)
        .width('90%')
        .margin({ top: 20 })
        .onClick(() => {
          this.controller.close();
          this.onConfirm();
        })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('90%')
  }

  getAnomalyTitle(type: string): string {
    const map: Record<string, string> = {
      'high_amount': '金额过高',
      'low_amount': '金额异常',
      'frequency_spike': '交易频繁',
      'unusual_category': '分类异常',
      'pattern_break': '消费习惯改变'
    };
    return map[type] || '检测到异常';
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
  @State accountOptions: SelectOption[] = []; // Added from MAIN logic requirement
  
  // 异常检测相关
  @State detectionAnomalies: AnomalyDetectionResult[] = [];
  
  // 智能推荐相关
  @State recommendations: CategoryRecommendation[] = [];
  @State predictedCategoryId: number = 0;

  // 响应式布局相关
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  inputFontSize: BreakPointType<number> = new BreakPointType({
    sm: 32,
    md: 36,
    lg: 40
  });
  labelFontSize: BreakPointType<number> = new BreakPointType({
    sm: 16,
    md: 18,
    lg: 20
  });
  buttonWidth: BreakPointType<string> = new BreakPointType({
    sm: '90%',
    md: '70%',
    lg: '50%'
  });
  contentPadding: BreakPointType<number> = new BreakPointType({
    sm: 15,
    md: 20,
    lg: 30
  });

  // 异常检测弹窗控制器
  anomalyDialogController: CustomDialogController = new CustomDialogController({
    builder: AnomalyAlertDialog({
      anomalies: this.detectionAnomalies,
      onConfirm: () => {
        const selectedCategory = this.allCategories.find(c => c.categoryId === this.selectedCategoryId);
        if (selectedCategory) {
          const userId = UserSessionService.getCurrentUserId();
          if (userId) {
            SmartCategoryService.learnFromUserAction(
              userId,
              this.notes,
              parseFloat(this.amount),
              this.selectedCategoryId,
              selectedCategory.name,
              this.predictedCategoryId
            );
          }
        }
        promptAction.showToast({ message: '保存成功，余额已更新' });
        router.back();
      }
    }),
    autoCancel: false,
    customStyle: true
  });

  async updateRecommendations() {
    const userId = UserSessionService.getCurrentUserId();
    if (!userId) return;

    if (!this.notes && !this.amount) {
      this.recommendations = [];
      return;
    }

    const amountNum = parseFloat(this.amount) || 0;
    this.recommendations = await SmartCategoryService.recommendCategory(userId, this.notes, amountNum);

    if (this.recommendations.length > 0) {
      this.predictedCategoryId = this.recommendations[0].categoryId;
    }
  }

  async loadData() {
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) {
        promptAction.showToast({ message: '请先登录' });
        return;
      }

      // 加载分类和账户列表
      this.allCategories = await CategoryDAO.getByType(userId, this.billType);
      this.allAccounts = await AccountDAO.getByUserId(userId);

      this.categoryOptions = this.allCategories.map((c: Category) => new SelectOption(c.name));
      this.accountOptions = this.allAccounts.map((a: Account) => new SelectOption(a.name));

      // --- 智能分类冷启动逻辑 ---
      // 检查用户是否有规则，如果没有，则触发历史数据学习
      const rules = await SmartCategoryService.getUserRules(userId);
      
      if (rules.length === 0) {
        hilog.info(HILOG_DOMAIN, LOG_TAG, '检测到无分类规则，开始从历史账单学习...');
        const result = await SmartCategoryService.batchLearnFromHistory(userId, 90); // 学习最近90天
        
        if (result.rulesCreated > 0) {
            hilog.info(HILOG_DOMAIN, LOG_TAG, `历史学习完成，创建了 ${result.rulesCreated} 条规则`);
            promptAction.showToast({ message: '已根据您的历史账单优化了分类推荐' });
        }
      }

    } catch (err) {
      let error = err as Error;
      hilog.error(HILOG_DOMAIN, LOG_TAG, '加载数据失败: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '加载分类/账户列表失败' });
    }
  }

  aboutToAppear() {
    // 检查是否有预填参数（来自OCR扫描）
    const params = router.getParams() as Record<string, string | number>;
    if (params) {
      if (params['prefilledAmount']) {
        this.amount = String(params['prefilledAmount']);
      }
      if (params['prefilledNote']) {
        this.notes = String(params['prefilledNote']);
      }
      if (params['prefilledCategoryId']) {
        this.selectedCategoryId = Number(params['prefilledCategoryId']);
      }
      if (params['prefilledDate']) {
        const dateStr = String(params['prefilledDate']);
        const parts = dateStr.split('-');
        if (parts.length === 3) {
          this.selectedDate = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
        }
      }
    }
    
    this.loadData();
  }
  //创建一个辅助函数:将Date对象转换成相应的格式
  private formatDate(date: Date): string {
    const y: number = date.getFullYear();
    const m: string = (date.getMonth() + 1).toString().padStart(2, '0');
    const d: string = date.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${d}`;
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
          .onChange((value: string) => {
            this.amount = value;
            this.updateRecommendations();
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
            .value(this.allCategories.find((c: Category) => c.categoryId === this.selectedCategoryId)?.name ?? '请选择分类')
            .onSelect((index: number) => {
              this.selectedCategoryId = this.allCategories[index].categoryId;
            })
            .fontColor(Color.Gray)

        }
        .width('100%')
        .padding(10)
        .backgroundColor(Color.White)

        // --- 智能推荐区域 ---
        if (this.recommendations.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.recommendations, (item: CategoryRecommendation) => {
              Row() {
                Text(item.categoryName)
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                if (item.reason.includes('关键词')) {
                  Text(' ⚡')
                    .fontSize(10)
                    .fontColor('#FFEB3B')
                }
              }
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor('#4A90E2')
              .borderRadius(16)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.selectedCategoryId = item.categoryId;
                promptAction.showToast({ message: `已采纳推荐: ${item.reason}` });
              })
            })
          }
          .width('100%')
          .padding({ left: 10, right: 10, bottom: 5 })
        }

        Divider()

        // 账户选择行 (From MAIN)
        Row() {
          Text('账户')
            .fontSize(this.labelFontSize.getValue(this.currentBreakpoint) as number)
            .fontWeight(FontWeight.Bold)
            .padding(10)

          if (this.allAccounts.length > 0) {
            Select(this.accountOptions)
              .value(this.allAccounts.find(a => a.accountId === this.selectedAccountId)?.name ?? '请选择账户')
              .onSelect((index: number) => {
                this.selectedAccountId = this.allAccounts[index].accountId;
              })
              .fontColor(Color.Gray)
          } else {
             Text('暂无账户，去创建 >')
               .fontSize(14)
               .fontColor(Color.Blue)
               .onClick(() => {
                 router.pushUrl({ url: 'pages/AccountManagement' })
               })
          }
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
            this.updateRecommendations();
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
            // 余额检查与更新 (HEAD Logic)
            try {
               const account = await AccountDAO.getById(this.selectedAccountId);
               if (!account) {
                 promptAction.showToast({ message: '账户不存在' });
                 return;
               }
               
                if (this.billType === 'expense') {
                  if (account.balance < finalAmount) {
                      // 余额不足，阻止记账
                      promptAction.showToast({ message: `余额不足！当前余额: ${account.balance.toFixed(2)}` });
                      return;
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
              const rowId = await BillDAO.insert(newBill);
              
              // 异常检测
              newBill.billId = rowId;
              const anomalies = await AnomalyDetectionService.detectBillAnomaly(newBill, userId);
              
              if (anomalies.length > 0) {
                this.detectionAnomalies = anomalies;
                this.anomalyDialogController.open();
                // 不立即返回，等待用户点击弹窗确认
              } else {
                // 智能分类学习
                const selectedCategory = this.allCategories.find(c => c.categoryId === this.selectedCategoryId);
                if (selectedCategory) {
                  SmartCategoryService.learnFromUserAction(
                    userId,
                    this.notes,
                    finalAmount,
                    this.selectedCategoryId,
                    selectedCategory.name,
                    this.predictedCategoryId
                  );
                }

                promptAction.showToast({ message: '保存成功，余额已更新' });
                router.back();
              }
            } catch (err) {
              let error = err as Error;
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
