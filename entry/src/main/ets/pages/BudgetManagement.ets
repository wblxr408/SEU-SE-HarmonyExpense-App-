import { Budget } from '../model/Budget'; //
import { BudgetDAO } from '../dao/BudgetDAO'; //
import { Category } from '../model/Category'; //
import { CategoryDAO } from '../dao/CategoryDAO'; //
import { BillDAO } from '../dao/BillDAO'; //
import promptAction from '@ohos.promptAction';
import hilog from '@ohos.hilog';

const LOG_TAG = 'BudgetManagement';
const HILOG_DOMAIN = 0x0001;

// 视图模型：用于 UI 展示
interface BudgetViewItem {
  budget: Budget;
  categoryName: string; // 分类名
  spentAmount: number;  // 已用金额
  percentage: number;   // 进度百分比 (0-100)
}
class SelectData {
  value: string = '';

  constructor(value: string) {
    this.value = value;
  }
}
// ---------------------------------
// 新建预算弹窗
// ---------------------------------
@CustomDialog
struct AddBudgetDialog {
  controller: CustomDialogController
  @Link allCategories: Category[]
  onConfirm: (categoryId: number, amount: number) => void = () => {}

  @State selectedCategoryId: number = 0
  @State amountStr: string = ''

  // 定义一个状态变量来存储下拉选项
  @State selectOptions: SelectData[] = []



  aboutToAppear() {
    this.selectOptions = this.allCategories.map(c => new SelectData(c.name))
  }

  build() {
    Navigation() {

    Column({ space: 15 }) {
      Text('设置月度预算').fontSize(20).fontWeight(FontWeight.Bold);

      // 选择分类
      Row() {
        Text('分类').width(60);
        Select(this.selectOptions)
          .value(this.allCategories.find(c => c.categoryId === this.selectedCategoryId)?.name ?? '请选择')
          .onSelect((index:number) => {
            if (index >= 0 && index < this.allCategories.length) {
              this.selectedCategoryId = this.allCategories[index].categoryId
            }
          })
          .layoutWeight(1)
      }.width('100%')

      // 2. 输入金额
      Row() {
        Text('金额').width(60);
        TextInput({ placeholder: '0.00', text: this.amountStr })
          .type(InputType.Number)
          .layoutWeight(1)
          .onChange((val) => { this.amountStr = val; });
      }.width('100%');

      // 按钮
      Row({ space: 10 }) {
        Button('取消').onClick(() => this.controller.close()).layoutWeight(1).backgroundColor(Color.Gray);
        Button('确定').onClick(() => {
          const amt = parseFloat(this.amountStr);
          if (this.selectedCategoryId === 0) {
            promptAction.showToast({ message: '请选择分类' });
            return;
          }
          if (isNaN(amt) || amt <= 0) {
            promptAction.showToast({ message: '请输入有效金额' });
            return;
          }
          this.onConfirm(this.selectedCategoryId, amt);
          this.controller.close();
        }).layoutWeight(1);
      }.width('100%');
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12);
  }
}
}


@Entry
@Component
struct BudgetManagement {
  @State budgetItems: Array<BudgetViewItem> = [];
  @State allCategories: Array<Category> = []; // 用于弹窗选择
  @StorageProp('currentUserId') currentUserId: number = 1;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: AddBudgetDialog({
      allCategories: $allCategories,
      onConfirm: (catId, amt): Promise<void> => this.handleAddBudget(catId, amt)
    }),
    alignment: DialogAlignment.Bottom,
    autoCancel: true
  });

  onPageShow() {
    this.loadData();
  }

  async loadData() {
    try {
      // 1. 获取该用户所有支出分类 (预算通常针对支出)
      this.allCategories = await CategoryDAO.getByType(this.currentUserId, 'expense'); //

      // 2. 获取该用户所有预算配置
      const budgets = await BudgetDAO.getByUserId(this.currentUserId);

      // 3. 计算日期范围 (本月 1号 到 月末)
      const now = new Date();
      const start = `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, '0')}-01`;
      const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
      const end = `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, '0')}-${lastDay}`;

      // 4. 组装 ViewItem (计算已用金额)
      const items: BudgetViewItem[] = [];

      for (const b of budgets) {
        // 4.1 找分类名
        const cat = this.allCategories.find(c => c.categoryId === b.categoryId);
        const catName = cat ? cat.name : '未知分类';

        // 4.2 查该分类本月的账单
        // 使用 BillDAO.getBillsByFilters (我们在 Sprint 2 实现的)
        const bills = await BillDAO.getBillsByFilters(this.currentUserId, { start, end }, b.categoryId); //

        // 4.3 累加金额
        const spent = bills.reduce((sum, bill) => sum + bill.amount, 0);

        items.push({
          budget: b,
          categoryName: catName,
          spentAmount: spent,
          percentage: (spent / b.amount) * 100
        });
      }

      this.budgetItems = items;

    } catch (error) {
      hilog.error(HILOG_DOMAIN, LOG_TAG, '加载预算数据失败: %{public}s', JSON.stringify(error));
    }
  }

  async handleAddBudget(categoryId: number, amount: number) {
    try {
      // 检查该分类是否已存在预算 (简单处理：如果存在则暂不处理或覆盖，这里假设是新增)
      const newBudget = new Budget();
      newBudget.userId = this.currentUserId;
      newBudget.categoryId = categoryId;
      newBudget.amount = amount;
      newBudget.period = 'monthly';
      newBudget.startDate = new Date().toISOString(); // 简单起见，从今天开始
      newBudget.createdAt = new Date().toISOString();

      await BudgetDAO.insert(newBudget);
      promptAction.showToast({ message: '预算设置成功' });
      this.loadData(); // 刷新列表
    } catch (error) {
      promptAction.showToast({ message: '保存失败' });
    }
  }

  // 删除预算
  async handleDelete(budgetId: number) {
    await BudgetDAO.softDelete(budgetId);
    this.loadData();
  }

  build() {
    Navigation() {
      Column() {
        if (this.budgetItems.length === 0) {
          Column() {
            Image($r('app.media.norecord')).width(100).height(100).opacity(0.5); //
            Text('暂无预算，点击右下角添加').fontSize(14).fontColor(Color.Gray).margin({top: 10});
          }.justifyContent(FlexAlign.Center).height('80%');
        } else {
          List({ space: 15 }) {
            ForEach(this.budgetItems, (item: BudgetViewItem) => {
              ListItem() {
                this.BudgetCard(item);
              }
              .swipeAction({ end: this.SwipeDelete(item.budget.budgetId) })
            })
          }
          .padding(15)
          .layoutWeight(1);
        }

        // 悬浮添加按钮
        Button('+')
          .type(ButtonType.Circle)
          .width(60).height(60)
          .position({ x: '80%', y: '85%' })
          .onClick(() => this.dialogController.open());
      }
      .width('100%').height('100%').backgroundColor('#F1F3F5');
    }
    .title('预算管理')
    .titleMode(NavigationTitleMode.Mini);
  }

  @Builder
  BudgetCard(item: BudgetViewItem) {
    Column({ space: 10 }) {
      // 标题栏：分类名 + 剩余/超支提示
      Row() {
        Text(item.categoryName).fontSize(18).fontWeight(FontWeight.Bold);

        if (item.spentAmount > item.budget.amount) {
          Text(`超支 ${(item.spentAmount - item.budget.amount).toFixed(0)}`).fontColor(Color.Red).fontSize(14);
        } else {
          Text(`剩余 ${(item.budget.amount - item.spentAmount).toFixed(0)}`).fontColor(Color.Gray).fontSize(14);
        }
      }.width('100%');

      // 进度条
      Progress({ value: item.spentAmount, total: item.budget.amount, type: ProgressType.Linear })
        .color(item.spentAmount > item.budget.amount ? Color.Red : '#1890FF') // 超支变红
        .width('100%');

      // 底部数字：已用 / 总额
      Row() {
        Text(`已用 ¥${item.spentAmount.toFixed(2)}`).fontSize(12).fontColor(Color.Gray);

        Text(`总额 ¥${item.budget.amount.toFixed(0)}`).fontSize(12).fontColor(Color.Gray);
      }.width('100%');
    }
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(12);
  }

  @Builder
  SwipeDelete(id: number) {
    Button('删除').type(ButtonType.Circle).backgroundColor(Color.Red).onClick(() => this.handleDelete(id));
  }
}