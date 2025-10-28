import {MOCK_TRANSACTIONS} from '../mock/MockData';
import {Transaction} from '../model/Transaction';
import router from '@ohos.router';


@Entry
@Component
struct Index {
  @State transactions: Array<Transaction> = MOCK_TRANSACTIONS;

  build() {
    //使用Navigation函数来显示页面导航和标题栏
    Navigation() {
      Column() {
        //UI的依赖状态
        List({ space: 10 }) {
          ForEach(this.transactions, (item: Transaction) => {
            ListItem() {
              //将展示内容封装成函数
              this.TransactionRow(item);
            }
          })
        }
        .layoutWeight(1) //列表占据剩余空间
        .padding({ left: 12, right: 12 })
      }

      //表格展示结束
      Button('记一笔')
        .type(ButtonType.Capsule)
        .fontSize(18)
        .width('80%')
        .height(50)
        .margin(20) //设置按钮外边框
        .onClick(() => {
          //当State变量遭到修改的话
          const newBill = new Transaction(99, 25, 'expense', '咖啡', '2025-10-28');
          //MOCK_TRANSACTION 是只读 不能直接push
          this.transactions = [...this.transactions, newBill];
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.point_color_checked')) //设置一个浅灰色的背景
    .title('记账APP 首页')
    .titleMode(NavigationTitleMode.Mini)
  }

  //自定义的展示行的函数
  @Builder
  TransactionRow(item: Transaction) {
    Row() {
        //暂时用图片代替资源
      Image(item.type=='expense'?$r('app.media.ic_expense_default'):$r('app.media.ic_income_default'))
        .width(40)
        .height(40)
        .margin({right:10})
        .objectFit(ImageFit.Contain)
      Column() {
        Text(item.type).fontSize(16).fontWeight(FontWeight.Bold)
        Text(item.notes).fontSize(14).fontColor(Color.Gray)
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

}




