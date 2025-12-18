import router from '@ohos.router';
<<<<<<< HEAD
import { UserSessionService, LoginResult } from '../service/UserSessionService';
import promptAction from '@ohos.promptAction';
=======
import promptAction from '@ohos.promptAction';
import { User } from '../model/User';
import { UserDAO } from '../dao/UserDAO';
import { AppTheme } from '../common/AppTheme';
>>>>>>> main

@Entry
@Component
struct LoginPage {
<<<<<<< HEAD
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
=======
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;

  // ================= 逻辑区域 (完全保持不变) =================

  // 登录逻辑
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

  // 注册逻辑
  async handleRegister() {
    // 【修改 1】: 增加邮箱非空校验
    if (!this.username || !this.password) {
      promptAction.showToast({ message: '请填写完整的注册信息' });
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
      newUser.email = `${this.username}@example.com`;
      newUser.createdAt = new Date().toISOString();
      newUser.updatedAt = new Date().toISOString();

      await UserDAO.insert(newUser);

      promptAction.showToast({ message: '注册成功，请点击登录' });
    } catch (error) {
      // 提示：如果邮箱重复（数据库有 UNIQUE 约束），也会在这里报错
      promptAction.showToast({ message: '注册失败: 用户名可能已存在' });
    } finally {
      this.isLoading = false;
    }
  }

  // ================= UI 构建区域 (已美化) =================
  @Builder
  InputRow(icon: Resource, placeholder: string, text: string, isPassword: boolean, onChange: (val: string) => void) {
    Row() {
      Image(icon)
        .width(20)
        .height(20)
        .margin({ left: 16, right: 12 })
        // 【修复点2】调用时使用 AppTheme.TextSub
        .fillColor(AppTheme.TextSub)

      TextInput({ placeholder: placeholder, text: text })
        .type(isPassword ? InputType.Password : InputType.Normal)
        .height(50)
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .placeholderColor(AppTheme.TextSub)
        .fontColor(AppTheme.TextMain)
        .onChange(onChange)
    }
    .width('100%')
    .height(52)
    .backgroundColor(AppTheme.InputBg)
    .borderRadius(16)
    .margin({ bottom: 16 })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 1. 背景装饰层
      Column()
        .width('100%')
        .height('40%')
        .linearGradient({
          angle: 180,
          colors: [
            // 【修复点3】ArkTS 中数组字面量需要明确，这里没问题，但颜色要引用类属性
            [AppTheme.PrimaryLight, 0.0],
            [AppTheme.Primary, 1.0]
          ]
        })
        .borderRadius({ bottomLeft: 40, bottomRight: 40 })

      // 2. 内容主体
      Column() {
        // --- Logo 区域 ---
        Column({ space: 8 }) {
          Image($r('app.media.icon'))
            .width(80)
            .height(80)
            .borderRadius(20)
            .backgroundColor(Color.White)
            .padding(2)
            .shadow({ radius: 30, color: 'rgba(0,0,0,0.1)', offsetY: 10 })

          Text('HarmonyExpense')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ top: 12 })
            .opacity(0.95)

          Text('记录每一笔美好')
            .fontSize(14)
            .fontColor(Color.White)
            .opacity(0.8)
        }
        .margin({ top: 80, bottom: 30 })

        // --- 悬浮卡片区域 ---
        Column() {
          Text('欢迎登录')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.TextMain)
            .width('100%')
            .margin({ bottom: 24, left: 4 })

          // 调用 InputRow (保持不变)
          this.InputRow($r('app.media.user'), '用户名', this.username, false, (val: string) => { this.username = val })

          this.InputRow($r('app.media.password'), '密码', this.password, true, (val: string) => { this.password = val })

          // --- 按钮区域 ---
          Column({ space: 16 }) {
            Button(this.isLoading ? '处理中...' : '登 录')
              .width('100%')
              .height(50)
              .type(ButtonType.Capsule)
              .backgroundColor(AppTheme.Primary)
              .shadow({ radius: 20, color: AppTheme.Shadow, offsetY: 8 })
              .enabled(!this.isLoading)
              .onClick(() => this.handleLogin())

            Row() {
              Text('还没有账号？')
                .fontSize(14)
                .fontColor(AppTheme.TextSub)
              Text('立即注册')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppTheme.Primary)
                .margin({ left: 5 })
            }
            .padding(10)
            .onClick(() => this.handleRegister())
          }
          .margin({ top: 10 })

        }
        .width('90%')
        .padding({ top: 32, bottom: 32, left: 24, right: 24 })
        .backgroundColor(AppTheme.CardBg)
        .borderRadius(24)
        .shadow({ radius: 40, color: 'rgba(0,0,0,0.06)', offsetY: 20 })

      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.Background)
>>>>>>> main
  }
}
