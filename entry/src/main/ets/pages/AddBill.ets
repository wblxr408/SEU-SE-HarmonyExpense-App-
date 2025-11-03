import router from '@ohos.router'
import { Bill } from '../model/Bill'
import { BillDAO } from '../dao/BillDAO'
// 2. 导入 promptAction 用于显示 Toast 提示
import promptAction from '@ohos.promptAction'
@Entry
@Component
struct AddBill{
  @State amount: string = '';
  @State selectedDate: Date = new Date(); // 默认为当前日期
  @State notes: string = '';
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

          Text('餐饮 >') // 这是一个模拟的选择器
            .fontSize(16)
            .fontColor(Color.Gray)
            .onClick(() => {
              // TODO: 在 Sprint 2 中实现分类管理页面
              console.info('弹出分类选择器');
            })
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
              promptAction.showToast({ message: '请输入有效的金额' });
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
      .backgroundColor('#F1F3F5')
    }
    .title('记一笔')
    .titleMode(NavigationTitleMode.Mini)
  }
}

function Spacer() {
  throw new Error('Function not implemented.');
}
