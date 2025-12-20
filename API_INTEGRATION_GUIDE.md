# HarmonyExpense API 集成指南

**文档版本**: 1.2.0
**生成日期**: 2025-12-20
**项目**: HarmonyExpense 记账应用
**目标**: 识别并替换所有 Mock 实现为真实 API

---

## 如何查找这些位置

### 方法 1: 全局搜索（最快）

#### 搜索 Mock 关键字
```grep -r "mock\|TODO\|模拟" entry/src/main/ets --include="*.ets" -i -n```
### 方法 2: IDE 内搜索（推荐）
* 在 DevEco Studio 按 Ctrl+Shift+F
* 搜索：mock|TODO|模拟|example.com
* 使用正则模式

### 方法 3: 直接查看关键文件
```
entry/src/main/ets/service/
├── CloudSyncService.ets          第 157, 429, 449 行
├── OCRRecognitionService.ets     第 230, 225 行
└── ReminderService.ets           第 229 行
```

## 集成优先级建议
* Phase 1 (立即，0-2周):
   * 云端同步 API 集成 - 40-60小时
   * 后台定时任务实现 - 16-24小时
   * 
* Phase 2 (近期，3-4周):
   * OCR 识别集成 (HarmonyOS ML Kit) - 32-48小时
   * 推送通知增强 - 16-24小时
* Phase 3 (后续，5-6周):
   * 第三方 OCR API 支持 - 24-32小时
   * 数据分析上报 - 16-24小时

## 关键代码位置
### 占位符 URL
```
// CloudSyncService.ets:157
private static readonly CLOUD_API_ENDPOINT: string = 'https://api.example.com/sync';
```
Mock 方法调用

```// CloudSyncService.ets:251
const uploadResult = await CloudSyncService.mockCloudUpload(payload, options.userId);
```

```// CloudSyncService.ets:267
const downloadResult = await CloudSyncService.mockCloudDownload(options.userId);
```
TODO 注释

```
// OCRRecognitionService.ets:230
// TODO: 实际项目中需要集成真实的OCR API
```

## 目录

1. [执行摘要](#执行摘要)
2. [如何查找 Mock 实现](#如何查找-mock-实现)
3. [关键 Mock 实现详情](#关键-mock-实现详情)
4. [集成优先级](#集成优先级)
5. [详细集成方案](#详细集成方案)
6. [代码示例](#代码示例)
7. [测试验证](#测试验证)
8. [安全性建议](#安全性建议)

---

## 执行摘要

### 发现总结

| 类别 | 数量 | 优先级 | 状态 |
|------|------|--------|----|
| 完全 Mock 实现 | 2 | CRITICAL/HIGH |  需要集成 |
| 部分实现 | 1 | MEDIUM |  基本可用 |
| 占位符端点 | 1 | CRITICAL |  需要配置 |
| 待实现功能 | 0 | - | 完整 |

###  影响范围

- **云端同步**: 完全无法工作（Mock 实现）
- **OCR 识别**: 返回假数据（Mock 实现）
- **推送通知**: 基本可用（使用 HarmonyOS API）

---

## 如何查找 Mock 实现

### 方法 1: 全局搜索关键字

在项目根目录使用以下搜索命令：

#### Windows (PowerShell)
```powershell
# 搜索 "mock" 关键字
Get-ChildItem -Path "entry/src/main/ets" -Filter "*.ets" -Recurse | Select-String -Pattern "mock" -CaseSensitive:$false

# 搜索 "TODO" 注释
Get-ChildItem -Path "entry/src/main/ets" -Filter "*.ets" -Recurse | Select-String -Pattern "TODO|FIXME|XXX"

# 搜索 "模拟" 中文关键字
Get-ChildItem -Path "entry/src/main/ets" -Filter "*.ets" -Recurse | Select-String -Pattern "模拟|待实现"
```

#### DevEco Studio (IDE 内搜索)
1. 按 `Ctrl+Shift+F` (Windows) 或 `Cmd+Shift+F` (Mac)
2. 在搜索框输入: `mock|TODO|模拟`
3. 选择 "Regex" 模式
4. 设置范围为 `entry/src/main/ets`

### 方法 2: 检查特定文件

直接检查以下关键文件：

```
entry/src/main/ets/service/
├── CloudSyncService.ets           包含 Mock 实现
├── OCRRecognitionService.ets      包含 Mock 实现
├── ReminderService.ets            部分实现
├── AnomalyDetectionService.ets    完全实现
├── EventSourcingService.ets       完全实现
└── SharedLedgerService.ets        完全实现
```

### 方法 3: 查找占位符 URL

搜索硬编码的测试/占位符 URL：

```bash
# 搜索 example.com 域名
grep -r "example\.com" entry/src/main/ets --include="*.ets"

# 搜索 localhost
grep -r "localhost\|127\.0\.0\.1" entry/src/main/ets --include="*.ets"

# 搜索 http:// 协议
grep -r "http://" entry/src/main/ets --include="*.ets"
```

### 方法 4: 检查注释掉的代码

搜索包含大量注释的代码块（通常是真实实现的示例）：

```bash
# 搜索连续的注释行（可能是注释掉的真实实现）
grep -A5 "// 实际实现" entry/src/main/ets --include="*.ets" -r

# 搜索多行注释块
grep -A10 "/\*.*实现.*\*/" entry/src/main/ets --include="*.ets" -r
```

---

## 关键 Mock 实现详情

### 1.  CloudSyncService - 云端同步（CRITICAL）

####  位置信息
- **文件**: `entry/src/main/ets/service/CloudSyncService.ets`
- **Mock 方法 1**: `mockCloudUpload()` - 第 429-444 行
- **Mock 方法 2**: `mockCloudDownload()` - 第 449-470 行
- **占位符 URL**: 第 157 行

####  如何找到
```bash
# 方法 1: 直接搜索方法名
grep -n "mockCloudUpload\|mockCloudDownload" entry/src/main/ets/service/CloudSyncService.ets

# 方法 2: 搜索 Mock 关键字
grep -n "mock" entry/src/main/ets/service/CloudSyncService.ets -i

# 方法 3: 搜索占位符 URL
grep -n "example.com" entry/src/main/ets/service/CloudSyncService.ets
```

####  代码片段

**占位符端点** (第 157 行):
```typescript
private static readonly CLOUD_API_ENDPOINT: string = 'https://api.example.com/sync';
```

**Mock 上传实现** (第 429-444 行):
```typescript
private static async mockCloudUpload(data: string, userId: number): Promise<CloudApiResponse> {
  console.log(`[Mock] 上传数据到云端 (userId: ${userId})`);
  console.log(`[Mock] 数据大小: ${data.length} 字符`);

  // 模拟网络延迟
  await new Promise<void>((resolve: Function) => setTimeout(() => resolve(), 1000));

  // 实际实现示例：
  // const response = await fetch(CloudSyncService.CLOUD_API_ENDPOINT + '/upload', {
  //   method: 'POST',
  //   headers: { 'Content-Type': 'application/json' },
  //   body: JSON.stringify({ userId, data })
  // });
  // return await response.json();

  return { success: true, message: 'Mock upload successful' };
}
```

**Mock 下载实现** (第 449-470 行):
```typescript
private static async mockCloudDownload(userId: number): Promise<CloudDataPackage> {
  console.log(`[Mock] 从云端下载数据 (userId: ${userId})`);

  // 模拟网络延迟
  await new Promise<void>((resolve: Function) => setTimeout(() => resolve(), 1000));

  // 实际实现示例：
  // const response = await fetch(CloudSyncService.CLOUD_API_ENDPOINT + '/download', {
  //   method: 'GET',
  //   headers: { 'User-Id': userId.toString() }
  // });
  // return await response.json();

  return {
    bills: [],
    accounts: [],
    categories: [],
    budgets: [],
    tags: [],
    timestamp: new Date().toISOString()
  };
}
```

####  需要替换的位置

**调用位置 1** - `syncData()` 方法（第 251 行）:
```typescript
const uploadResult: CloudApiResponse = await CloudSyncService.mockCloudUpload(payload, options.userId);
```

**调用位置 2** - `syncData()` 方法（第 267 行）:
```typescript
const downloadResult: CloudDataPackage = await CloudSyncService.mockCloudDownload(options.userId);
```

####  所需的真实 API

**端点要求**:
```
POST /api/sync/upload
  Headers: Authorization, Content-Type
  Body: { userId, data, timestamp, checksum }
  Response: { success, message, syncId }

GET /api/sync/download
  Headers: Authorization, User-Id
  Response: { bills[], accounts[], categories[], budgets[], tags[], timestamp }

GET /api/sync/history/{userId}
  Headers: Authorization
  Response: { records[], totalCount }

POST /api/sync/resolve-conflict
  Headers: Authorization
  Body: { conflictId, resolution }
  Response: { success, resolvedData }
```

---

### 2.  OCRRecognitionService - 票据识别（HIGH）

####  位置信息
- **文件**: `entry/src/main/ets/service/OCRRecognitionService.ets`
- **Mock 方法**: `performOCR()` - 第 225-268 行
- **TODO 注释**: 第 230 行

####  如何找到
```bash
# 方法 1: 搜索 performOCR 方法
grep -n "performOCR" entry/src/main/ets/service/OCRRecognitionService.ets

# 方法 2: 搜索 TODO 注释
grep -n "TODO" entry/src/main/ets/service/OCRRecognitionService.ets

# 方法 3: 搜索 Mock 关键字
grep -n "mock" entry/src/main/ets/service/OCRRecognitionService.ets -i
```

####  代码片段

**TODO 注释** (第 230 行):
```typescript
// TODO: 实际项目中需要集成真实的OCR API
```

**Mock OCR 实现** (第 225-268 行):
```typescript
private static async performOCR(
  _imagePath: string,
  _provider: string
): Promise<OCRPerformResult> {
  console.log('[Mock] 执行OCR识别');

  // 模拟OCR处理时间
  await new Promise<void>((resolve) => setTimeout(resolve, 500));

  // TODO: 实际项目中需要集成真实的OCR API

  // 模拟识别结果
  const mockResult = `
华润万家超市
地址：深圳市南山区科技园
电话：0755-12345678
--------------------------------
商品名称      数量  单价    金额
牛奶          2    15.00   30.00
面包          1    8.50    8.50
水果          1    25.00   25.00
--------------------------------
小计：                     63.50
优惠：                     -3.50
合计：                     60.00
支付方式：微信支付
交易时间：2024-01-15 14:23:56
收银员：001
谢谢惠顾！
`.trim();

  const result: OCRPerformResult = {
    success: true,
    rawText: mockResult,
    confidence: 0.95
  };

  return result;
}
```

####  需要替换的位置

**调用位置** - `recognizeReceipt()` 方法（第 154 行）:
```typescript
const ocrResult: OCRPerformResult = await OCRRecognitionService.performOCR(params.imagePath, params.provider);
```

####  支持的 OCR 提供商

**接口定义** (第 22-26 行):
```typescript
export interface OCRRecognitionParams {
  imagePath: string;
  userId: number;
  receiptType?: string;
  provider?: 'huawei_ml_kit' | 'baidu' | 'tencent' | 'local';
  language?: string;
}
```

####  集成选项

**选项: HarmonyOS ML Kit**
```typescript
import textRecognition from '@ohos.ai.textRecognition';

// 本地识别，无需网络
const result = await textRecognition.recognizeText({
  uri: imagePath,
  language: 'zh-CN'
});
```

---

### 3.  ReminderService - 推送通知（MEDIUM）

####  位置信息
- **文件**: `entry/src/main/ets/service/ReminderService.ets`
- **实现方法**: `sendNotification()` - 第 229-249 行
- **状态**:  部分实现（使用 HarmonyOS 原生 API）

####  如何找到
```bash
# 搜索通知相关方法
grep -n "sendNotification\|notificationManager" entry/src/main/ets/service/ReminderService.ets

# 搜索 HarmonyOS API 导入
grep -n "@ohos" entry/src/main/ets/service/ReminderService.ets
```

####  当前实现

**HarmonyOS API 导入** (第 12 行):
```typescript
import notificationManager from '@ohos.notificationManager';
```

**通知发送实现** (第 229-249 行):
```typescript
private static async sendNotification(reminder: Reminder): Promise<void> {
  try {
    const notificationRequest: notificationManager.NotificationRequest = {
      id: reminder.reminderId,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: reminder.title,
          text: reminder.description,
          additionalText: `金额: ${reminder.amount || '无'}`
        }
      }
    };

    await notificationManager.publish(notificationRequest);
    console.log(`[ReminderService] 通知已发送: ${reminder.title}`);
  } catch (error) {
    console.error('[ReminderService] 发送通知失败:', error);
  }
}
```

####  需要增强的功能

1. **后台定时任务**
   - 当前: 只能手动触发检查
   - 需要: 使用 `@ohos.resourceschedule.workScheduler` 定期检查

2. **通知增强**
   - 添加声音提示
   - 添加振动反馈
   - 支持通知点击跳转
   - 支持通知操作按钮

3. **通知管理**
   - 通知分组
   - 批量通知摘要
   - 通知历史记录

---

## 集成优先级

### Phase 1: 立即执行

#### 1.1 云端同步 API 集成 

**任务**:
- [ ] 实现 HTTP 网络请求客户端
- [ ] 配置真实的云端 API 端点
- [ ] 实现身份认证机制（JWT/OAuth）
- [ ] 替换 `mockCloudUpload()` 和 `mockCloudDownload()`
- [ ] 实现错误处理和重试逻辑
- [ ] 添加离线同步队列

**预估工时**: 40-60 小时

**关键文件**:
- `service/CloudSyncService.ets` (修改)
- `http/NetworkManager.ets` (新建)
- `http/HttpConfig.ets` (新建)
- `config/ApiEndpoints.ets` (新建)

#### 1.2 后台定时任务实现

**任务**:
- [ ] 集成 `@ohos.resourceschedule.workScheduler`
- [ ] 实现定期检查提醒的后台任务
- [ ] 配置任务调度策略

**关键文件**:
- `service/ReminderService.ets` (修改)
- `background/WorkSchedulerService.ets` (新建)

---

### Phase 2: 近期执行

#### 2.1 OCR 识别集成

**任务**:
- [ ] 集成 HarmonyOS ML Kit
- [ ] 实现图片预处理和压缩
- [ ] 替换 `performOCR()` Mock 实现
- [ ] 实现结构化数据提取
- [ ] 添加识别结果缓存

**预估工时**: 32-48 小时

**关键文件**:
- `service/OCRRecognitionService.ets` (修改)
- `ml/TextRecognitionService.ets` (新建)
- `ml/ImageProcessor.ets` (新建)
- 
#### 2.2 推送通知增强

**任务**:
- [ ] 添加声音和振动提示
- [ ] 实现通知点击回调
- [ ] 支持通知操作按钮
- [ ] 实现通知分组

**预估工时**: 16-24 小时

**关键文件**:
- `service/ReminderService.ets` (修改)

---

### Phase 3: 后续优化（5-6 周）

#### 3.1 第三方 OCR API 支持

**任务**:
- [ ] 集成百度 OCR API
- [ ] 集成腾讯 OCR API
- [ ] 实现多提供商切换机制
- [ ] 添加识别结果对比功能

**预估工时**: 24-32 小时

#### 3.2 数据分析上报 

**任务**:
- [ ] 集成数据分析 SDK
- [ ] 实现用户行为追踪
- [ ] 添加性能监控上报

**预估工时**: 16-24 小时

---

## 详细集成方案

### 方案 1: 云端同步 API 集成

#### Step 1: 创建 HTTP 网络客户端

**文件**: `entry/src/main/ets/http/NetworkManager.ets`

```typescript
import http from '@ohos.net.http';

export class NetworkManager {
  private static readonly TIMEOUT = 60000; // 60秒
  private static readonly MAX_RETRY = 3;

  /**
   * 执行 HTTP POST 请求
   */
  static async post<T>(
    url: string,
    data: Record<string, ESObject>,
    headers?: Record<string, string>
  ): Promise<T> {
    const httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          ...headers
        },
        extraData: JSON.stringify(data),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.TIMEOUT,
        readTimeout: this.TIMEOUT
      });

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as T;
      } else {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 执行 HTTP GET 请求
   */
  static async get<T>(
    url: string,
    headers?: Record<string, string>
  ): Promise<T> {
    const httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: headers || {},
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.TIMEOUT,
        readTimeout: this.TIMEOUT
      });

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as T;
      } else {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 带重试的 POST 请求
   */
  static async postWithRetry<T>(
    url: string,
    data: Record<string, ESObject>,
    headers?: Record<string, string>,
    retryCount: number = this.MAX_RETRY
  ): Promise<T> {
    for (let i = 0; i < retryCount; i++) {
      try {
        return await this.post<T>(url, data, headers);
      } catch (error) {
        if (i === retryCount - 1) throw error;
        await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
      }
    }
    throw new Error('请求失败，已达最大重试次数');
  }
}
```

#### Step 2: 配置 API 端点（华为云）

**文件**: `entry/src/main/ets/config/ApiEndpoints.ets`

```typescript
/**
 * 华为云 API 端点配置
 *
 * 注意事项:
 * 1. 使用华为云 ELB (弹性负载均衡) 或 API Gateway 作为入口
 * 2. 建议使用华为云 DNS 服务配置域名
 * 3. 启用华为云 WAF (Web 应用防火墙) 保护 API
 * 4. 配置华为云 CDN 加速静态资源访问
 */
export class ApiEndpoints {
  // 生产环境 - 华为云（示例：华东-上海一）
  static readonly PRODUCTION = {
    BASE_URL: 'https://api.harmonyexpense.cn-east-3.myhuaweicloud.com',
    REGION: 'cn-east-3',  // 华东-上海一
    SYNC_UPLOAD: '/api/v1/sync/upload',
    SYNC_DOWNLOAD: '/api/v1/sync/download',
    SYNC_HISTORY: '/api/v1/sync/history',
    RESOLVE_CONFLICT: '/api/v1/sync/resolve-conflict',
    AUTH_LOGIN: '/api/v1/auth/login',
    AUTH_REFRESH: '/api/v1/auth/refresh',
    // 华为云 OBS 对象存储（用于图片/文件上传）
    OBS_ENDPOINT: 'https://obs.cn-east-3.myhuaweicloud.com',
    OBS_BUCKET: 'harmonyexpense-prod'
  };

  // 开发环境 - 华为云
  static readonly DEVELOPMENT = {
    BASE_URL: 'https://dev-api.harmonyexpense.cn-east-3.myhuaweicloud.com',
    REGION: 'cn-east-3',
    SYNC_UPLOAD: '/api/v1/sync/upload',
    SYNC_DOWNLOAD: '/api/v1/sync/download',
    SYNC_HISTORY: '/api/v1/sync/history',
    RESOLVE_CONFLICT: '/api/v1/sync/resolve-conflict',
    AUTH_LOGIN: '/api/v1/auth/login',
    AUTH_REFRESH: '/api/v1/auth/refresh',
    OBS_ENDPOINT: 'https://obs.cn-east-3.myhuaweicloud.com',
    OBS_BUCKET: 'harmonyexpense-dev'
  };

  // 测试环境 - 华为云
  static readonly STAGING = {
    BASE_URL: 'https://staging-api.harmonyexpense.cn-east-3.myhuaweicloud.com',
    REGION: 'cn-east-3',
    SYNC_UPLOAD: '/api/v1/sync/upload',
    SYNC_DOWNLOAD: '/api/v1/sync/download',
    SYNC_HISTORY: '/api/v1/sync/history',
    RESOLVE_CONFLICT: '/api/v1/sync/resolve-conflict',
    AUTH_LOGIN: '/api/v1/auth/login',
    AUTH_REFRESH: '/api/v1/auth/refresh',
    OBS_ENDPOINT: 'https://obs.cn-east-3.myhuaweicloud.com',
    OBS_BUCKET: 'harmonyexpense-staging'
  };

  // 当前环境（可通过配置切换）
  static readonly CURRENT = ApiEndpoints.DEVELOPMENT;

  /**
   * 华为云可用区域列表
   */
  static readonly HUAWEI_REGIONS = {
    'cn-north-1': '华北-北京一',
    'cn-north-4': '华北-北京四',
    'cn-east-2': '华东-上海二',
    'cn-east-3': '华东-上海一',
    'cn-south-1': '华南-广州',
    'cn-southwest-2': '西南-贵阳一'
  };
}
```

#### Step 3: 替换 Mock 实现

**文件**: `entry/src/main/ets/service/CloudSyncService.ets`

**修改前** (第 429-444 行):
```typescript
private static async mockCloudUpload(data: string, userId: number): Promise<CloudApiResponse> {
  console.log(`[Mock] 上传数据到云端 (userId: ${userId})`);
  // ... Mock 实现
  return { success: true, message: 'Mock upload successful' };
}
```

**修改后**:
```typescript
private static async realCloudUpload(data: string, userId: number): Promise<CloudApiResponse> {
  try {
    const url = `${ApiEndpoints.CURRENT.BASE_URL}${ApiEndpoints.CURRENT.SYNC_UPLOAD}`;
    const token = await CloudSyncService.getAuthToken(userId);

    const response = await NetworkManager.postWithRetry<CloudApiResponse>(
      url,
      {
        userId,
        data,
        timestamp: new Date().toISOString(),
        checksum: CloudSyncService.calculateChecksum(data)
      },
      {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    );

    console.log(`[CloudSync] 上传成功 (userId: ${userId})`);
    return response;
  } catch (error) {
    console.error('[CloudSync] 上传失败:', error);
    throw new Error(`云端上传失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}
```

**同步方法调用修改** (第 251 行):
```typescript
// 修改前
const uploadResult: CloudApiResponse = await CloudSyncService.mockCloudUpload(payload, options.userId);

// 修改后
const uploadResult: CloudApiResponse = await CloudSyncService.realCloudUpload(payload, options.userId);
```

#### Step 4: 实现身份认证

**添加到**: `entry/src/main/ets/service/CloudSyncService.ets`

```typescript
/**
 * 获取用户认证 Token
 */
private static async getAuthToken(userId: number): Promise<string> {
  // 方案 1: 从本地存储获取
  const preferences = await dataPreferences.getPreferences(context, 'auth');
  const token = await preferences.get(`token_${userId}`, '');

  if (token) {
    return token as string;
  }

  // 方案 2: 刷新 Token
  return await CloudSyncService.refreshAuthToken(userId);
}

/**
 * 刷新认证 Token
 */
private static async refreshAuthToken(userId: number): Promise<string> {
  const url = `${ApiEndpoints.CURRENT.BASE_URL}/api/v1/auth/refresh`;
  const response = await NetworkManager.post<{ token: string }>(
    url,
    { userId },
    { 'Content-Type': 'application/json' }
  );

  // 保存新 Token
  const preferences = await dataPreferences.getPreferences(context, 'auth');
  await preferences.put(`token_${userId}`, response.token);
  await preferences.flush();

  return response.token;
}

/**
 * 计算数据校验和
 */
private static calculateChecksum(data: string): string {
  // 使用现有的 ChecksumHelper
  return ChecksumHelper.calculateChecksum(data);
}
```

---

### 方案 2: OCR 识别集成（HarmonyOS ML Kit）

#### Step 1: 导入 ML Kit 模块

**修改文件**: `entry/src/main/ets/service/OCRRecognitionService.ets`

**添加导入** (在文件顶部):
```typescript
import textRecognition from '@ohos.ai.textRecognition';
import { image } from '@kit.ImageKit';
```

#### Step 2: 实现真实 OCR 识别

**替换** `performOCR()` 方法 (第 225-268 行):

```typescript
/**
 * 执行 OCR 识别（真实实现）
 */
private static async performOCR(
  imagePath: string,
  provider: string
): Promise<OCRPerformResult> {
  console.log('[OCR] 开始识别票据');

  try {
    // 加载图片
    const imageSource = image.createImageSource(imagePath);
    const pixelMap = await imageSource.createPixelMap();

    // 执行文字识别
    const recognizer = await textRecognition.createTextRecognizer();
    const result = await recognizer.recognize(pixelMap);

    // 提取识别结果
    const rawText = result.blocks
      .map(block => block.text)
      .join('\n');

    // 计算置信度（平均值）
    const confidences = result.blocks.map(block => block.confidence);
    const avgConfidence = confidences.reduce((a, b) => a + b, 0) / confidences.length;

    console.log(`[OCR] 识别完成，置信度: ${avgConfidence.toFixed(2)}`);

    return {
      success: true,
      rawText: rawText,
      confidence: avgConfidence
    };
  } catch (error) {
    console.error('[OCR] 识别失败:', error);
    return {
      success: false,
      rawText: '',
      confidence: 0,
      error: error instanceof Error ? error.message : String(error)
    };
  }
}
```

#### Step 3: 添加图片预处理

**新增方法**:

```typescript
/**
 * 预处理图片（压缩、旋转、增强）
 */
private static async preprocessImage(imagePath: string): Promise<string> {
  try {
    const imageSource = image.createImageSource(imagePath);
    const pixelMap = await imageSource.createPixelMap();

    // 图片旋转校正
    const rotated = await OCRRecognitionService.correctRotation(pixelMap);

    // 图片增强（提高对比度）
    const enhanced = await OCRRecognitionService.enhanceContrast(rotated);

    // 保存处理后的图片
    const processedPath = `${imagePath}_processed.jpg`;
    const imagePacker = image.createImagePacker();
    const arrayBuffer = await imagePacker.packing(enhanced, {
      format: 'image/jpeg',
      quality: 90
    });

    // 保存到文件
    await fileIO.write(processedPath, arrayBuffer);

    return processedPath;
  } catch (error) {
    console.error('[OCR] 图片预处理失败:', error);
    return imagePath; // 失败时返回原图
  }
}

/**
 * 校正图片旋转
 */
private static async correctRotation(pixelMap: image.PixelMap): Promise<image.PixelMap> {
  // 使用 ML Kit 的方向检测
  // 返回旋转后的 pixelMap
  return pixelMap;
}

/**
 * 增强图片对比度
 */
private static async enhanceContrast(pixelMap: image.PixelMap): Promise<image.PixelMap> {
  // 图像处理算法
  // 返回增强后的 pixelMap
  return pixelMap;
}
```

---

### 方案 3: 后台定时任务实现

#### Step 1: 创建 WorkScheduler 服务

**新建文件**: `entry/src/main/ets/background/WorkSchedulerService.ets`

```typescript
import workScheduler from '@ohos.resourceschedule.workScheduler';
import { ReminderService } from '../service/ReminderService';

export class WorkSchedulerService {
  private static readonly WORK_ID = 1001;

  /**
   * 注册定期检查提醒的后台任务
   */
  static async registerReminderCheckTask(): Promise<void> {
    const workInfo: workScheduler.WorkInfo = {
      workId: this.WORK_ID,
      bundleName: 'com.harmonyexpense.app',
      abilityName: 'EntryAbility',
      networkType: workScheduler.NetworkType.NETWORK_TYPE_ANY,
      isCharging: false,
      chargerType: workScheduler.ChargingType.CHARGING_PLUGGED_ANY,
      batteryLevel: 20,
      batteryStatus: workScheduler.BatteryStatus.BATTERY_STATUS_LOW_OR_OKAY,
      storageRequest: workScheduler.StorageRequest.STORAGE_LEVEL_LOW_OR_OKAY,
      isRepeat: true,
      repeatCycleTime: 3600000, // 每小时检查一次（毫秒）
      repeatCount: 0, // 无限重复
      isPersisted: true,
      isDeepIdle: false
    };

    try {
      await workScheduler.startWork(workInfo);
      console.log('[WorkScheduler] 后台任务已注册');
    } catch (error) {
      console.error('[WorkScheduler] 注册后台任务失败:', error);
    }
  }

  /**
   * 取消后台任务
   */
  static async unregisterReminderCheckTask(): Promise<void> {
    try {
      await workScheduler.stopWork(this.WORK_ID, false);
      console.log('[WorkScheduler] 后台任务已取消');
    } catch (error) {
      console.error('[WorkScheduler] 取消后台任务失败:', error);
    }
  }

  /**
   * 执行定时检查（由系统回调）
   */
  static async onWorkSchedulerTrigger(): Promise<void> {
    console.log('[WorkScheduler] 开始检查提醒');
    try {
      const results = await ReminderService.checkAndTriggerReminders();
      console.log(`[WorkScheduler] 检查完成，触发了 ${results.length} 个提醒`);
    } catch (error) {
      console.error('[WorkScheduler] 检查提醒失败:', error);
    }
  }
}
```

#### Step 2: 在 EntryAbility 中注册

**修改文件**: `entry/src/main/ets/entryability/EntryAbility.ets`

```typescript
import { WorkSchedulerService } from '../background/WorkSchedulerService';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // ... 现有代码

    // 注册后台定时任务
    WorkSchedulerService.registerReminderCheckTask();
  }

  onDestroy(): void {
    // 取消后台任务
    WorkSchedulerService.unregisterReminderCheckTask();
  }

  // 处理后台任务回调
  onBackgroundRunning(): void {
    WorkSchedulerService.onWorkSchedulerTrigger();
  }
}
```

---

## 测试验证

### 测试清单

#### 云端同步测试

```typescript
// 测试文件: ohosTest/ets/test/CloudSyncService.test.ets

describe('CloudSyncService 集成测试', () => {
  it('应该成功上传数据到云端', async () => {
    const result = await CloudSyncService.syncData({
      userId: 1,
      syncType: 'full',
      syncDirection: 'upload'
    });

    expect(result.success).assertTrue();
    expect(result.recordCount).toBeGreaterThan(0);
  });

  it('应该成功从云端下载数据', async () => {
    const result = await CloudSyncService.syncData({
      userId: 1,
      syncType: 'full',
      syncDirection: 'download'
    });

    expect(result.success).assertTrue();
  });

  it('应该正确处理网络错误', async () => {
    // 模拟网络断开
    try {
      await CloudSyncService.syncData({
        userId: 1,
        syncType: 'full',
        syncDirection: 'upload'
      });
      fail('应该抛出错误');
    } catch (error) {
      expect(error).toBeDefined();
    }
  });
});
```

#### OCR 识别测试

```typescript
// 测试文件: ohosTest/ets/test/OCRRecognitionService.test.ets

describe('OCRRecognitionService 集成测试', () => {
  it('应该成功识别票据图片', async () => {
    const result = await OCRRecognitionService.recognizeReceipt({
      imagePath: '/data/test_receipt.jpg',
      userId: 1,
      provider: 'huawei_ml_kit'
    });

    expect(result.success).assertTrue();
    expect(result.merchantName).not.toBeEmpty();
    expect(result.totalAmount).toBeGreaterThan(0);
  });

  it('应该正确提取结构化数据', async () => {
    const result = await OCRRecognitionService.recognizeReceipt({
      imagePath: '/data/test_receipt.jpg',
      userId: 1
    });

    expect(result.structuredData).toBeDefined();
    expect(result.structuredData.totalAmount).toBeDefined();
    expect(result.structuredData.merchantName).toBeDefined();
    expect(result.structuredData.transactionDate).toBeDefined();
  });
});
```

#### 后台任务测试

```typescript
// 测试文件: ohosTest/ets/test/WorkSchedulerService.test.ets

describe('WorkSchedulerService 集成测试', () => {
  it('应该成功注册后台任务', async () => {
    await WorkSchedulerService.registerReminderCheckTask();
    // 验证任务已注册
  });

  it('应该成功执行定时检查', async () => {
    await WorkSchedulerService.onWorkSchedulerTrigger();
    // 验证提醒已触发
  });

  it('应该成功取消后台任务', async () => {
    await WorkSchedulerService.unregisterReminderCheckTask();
    // 验证任务已取消
  });
});
```

---

## 安全性建议

### 1. 网络通信安全

#### HTTPS 强制使用（华为云配置）
```typescript
// config/SecurityConfig.ets
export class SecurityConfig {
  static readonly ENFORCE_HTTPS = true;

  // 华为云域名白名单
  static readonly ALLOWED_DOMAINS = [
    'myhuaweicloud.com',
    'cn-east-3.myhuaweicloud.com',
    'cn-north-4.myhuaweicloud.com',
    'obs.cn-east-3.myhuaweicloud.com'  // OBS 对象存储
  ];

  static validateUrl(url: string): boolean {
    if (this.ENFORCE_HTTPS && !url.startsWith('https://')) {
      throw new Error('只允许使用 HTTPS 协议');
    }

    // 验证域名是否在白名单中
    const isAllowed = this.ALLOWED_DOMAINS.some(domain => url.includes(domain));
    if (!isAllowed) {
      throw new Error(`域名不在白名单中: ${url}`);
    }

    return true;
  }
}
```

#### 华为云 SSL/TLS 配置
```typescript
// 华为云 ELB 默认提供免费 SSL 证书（Let's Encrypt）
// 也可以上传自定义证书到华为云证书管理服务（CCM）

export class HuaweiCloudSecurityConfig {
  // 启用 TLS 1.2/1.3
  static readonly MIN_TLS_VERSION = 'TLSv1.2';

  // 华为云推荐的加密套件
  static readonly CIPHER_SUITES = [
    'ECDHE-RSA-AES128-GCM-SHA256',
    'ECDHE-RSA-AES256-GCM-SHA384',
    'ECDHE-RSA-CHACHA20-POLY1305'
  ];

  // 证书固定（针对华为云服务）
  private static readonly CERT_PINS = {
    'cn-east-3.myhuaweicloud.com': 'sha256/华为云证书指纹',
    'obs.cn-east-3.myhuaweicloud.com': 'sha256/OBS证书指纹'
  };

  static validateCertificate(hostname: string, cert: string): boolean {
    const expectedPin = this.CERT_PINS[hostname];
    return expectedPin === cert;
  }
}
```

### 2. 身份认证安全

#### JWT Token 管理
```typescript
export class AuthTokenManager {
  private static readonly TOKEN_EXPIRY = 3600000; // 1小时

  static async getToken(userId: number): Promise<string> {
    const cachedToken = await this.getCachedToken(userId);
    if (cachedToken && !this.isTokenExpired(cachedToken)) {
      return cachedToken;
    }

    // 刷新 Token
    return await this.refreshToken(userId);
  }

  private static isTokenExpired(token: string): boolean {
    // 解析 JWT 并检查过期时间
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.exp * 1000 < Date.now();
  }
}
```

### 3. 数据加密

#### 敏感数据加密
```typescript
// 使用现有的 EncryptionModule
export class DataEncryption {
  static async encryptSyncData(data: string, userId: number): Promise<string> {
    const key = await this.deriveKey(userId);
    return EncryptionModule.encrypt(data, key);
  }

  static async decryptSyncData(encryptedData: string, userId: number): Promise<string> {
    const key = await this.deriveKey(userId);
    return EncryptionModule.decrypt(encryptedData, key);
  }

  private static async deriveKey(userId: number): Promise<string> {
    // 从用户密码派生加密密钥
    const password = await this.getUserPassword(userId);
    return EncryptionModule.deriveKey(password, `salt_${userId}`);
  }
}
```

### 4. 输入验证

#### API 请求验证
```typescript
export class RequestValidator {
  static validateSyncRequest(data: SyncOptions): void {
    if (!data.userId || data.userId <= 0) {
      throw new Error('无效的用户 ID');
    }

    if (!['full', 'incremental'].includes(data.syncType)) {
      throw new Error('无效的同步类型');
    }

    if (data.dataTypes && data.dataTypes.length === 0) {
      throw new Error('至少选择一种数据类型');
    }
  }

  static validateOCRRequest(params: OCRRecognitionParams): void {
    if (!params.imagePath || params.imagePath.trim() === '') {
      throw new Error('图片路径不能为空');
    }

    if (!params.userId || params.userId <= 0) {
      throw new Error('无效的用户 ID');
    }
  }
}
```

---

## 附录

### A. 完整的文件清单

#### 需要新建的文件

```
entry/src/main/ets/
├── http/
│   ├── NetworkManager.ets           ✅ HTTP 客户端
│   ├── HttpConfig.ets               ✅ HTTP 配置
│   └── RequestValidator.ets         ✅ 请求验证
├── config/
│   ├── ApiEndpoints.ets             ✅ API 端点配置
│   └── SecurityConfig.ets           ✅ 安全配置
├── background/
│   └── WorkSchedulerService.ets     ✅ 后台任务服务
├── ml/
│   ├── TextRecognitionService.ets   ✅ ML Kit 封装
│   └── ImageProcessor.ets           ✅ 图片预处理
└── auth/
    ├── AuthTokenManager.ets         ✅ Token 管理
    └── DataEncryption.ets           ✅ 数据加密
```

#### 需要修改的文件

```
entry/src/main/ets/
├── service/
│   ├── CloudSyncService.ets         🔧 替换 Mock 实现
│   ├── OCRRecognitionService.ets    🔧 集成 ML Kit
│   └── ReminderService.ets          🔧 添加后台任务
├── entryability/
│   └── EntryAbility.ets             🔧 注册后台任务
└── module.json5                     🔧 添加权限配置
```

### B. 权限配置

#### module.json5 需要添加的权限

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:internet_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      },
      {
        "name": "ohos.permission.NOTIFICATION",
        "reason": "$string:notification_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      },
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:camera_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.READ_MEDIA",
        "reason": "$string:read_media_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.WORK_SCHEDULER",
        "reason": "$string:work_scheduler_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      }
    ]
  }
}
```

### C. 环境变量配置

#### .env 文件示例

```env
# API 配置
API_BASE_URL=https://api.harmonyexpense.com
API_VERSION=v1
API_TIMEOUT=60000

# 云同步配置
SYNC_MAX_RETRY=3
SYNC_RETRY_DELAY=1000

# OCR 配置
OCR_PROVIDER=huawei_ml_kit
OCR_LANGUAGE=zh-CN
OCR_CONFIDENCE_THRESHOLD=0.8

# 认证配置
AUTH_TOKEN_EXPIRY=3600000
AUTH_REFRESH_THRESHOLD=300000

# 调试配置
DEBUG_MODE=false
LOG_LEVEL=info
```

---

## 华为云特定配置

### 1. 华为云服务架构建议

#### 推荐的华为云服务组合

```
┌─────────────────────────────────────────────────────────┐
│                    HarmonyOS 应用                        │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │   华为云 API Gateway / ELB            │  ← 负载均衡 + API管理
    │   - 请求路由                          │
    │   - 限流保护                          │
    │   - API 密钥验证                      │
    └──────────┬────────────────────────────┘
               │
               ├──────────┬─────────────┬────────────┐
               ▼          ▼             ▼            ▼
         ┌─────────┐ ┌─────────┐  ┌─────────┐  ┌─────────┐
         │   ECS   │ │   ECS   │  │   ECS   │  │  RDS    │
         │ (应用1) │ │ (应用2) │  │ (应用N) │  │(MySQL)  │
         └─────────┘ └─────────┘  └─────────┘  └─────────┘
               │                                      │
               └──────────────┬───────────────────────┘
                              ▼
                    ┌──────────────────┐
                    │   华为云 OBS     │  ← 对象存储（图片/文件）
                    │   - 票据图片     │
                    │   - 导出文件     │
                    └──────────────────┘
```

#### 服务清单与配置

| 服务 | 用途 | 配置建议 |
|------|------|----------|
| **ECS (弹性云服务器)** | 后端应用服务器 | 2核4GB × 2台，按需计费 |
| **RDS (关系型数据库)** | MySQL 数据库 | 2核4GB，高可用版 |
| **ELB (弹性负载均衡)** | 分发流量 | 共享型，按流量计费 |
| **OBS (对象存储)** | 存储图片/文件 | 标准存储，按用量计费 |
| **WAF (Web应用防火墙)** | 安全防护 | 基础版，防SQL注入/XSS |
| **CDN (内容分发网络)** | 加速访问 | 国内节点，按流量计费 |
| **API Gateway** | API 管理 | 专享版（可选） |
| **CCM (证书管理)** | SSL 证书 | 免费 Let's Encrypt |

### 2. 华为云 OBS 对象存储集成

#### 安装华为云 OBS SDK（如适用）

如果需要直接从应用上传文件到 OBS：

```typescript
// 注意: HarmonyOS 可能需要通过后端中转，而非直接调用 OBS SDK
// 以下为概念示例

export class HuaweiOBSService {
  private static readonly OBS_CONFIG = {
    endpoint: ApiEndpoints.CURRENT.OBS_ENDPOINT,
    bucket: ApiEndpoints.CURRENT.OBS_BUCKET,
    // 建议通过后端 API 获取临时 AK/SK (STS 临时凭证)
  };

  /**
   * 上传票据图片到华为云 OBS
   */
  static async uploadReceiptImage(
    imagePath: string,
    userId: number
  ): Promise<string> {
    try {
      // 生成对象存储路径
      const objectKey = `receipts/${userId}/${Date.now()}.jpg`;

      // 方案1: 通过后端 API 上传（推荐）
      const uploadUrl = await this.getPresignedUploadUrl(objectKey);
      await this.uploadToPresignedUrl(uploadUrl, imagePath);

      // 返回 OBS 对象 URL
      return `${this.OBS_CONFIG.endpoint}/${this.OBS_CONFIG.bucket}/${objectKey}`;
    } catch (error) {
      console.error('[OBS] 上传失败:', error);
      throw error;
    }
  }

  /**
   * 从后端获取预签名上传 URL (推荐方式)
   */
  private static async getPresignedUploadUrl(objectKey: string): Promise<string> {
    const response = await NetworkManager.post<{ uploadUrl: string }>(
      `${ApiEndpoints.CURRENT.BASE_URL}/api/v1/obs/presigned-upload`,
      { objectKey },
      { 'Content-Type': 'application/json' }
    );
    return response.uploadUrl;
  }

  /**
   * 使用预签名 URL 上传文件
   */
  private static async uploadToPresignedUrl(
    presignedUrl: string,
    filePath: string
  ): Promise<void> {
    // 读取文件并上传到预签名 URL
    const httpRequest = http.createHttp();
    const fileData = await fs.readFile(filePath);

    await httpRequest.request(presignedUrl, {
      method: http.RequestMethod.PUT,
      header: { 'Content-Type': 'image/jpeg' },
      extraData: fileData
    });

    httpRequest.destroy();
  }
}
```

#### 后端 API 实现（预签名 URL）

后端应该实现预签名 URL 生成接口，避免在客户端暴露 AK/SK：

```python
# Python 示例（使用 obs-python-sdk）
from obs import ObsClient

def generate_presigned_upload_url(object_key: str) -> str:
    """生成华为云 OBS 预签名上传 URL"""
    obs_client = ObsClient(
        access_key_id=os.getenv('HUAWEI_AK'),
        secret_access_key=os.getenv('HUAWEI_SK'),
        server='https://obs.cn-east-3.myhuaweicloud.com'
    )

    # 生成有效期 1 小时的上传 URL
    resp = obs_client.createSignedUrl(
        method='PUT',
        bucketName='harmonyexpense-prod',
        objectKey=object_key,
        expires=3600
    )

    return resp.signedUrl
```

### 3. 华为云数据库 RDS 配置

#### 连接配置

```typescript
// config/DatabaseConfig.ets
export class HuaweiRDSConfig {
  static readonly RDS_CONFIG = {
    // 华为云 RDS 内网地址（推荐使用内网连接）
    host: 'rds-mysql-harmonyexpense.cn-east-3.myhuaweicloud.com',
    port: 3306,
    database: 'harmonyexpense_db',
    // 凭证应存储在华为云 DEW (数据加密服务) 或环境变量中
    username: process.env.RDS_USERNAME,
    password: process.env.RDS_PASSWORD,

    // 连接池配置
    connectionLimit: 10,
    connectTimeout: 10000,

    // SSL 连接（生产环境推荐）
    ssl: {
      rejectUnauthorized: true,
      ca: '/path/to/huawei-rds-ca.pem'
    }
  };
}
```

#### 备份策略

在华为云控制台配置：
- **自动备份**: 每天凌晨 3:00
- **保留天数**: 7 天
- **备份方式**: 物理备份（全量）
- **备份存储**: 自动存储到 OBS

### 4. 华为云 WAF 配置

#### 启用 Web 应用防火墙

```yaml
# 华为云 WAF 规则配置（在控制台配置）
waf_rules:
  # 基础防护
  - name: SQL 注入防护
    enabled: true
    mode: block

  - name: XSS 攻击防护
    enabled: true
    mode: block

  # IP 黑名单
  - name: IP 黑名单
    enabled: true
    blacklist:
      - 192.168.1.1/32
      - 10.0.0.0/8

  # 地理位置限制
  - name: 地理位置访问控制
    enabled: true
    allowed_regions:
      - CN  # 仅允许中国大陆访问

  # 频率限制
  - name: CC 攻击防护
    enabled: true
    rate_limit: 100 req/min per IP
```

### 5. 华为云 API Gateway 配置

#### API 限流策略

```typescript
// 华为云 API Gateway 配置示例
export const ApiGatewayConfig = {
  // 请求限流
  rateLimit: {
    // 每个用户每分钟最多 60 次请求
    perUser: {
      limit: 60,
      period: '1m'
    },
    // 每个 IP 每分钟最多 100 次请求
    perIP: {
      limit: 100,
      period: '1m'
    }
  },

  // API 认证
  authentication: {
    type: 'APP',  // 应用认证
    // 或使用 IAM 认证
    // type: 'IAM'
  },

  // CORS 配置
  cors: {
    allowOrigins: ['https://harmonyexpense.com'],
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowHeaders: ['Content-Type', 'Authorization'],
    maxAge: 3600
  }
};
```

### 6. 华为云监控告警配置

#### 云监控服务 (CES) 配置

```typescript
// 监控指标配置
export const HuaweiMonitoringConfig = {
  // ECS 监控
  ecs_metrics: [
    { name: 'cpu_usage', threshold: 80, alarm: true },
    { name: 'memory_usage', threshold: 85, alarm: true },
    { name: 'disk_usage', threshold: 90, alarm: true }
  ],

  // RDS 监控
  rds_metrics: [
    { name: 'cpu_usage', threshold: 75, alarm: true },
    { name: 'connection_usage', threshold: 80, alarm: true },
    { name: 'disk_usage', threshold: 85, alarm: true }
  ],

  // OBS 监控
  obs_metrics: [
    { name: 'storage_usage', threshold: 1000, unit: 'GB', alarm: true },
    { name: 'request_count', threshold: 10000, period: 'hour', alarm: true }
  ],

  // 告警通知
  notifications: {
    sms: ['+86-138-xxxx-xxxx'],  // 短信通知
    email: ['admin@harmonyexpense.com'],  // 邮件通知
    webhook: 'https://your-webhook.com/alerts'  // Webhook 通知
  }
};
```

### 7. 华为云成本优化建议

#### 按需资源配置

| 场景 | 推荐配置 | 月成本估算 |
|------|----------|------------|
| **开发环境** | 1台 ECS (2核4GB) + RDS 单机版 | ¥200-300 |
| **测试环境** | 1台 ECS (2核4GB) + RDS 单机版 | ¥200-300 |
| **生产环境（小型）** | 2台 ECS (2核4GB) + RDS 高可用 + ELB | ¥800-1200 |
| **生产环境（中型）** | 3台 ECS (4核8GB) + RDS 高可用 + WAF + CDN | ¥2000-3000 |

#### 节省成本的技巧

1. **使用包年包月**: ECS 和 RDS 使用包年包月可节省 20%-40%
2. **合理配置资源**: 监控资源使用率，避免过度配置
3. **使用弹性伸缩**: 在流量低峰期自动缩减实例
4. **OBS 生命周期管理**: 30天后自动转为低频存储，降低成本 60%
5. **使用 CDN**: 减少 ECS 带宽费用
6. **预留实例**: 对于稳定业务，使用预留实例节省成本

### 8. 华为云部署清单

#### 生产环境部署步骤

1. **创建 VPC 和子网**
   ```
   - VPC: 10.0.0.0/16
   - 子网1 (公网): 10.0.1.0/24 (ELB)
   - 子网2 (私网): 10.0.2.0/24 (ECS)
   - 子网3 (数据库): 10.0.3.0/24 (RDS)
   ```

2. **创建安全组规则**
   ```
   ELB 安全组:
   - 入站: TCP 80, 443 from 0.0.0.0/0

   ECS 安全组:
   - 入站: TCP 8080 from ELB 安全组
   - 入站: TCP 22 from 跳板机 IP

   RDS 安全组:
   - 入站: TCP 3306 from ECS 安全组
   ```

3. **创建 RDS 实例**
   - 引擎: MySQL 8.0
   - 规格: 2核4GB 高可用版
   - 存储: 100GB SSD
   - 备份: 自动备份，保留 7 天

4. **创建 OBS 桶**
   ```bash
   桶名: harmonyexpense-prod
   区域: 华东-上海一 (cn-east-3)
   存储类别: 标准存储
   访问权限: 私有
   ```

5. **创建 ECS 实例**
   - 镜像: Ubuntu 22.04 LTS
   - 规格: 2核4GB × 2台
   - 系统盘: 40GB SSD
   - 配置用户数据脚本自动部署应用

6. **配置 ELB**
   - 类型: 应用型（HTTP/HTTPS）
   - 监听器: 443 (HTTPS) → 后端 8080
   - 健康检查: GET /health 每 10s
   - 会话保持: 基于 Cookie

7. **配置域名和 SSL**
   - 在华为云 DNS 解析域名到 ELB
   - 在 CCM 申请免费 SSL 证书
   - 在 ELB 绑定证书

8. **启用 WAF 和 CDN**
   - WAF: 绑定域名，启用基础防护规则
   - CDN: 配置加速域名，源站为 ELB

---

## 总结

本文档已更新为**华为云版本**,详细列出了 HarmonyExpense 项目中所有需要真实 API 集成的位置，并提供了：

1. ✅ 精确的文件路径和行号
2. ✅ 多种查找方法（命令行、IDE、关键字）
3. ✅ 完整的集成方案和代码示例（华为云适配）
4. ✅ 分阶段的实施计划
5. ✅ 测试验证方法
6. ✅ 华为云专属安全性和架构建议
7. ✅ 华为云服务配置详解
8. ✅ 成本优化和部署清单

**关键要点**:
- **2个完全 Mock 实现**需要立即替换（云同步、OCR）
- **1个部分实现**需要增强（推送通知）
- **华为云服务**: 使用 ECS + RDS + OBS + ELB + WAF 构建稳定架构
- **推荐区域**: 华东-上海一 (cn-east-3) 或根据用户分布选择
- 预估总工时：**120-200 小时**（含华为云配置）
- 优先级：云同步 > 后台任务 > OCR > 通知增强

**华为云特色**:
- 🔐 使用华为云 OBS 存储票据图片
- 🛡️ 启用 WAF 防护 Web 攻击
- 🚀 使用 CDN 加速全国访问
- 📊 使用云监控服务实时监控
- 💰 合理配置资源，优化成本

