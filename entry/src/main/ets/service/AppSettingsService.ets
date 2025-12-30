/**
 * 应用设置服务
 * 管理主题、语言、货币等应用级配置
 */
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

/**
 * 主题模式
 */
export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system'
}

/**
 * 语言设置
 */
export enum LanguageSetting {
  ZH_CN = 'zh_CN',
  EN_US = 'en_US'
}

/**
 * 货币符号
 */
export enum CurrencySymbol {
  CNY = '¥',
  USD = '$',
  EUR = '€',
  JPY = '¥',
  GBP = '£'
}

/**
 * 应用设置
 */
export interface AppSettings {
  theme: ThemeMode;
  language: LanguageSetting;
  currencySymbol: CurrencySymbol;
}

const PREFERENCES_NAME = 'app_settings';
const KEY_THEME = 'theme';
const KEY_LANGUAGE = 'language';
const KEY_CURRENCY = 'currency_symbol';

export class AppSettingsService {
  private static preferencesInstance: preferences.Preferences | null = null;
  private static initPromise: Promise<void> | null = null;

  /**
   * 初始化 Preferences
   */
  static async init(context: common.UIAbilityContext): Promise<void> {
    if (AppSettingsService.initPromise) {
      return AppSettingsService.initPromise;
    }

    AppSettingsService.initPromise = (async () => {
      try {
        AppSettingsService.preferencesInstance = await preferences.getPreferences(context, PREFERENCES_NAME);
        console.log('[AppSettingsService] 初始化成功');
      } catch (err) {
        const error = err as Error;
        console.error('[AppSettingsService] 初始化失败:', error.message);
        throw new Error('Failed to initialize AppSettingsService');
      }
    })();

    return AppSettingsService.initPromise;
  }

  /**
   * 确保已初始化
   */
  private static async ensureInitialized(): Promise<void> {
    if (!AppSettingsService.preferencesInstance) {
      if (AppSettingsService.initPromise) {
        await AppSettingsService.initPromise;
      } else {
        throw new Error('AppSettingsService not initialized. Call init() first.');
      }
    }
  }

  /**
   * 获取当前主题
   */
  static async getTheme(): Promise<ThemeMode> {
    await AppSettingsService.ensureInitialized();
    const value = await AppSettingsService.preferencesInstance!.get(KEY_THEME, ThemeMode.SYSTEM);
    return value as ThemeMode;
  }

  /**
   * 设置主题
   */
  static async setTheme(theme: ThemeMode): Promise<void> {
    console.log(`[AppSettingsService] setTheme called with: ${theme}`);
    await AppSettingsService.ensureInitialized();
    await AppSettingsService.preferencesInstance!.put(KEY_THEME, theme);
    await AppSettingsService.preferencesInstance!.flush();
    console.log(`[AppSettingsService] 主题已设置为: ${theme}`);
  }

  /**
   * 获取当前语言
   */
  static async getLanguage(): Promise<LanguageSetting> {
    await AppSettingsService.ensureInitialized();
    const value = await AppSettingsService.preferencesInstance!.get(KEY_LANGUAGE, LanguageSetting.ZH_CN);
    return value as LanguageSetting;
  }

  /**
   * 设置语言
   */
  static async setLanguage(language: LanguageSetting): Promise<void> {
    console.log(`[AppSettingsService] setLanguage called with: ${language}`);
    await AppSettingsService.ensureInitialized();
    await AppSettingsService.preferencesInstance!.put(KEY_LANGUAGE, language);
    await AppSettingsService.preferencesInstance!.flush();
    console.log(`[AppSettingsService] 语言已设置为: ${language}`);
  }

  /**
   * 获取货币符号
   */
  static async getCurrencySymbol(): Promise<CurrencySymbol> {
    await AppSettingsService.ensureInitialized();
    const value = await AppSettingsService.preferencesInstance!.get(KEY_CURRENCY, CurrencySymbol.CNY);
    return value as CurrencySymbol;
  }

  /**
   * 设置货币符号
   */
  static async setCurrencySymbol(symbol: CurrencySymbol): Promise<void> {
    console.log(`[AppSettingsService] setCurrencySymbol called with: ${symbol}`);
    await AppSettingsService.ensureInitialized();
    await AppSettingsService.preferencesInstance!.put(KEY_CURRENCY, symbol);
    await AppSettingsService.preferencesInstance!.flush();
    console.log(`[AppSettingsService] 货币符号已设置为: ${symbol}`);
  }

  /**
   * 获取所有设置
   */
  static async getAllSettings(): Promise<AppSettings> {
    return {
      theme: await AppSettingsService.getTheme(),
      language: await AppSettingsService.getLanguage(),
      currencySymbol: await AppSettingsService.getCurrencySymbol()
    };
  }

  /**
   * 重置为默认设置
   */
  static async resetToDefaults(): Promise<void> {
    await AppSettingsService.setTheme(ThemeMode.SYSTEM);
    await AppSettingsService.setLanguage(LanguageSetting.ZH_CN);
    await AppSettingsService.setCurrencySymbol(CurrencySymbol.CNY);
    console.log('[AppSettingsService] 已重置为默认设置');
  }
}
