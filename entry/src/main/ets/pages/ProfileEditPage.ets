/**
 * 个人信息编辑页面
 * 支持头像更换、昵称编辑、邮箱修改、密码修改
 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import { UserSessionService, SessionInfo } from '../service/UserSessionService';

@Entry
@Component
struct ProfileEditPage {
  @State currentUser: SessionInfo | null = null;
  @State nickname: string = '';
  @State email: string = '';
  @State avatarPath: string = '';
  @State isLoading: boolean = false;

  // 密码修改
  @State showPasswordDialog: boolean = false;
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';

async   aboutToAppear() {
    this.currentUser =await UserSessionService.getCurrentSession();
    if (this.currentUser) {
      this.nickname = this.currentUser.username;
      this.email = this.currentUser.email;
    }
  }

  build() {
    Navigation() {
      Scroll() {
        Column() {
          // 头像区域
          Column() {
            Stack() {
              if (this.avatarPath) {
                Image(this.avatarPath)
                  .width(100)
                  .height(100)
                  .borderRadius(50)
                  .objectFit(ImageFit.Cover)
              } else {
                Image($r('app.media.icon'))
                  .width(100)
                  .height(100)
                  .borderRadius(50)
                  .backgroundColor('#E0E0E0')
              }
              // 编辑按钮
              Row() {
                Text('📷')
                  .fontSize(16)
              }
              .width(32)
              .height(32)
              .backgroundColor('#2E65F3')
              .borderRadius(16)
              .justifyContent(FlexAlign.Center)
              .position({ x: 70, y: 70 })
            }
            .width(100)
            .height(100)
            .onClick(() => this.selectAvatar())

            Text('点击更换头像')
              .fontSize(12)
              .fontColor('#8395A7')
              .margin({ top: 8 })
          }
          .margin({ top: 24, bottom: 24 })

          // 表单区域
          Column() {
            // 昵称
            this.FormItem('昵称', this.nickname, (value: string) => {
              this.nickname = value;
            })

            Divider().color('#F0F0F0')

            // 邮箱
            this.FormItem('邮箱', this.email, (value: string) => {
              this.email = value;
            })

            Divider().color('#F0F0F0')

            // 修改密码
            Row() {
              Text('修改密码')
                .fontSize(16)
                .fontColor('#2D3436')
                .layoutWeight(1)
              Text('>')
                .fontSize(18)
                .fontColor('#8395A7')
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.showPasswordDialog = true;
            })
          }
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ left: 16, right: 16 })

          // 保存按钮
          Button('保存修改')
            .width('90%')
            .height(50)
            .margin({ top: 40 })
            .backgroundColor('#2E65F3')
            .onClick(() => this.saveProfile())
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7F9')

      // 密码修改弹窗
      if (this.showPasswordDialog) {
        this.PasswordDialog()
      }
    }
    .title('编辑资料')
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  FormItem(label: string, value: string, onChange: (value: string) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#2D3436')
        .width(80)
      TextInput({ text: value, placeholder: `请输入${label}` })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .onChange(onChange)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  PasswordDialog() {
    Column() {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .position({ x: 0, y: 0 })
        .onClick(() => {
          this.showPasswordDialog = false;
        })

      // 弹窗内容
      Column() {
        Text('修改密码')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 24 })

        TextInput({ placeholder: '请输入旧密码' })
          .type(InputType.Password)
          .width('100%')
          .height(44)
          .margin({ bottom: 12 })
          .onChange((value: string) => {
            this.oldPassword = value;
          })

        TextInput({ placeholder: '请输入新密码' })
          .type(InputType.Password)
          .width('100%')
          .height(44)
          .margin({ bottom: 12 })
          .onChange((value: string) => {
            this.newPassword = value;
          })

        TextInput({ placeholder: '再次确认新密码' })
          .type(InputType.Password)
          .width('100%')
          .height(44)
          .margin({ bottom: 24 })
          .onChange((value: string) => {
            this.confirmPassword = value;
          })

        Row() {
          Button('取消')
            .width('45%')
            .height(44)
            .backgroundColor('#F5F7F9')
            .fontColor('#2D3436')
            .onClick(() => {
              this.showPasswordDialog = false;
              this.oldPassword = '';
              this.newPassword = '';
              this.confirmPassword = '';
            })
          Button('确认')
            .width('45%')
            .height(44)
            .backgroundColor('#2E65F3')
            .onClick(() => this.changePassword())
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .padding(24)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .width('85%')
      .position({ x: '7.5%', y: '30%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  async selectAvatar() {
    try {
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (result.photoUris && result.photoUris.length > 0) {
        this.avatarPath = result.photoUris[0];
        promptAction.showToast({ message: '头像已选择' });
      }
    } catch (error) {
      console.error('[ProfileEditPage] 选择头像失败:', error);
      promptAction.showToast({ message: '选择图片失败' });
    }
  }

  async saveProfile() {
    if (!this.nickname.trim()) {
      promptAction.showToast({ message: '昵称不能为空' });
      return;
    }

    this.isLoading = true;
    try {
      // 更新资料
      const profileResult = await UserSessionService.updateProfile(this.nickname, this.avatarPath);
      if (!profileResult) {
        promptAction.showToast({ message: '保存失败' });
        return;
      }

      // 如果邮箱有变化，更新邮箱
      if (this.email !== this.currentUser?.email) {
        const emailResult = await UserSessionService.updateEmail(this.email);
        if (!emailResult.success) {
          promptAction.showToast({ message: emailResult.message });
          return;
        }
      }

      promptAction.showToast({ message: '保存成功' });
      router.back();
    } catch (error) {
      console.error('[ProfileEditPage] 保存失败:', error);
      promptAction.showToast({ message: '保存失败' });
    } finally {
      this.isLoading = false;
    }
  }

  async changePassword() {
    if (!this.oldPassword || !this.newPassword || !this.confirmPassword) {
      promptAction.showToast({ message: '请填写完整密码信息' });
      return;
    }
    if (this.newPassword !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的新密码不一致' });
      return;
    }
    if (this.newPassword.length < 6) {
      promptAction.showToast({ message: '新密码长度至少6位' });
      return;
    }

    const result = await UserSessionService.changePassword(this.oldPassword, this.newPassword);
    promptAction.showToast({ message: result.message });
    if (result.success) {
      this.showPasswordDialog = false;
      this.oldPassword = '';
      this.newPassword = '';
      this.confirmPassword = '';
    }
  }
}
