/**
 * 全局上下文管理
 * 提供应用级别的上下文访问
 */
import common from '@ohos.app.ability.common';

/**
 * 全局上下文存储
 */
class GlobalContextStore {
  private static context: common.Context | null = null;

  /**
   * 设置全局上下文
   */
  static setContext(context: common.Context): void {
    GlobalContextStore.context = context;
  }

  /**
   * 获取全局上下文
   */
  static getContext(): common.Context | null {
    return GlobalContextStore.context;
  }

  /**
   * 清除上下文
   */
  static clearContext(): void {
    GlobalContextStore.context = null;
  }
}

/**
 * 全局上下文工具类
 */
export class GlobalContext {
  private static initialized: boolean = false;

  /**
   * 初始化全局上下文（在应用启动时调用）
   */
  static init(context: common.Context): void {
    if (!GlobalContext.initialized) {
      GlobalContextStore.setContext(context);
      GlobalContext.initialized = true;
      console.log('[GlobalContext] 全局上下文已初始化');
    }
  }

  /**
   * 获取上下文
   */
  static getContext(): common.Context | null {
    return GlobalContextStore.getContext();
  }

  /**
   * 检查是否已初始化
   */
  static isInitialized(): boolean {
    return GlobalContext.initialized;
  }
}