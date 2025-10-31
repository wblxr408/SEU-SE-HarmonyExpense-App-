import router from '@ohos.router'

@Entry
@Component
struct AddBill{
  @State amount: string = '';
  @State selectedDate: Date = new Date(); // 默认为当前日期
  @State notes: string = '';
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

        // 分类选择
        Row() {
          Text('分类').fontSize(16)

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
          .onChange((value) => {
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
          .onChange((value)=>{
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
          .onClick(() => {
            // 现阶段：不调用数据库
            // 只是打印信息并返回
            console.info(`[Mock Save] 金额: ${this.amount}, 日期: ${this.selectedDate}, 备注: ${this.notes}`);

            // TODO: Sprint 1 任务 ，这里需要调用 B 提供的 DAO 接口
            // 并且在成功后刷新首页列表

            // 返回上一页
            router.back();
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