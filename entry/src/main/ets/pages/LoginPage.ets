import router from '@ohos.router';
import { UserSessionService, LoginResult } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';
import { DemoDataService } from '../service/DemoDataService';

@Entry
@Component
struct LoginPage {

  @State email: string = '';
  @State password: string = '';

  build() {
    Column() {
      Text('欢迎回来')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100, bottom: 20 })

      TextInput({ placeholder: '邮箱' })
        .width('80%')
        .height(50)
        .margin({ bottom: 20 })
        .onChange((value: string) => {
          this.email = value;
        })

      TextInput({ placeholder: '密码' })
        .type(InputType.Password)
        .width('80%')
        .height(50)
        .margin({ bottom: 40 })
        .onChange((value: string) => {
          this.password = value;
        })

      Button('登录')
        .width('80%')
        .height(50)
        .type(ButtonType.Capsule)
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
          .fontColor(Color.Gray)
        Text('立即注册')
          .fontSize(14)
          .fontColor(Color.Blue)
          .onClick(() => {
            router.pushUrl({ url: 'pages/RegisterPage' });
          })
      }
      .margin({ top: 20 })

      Button('一键演示 (Demo Mode)')
        .width('60%')
        .height(40)
        .type(ButtonType.Normal)
        .fontColor('#4A90E2')
        .backgroundColor(Color.Transparent)
        .margin({ top: 40 })
        .onClick(async () => {
          promptAction.showToast({ message: '正在准备演示环境...' });

          const success = await DemoDataService.setupDemoUser();
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
    .backgroundColor('#F1F3F5')
  }
}
