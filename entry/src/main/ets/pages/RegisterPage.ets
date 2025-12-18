import router from '@ohos.router';
import { UserSessionService, LoginResult } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State email: string = '';
  @State password: string = '';

  build() {
    Column() {
      Text('创建账号')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 20 })

      TextInput({ placeholder: '用户名' })
        .width('80%')
        .height(50)
        .margin({ bottom: 20 })
        .onChange((value: string) => {
          this.username = value;
        })

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

      Button('注册')
        .width('80%')
        .height(50)
        .type(ButtonType.Capsule)
        .onClick(async () => {
          if (!this.username || !this.email || !this.password) {
            try {
              promptAction.showToast({ message: '请填写完整信息' });
            } catch (e) {}
            return;
          }
          const result: LoginResult = await UserSessionService.register(this.username, this.email, this.password);
          if (result.success) {
            try {
              promptAction.showToast({ message: '注册成功，已自动登录' });
            } catch (e) {}
            router.replaceUrl({ url: 'pages/Index' });
          } else {
            try {
              promptAction.showToast({ message: result.message });
            } catch (e) {}
          }
        })

      Row() {
        Text('已有账号？')
          .fontSize(14)
          .fontColor(Color.Gray)
        Text('直接登录')
          .fontSize(14)
          .fontColor(Color.Blue)
          .onClick(() => {
            router.back();
          })
      }
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
