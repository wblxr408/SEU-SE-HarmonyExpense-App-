# Service 层文档 - 业务逻辑与服务封装

本目录包含应用程序的核心业务逻辑和服务层封装。这些服务处理数据流、用户会话、云端同步以及与外部 API（如 LLM）的交互。

## 目录结构

- **UserSessionService.ets**: 用户会话管理（登录、注册、注销）。
- **CloudSyncService.ets**: 数据云端同步服务。
- **LLMService.ets**: 大语言模型接口集成（AI 助手）。
- **ReminderService.ets**: 提醒事项管理服务。
- **export/**: 数据导出与导入相关服务。
  - **ExportService.ets**: 导出数据为 CSV/JSON。
  - **ImportService.ets**: 从文件导入数据。
  - **EncryptionModule.ets**: 数据加密模块。

## 核心服务说明
  
### 1. 用户会话服务 (UserSessionService)
管理用户的登录状态和会话信息。替代了简单的全局变量，提供了更完整的身份认证流程。

**主要功能**:
- `login(email, password)`: 用户登录。
- `register(username, email, password)`: 用户注册。
- `logout()`: 注销当前用户。
- `getCurrentUserId()`: 获取当前登录用户的 ID。
- `isLoggedIn()`: 检查当前是否已登录。

### 2. 云端同步服务 (CloudSyncService)
负责将本地数据库的数据同步到云端，支持增量同步和双向同步。

**主要功能**:
- `sync(options)`: 执行同步任务。支持配置同步类型（全量/增量）、方向（上传/下载/双向）和数据类型。
- `getSyncHistory(userId)`: 获取同步历史记录。
- `cancelSync(userId)`: 取消正在进行的同步。

### 3. LLM AI 服务 (LLMService)
集成了大语言模型 API（目前配置为 DeepSeek/OpenAI 兼容接口），用于提供智能记账建议和对话功能。

**主要功能**:
- `chat(messages)`: 发送对话历史并获取 AI 回复。

**配置**:
请在 `LLMService.ets` 中配置 `DEFAULT_API_URL` 和获取 API Key 的逻辑。

### 4. 提醒服务 (ReminderService)
管理用户的定时提醒，如每日记账提醒、预算超支提醒等。

### 5. 导入导出服务 (export/...)
提供数据的备份与恢复功能，支持将账本数据导出为标准格式或从备份文件中恢复。

## 使用示例

### 检查登录状态
```typescript
import { UserSessionService } from '../service/UserSessionService';

if (UserSessionService.isLoggedIn()) {
  const userId = UserSessionService.getCurrentUserId();
  console.log('当前用户ID:', userId);
} else {
  // 跳转到登录页
  router.pushUrl({ url: 'pages/LoginPage' });
}
```

### 调用 AI 助手
```typescript
import { LLMService, ChatMessage } from '../service/LLMService';

const messages: ChatMessage[] = [
  { role: 'system', content: '你是一个专业的记账助手。' },
  { role: 'user', content: '我这个月餐饮花费了 500 元，算多吗？' }
];

try {
  const response = await LLMService.chat(messages);
  console.log('AI 回复:', response);
} catch (error) {
  console.error('AI 请求失败:', error);
}
```

## 注意事项

1. **异步操作**: 大多数服务方法都是异步的（`Promise`），调用时请使用 `await` 或 `.then()`。
2. **单例模式**: 部分服务（如 `UserSessionService`）内部维护了静态状态，在应用生命周期内保持一致。
3. **数据安全**: `CloudSyncService` 和 `UserSessionService` 中包含加密相关的逻辑，请确保在生产环境使用安全的密钥管理方式。
