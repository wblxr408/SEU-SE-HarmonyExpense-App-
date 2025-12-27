/**
 * 性能监控页面 - 展示应用性能数据
 *
 * 功能：
 * - 查询性能统计（总查询数、平均耗时、慢查询比例）
 * - 缓存统计（有效缓存数、过期缓存数）
 * - 方法级性能详情列表
 * - 支持刷新、清除统计、清理缓存操作
 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { PerformanceMonitor } from '../database/PerformanceMonitor';
import { CacheManager, CacheStats } from '../database/CacheManager';

/**
 * 方法性能统计项
 */
interface MethodStats {
  methodName: string;
  count: number;
  avgTime: number;
  maxTime: number;
  minTime: number;
  slowQueryCount: number;
  slowQueryRate: string;
}


@Entry
@Component
struct PerformanceMonitorPage {
  // 性能统计数据
  @State methodStatsList: MethodStats[] = [];
  @State totalQueries: number = 0;
  @State totalAvgTime: number = 0;
  @State totalSlowQueries: number = 0;

  // 缓存统计数据
  @State cacheStats: CacheStats = {
    totalCount: 0,
    validCount: 0,
    expiredCount: 0,
    keys: []
  };

  // 加载状态
  @State isLoading: boolean = false;

  aboutToAppear() {
    this.refreshData();
  }

  /**
   * 刷新所有统计数据
   */
  refreshData(): void {
    this.isLoading = true;

    // 获取性能统计
    const statsMap = PerformanceMonitor.getStats();
    const methodList: MethodStats[] = [];
    let totalCount = 0;
    let totalTime = 0;
    let slowCount = 0;

    statsMap.forEach((stats, methodName) => {
      const slowRate = stats.count > 0
        ? (stats.slowQueryCount / stats.count * 100).toFixed(1)
        : '0.0';

      methodList.push({
        methodName: methodName,
        count: stats.count,
        avgTime: Number(stats.avgTime.toFixed(2)),
        maxTime: Number(stats.maxTime.toFixed(2)),
        minTime: stats.minTime === Infinity ? 0 : Number(stats.minTime.toFixed(2)),
        slowQueryCount: stats.slowQueryCount,
        slowQueryRate: slowRate
      });

      totalCount += stats.count;
      totalTime += stats.totalTime;
      slowCount += stats.slowQueryCount;
    });

    this.methodStatsList = methodList;
    this.totalQueries = totalCount;
    this.totalAvgTime = totalCount > 0 ? Number((totalTime / totalCount).toFixed(2)) : 0;
    this.totalSlowQueries = slowCount;

    // 获取缓存统计
    this.cacheStats = CacheManager.getStats();

    this.isLoading = false;
    console.log('[PerformanceMonitorPage] 数据已刷新');
  }

  /**
   * 清除性能统计
   */
  clearStats(): void {
    PerformanceMonitor.clearStats();
    this.refreshData();
    promptAction.showToast({ message: '性能统计已清除' });
  }

  /**
   * 清理过期缓存
   */
  cleanExpiredCache(): void {
    const count = CacheManager.cleanExpired();
    this.refreshData();
    promptAction.showToast({ message: `已清理 ${count} 条过期缓存` });
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#007AFF')
          .margin({ right: 16 })
          .onClick(() => {
            router.back();
          })

        Text('性能监控')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        Text('刷新')
          .fontSize(14)
          .fontColor('#007AFF')
          .onClick(() => {
            this.refreshData();
            promptAction.showToast({ message: '数据已刷新' });
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      // 内容区域
      Scroll() {
        Column() {
          // 性能概览卡片
          this.OverviewCard()

          // 缓存统计卡片
          this.CacheCard()

          // 方法性能列表
          this.MethodStatsList()

          // 操作按钮区域
          this.ActionButtons()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 24 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  /**
   * 性能概览卡片
   */
  @Builder
  OverviewCard() {
    Column() {
      Text('📊 性能概览')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      Row() {
        this.StatItem('总查询数', `${this.totalQueries}`, '#007AFF')
        this.StatItem('平均耗时', `${this.totalAvgTime}ms`, '#34C759')
        this.StatItem('慢查询', `${this.totalSlowQueries}`, this.totalSlowQueries > 0 ? '#FF9500' : '#34C759')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  /**
   * 缓存统计卡片
   */
  @Builder
  CacheCard() {
    Column() {
      Text('💾 缓存统计')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      Row() {
        this.StatItem('有效缓存', `${this.cacheStats.validCount}`, '#007AFF')
        this.StatItem('过期缓存', `${this.cacheStats.expiredCount}`, this.cacheStats.expiredCount > 0 ? '#FF9500' : '#8E8E93')
        this.StatItem('总计', `${this.cacheStats.totalCount}`, '#8E8E93')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  /**
   * 统计项组件
   */
  @Builder
  StatItem(label: string, value: string, color: string) {
    Column() {
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)

      Text(label)
        .fontSize(12)
        .fontColor('#8E8E93')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 方法性能列表
   */
  @Builder
  MethodStatsList() {
    Column() {
      Text('📋 方法性能详情')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      if (this.methodStatsList.length === 0) {
        Column() {
          Text('暂无性能数据')
            .fontSize(14)
            .fontColor('#8E8E93')
        }
        .width('100%')
        .padding(32)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.methodStatsList, (item: MethodStats) => {
          this.MethodStatsRow(item)
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  /**
   * 方法统计行
   */
  @Builder
  MethodStatsRow(item: MethodStats) {
    Column() {
      // 方法名
      Text(item.methodName)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 统计数据
      Row() {
        Text(`调用: ${item.count}`)
          .fontSize(12)
          .fontColor('#8E8E93')

        Text(`平均: ${item.avgTime}ms`)
          .fontSize(12)
          .fontColor('#34C759')
          .margin({ left: 12 })

        Text(`最大: ${item.maxTime}ms`)
          .fontSize(12)
          .fontColor(item.maxTime > 100 ? '#FF9500' : '#8E8E93')
          .margin({ left: 12 })

        if (item.slowQueryCount > 0) {
          Text(`慢查询: ${item.slowQueryRate}%`)
            .fontSize(12)
            .fontColor('#FF3B30')
            .margin({ left: 12 })
        }
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .border({ width: { bottom: 1 }, color: '#F0F0F0' })
  }

  /**
   * 操作按钮区域
   */
  @Builder
  ActionButtons() {
    Row() {
      Button('清除统计')
        .fontSize(14)
        .fontColor('#FF3B30')
        .backgroundColor('#FFF0F0')
        .borderRadius(8)
        .height(40)
        .layoutWeight(1)
        .onClick(() => {
          this.clearStats();
        })

      Button('清理过期缓存')
        .fontSize(14)
        .fontColor('#007AFF')
        .backgroundColor('#F0F8FF')
        .borderRadius(8)
        .height(40)
        .layoutWeight(1)
        .margin({ left: 12 })
        .onClick(() => {
          this.cleanExpiredCache();
        })
    }
    .width('100%')
    .padding({ top: 8 })
  }
}
