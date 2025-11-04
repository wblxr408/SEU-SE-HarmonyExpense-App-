


// 使用新模块
import { router } from '@kit.ArkUI';
import { Bill } from '../model/Bill'; //
import { BillDAO } from '../dao/BillDAO'; //
import hilog from '@ohos.hilog'; // 用于日志
import { BusinessError } from '@ohos.base';


@Entry
@Component
struct Index {
  @State transactions: Array<Bill> = []; //定义一个变量，用于存储交易数据>;
  @State isLoading: boolean = true;
  //添加onPageShow 生命周期函数
  onPageShow() {
    hilog.info(0x0000, 'Index', 'onPageShow triggered');
    this.loadBills();
  }
  async loadBills() {
    this.isLoading = true;

    try {
      //使用BillDAO类中的getAllBills方法获取所有交易数据
      const billsFromDB = await BillDAO.getAll();
      this.transactions = billsFromDB;
      this.isLoading = false;
    } catch (error) {

        // 处理业务错误
        hilog.error(0x0000, 'Index','加载账单失败: %{public}s', JSON.stringify(error));

    }  finally{
      this.isLoading = false;
    }
  }

  build() {
    //使用Navigation函数来显示页面导航和标题栏
    Navigation() {
      Column() {
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

}




