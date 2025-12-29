import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AccountDAO } from '../dao/AccountDAO';
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
import { SharedLedgerService } from '../service/SharedLedgerService';
import { LedgerInvitation } from '../model/SharedLedger';

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
  @State transactions: Array<Bill> = [];
  @State isLoading: boolean = true;
  @State allCategories: Array<Category> = [];
  @State selectedDate: Date = new Date();
  @State selectedCategoryId: number = 0;
  @State statRefreshTrigger: number = 0;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'md';
  
  // 邀请状态
  @State pendingInvitations: LedgerInvitation[] = [];
  
  // 弹窗控制器
  invitationController: CustomDialogController = new CustomDialogController({
    builder: InvitationProcessingDialog({
      invitations: $pendingInvitations,
      onHandle: (invite, action) => this.handleInvitation(invite, action)
    }),
    autoCancel: false,
    customStyle: true
  });

  private listPadding = new BreakPointType({ xs: 8, sm: 10, md: 12, lg: 16, xl: 20, xxl: 24 });
  private buttonWidth = new BreakPointType({ xs: '90%', sm: '85%', md: '80%', lg: '70%', xl: '60%', xxl: '50%' });
  private titleFontSize = new BreakPointType({ xs: 14, sm: 15, md: 16, lg: 18, xl: 20, xxl: 22 });
  private amountFontSize = new BreakPointType({ xs: 16, sm: 17, md: 18, lg: 20, xl: 22, xxl: 24 });

  async onPageShow(): Promise<void> {
    hilog.info(HILOG_DOMAIN, LOG_TAG, 'onPageShow triggered');

    if (!UserSessionService.isLoggedIn()) {
      hilog.info(HILOG_DOMAIN, LOG_TAG, 'User not logged in, redirecting to login');
      router.replaceUrl({ url: 'pages/LoginPage' });
      return;
    }

    await this.loadFilterData();
    await this.loadBills();
    
    // 检查邀请
    this.checkInvitations();
  }

  async checkInvitations(): Promise<void> {
    const userId = UserSessionService.getCurrentUserId();
    if (userId) {
       const invites = await SharedLedgerService.getUserInvitations(userId);
       if (invites.length > 0) {
          this.pendingInvitations = invites;
          this.invitationController.open();
       }
    }
  }

  async handleInvitation(invite: LedgerInvitation, action: 'accept' | 'decline'): Promise<void> {
    try {
      if (action === 'accept') {
        await SharedLedgerService.acceptInvitation(invite.invitationId);
        promptAction.showToast({ message: '已加入账本' });
      } else {
        await SharedLedgerService.declineInvitation(invite.invitationId);
        promptAction.showToast({ message: '已拒绝邀请' });
      }
      this.pendingInvitations = this.pendingInvitations.filter(i => i.invitationId !== invite.invitationId);
      
      if (this.pendingInvitations.length === 0) {
        this.invitationController.close();
      }
    } catch (error) {
       promptAction.showToast({ message: '操作失败' });
    }
  }

  async loadBills(): Promise<void> {
    this.isLoading = true;
    try {
      const dateRangeObj = this.getDateRange(this.selectedDate);
      const dateRange = dateRangeObj as DateRangeFilter;
      hilog.info(HILOG_DOMAIN, LOG_TAG, `加载账单: DateRange=${JSON.stringify(dateRange)}, CategoryID=${this.selectedCategoryId}`);

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
        hilog.error(0x0000, 'Index','加载账单失败: %{public}s', JSON.stringify(error));
    }  finally{
      this.isLoading = false;
    }
  }

  async loadFilterData(): Promise<void> {
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) return;
      const categories: Category[]= await CategoryDAO.getAll(userId);
      const allOption = new Category();
      allOption.categoryId = 0;
      allOption.name = '所有分类';
      this.allCategories = [allOption, ...categories];
    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '加载分类列表失败: %{public}s', JSON.stringify(error));
    }
  }

  private getDateRange(date: Date): DateFilter{
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

  async deleteBill(bill: Bill): Promise<void> {
    try {
      const userId = UserSessionService.getCurrentUserId();
      if (!userId) return;

      const account = await AccountDAO.getById(bill.accountId);
      if (account) {
        if (bill.type === 'expense') {
          account.balance += bill.amount;
        } else {
          account.balance -= bill.amount;
        }
        await AccountDAO.update(account);
      }

      await BillDAO.delete(bill.billId, userId);

      this.transactions = this.transactions.filter(item => item.billId !== bill.billId);
      
      this.statRefreshTrigger++;

      promptAction.showToast({ message: '删除成功，余额已还原' });

    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '删除账单失败: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '删除失败，请重试' });
    }
  }

  @Builder
  DeleteButton(bill: Bill) {
    Button({ type: ButtonType.Normal }) {
      Image($r('app.media.ic_public_delete'))
        .width(20)
        .height(20)
        .fillColor(Color.White)
        .objectFit(ImageFit.Contain)
    }
    .width(60)
    .height('100%')
    .backgroundColor(Color.Red)
    .onClick(() => {
        AlertDialog.show({
          title: '确认删除',
          message: '删除后金额将退回账户，确定要删除这条记录吗？',
          primaryButton: {
            value: '取消',
            action: () => {}
          },
          secondaryButton: {
            value: '删除',
            fontColor: Color.Red,
            action: () => {
              this.deleteBill(bill);
            }
          }
        })
    })
  }

  @State currentIndex: number = 0;
  private controller: TabsController = new TabsController();

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
      TabContent() {
        this.BillListContent()
      }
      .tabBar(this.TabBuilder('账本', 0, $r('app.media.ic_bottom_home')))

      TabContent() {
        StatisticsPage({ refreshTrigger: this.statRefreshTrigger })
      }
      .tabBar(this.TabBuilder('统计', 1, $r('app.media.ic_bottom_home')))

      TabContent() {
        MinePage()
      }
      .tabBar(this.TabBuilder('我的', 2, $r('app.media.ic_bottom_home')))
    }
    .onChange((index: number) => {
      this.currentIndex = index;
      if (index === 1) {
         this.statRefreshTrigger++;
      }
    })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  TabBuilder(title: string, targetIndex: number, selectedImg: Resource) {
    Column() {
      Image(selectedImg)
        .size({ width: 24, height: 24 })
        .fillColor(this.currentIndex === targetIndex ? '#007DFF' : '#999999')
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
          Text(this.formatDateToYearMonth(this.selectedDate) + ' ▽')
            .fontSize(16)
            .padding(10)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onClick(() => {
              this.showMonthPicker();
            })
            .layoutWeight(1)

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

        List() {
          ForEach(this.transactions, (item: Bill) => {
            ListItem() {
              this.TransactionRow(item)
            }
            .swipeAction({ end: this.DeleteButton(item) })
          }, (item: Bill, index: number) => index + JSON.stringify(item))
        }
        .layoutWeight(1)
        .padding({ 
          left: this.listPadding.getValue(this.currentBreakpoint) as number, 
          right: this.listPadding.getValue(this.currentBreakpoint) as number 
        })

        Row({ space: 10 }) {
           Button('管理分类')
            .type(ButtonType.Capsule)
            .fontSize(this.titleFontSize.getValue(this.currentBreakpoint) as number)
            .height(40)
            .backgroundColor(Color.Gray)
            .onClick(() => {
              router.pushUrl({ url: 'pages/CategoryManagement' })
            })
           
           Button('📷 扫码')
            .type(ButtonType.Capsule)
            .fontSize(this.titleFontSize.getValue(this.currentBreakpoint) as number)
            .height(40)
            .backgroundColor('#4A90E2')
            .onClick(() => {
              router.pushUrl({ url: 'pages/OCRScanPage' })
            })
            
            Button('预算')
            .type(ButtonType.Capsule)
            .fontSize(this.titleFontSize.getValue(this.currentBreakpoint) as number)
            .height(40)
            .backgroundColor('#FFA000') // Orange for budget
            .onClick(() => {
              router.pushUrl({ url: 'pages/BudgetManagement' })
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
    .hideBackButton(true)
  }

  @Builder
  TransactionRow(item: Bill) {
    Row() {
      /*
      Image(item.type=='expense'?$r('app.media.ic_expense_default'):$r('app.media.ic_income_default'))
        .width(40)
        .height(40)
        .margin({right:10})
        .objectFit(ImageFit.Contain)
      */
      Column() {
        Text(this.allCategories.find(c => c.categoryId === item.categoryId)?.name || (item.type === 'expense' ? '支出' : '收入'))
          .fontSize(this.titleFontSize.getValue(this.currentBreakpoint) as number)
          .fontWeight(FontWeight.Bold)
        
        Row() {
           Text(item.transactionDate.replace('T', ' ').substring(5, 16))
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
      .layoutWeight(1)

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
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    return `${year}-${month}`;
  }

}

@CustomDialog
struct InvitationProcessingDialog {
  controller: CustomDialogController;
  @Link invitations: LedgerInvitation[];
  onHandle: (invite: LedgerInvitation, action: 'accept' | 'decline') => void = () => {};

  build() {
    Column() {
      Text('收到新的账本邀请!')
        .fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 20, bottom: 10 })
      
      List() {
        ForEach(this.invitations, (invite: LedgerInvitation) => {
          ListItem() {
             Column() {
               Text(`邀请人: ${invite.inviterName}`)
                 .fontSize(14).fontColor(Color.Gray)
               Text(`账本: ${invite.ledgerName}`)
                 .fontSize(16).fontWeight(FontWeight.Medium).margin({top: 4, bottom: 8})
               
               Row() {
                 Button('拒绝')
                   .fontColor(Color.Red).backgroundColor('#FFEBEE')
                   .height(30).fontSize(12)
                   .onClick(() => this.onHandle(invite, 'decline'))
                   .margin({ right: 10 })
                   
                 Button('接受')
                   .fontColor(Color.Green).backgroundColor('#E8F5E9')
                   .height(30).fontSize(12)
                   .onClick(() => this.onHandle(invite, 'accept'))
               }
               .width('100%').justifyContent(FlexAlign.End)
             }
             .width('100%')
             .padding(10)
             .backgroundColor('#F5F5F5')
             .borderRadius(8)
             .margin({ bottom: 10 })
          }
        })
      }
      .width('100%')
      .constraintSize({ maxHeight: 300 })
      .padding(10)

      Button('关闭')
        .width('40%').margin({ top: 10, bottom: 20 })
        .backgroundColor(Color.Gray)
        .onClick(() => this.controller.close())
    }
    .width('80%')
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
