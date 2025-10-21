import { BreakpointSystem, BreakPointType } from '../common/BreakpointSystem'

@Entry
@Component
struct Home {
  @State currentTabIndex: number = 0
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  private breakpointSystem: BreakpointSystem = new BreakpointSystem()

  @Builder
  bottomBarItemBuilder(name: Resource, icon: Resource, index: number) {
    Flex({
      direction: new BreakPointType({
        sm: FlexDirection.Column,
        md: FlexDirection.Row,
        lg: FlexDirection.Column
      }).getValue(this.currentBreakpoint),
      justifyContent: FlexAlign.Center,
      alignItems: ItemAlign.Center
    }) {
      Image(icon)
        .height(24)
        .width(24)
        .fillColor(this.getTabBarColor(index))
      Text(name)
        .margin(new BreakPointType<Padding>({
          sm: { top: 4 },
          md: { left: 8 },
          lg: { top: 4 }
        }).getValue(this.currentBreakpoint) as Padding)
        .fontSize(11)
        .fontColor(this.getTabBarColor(index))
    }
  }

  aboutToAppear() {
    this.breakpointSystem.register()
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister()
  }

  build() {
    Tabs({
      barPosition: new BreakPointType({
        sm: BarPosition.End,
        md: BarPosition.End,
        lg: BarPosition.Start
      }).getValue(this.currentBreakpoint)
    })
    .vertical(new BreakPointType({ sm: false, md: false, lg: true }).getValue(this.currentBreakpoint) as boolean)
    .barWidth(new BreakPointType({ sm: '100%', md: '100%', lg: '56vp' }).getValue(this.currentBreakpoint) as string)
    .barHeight(new BreakPointType({ sm: '56vp', md: '56vp', lg: '60%' }).getValue(this.currentBreakpoint) as string)
    .animationDuration(0)
    .onChange((index) => {
      this.currentTabIndex = index
    })
  }

  private getTabBarColor(index: number) {
    return this.currentTabIndex == index ? $r('app.color.tab_bar_select_color') : $r('app.color.tab_bar_normal_color')
  }
}