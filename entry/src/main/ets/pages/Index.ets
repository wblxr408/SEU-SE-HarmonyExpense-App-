import router from '@ohos.router';
import { Bill } from '../model/Bill';
import { BillDAO, DateRangeFilter } from '../dao/BillDAO';
import hilog from '@ohos.hilog';
import { CURRENT_USER_ID } from '../common/Constants';
import { BusinessError } from '@ohos.base';
import { Category } from '../model';
import { CategoryDAO } from '../dao/CategoryDAO';
import { BreakPointType } from '../common/BreakpointSystem';
import { MinePage } from './MinePage';
import { StatisticsPage } from './StatisticsPage';
import { UserSessionService } from '../service/UserSessionService';
import { AppTheme } from '../common/AppTheme';

interface DateFilter {
  start: string;
  end: string;
}

class SelectOption {
  value: string;

  constructor(value: string) {
    this.value = value;
  }
}

class CategoryOption {
  value: ResourceStr = '';

  constructor(value: ResourceStr) {
    this.value = value;
  }
}

const HILOG_DOMAIN = 0x0001
const LOG_TAG = 'Index'

@Entry
@Component
struct Index {
  @State transactions: Array<Bill> = []; //定义一个变量，用于存储交易数据>;
  @State isLoading: boolean = true;
  @State allCategories: Array<Category> = [];
  @State selectedDate: Date = new Date(); // 用于月份选择器
  @State selectedCategoryId: number = 0; // 0 代表 "所有分类"
  @State statRefreshTrigger: number = 0; // Trigger for statistics refresh
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'md';
  
  // 响应式配置
  private listPadding = new BreakPointType({ xs: 8, sm: 10, md: 12, lg: 16, xl: 20, xxl: 24 });
  private buttonWidth = new BreakPointType({ xs: '90%', sm: '85%', md: '80%', lg: '70%', xl: '60%', xxl: '50%' });
  private titleFontSize = new BreakPointType({ xs: 14, sm: 15, md: 16, lg: 18, xl: 20, xxl: 22 });
  private amountFontSize = new BreakPointType({ xs: 16, sm: 17, md: 18, lg: 20, xl: 22, xxl: 24 });
  //添加onPageShow 生命周期函数
  async onPageShow() {
    hilog.info(HILOG_DOMAIN, LOG_TAG, 'onPageShow triggered');

    // 检查登录状态
    if (!UserSessionService.isLoggedIn()) {
      hilog.info(HILOG_DOMAIN, LOG_TAG, 'User not logged in, redirecting to login');
      router.replaceUrl({ url: 'pages/LoginPage' });
      return;
    }

    await this.loadFilterData();


    await this.loadBills();
  }
  async loadBills() {
    this.isLoading = true;

    try {
      //使用BillDAO类中的getAllBills方法获取所有交易数据
      // 1. 根据当前 @State selectedDate 计算日期范围
      const dateRangeObj = this.getDateRange(this.selectedDate);
      const dateRange = dateRangeObj as DateRangeFilter;
      hilog.info(HILOG_DOMAIN, LOG_TAG, `加载账单: DateRange=${JSON.stringify(dateRange)}, CategoryID=${this.selectedCategoryId}`);

      // 2. 调用 B 成员提供的新 DAO 方法
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) { 
        hilog.warn(HILOG_DOMAIN, LOG_TAG, 'loadBills skipped: No user logged in');
        return; 
      }
      const billsFromDB = await BillDAO.getBillsByFilters(
        userId,
        dateRange,
        this.selectedCategoryId
      );
      this.transactions = billsFromDB;
      this.isLoading = false;
    } catch (error) {

        // 处理业务错误
        hilog.error(0x0000, 'Index','加载账单失败: %{public}s', JSON.stringify(error));

    }  finally{
      this.isLoading = false;
    }
  }
  //辅助函数，加载分类筛选器
  async loadFilterData() {
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) return;
      const categories: Category[]= await CategoryDAO.getAll(userId);
      // 手动添加一个 "所有分类" 选项
      const allOption = new Category();
      allOption.categoryId = 0;
      allOption.name = '所有分类';
      this.allCategories = [allOption, ...categories];
    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '加载分类列表失败: %{public}s', JSON.stringify(error));
    }
  }
//获取指定月份的开始和结束日期 (YYYY-MM-DD)
  private getDateRange(date: Date): DateFilter{
    const year = date.getFullYear();
    const month = date.getMonth() + 1; // 月份从 0 开始

    // YYYY-MM-01
    const startDate = `${year}-${month.toString().padStart(2, '0')}-01`;

    // YYYY-MM-LastDay
    const lastDay = new Date(year, month, 0).getDate();
    const endDate = `${year}-${month.toString().padStart(2, '0')}-${lastDay.toString().padStart(2, '0')}`;

    return { start: startDate, end: endDate };
  }
//显示月份弹窗的函数
  showMonthPicker() {
    DatePickerDialog.show({
      selected: this.selectedDate,
      onAccept: (value: DatePickerResult) => {
        const year = value.year ?? new Date().getFullYear();
        const month = value.month ?? new Date().getMonth();
        this.selectedDate = new Date(year, month);
        // (连接逻辑) 日期变化时，重新加载账单
        this.loadBills();
      }
    })
  }

  @State currentIndex: number = 0;
  private controller: TabsController = new TabsController();

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
      // Tab 1: 账本 (Original Content)
      TabContent() {
        this.BillListContent()
      }
      .tabBar(this.TabBuilder('账本', 0, $r('app.media.ic_bottom_home')))

      // Tab 2: 统计
      TabContent() {
        StatisticsPage({ refreshTrigger: this.statRefreshTrigger })
      }
      .tabBar(this.TabBuilder('统计', 1, $r('app.media.icon')))

      // Tab 3: 我的 (User Center)
      TabContent() {
        MinePage()
      }
      .tabBar(this.TabBuilder('我的', 2, $r('app.media.icon')))
    }
    .onChange((index: number) => {
      this.currentIndex = index;
      if (index === 1) { // Statistics Tab
         this.statRefreshTrigger++;
      }
    })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  TabBuilder(title: string, targetIndex: number, selectedImg: Resource) {
    Column() {
      // 这里的图标逻辑可以优化，区分选中/未选中状态
      // 暂时无论是否选中都显示相同图标，或者用颜色区分
      Image(selectedImg)
        .size({ width: 24, height: 24 })
        .fillColor(this.currentIndex === targetIndex ? '#007DFF' : '#999999') // 如果图片支持着色
        .objectFit(ImageFit.Contain)
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#007DFF' : '#999999')
        .fontSize(10)
        .margin({ top: 4 })
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.controller.changeIndex(targetIndex);
    })
  }

  @Builder
  BillListContent() {
    Navigation() {
      Column() {
        Row({ space: 10 }) {
          // 月份选择器
          Text(this.formatDateToYearMonth(this.selectedDate) + ' ▽')
            .fontSize(16)
            .padding(10)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onClick(() => {
              this.showMonthPicker();
            })
            .layoutWeight(1)

          // 分类筛选器
          Select(this.allCategories.map((c) => new CategoryOption(c.name)))
            .value(this.allCategories.find(c => c.categoryId === this.selectedCategoryId)?.name ?? '所有分类')
            .onSelect((index: number) => {
              this.selectedCategoryId = this.allCategories[index].categoryId;
              this.loadBills();
            })
            .layoutWeight(1)
        }
        .padding(10)
        .width('100%')
        .backgroundColor('#F1F3F5')

        // 账单列表
        List() {
          ForEach(this.transactions, (item: Bill) => {
            ListItem() {
              this.TransactionRow(item)
            }
          }, (item: Bill, index: number) => index + JSON.stringify(item))
        }
        .layoutWeight(1)
        .padding({ 
          left: this.listPadding.getValue(this.currentBreakpoint) as number, 
          right: this.listPadding.getValue(this.currentBreakpoint) as number 
        })

        // 按钮区域
        Row() {
           Button('管理分类')
            .type(ButtonType.Capsule)
            .fontSize(this.titleFontSize.getValue(this.currentBreakpoint) as number)
            .height(40)
            .backgroundColor(Color.Gray)
            .margin({ right: 10 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/CategoryManagement' })
            })
            
           Button('记一笔')
            .type(ButtonType.Capsule)
            .fontSize(this.titleFontSize.getValue(this.currentBreakpoint) as number)
            .height(40)
            .onClick(() => {
              router.pushUrl({ url: 'pages/AddBill' })
            })
        }
        .margin(20)
      }
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.point_color_checked'))
    .title('记账APP')
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true) // 首页隐藏返回按钮
    .menus([
      {
        value: 'AI 助手',
        icon: 'resources/base/media/ic_bottom_record.svg', // 使用现有图标作为替代
        action: () => {
          router.pushUrl({ url: 'pages/AIChatPage' })
        }
      }
    ])
  }

  //自定义的展示行的函数
  @Builder
  TransactionRow(item: Bill) {
    Row() {
        //暂时用图片代替资源
      Image(item.type=='expense'?$r('app.media.ic_expense_default'):$r('app.media.ic_income_default'))
        .width(40)
        .height(40)
        .margin({right:10})
        .objectFit(ImageFit.Contain)
      Column() {
        // Find category name
        Text(this.allCategories.find(c => c.categoryId === item.categoryId)?.name || (item.type === 'expense' ? '支出' : '收入'))
          .fontSize(this.titleFontSize.getValue(this.currentBreakpoint) as number)
          .fontWeight(FontWeight.Bold)
        
        Row() {
           Text(item.transactionDate.replace('T', ' ').substring(5, 16)) // Display MM-DD HH:mm
            .fontSize(12)
            .fontColor(Color.Gray)
            .margin({ right: 8 })
           if (item.note) {
             Text(item.note)
               .fontSize((this.titleFontSize.getValue(this.currentBreakpoint) as number) - 2)
               .fontColor(Color.Gray)
           }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1) // Push amount to right

      Text(item.type === 'expense' ? `-${item.amount.toFixed(2)}` : `+${item.amount.toFixed(2)}`)
        .fontSize(this.amountFontSize.getValue(this.currentBreakpoint) as number)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.type === 'expense' ? Color.Red : Color.Green)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
    }
  formatDateToYearMonth(date: Date): string {
    const year = date.getFullYear();
    // getMonth() 返回 0-11，所以需要 +1
    // padStart(2, '0') 确保月份是两位数 (例如 "05" 而不是 "5")
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    return `${year}-${month}`;
  }

}
