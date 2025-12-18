import router from '@ohos.router';
import { UserSessionService, LoginResult } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';

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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
