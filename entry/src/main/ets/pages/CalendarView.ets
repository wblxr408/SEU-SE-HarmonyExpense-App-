// 移除错误的 @ohos.arkui.UI 导入，ArkUI 内置组件在 ArkTS 环境下通常全局可用，或者通过正确的 @kit.ArkUI 导入

import { promptAction } from '@kit.ArkUI';
import { AppTheme } from '../common/config/AppTheme';

export interface CalendarDay {
  day: number;
  date: Date;
  isCurrentMonth: boolean;
  expense: number;
  income: number;
  hasRecord: boolean;
}

@Entry
@Component
export struct CalendarView {
  @State currentDate: Date = new Date()
  @State selectedDate: Date = new Date()
  @State calendarDays: Array<CalendarDay> = []

  aboutToAppear() {
    this.generateCalendarDays()
  }

  isSameDate(d1: Date, d2: Date): boolean {
    return d1.getFullYear() === d2.getFullYear() &&
           d1.getMonth() === d2.getMonth() &&
           d1.getDate() === d2.getDate()
  }

  generateCalendarDays() {
    let days: Array<CalendarDay> = []
    let year = this.currentDate.getFullYear()
    let month = this.currentDate.getMonth()
    
    let firstDay = new Date(year, month, 1)
    let startDayOfWeek = firstDay.getDay()
    // ArkUI中通常星期一开始，0位对应的星期天移至末尾
    let startIndex = startDayOfWeek === 0 ? 6 : startDayOfWeek - 1
    
    let prevMonthDays = new Date(year, month, 0).getDate()
    for (let i = startIndex - 1; i >= 0; i--) {
      days.push({
        day: prevMonthDays - i,
        date: new Date(year, month - 1, prevMonthDays - i),
        isCurrentMonth: false,
        expense: 0,
        income: 0,
        hasRecord: false
      })
    }
    
    let currentMonthDays = new Date(year, month + 1, 0).getDate()
    for (let i = 1; i <= currentMonthDays; i++) {
      // 模拟一点账单数据用于预览 UI
      let expense = i % 5 === 0 ? 120.5 : 0
      let income = i % 8 === 0 ? 500 : 0
      days.push({
        day: i,
        date: new Date(year, month, i),
        isCurrentMonth: true,
        expense: expense,
        income: income,
        hasRecord: expense > 0 || income > 0
      })
    }
    
    // 填充到 42 格 (6 行 * 7 列)
    let remaining = 42 - days.length
    for (let i = 1; i <= remaining; i++) {
      days.push({
        day: i,
        date: new Date(year, month + 1, i),
        isCurrentMonth: false,
        expense: 0,
        income: 0,
        hasRecord: false
      })
    }
    
    this.calendarDays = days
  }

  getYearMonthString(): string {
    return `${this.currentDate.getFullYear()}年${this.currentDate.getMonth() + 1}月明细`
  }

  goToPreviousMonth() {
    this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() - 1, 1)
    this.generateCalendarDays()
  }

  goToNextMonth() {
    this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 1)
    this.generateCalendarDays()
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // ==============================
          // 顶部月份切换区
          // ==============================
          Row() {
            Text('<')
              .fontColor(AppTheme.TextMain)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .padding(10)
              .onClick(() => {
                this.goToPreviousMonth()
              })

            Text(this.getYearMonthString())
              .fontColor(AppTheme.TextMain)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 16, right: 16 })

            Text('>')
              .fontColor(AppTheme.TextMain)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .padding(10)
              .onClick(() => {
                this.goToNextMonth()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 16, bottom: 20 })

          // ==============================
          // 核心日历网格卡片 (Glassmorphic Calendar Card)
          // ==============================
          Column() {
            // 星期表头
            Row() {
              ForEach(['周一', '周二', '周三', '周四', '周五', '周六', '周日'], (day: string) => {
                Text(day)
                  .fontSize(12)
                  .fontColor(AppTheme.TextMain)
                  .width(`${100 / 7}%`)
                  .textAlign(TextAlign.Center)
              })
            }
            .width('100%')
            .margin({ bottom: 12 })

            // 日历主体
            Grid() {
              ForEach(this.calendarDays, (day: CalendarDay) => {
                GridItem() {
                  Column() {
                    Text(day.day.toString())
                      .fontSize(16)
                      .fontColor(this.isSameDate(day.date, this.selectedDate) ? AppTheme.TextWhite : AppTheme.TextMain)
                      .fontWeight(FontWeight.Medium)
                      .margin({ top: 4 })
                    
                    if (day.expense > 0 || day.income > 0) {
                      Column() {
                        if (day.expense > 0) {
                          Text(`-${day.expense}`)
                            .fontSize(10)
                            .fontColor(this.isSameDate(day.date, this.selectedDate) ? AppTheme.TextWhite : AppTheme.Expense)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        if (day.income > 0) {
                          Text(`+${day.income}`)
                            .fontSize(10)
                            .fontColor(this.isSameDate(day.date, this.selectedDate) ? AppTheme.TextWhite : AppTheme.Income)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                      }
                      .margin({ top: 2 })
                    }
                  }
                  .width('100%')
                  // 高度建议 56vp
                  .height(56)
                  .justifyContent(FlexAlign.Center)
                  .borderRadius(24)
                  // 背景色逻辑：选中/今天日期为活力橙，其他视需透明
                  .backgroundColor(this.isSameDate(day.date, this.selectedDate) ? AppTheme.HeroBg : 'transparent')
                  // 阴影逻辑：选中状态带有特定参数阴影
                  // 为了避免类型错误，使用条件判断或透明颜色模拟空阴影
                  .shadow(this.isSameDate(day.date, this.selectedDate) 
                    ? AppTheme.FabShadow
                    : { radius: 0, color: 'rgba(0,0,0,0)' })
                }
                // 非本月日期 opacity(0.3)
                .opacity(day.isCurrentMonth ? 1.0 : 0.3)
                .onClick(() => {
                  this.selectedDate = day.date
                })
              })
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .columnsGap(4)
            .rowsGap(8)
            .width('100%')
          }
          .backgroundColor(AppTheme.CardBg)
          .backdropBlur(25)
          .borderRadius(24)
          .border({ width: 0.5, color: AppTheme.Border })
          .shadow(AppTheme.CardShadow)
          .margin({ left: 16, right: 16 })
          .padding(20)

          // ==============================
          // 底部记录与操作区
          // ==============================
          Row() {
            // 左侧标题：马克笔高亮
            Stack({ alignContent: Alignment.BottomStart }) {
              Row()
                .width('100%')
                .height(8)
                .backgroundColor(AppTheme.CardBg)
                .margin({ bottom: 2 })
              Text('收支记录')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.TextMain)
            }

            // 右侧“记一笔”按钮：悬浮胶囊按钮
            Button('记一笔')
              .type(ButtonType.Capsule)
              // 高度 36vp
              .height(36)
              // 纯白背景
              .backgroundColor(AppTheme.CardBg)
              // 文字要求颜色
              .fontColor(AppTheme.TextMain)
              .fontSize(14)
              // 圆角 18vp (通过 ButtonType.Capsule 和 height=36 自动达成)
              // 加上微投影
              .shadow(AppTheme.CardShadow)
          }
          .width('100%')
          .padding(20)
          .justifyContent(FlexAlign.SpaceBetween)

          // 记录列表/空状态
          List() {
            // 这里用一个假节点展示空状态插画
            ListItem() {
              Column() {
                // 如果你有内置的一只可爱小猪图片，取消注释下方逻辑
                // Image($r('app.media.ic_empty_pig'))
                //   .width(120).height(120).margin({ bottom: 16 })
                
                // 作为替代示意，展示一个emoji (建议使用真实插画资源)
                Image($r('app.media.ill_empty_state_glass'))
                   .width(120).height(120).opacity(0.4).margin({ bottom: 16 }).objectFit(ImageFit.Contain)
                  
                Text('哎呀，当前时间没有记录呢~')
                  .fontSize(14)
                  .fontColor(AppTheme.TextSub)
              }
              .width('100%')
              .margin({ top: 40 })
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('100%')
          // 让List的内部空洞不引起滚动冲突，如果内容增加导致页面滚动
          // 可以设置 nestedScroll 等相关参数，依据真实交互再行拓展

        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    // 开启顶部及安全区沉浸式
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    // 全局渐变背景
    .backgroundColor(AppTheme.Background)
  }
}
