/**
 * 应用设置页面
 * 主题切换、语言选择、货币符号设置
 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import {
  AppSettingsService,
  ThemeMode,
  LanguageSetting,
  CurrencySymbol
} from '../service/AppSettingsService';

@Entry
@Component
struct AppSettingsPage {
  @State currentTheme: ThemeMode = ThemeMode.SYSTEM;
  @State currentLanguage: LanguageSetting = LanguageSetting.ZH_CN;
  @State currentCurrency: CurrencySymbol = CurrencySymbol.CNY;
  @State isLoading: boolean = true;

  async aboutToAppear() {
    try {
      this.currentTheme = await AppSettingsService.getTheme();
      this.currentLanguage = await AppSettingsService.getLanguage();
      this.currentCurrency = await AppSettingsService.getCurrencySymbol();
    } catch (error) {
      console.error('[AppSettingsPage] 加载设置失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Navigation() {
      Scroll() {
        Column() {
          // 主题设置
          Column() {
            Text('外观')
              .fontSize(14)
              .fontColor('#8395A7')
              .width('100%')
              .padding({ left: 16, top: 16, bottom: 8 })

            Column() {
              SettingRowItem({
                label: '浅色模式',
                isSelected: this.currentTheme === ThemeMode.LIGHT,
                onClickAction: () => {
                  this.setTheme(ThemeMode.LIGHT);
                }
              })
              Divider().color('#F0F0F0').padding({ left: 16 })
              SettingRowItem({
                label: '深色模式',
                isSelected: this.currentTheme === ThemeMode.DARK,
                onClickAction: () => {
                  this.setTheme(ThemeMode.DARK);
                }
              })
              Divider().color('#F0F0F0').padding({ left: 16 })
              SettingRowItem({
                label: '跟随系统',
                isSelected: this.currentTheme === ThemeMode.SYSTEM,
                onClickAction: () => {
                  this.setTheme(ThemeMode.SYSTEM);
                }
              })
            }
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ left: 16, right: 16 })
          }

          // 语言设置
          Column() {
            Text('语言')
              .fontSize(14)
              .fontColor('#8395A7')
              .width('100%')
              .padding({ left: 16, top: 24, bottom: 8 })

            Column() {
              SettingRowItem({
                label: '简体中文',
                isSelected: this.currentLanguage === LanguageSetting.ZH_CN,
                onClickAction: () => {
                  this.setLanguage(LanguageSetting.ZH_CN);
                }
              })
              Divider().color('#F0F0F0').padding({ left: 16 })
              SettingRowItem({
                label: 'English',
                isSelected: this.currentLanguage === LanguageSetting.EN_US,
                onClickAction: () => {
                  this.setLanguage(LanguageSetting.EN_US);
                }
              })
            }
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ left: 16, right: 16 })
          }

          // 货币符号设置
          Column() {
            Text('货币符号')
              .fontSize(14)
              .fontColor('#8395A7')
              .width('100%')
              .padding({ left: 16, top: 24, bottom: 8 })

            Column() {
              SettingRowItem({
                label: '¥ 人民币 (CNY)',
                isSelected: this.currentCurrency === CurrencySymbol.CNY,
                onClickAction: () => {
                  this.setCurrency(CurrencySymbol.CNY);
                }
              })
              Divider().color('#F0F0F0').padding({ left: 16 })
              SettingRowItem({
                label: '$ 美元 (USD)',
                isSelected: this.currentCurrency === CurrencySymbol.USD,
                onClickAction: () => {
                  this.setCurrency(CurrencySymbol.USD);
                }
              })
              Divider().color('#F0F0F0').padding({ left: 16 })
              SettingRowItem({
                label: '€ 欧元 (EUR)',
                isSelected: this.currentCurrency === CurrencySymbol.EUR,
                onClickAction: () => {
                  this.setCurrency(CurrencySymbol.EUR);
                }
              })
              Divider().color('#F0F0F0').padding({ left: 16 })
              SettingRowItem({
                label: '£ 英镑 (GBP)',
                isSelected: this.currentCurrency === CurrencySymbol.GBP,
                onClickAction: () => {
                  this.setCurrency(CurrencySymbol.GBP);
                }
              })
            }
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ left: 16, right: 16 })
          }

          // 重置按钮
          Button('恢复默认设置')
            .width('90%')
            .height(50)
            .margin({ top: 40 })
            .backgroundColor('#F5F7F9')
            .fontColor('#2D3436')
            .onClick(() => this.resetDefaults())
        }
        .width('100%')
        .padding({ bottom: 40 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7F9')
    }
    .title('应用设置')
    .titleMode(NavigationTitleMode.Mini)
  }



  async setTheme(theme: ThemeMode) {
    // 先更新UI状态，确保立即响应
    this.currentTheme = theme;
    try {
      await AppSettingsService.setTheme(theme);
      promptAction.showToast({ message: '主题已切换' });
    } catch (error) {
      promptAction.showToast({ message: '切换失败' });
    }
  }

  async setLanguage(language: LanguageSetting) {
    // 先更新UI状态，确保立即响应
    this.currentLanguage = language;
    try {
      await AppSettingsService.setLanguage(language);
      promptAction.showToast({ message: '语言已切换，重启后生效' });
    } catch (error) {
      promptAction.showToast({ message: '切换失败' });
    }
  }

  async setCurrency(currency: CurrencySymbol) {
    // 先更新UI状态，确保立即响应
    this.currentCurrency = currency;
    try {
      await AppSettingsService.setCurrencySymbol(currency);
      promptAction.showToast({ message: '货币符号已更新' });
    } catch (error) {
      promptAction.showToast({ message: '更新失败' });
    }
  }

  async resetDefaults() {
    try {
      await AppSettingsService.resetToDefaults();
      this.currentTheme = ThemeMode.SYSTEM;
      this.currentLanguage = LanguageSetting.ZH_CN;
      this.currentCurrency = CurrencySymbol.CNY;
      promptAction.showToast({ message: '已恢复默认设置' });
    } catch (error) {
      promptAction.showToast({ message: '重置失败' });
    }
  }
}

@Component
struct SettingRowItem {
  @Prop isSelected: boolean
  label: string = ''
  onClickAction: () => void = () => {}

  build() {
    Row() {
      Text(this.label)
        .fontSize(16)
        .fontColor('#2D3436')
        .layoutWeight(1)
      if (this.isSelected) {
        Text('✓')
          .fontSize(18)
          .fontColor('#2E65F3')
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      this.onClickAction()
    })
  }
}
