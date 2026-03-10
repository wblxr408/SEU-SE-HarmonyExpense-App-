# Common 公共模块

提供全局配置、常量定义和通用工具类。

---

## 目录结构

```
common/
├── config/              # 配置文件
│   ├── AppConfig.ets   # 应用配置
│   ├── AppTheme.ets    # 主题配置
│   └── BreakpointSystem.ets  # 响应式断点系统
├── constants/           # 常量定义
│   └── Constants.ets   # 应用常量
├── utils/               # 工具类
│   └── DAOHelper.ets   # DAO 通用辅助类
├── index.ets            # 统一导出
└── README.md            # 本文档
```

---

## 配置文件 (config/)

### AppConfig.ets
应用全局配置，包括：
- 数据库配置
- API 配置
- 功能开关
- 性能参数

### AppTheme.ets
UI 主题配置，包括：
- 颜色定义
- 字体大小
- 间距规范
- 圆角半径

### BreakpointSystem.ets
响应式断点系统：
- 屏幕尺寸断点
- 自适应布局配置
- 多设备适配

---

## 常量定义 (constants/)

### Constants.ets
应用级常量定义：
- UI 常量（如 `CIRCLE_RADIUS`）
- 已废弃常量标记 (`@deprecated`)
- 向后兼容性支持

**注意**：`CURRENT_USER_ID` 已标记为废弃，请使用 `UserSessionService.getCurrentUserId()` 替代。

---

## 工具类 (utils/)

### DAOHelper.ets
DAO 层通用辅助工具，提供：

#### 1. 错误处理
```typescript
static toError(message: string, err: Error | string | object): Error
```
统一错误对象格式化

#### 2. 事务管理
```typescript
static async transaction<T>(fn: () => Promise<T>): Promise<T>
```
自动处理事务的开启、提交和回滚

#### 3. 批量操作
```typescript
static async batchInsert<T>(tableName: string, records: T[]): Promise<void>
static async batchUpdate<T>(tableName: string, records: T[]): Promise<void>
static async batchDelete(tableName: string, ids: number[]): Promise<void>
```
批量数据操作，自动分批处理（每批 100 条）

#### 4. 查询辅助
```typescript
static buildWhereClause(conditions: Record<string, any>): string
static buildOrderClause(order: string[]): string
```
SQL 查询语句构建辅助

#### 5. 数据验证
```typescript
static validateRequired(data: object, fields: string[]): void
static validateForeignKey(table: string, id: number): Promise<boolean>
```
数据完整性验证

---

## 使用示例

### 导入配置
```typescript
import { AppConfig, AppTheme } from '../common';

// 使用配置
const dbName = AppConfig.DATABASE_NAME;
const primaryColor = AppTheme.PRIMARY_COLOR;
```

### 使用常量
```typescript
import { CIRCLE_RADIUS } from '../common';

// 在 UI 中使用
Circle()
  .radius(CIRCLE_RADIUS)
```

### 使用工具类
```typescript
import { DAOHelper } from '../common';

// 错误处理
try {
  // ... 数据库操作
} catch (err) {
  throw DAOHelper.toError('操作失败', err);
}

// 批量插入
await DAOHelper.batchInsert('bills', billArray);

// 事务处理
await DAOHelper.transaction(async () => {
  await operation1();
  await operation2();
});
```

---

## 设计原则

1. **单一职责**：每个文件只负责一类功能
2. **统一导出**：通过 `index.ets` 统一对外暴露
3. **分类清晰**：config、constants、utils 分离
4. **向后兼容**：使用 `@deprecated` 标记废弃功能
5. **文档完善**：每个工具方法都有详细注释

---

## 注意事项

1. **废弃功能**：标记为 `@deprecated` 的功能请避免使用
2. **配置修改**：修改配置后需要重新构建应用
3. **工具类扩展**：新增工具方法请更新本文档
4. **导入路径**：统一使用 `from '../common'` 导入

---

*文档最后更新：2026-03-09*
