import router from '@ohos.router';
import { Bill } from '../model/Bill';
import { BillDAO, DateRangeFilter } from '../dao/BillDAO';
import hilog from '@ohos.hilog';
import { Category } from '../model';
import { CategoryDAO } from '../dao/CategoryDAO';
import { AppTheme } from '../common/AppTheme';

interface DateFilter {
  start: string;
  end: string;
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
  @StorageLink('currentUserId') currentUserId: number = 1;
  @State transactions: Array<Bill> = [];
  @State isLoading: boolean = true;
  @State allCategories: Array<Category> = [];
  @State selectedDate: Date = new Date();
  @State selectedCategoryId: number = 0; // 0 代表 "所有分类"

  async onPageShow() {
    hilog.info(HILOG_DOMAIN, LOG_TAG, 'onPageShow triggered');
    await this.loadFilterData();
    await this.loadBills();
  }

  async loadBills() {
    this.isLoading = true;
    try {
      const dateRangeObj = this.getDateRange(this.selectedDate);
      const dateRange = dateRangeObj as DateRangeFilter;
      hilog.info(HILOG_DOMAIN, LOG_TAG, `加载账单: DateRange=${JSON.stringify(dateRange)}, CategoryID=${this.selectedCategoryId}`);

      const billsFromDB = await BillDAO.getBillsByFilters(
        this.currentUserId,
        dateRange,
        this.selectedCategoryId
      );
      this.transactions = billsFromDB;
    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '加载账单失败: %{public}s', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  async loadFilterData() {
    try {
      const categories: Category[] = await CategoryDAO.getAll(this.currentUserId);
      const allOption = new Category();
      allOption.categoryId = 0;
      allOption.name = '所有分类';
      this.allCategories = [allOption, ...categories];
    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '加载分类列表失败: %{public}s', JSON.stringify(error));
    }
  }

  private getDateRange(date: Date): DateFilter {
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const startDate = `${year}-${month.toString().padStart(2, '0')}-01`;
    const lastDay = new Date(year, month, 0).getDate();
    const endDate = `${year}-${month.toString().padStart(2, '0')}-${lastDay.toString().padStart(2, '0')}`;
    return { start: startDate, end: endDate };
  }

  showMonthPicker() {
    DatePickerDialog.show({
      selected: this.selectedDate,
      onAccept: (value: DatePickerResult) => {
        const year = value.year ?? new Date().getFullYear();
        const month = value.month ?? new Date().getMonth();
        this.selectedDate = new Date(year, month);
        this.loadBills();
      }
    })
  }

  formatDateToYearMonth(date: Date): string {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    return `${year}-${month}`;
  }

  // --- 新增：底部按钮的公共构建器 (美化核心) ---
  @Builder
  BottomActionItem(title: string, icon: ResourceStr, action: () => void) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ bottom: 4 })
        .objectFit(ImageFit.Contain)
      // .fillColor('#666666') // 如果是SVG图标，建议开启这行统一颜色

      Text(title)
        .fontSize(10) // 字体改小，更像原生 TabBar
        .fontColor(AppTheme.TextSub) // 使用主题色
        .fontWeight(FontWeight.Medium)
    }
    .layoutWeight(1) // 均分宽度
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(AppTheme.CardBg) // 点击时的背景反馈区域
    .onClick(() => {
      action()
    })
  }

  @Builder
  TransactionRow(item: Bill) {
    Row() {

      Column() {
        Text(this.allCategories.find(c => c.categoryId === item.categoryId)?.name || '未分类')
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppTheme.TextMain)
        Row() {
          Text(item.transactionDate).fontSize(12).fontColor(AppTheme.TextSub).margin({ right: 10 })
          Text(item.note || '无备注').fontSize(12).fontColor(AppTheme.TextSub)
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank() // 撑开中间距离

      Text(item.type === 'expense' ? `-${item.amount.toFixed(2)}` : `+${item.amount.toFixed(2)}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.type === 'expense' ? AppTheme.Failure : AppTheme.Success) // 使用红绿语义色
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppTheme.CardBg)
    .borderRadius(8)
  }

  build() {
    Navigation() {
      Column() {
        // --- 1. 顶部筛选栏 ---
        Row({ space: 10 }) {
          Text(this.formatDateToYearMonth(this.selectedDate) + ' ▽')
            .fontSize(16)
            .padding(10)
            .backgroundColor(AppTheme.CardBg)
            .borderRadius(8)
            .onClick(() => { this.showMonthPicker(); })
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Select(this.allCategories.map((c) => new CategoryOption(c.name)))
            .value(this.allCategories.find(c => c.categoryId === this.selectedCategoryId)?.name ?? '所有分类')
            .onSelect((index: number) => {
              this.selectedCategoryId = this.allCategories[index].categoryId;
              this.loadBills();
            })
            .backgroundColor(AppTheme.CardBg)
            .borderRadius(8)
            .layoutWeight(1)
        }
        .padding(10)
        .width('100%')
        .backgroundColor(AppTheme.Background) // 使用统一背景

        // --- 2. 账单列表 ---
        List({ space: 10 }) {
          ForEach(this.transactions, (item: Bill) => {
            ListItem() {
              this.TransactionRow(item);
            }
          })
        }
        .width('100%')
        .layoutWeight(1) // 【关键】让列表占据剩余的所有高度
        .padding({ left: 12, right: 12 })

        // --- 3. 底部操作栏 (新设计) ---
        Row() {
          // 使用 Builder 构建，代码更整洁
          this.BottomActionItem('记一笔', $r('app.media.ic_expense_default'), () => {
            router.pushUrl({ url: 'pages/AddBill' })
          })

          this.BottomActionItem('统计', $r('app.media.ic_income_default'), () => {
            router.pushUrl({ url: 'pages/StatisticsPage' })
          })

          this.BottomActionItem('分类', $r('app.media.ic_switch'), () => {
            router.pushUrl({ url: 'pages/CategoryManagement' })
          })

          this.BottomActionItem('账户', $r('app.media.ic_public_delete'), () => {
            router.pushUrl({ url: 'pages/AccountManagement' })
          })
        }
        .width('100%')
        .height(56) // 标准底部栏高度
        .backgroundColor(AppTheme.CardBg)
        .border({ width: { top: 0.5 }, color: AppTheme.Border }) // 顶部细线分割
        .shadow({ radius: 10, color: AppTheme.Shadow, offsetY: -2 }) // 淡淡的阴影提升层次感
      }
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.Background)
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
}
