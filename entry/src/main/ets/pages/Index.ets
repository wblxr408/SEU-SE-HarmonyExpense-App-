
import  router from '@ohos.router';
import { Bill } from '../model/Bill'; //
import { BillDAO } from '../dao/BillDAO'; //
import { DateRangeFilter } from '../dao/BillDAO';
import hilog from '@ohos.hilog'; // 用于日志
import { BusinessError } from '@ohos.base';
import { Category } from '../model';
import { CategoryDAO } from '../dao/CategoryDAO';
interface DateFilter{
  start:string;
  end:string;
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
const LOG_TAG = 'AddBill'

@Entry
@Component
struct Index {
  @StorageLink('currentUserId') currentUserId: number = 1;
  @State transactions: Array<Bill> = []; //定义一个变量，用于存储交易数据>;
  @State isLoading: boolean = true;
  @State allCategories: Array<Category> = [];
  @State selectedDate: Date = new Date(); // 用于月份选择器
  @State selectedCategoryId: number = 0; // 0 代表 "所有分类"
  //添加onPageShow 生命周期函数
  async onPageShow() {
    hilog.info(HILOG_DOMAIN, LOG_TAG, 'onPageShow triggered');

    await this.loadFilterData();


    await this.loadBills();
  }
  async loadBills() {
    this.isLoading = true;

    try {
      //使用BillDAO类中的getAllBills方法获取所有交易数据

      const dateRangeObj = this.getDateRange(this.selectedDate);
      const dateRange = dateRangeObj as DateRangeFilter;
      hilog.info(HILOG_DOMAIN, LOG_TAG, `加载账单: DateRange=${JSON.stringify(dateRange)}, CategoryID=${this.selectedCategoryId}`);


      const billsFromDB = await BillDAO.getBillsByFilters(
        this.currentUserId,
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
      const categories: Category[]= await CategoryDAO.getAll(this.currentUserId);
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

  build() {
    Navigation() {
      // 使用 Stack 布局，让操作栏悬浮在底部，或者直接用 Column 垂直排列
      Column() {

        // --- 1. 顶部筛选栏 (保持不变) ---
        Row({ space: 10 }) {
          // ... 月份选择器 ...
          Text(this.formatDateToYearMonth(this.selectedDate) + ' ▽')
          // ... 属性保持不变 ...
            .onClick(() => { this.showMonthPicker(); })
            .layoutWeight(1)

          // ... 分类筛选器 ...
          Select(this.allCategories.map((c) => new CategoryOption(c.name)))
          // ... 属性保持不变 ...
            .layoutWeight(1)
        }
        .padding(10)
        .width('100%')
        .backgroundColor('#F1F3F5')

        // --- 2. 账单列表 (保持不变，layoutWeight 设为 1 自动占满剩余空间) ---
        List({ space: 10 }) {
          ForEach(this.transactions, (item: Bill) => {
            ListItem() {
              this.TransactionRow(item);
            }
          })
        }
        .layoutWeight(1) // 关键：让列表占据中间所有剩余空间
        .padding({ left: 12, right: 12 })

        // --- 3. 底部功能区 (优化部分) ---
        // 将原来的大按钮改为一行小图标+文字
        Row() {
          // 3.1 记一笔 (最核心功能，放中间或醒目位置)
          Column() {
            Image($r('app.media.ic_expense_default')) // 建议换个 "加号" 或 "笔" 的图标
              .width(24).height(24).margin({bottom: 4})
            Text('记账').fontSize(12).fontColor('#666666')
          }
          .onClick(() => { router.pushUrl({ url: 'pages/AddBill' }) })
          .layoutWeight(1) // 均分宽度
          .alignItems(HorizontalAlign.Center)

          // 3.2 统计分析
          Column() {
            Image($r('app.media.ic_income_default')) // 建议换个 "报表" 图标
              .width(24).height(24).margin({bottom: 4})
            Text('统计').fontSize(12).fontColor('#666666')
          }
          .onClick(() => { router.pushUrl({ url: 'pages/StatisticsPage' }) })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          // 3.3 管理分类
          Column() {
            Image($r('app.media.ic_switch')) // 建议换个 "分类" 图标
              .width(24).height(24).margin({bottom: 4})
            Text('分类').fontSize(12).fontColor('#666666')
          }
          .onClick(() => { router.pushUrl({ url: 'pages/CategoryManagement' }) })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          // 3.4 管理账户
          Column() {
            Image($r('app.media.ic_public_delete')) // 建议换个 "卡片" 图标
              .width(24).height(24).margin({bottom: 4})
            Text('账户').fontSize(12).fontColor('#666666')
          }
          .onClick(() => { router.pushUrl({ url: 'pages/AccountManagement' }) })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height(60) // 固定底部栏高度
        .backgroundColor(Color.White)
        .border({ width: { top: 1 }, color: '#EEEEEE' }) // 顶部加一条细线
        .padding({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5') // 背景色
    .title('记账APP 首页')
    .titleMode(NavigationTitleMode.Mini)
    .menus([
      {
        value: '设置',
        action: () => {
          router.pushUrl({ url: 'pages/SettingsPage' })
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
        Text(item.type === 'expense' ? '支出' : '收入').fontSize(16).fontWeight(FontWeight.Bold) //
        Text(item.note || '无备注').fontSize(14).fontColor(Color.Gray)
      }
      .alignItems(HorizontalAlign.Start)



      Text(item.type === 'expense' ? `-${item.amount.toFixed(2)}` : `+${item.amount.toFixed(2)}`)
        .fontSize(18)
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




