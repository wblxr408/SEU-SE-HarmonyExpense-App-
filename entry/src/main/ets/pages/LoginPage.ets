import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { User } from '../model/User';
import { UserDAO } from '../dao/UserDAO';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  // 【新增 1】: 添加邮箱状态
  @State email: string = '';
  @State isLoading: boolean = false;

  // 登录逻辑 (保持不变，登录通常只需要用户名/密码)
  async handleLogin() {
    if (!this.username || !this.password) {
      promptAction.showToast({ message: '请输入用户名和密码' });
      return;
    }

    this.isLoading = true;
    try {
      const user = await UserDAO.getByUsername(this.username);

      if (!user) {
        promptAction.showToast({ message: '用户不存在，请先注册' });
        this.isLoading = false;
        return;
      }

      if (user.passwordHash !== this.password) {
        promptAction.showToast({ message: '密码错误' });
        this.isLoading = false;
        return;
      }

      // 登录成功，保存全局 ID
      AppStorage.SetOrCreate('currentUserId', user.userId);

      promptAction.showToast({ message: '登录成功' });
      router.replaceUrl({ url: 'pages/Index' });

    } catch (error) {
      promptAction.showToast({ message: '登录出错: ' + error.message });
      this.isLoading = false;
    }
  }

  // 注册逻辑 (已修改)
  async handleRegister() {
    // 【修改 1】: 增加邮箱非空校验
    if (!this.username || !this.password || !this.email) {
      promptAction.showToast({ message: '请填写完整的注册信息（含邮箱）' });
      return;
    }

    this.isLoading = true;
    try {
      const existingUser = await UserDAO.getByUsername(this.username);
      if (existingUser) {
        promptAction.showToast({ message: '用户名已存在' });
        this.isLoading = false;
        return;
      }

      const newUser = new User();
      newUser.username = this.username;
      newUser.passwordHash = this.password;
      // 【修改 2】: 使用用户输入的邮箱
      newUser.email = this.email;
      newUser.createdAt = new Date().toISOString();
      newUser.updatedAt = new Date().toISOString();

      await UserDAO.insert(newUser);

      promptAction.showToast({ message: '注册成功，请点击登录' });
    } catch (error) {
      // 提示：如果邮箱重复（数据库有 UNIQUE 约束），也会在这里报错
      promptAction.showToast({ message: '注册失败: 邮箱或用户名可能已存在' });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 1. Logo 区域
      Column({ space: 10 }) {
        Image($r('app.media.app_icon'))
          .width(80)
          .height(80)
          .margin({ bottom: 10 })
          .borderRadius(16)

        Text('HarmonyExpense')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text('记账，从未如此简单')
          .fontSize(14)
          .fontColor('#999999')
      }
      .margin({ top: 60, bottom: 40 })

      // 2. 输入区域
      Column({ space: 15 }) {
        // 用户名
        TextInput({ placeholder: '用户名', text: this.username })
          .height(50)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#E0E0E0', radius: 8 })
          .padding({ left: 15 })
          .onChange((value) => this.username = value)

        // 【新增 2】: 邮箱输入框
        TextInput({ placeholder: '邮箱 (注册必填)', text: this.email })
          .height(50)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#E0E0E0', radius: 8 })
          .padding({ left: 15 })
          .onChange((value) => this.email = value)

        // 密码
        TextInput({ placeholder: '密码', text: this.password })
          .type(InputType.Password)
          .height(50)
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#E0E0E0', radius: 8 })
          .padding({ left: 15 })
          .onChange((value) => this.password = value)
      }
      .width('85%')

      // 3. 按钮区域
      Column({ space: 15 }) {
        Button(this.isLoading ? '处理中...' : '登录')
          .width('85%')
          .height(50)
          .type(ButtonType.Capsule)
          .backgroundColor('#007DFF')
          .onClick(() => this.handleLogin())
          .enabled(!this.isLoading)

        Button('注册账号')
          .width('85%')
          .height(50)
          .type(ButtonType.Normal)
          .fontColor('#007DFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => this.handleRegister())
          .enabled(!this.isLoading)
      }
      .margin({ top: 40 })

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}