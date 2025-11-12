/**
 * 性能监控装饰器 - 企业级数据库性能监控方案（⭐ 亮点）
 * 
 * 核心功能：
 * 1. 自动记录查询执行时间
 * 2. 慢查询警告（> 100ms）
 * 3. 错误捕获和日志记录
 * 4. 零侵入式监控（使用装饰器模式）
 * 
 * 技术亮点：
 * - 装饰器模式（Decorator Pattern）：在不修改原有代码的情况下增强功能
 * - AOP 思想（面向切面编程）：将性能监控作为横切关注点统一处理
 * - 企业级实践：生产环境常用的性能监控方案
 * 
 * 使用示例：
 * ```typescript
 * class BillDAO {
 *   @measureQueryTime
 *   static async getAll(): Promise<Bill[]> {
 *     // 查询逻辑
 *   }
 * }
 * ```
 */

/**
 * 性能监控装饰器
 * 
 * 功能：
 * - 自动记录方法执行时间
 * - 慢查询警告（> 100ms）
 * - 错误捕获和日志记录
 * 
 * 技术原理：
 * 1. 装饰器模式：包装原始方法，在执行前后添加监控逻辑
 * 2. AOP 思想：将性能监控作为横切关注点，与业务逻辑解耦
 * 3. 零侵入：不修改原有代码，通过装饰器语法糖实现
 * 
 * @param target 目标类
 * @param propertyKey 方法名
 * @param descriptor 方法描述符
 */
export function measureQueryTime(
  target: any,
  propertyKey: string,
  descriptor: PropertyDescriptor
): PropertyDescriptor {
  const originalMethod = descriptor.value;

  descriptor.value = async function (...args: any[]) {
    const className = target.constructor.name;
    const methodName = propertyKey;
    const startTime = Date.now();

    console.log(`[PerformanceMonitor] 🚀 开始执行: ${className}.${methodName}()`);

    try {
      // 执行原始方法
      const result = await originalMethod.apply(this, args);
      
      // 计算执行时间
      const endTime = Date.now();
      const duration = endTime - startTime;

      // 慢查询警告（> 100ms）
      if (duration > 100) {
        console.warn(
          `[PerformanceMonitor] ⚠️ 慢查询警告: ${className}.${methodName}() ` +
          `耗时 ${duration}ms (超过 100ms 阈值)`
        );
      } else {
        console.log(
          `[PerformanceMonitor] ✅ 执行完成: ${className}.${methodName}() ` +
          `耗时 ${duration}ms`
        );
      }

      return result;
    } catch (error) {
      // 错误捕获和日志记录
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      console.error(
        `[PerformanceMonitor] ❌ 执行失败: ${className}.${methodName}() ` +
        `耗时 ${duration}ms, 错误:`, error
      );
      
      throw error;
    }
  };

  return descriptor;
}

/**
 * 性能监控管理器
 * 
 * 提供更灵活的性能监控功能：
 * - 手动开始/结束计时
 * - 性能统计汇总
 * - 慢查询日志导出
 */
export class PerformanceMonitor {
  // 慢查询阈值（毫秒）
  private static readonly SLOW_QUERY_THRESHOLD = 100;
  
  // 性能统计数据
  private static stats: Map<string, {
    count: number;
    totalTime: number;
    avgTime: number;
    maxTime: number;
    minTime: number;
    slowQueryCount: number;
  }> = new Map();

  /**
   * 记录查询性能
   * 
   * @param methodName 方法名
   * @param duration 执行时间（毫秒）
   */
  static recordQuery(methodName: string, duration: number): void {
    const stats = PerformanceMonitor.stats.get(methodName) || {
      count: 0,
      totalTime: 0,
      avgTime: 0,
      maxTime: 0,
      minTime: Infinity,
      slowQueryCount: 0
    };

    stats.count++;
    stats.totalTime += duration;
    stats.avgTime = stats.totalTime / stats.count;
    stats.maxTime = Math.max(stats.maxTime, duration);
    stats.minTime = Math.min(stats.minTime, duration);
    
    if (duration > PerformanceMonitor.SLOW_QUERY_THRESHOLD) {
      stats.slowQueryCount++;
    }

    PerformanceMonitor.stats.set(methodName, stats);
  }

  /**
   * 获取性能统计报告
   * 
   * @returns 性能统计数据
   */
  static getStats(): Map<string, any> {
    return new Map(PerformanceMonitor.stats);
  }

  /**
   * 打印性能统计报告
   */
  static printStats(): void {
    console.log('\n========== 性能统计报告 ==========');
    
    if (PerformanceMonitor.stats.size === 0) {
      console.log('暂无性能数据');
      return;
    }

    PerformanceMonitor.stats.forEach((stats, methodName) => {
      console.log(`\n方法: ${methodName}`);
      console.log(`  调用次数: ${stats.count}`);
      console.log(`  总耗时: ${stats.totalTime.toFixed(2)}ms`);
      console.log(`  平均耗时: ${stats.avgTime.toFixed(2)}ms`);
      console.log(`  最大耗时: ${stats.maxTime.toFixed(2)}ms`);
      console.log(`  最小耗时: ${stats.minTime === Infinity ? 0 : stats.minTime.toFixed(2)}ms`);
      console.log(`  慢查询次数: ${stats.slowQueryCount}`);
      
      if (stats.slowQueryCount > 0) {
        const slowQueryRate = (stats.slowQueryCount / stats.count * 100).toFixed(2);
        console.log(`  慢查询比例: ${slowQueryRate}%`);
      }
    });
    
    console.log('\n==================================\n');
  }

  /**
   * 清除性能统计数据
   */
  static clearStats(): void {
    PerformanceMonitor.stats.clear();
    console.log('[PerformanceMonitor] 性能统计数据已清除');
  }

  /**
   * 手动测量方法执行时间
   * 
   * 使用示例：
   * ```typescript
   * const result = await PerformanceMonitor.measure('myMethod', async () => {
   *   // 执行业务逻辑
   *   return await someAsyncOperation();
   * });
   * ```
   */
  static async measure<T>(
    methodName: string,
    fn: () => Promise<T>
  ): Promise<T> {
    const startTime = Date.now();
    console.log(`[PerformanceMonitor] 🚀 开始执行: ${methodName}`);

    try {
      const result = await fn();
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      // 记录性能数据
      PerformanceMonitor.recordQuery(methodName, duration);

      // 慢查询警告
      if (duration > PerformanceMonitor.SLOW_QUERY_THRESHOLD) {
        console.warn(
          `[PerformanceMonitor] ⚠️ 慢查询警告: ${methodName} ` +
          `耗时 ${duration}ms (超过 ${PerformanceMonitor.SLOW_QUERY_THRESHOLD}ms 阈值)`
        );
      } else {
        console.log(
          `[PerformanceMonitor] ✅ 执行完成: ${methodName} 耗时 ${duration}ms`
        );
      }

      return result;
    } catch (error) {
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      console.error(
        `[PerformanceMonitor] ❌ 执行失败: ${methodName} 耗时 ${duration}ms, 错误:`, error
      );
      
      throw error;
    }
  }
}
