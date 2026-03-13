
import router from '@ohos.router';
import { UserSessionService, LoginResult } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';
import { DemoDataService } from '../service/DemoDataService';
import { AppTheme } from '../common/config/AppTheme';

@Entry
@Component
struct LoginPage {

  @State email: string = '';
  @State password: string = '';

  build() {
    Stack() {
      // 全局背景：铺满全屏的渐变色
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppTheme.Background)

      Column() {
        // 标题文字：主文本色，避让沉浸式状态栏
        Text('欢迎回来')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TextMain)
          .margin({ top: 120, bottom: 40 })

        // 输入框 (TextInput)：实现玻璃拟态
        TextInput({ placeholder: '邮箱', text: this.email })
          .width('85%')
          .height(56)
          .margin({ bottom: 20 })
          .backgroundColor('rgba(255, 255, 255, 0.6)')
          .backdropBlur(20)
          .borderRadius(16)
          .placeholderColor('rgba(0, 0, 0, 0.4)')
          .padding({ left: 20, right: 20 })
          .onChange((value: string) => {
            this.email = value;
          })

        TextInput({ placeholder: '密码', text: this.password })
          .type(InputType.Password)
          .width('85%')
          .height(56)
          .margin({ bottom: 48 })
          .backgroundColor('rgba(255, 255, 255, 0.6)')
          .backdropBlur(20)
          .borderRadius(16)
          .placeholderColor('rgba(0, 0, 0, 0.4)')
          .padding({ left: 20, right: 20 })
          .onChange((value: string) => {
            this.password = value;
          })

        // 登录按钮：活力橙 + 新拟态发光阴影
        Button('立即登录')
          .width('85%')
          .height(56)
          .type(ButtonType.Capsule)
          .backgroundColor(AppTheme.HeroBg)
          .fontColor(AppTheme.TextWhite)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .borderRadius(24)
          .shadow(AppTheme.FabShadow)
          .onClick(async () => {
            if (!this.email || !this.password) {
              promptAction.showToast({ message: '请输入邮箱和密码' });
              return;
            }
            const result: LoginResult = await UserSessionService.login(this.email, this.password);
            if (result.success) {
              promptAction.showToast({ message: '登录成功' });
              router.replaceUrl({ url: 'pages/Index' });
            } else {
              promptAction.showToast({ message: result.message });
            }
          })

        Row() {
          Text('还没有账号？')
            .fontSize(14)
            .fontColor(AppTheme.TextSub)
          Text('立即注册')
            .fontSize(14)
            .fontColor(AppTheme.TextMain) // 深绿色
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              router.pushUrl({ url: 'pages/RegisterPage' });
            })
        }
        .margin({ top: 24 })

        // 一键演示
        Button('尝试 Demo 环境')
          .width('60%')
          .height(44)
          .type(ButtonType.Normal)
          .fontColor(AppTheme.TextMain) // 深绿色
          .backgroundColor(Color.Transparent)
          .margin({ top: 60 })
          .onClick(async () => {
            promptAction.showToast({ message: '正在准备演示环境...' });

            const success = await DemoDataService.setupDemoUser(getContext(this));
            if (success) {
              promptAction.showToast({ message: '演示环境就绪' });
              router.replaceUrl({ url: 'pages/Index' });
            } else {
               promptAction.showToast({ message: '演示模式启动失败' });
            }
          })
      }
      .width('100%')
      .height('100%')
      .padding({ top: 48 })
    }
    .width('100%')
    .height('100%')
  }

  pageTransition() {
    PageTransitionEnter({ duration: 200 })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 200 })
      .slide(SlideEffect.Left)
  }
}
