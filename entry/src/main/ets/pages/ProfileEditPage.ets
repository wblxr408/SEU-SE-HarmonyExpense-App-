
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import { UserSessionService, SessionInfo } from '../service/UserSessionService';
import { AppTheme } from '../common/config/AppTheme';

@Entry
@Component
struct ProfileEditPage {
  @State currentUser: SessionInfo | null = null;
  @State nickname: string = '';
  @State email: string = '';
  @State avatarPath: string = '';
  @State isLoading: boolean = false;

  @State showPasswordDialog: boolean = false;
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';

  async aboutToAppear() {
    this.currentUser = await UserSessionService.getCurrentSession();
    if (this.currentUser) {
      this.nickname = this.currentUser.username;
      this.email = this.currentUser.email;
    }
  }

  build() {
    Navigation() {
      Scroll() {
        Column() {
          Column() {
            Stack() {
              if (this.avatarPath) {
                Image(this.avatarPath)
                  .width(104)
                  .height(104)
                  .borderRadius(52)
                  .objectFit(ImageFit.Cover)
              } else {
                Image($r('app.media.ic_user_avatar_glass'))
                  .width(104)
                  .height(104)
                  .padding(14)
                  .borderRadius(52)
                  .backgroundColor(AppTheme.CardBg)
                  .backdropBlur(18)
                  .border({ width: 0.5, color: AppTheme.Border })
              }

              Row() {
                Image($r('app.media.ic_edit_glass'))
                  .width(16)
                  .height(16)
              }
              .width(32)
              .height(32)
              .backgroundColor(AppTheme.HeroBg)
              .borderRadius(16)
              .justifyContent(FlexAlign.Center)
              .position({ x: 72, y: 72 })
            }
            .width(104)
            .height(104)
            .onClick(() => this.selectAvatar())

            Text('点击更换头像')
              .fontSize(12)
              .fontColor(AppTheme.TextSub)
              .margin({ top: 10 })
          }
          .margin({ top: 24, bottom: 24 })

          Column() {
            this.FormItem('昵称', this.nickname, (value: string) => {
              this.nickname = value;
            })

            Divider().color(AppTheme.Border)

            this.FormItem('邮箱', this.email, (value: string) => {
              this.email = value;
            })

            Divider().color(AppTheme.Border)

            Row() {
              Text('修改密码')
                .fontSize(16)
                .fontColor(AppTheme.TextMain)
                .layoutWeight(1)
              Image($r('app.media.ic_chevron_right_glass'))
                .width(16)
                .height(16)
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.showPasswordDialog = true;
            })
          }
          .backgroundColor(AppTheme.CardBg)
          .backdropBlur(18)
          .border({ width: 0.5, color: AppTheme.Border })
          .borderRadius(20)
          .margin({ left: 16, right: 16 })

          Button(this.isLoading ? '保存中...' : '保存修改')
            .width('90%')
            .height(50)
            .margin({ top: 40 })
            .backgroundColor(AppTheme.HeroBg)
            .fontColor(AppTheme.TextWhite)
            .enabled(!this.isLoading)
            .onClick(() => this.saveProfile())
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.Background)

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
        .fontColor(AppTheme.TextMain)
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
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.45)')
        .position({ x: 0, y: 0 })
        .onClick(() => {
          this.showPasswordDialog = false;
        })

      Column() {
        Text('修改密码')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TextMain)
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
            .backgroundColor(AppTheme.Background)
            .fontColor(AppTheme.TextMain)
            .onClick(() => {
              this.showPasswordDialog = false;
              this.oldPassword = '';
              this.newPassword = '';
              this.confirmPassword = '';
            })
          Button('确认')
            .width('45%')
            .height(44)
            .backgroundColor(AppTheme.HeroBg)
            .fontColor(AppTheme.TextWhite)
            .onClick(() => this.changePassword())
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .padding(24)
      .backgroundColor(AppTheme.CardBg)
      .backdropBlur(20)
      .borderRadius(20)
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
      console.error('[ProfileEditPage] Failed to select avatar:', error);
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
      const profileResult = await UserSessionService.updateProfile(this.nickname, this.avatarPath);
      if (!profileResult) {
        promptAction.showToast({ message: '保存失败' });
        return;
      }

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
      console.error('[ProfileEditPage] Failed to save profile:', error);
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
      promptAction.showToast({ message: '新密码长度至少 6 位' });
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
