# Components 组件模块

可复用的 UI 组件库。

---

## 组件列表

### DailyBarChart.ets
日常柱状图组件

#### 功能
- 显示每日收支数据
- 柱状图可视化
- 支持点击交互
- 自适应布局

#### 使用示例
```typescript
import { DailyBarChart } from '../components/DailyBarChart';

@Entry
@Component
struct MyPage {
  @State dailyData: Array<{date: string, amount: number}> = [];

  build() {
    Column() {
      DailyBarChart({ data: this.dailyData })
    }
  }
}
```

---

## 组件规范

### 文件命名
- 大驼峰命名：`ComponentName.ets`
- 一个文件一个主组件

### 组件导出
```typescript
@Component
export struct ComponentName {
  // 组件实现
}
```

### Props 定义
```typescript
@Component
export struct MyComponent {
  @Prop() data: DataType;     // 单向数据流
  @Link() count: number;       // 双向绑定
  @State() internal: string;   // 内部状态
}
```

---

## 开发指南

### 新增组件步骤
1. 创建 `ComponentName.ets` 文件
2. 使用 `@Component` 装饰器
3. 导出组件结构
4. 更新本 README 文档

### 组件设计原则
- **单一职责**：每个组件只负责一个功能
- **可复用**：避免硬编码，使用 Props 传参
- **响应式**：支持不同屏幕尺寸
- **性能优化**：避免不必要的渲染

---

*文档最后更新：2026-03-09*
