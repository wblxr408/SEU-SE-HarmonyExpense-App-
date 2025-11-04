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
  //创建onPageShow 在页面显示的时候执行
  onPageShow(){
    this.loadData();
  }

  async loadData(){
    try{
      const userId = 1;
      //添加支出分裂
      const categories = await CategoryDAO.getByType(userId,this.billType);
      const accounts = await AccountDAO.getAll();

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
      Column({ space: 15 }) {
        TextInput({ placeholder: '0.00' })
          .type(InputType.Number) // 使用数字输入法
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .onChange((value) => {
            this.amount = value;
          })
          .margin({ top: 20 })
        //画一条分割线
        Divider()

        // 分类选择,在spring2中实现
        Row() {
          Text('分类')
            .fontSize(16)
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
          .width('90%')
          .height(50)
          .type(ButtonType.Capsule)
          .margin(15)
          .onClick(async () => {
            const finalAmount = parseFloat(this.amount);
            if (isNaN(finalAmount) || finalAmount <= 0) {
              try {
                promptAction.showToast({ message: '请输入有效的金额' });
              } catch (error) {
                let e = error as BusinessError;
                console.error(`showToast 失败: code=${e.code}, msg=${e.message}`);
              }
              return;
            }
            //创建账单对象
            const now = new Date().toISOString();
            const newBill = new Bill();

            // 假设的硬编码外键 (对应步骤一中插入的模拟数据)
            //newBill.userId = 1; // 假设用户 ID 为 1
            newBill.accountId = 1; // 假设账户 ID 为 1 (默认现金账户)
            newBill.categoryId = 1; // 假设分类 ID 为 1 (餐饮)

            // 从表单获取的数据
            newBill.amount = finalAmount;
            newBill.type = 'expense'; // TODO: Sprint 2 需要添加类型选择
            newBill.note = this.notes;
            newBill.transactionDate = this.formatDate(this.selectedDate); // 'YYYY-MM-DD'
            newBill.createdAt = now;
            newBill.updatedAt = now;
            newBill.isDeleted = 0;
            //调用接口插入数据
            try{
              await BillDAO.insert(newBill);
              promptAction.showToast({ message: '保存成功' });

              // TODO: Sprint 1 任务，通知首页刷新
              // (目前先直接返回)

              router.back();
            }catch (error){
              console.error('[添加账单] 保存失败: %{public}s', JSON.stringify(error));
              promptAction.showToast({ message: `保存失败: ${error.message}` });
            }
          })
      }
      .padding(15)
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
