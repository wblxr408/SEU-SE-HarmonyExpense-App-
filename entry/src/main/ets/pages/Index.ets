import  router from '@ohos.router';
import { Bill } from '../model/Bill'; //
import { BillDAO } from '../dao/BillDAO'; //
import { DateRangeFilter } from '../dao/BillDAO';
import hilog from '@ohos.hilog'; // 用于日志
import { CURRENT_USER_ID } from '../common/Constants';
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
      // 1. 根据当前 @State selectedDate 计算日期范围
      const dateRangeObj = this.getDateRange(this.selectedDate);
      const dateRange = dateRangeObj as DateRangeFilter;
      hilog.info(HILOG_DOMAIN, LOG_TAG, `加载账单: DateRange=${JSON.stringify(dateRange)}, CategoryID=${this.selectedCategoryId}`);

      // 2. 调用 B 成员提供的新 DAO 方法
      const billsFromDB = await BillDAO.getBillsByFilters(
        CURRENT_USER_ID,
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
      const categories: Category[]= await CategoryDAO.getAll(CURRENT_USER_ID);
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

    //使用Navigation函数来显示页面导航和标题栏
    Navigation() {
      Column() {

        Row({ space: 10 }) {
          // 月份选择器 (改成 Text + 弹窗)
          Text(this.formatDateToYearMonth(this.selectedDate) + ' ▽')
            .fontSize(16)
            .padding(10)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onClick(() => {
              this.showMonthPicker(); // 调用弹窗
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
        .backgroundColor('#F1F3F5') // 改成和背景一致

        // 账单列表

        //UI的依赖状态
        List({ space: 10 }) {
          ForEach(this.transactions, (item: Bill) => {
            ListItem() {
              //将展示内容封装成函数
              this.TransactionRow(item);
            }
          })
        }
        .layoutWeight(1) //列表占据剩余空间
        .padding({ left: 12, right: 12 })

        //表格展示结束
        Button('管理分类 ')
          .type(ButtonType.Capsule)
          .fontSize(18)
          .width('80%')
          .height(50)
          .margin(20)
          .onClick(() => {
            router.push({
              url: 'pages/CategoryManagement' //
            })
          })
        Button('记一笔')
          .type(ButtonType.Capsule)
          .fontSize(18)
          .width('80%')
          .height(50)
          .margin(20) //设置按钮外边框
          .onClick(() => {
            router.push({
              url: 'pages/AddBill'

            })
          })
      }
    }

    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.point_color_checked')) //设置一个浅灰色的背景
    .title('记账APP 首页')
    .titleMode(NavigationTitleMode.Mini)
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




