# API 配置实战指南 - 华为云版（零基础）

**适用人群**: 完全不懂 API 配置的开发者
**完成时间**: 跟着做 3-4 小时
**目标**: 把 Mock 实现替换为真实的华为云 API
**云服务商**: 华为云（HUAWEI CLOUD）

---

## 第一步：理解什么是 API

### 什么是 Mock（模拟）？

**Mock** = 假数据，不会真正联网

```typescript
// 这是 Mock - 假的上传
async mockCloudUpload() {
  console.log('假装上传中...');
  return { success: true };  // 假的成功消息
}
```

### 什么是真实 API？

**真实 API** = 真正的服务器，能保存和同步数据

```typescript
// 这是真实 API - 真的上传到华为云服务器
async realCloudUpload() {
  const response = await fetch('https://your-api.cn-east-3.myhuaweicloud.com/upload', {
    method: 'POST',
    body: JSON.stringify(数据)
  });
  return response;  // 华为云服务器返回的真实结果
}
```

## 第二步：需要准备的东西

### 2.1 华为云账号和服务器

#### 推荐方案：使用华为云 ECS + 自建后端

**本指南使用华为云演示（国内访问稳定，有中文支持）**

**需要准备**:
- 华为云账号（实名认证）
- 华为云 ECS 服务器（弹性云服务器）
- 域名（可选，建议配置）
- 后端应用（Node.js/Java/Python）

**费用估算**:
- ECS (2核4GB): ¥70-100/月
- RDS 数据库: ¥150-200/月
- 带宽流量: ¥20-50/月
- **总计**: ¥250-350/月

**新用户优惠**: 华为云新用户有免费试用额度

### 2.2 开发工具

- DevEco Studio（已安装）
- 文本编辑器（系统自带记事本即可）
- 浏览器（Chrome/Edge）

---

## 第三步：配置华为云服务

### 3.1 注册华为云账号

1. 在浏览器打开: https://www.huaweicloud.com/
2. 点击右上角"注册"
3. 填写手机号和验证码
4. 完成实名认证（需要身份证）

### 3.2 创建 ECS 云服务器（使用代金券购买）

#### 方式1：从开发者中心购买（推荐）

1. **访问华为云开发者中心 ECS 服务页面**
   - 直接访问: https://developer.huaweicloud.com/capability-detail?businessTypeNo=1d0617d8abb14516a806e184342996e2
   - 或者在 https://developer.huaweicloud.com 页面找到"计算能力"分类下的"ECS弹性云服务器"

2. **点击"购买弹性云服务器"或"立即使用"**

3. **配置服务器参数**:
   - **区域**: 华东-上海一 (cn-east-3) 或就近选择
   - **规格**: 通用计算型 s6.large.2 (2核4GB)
   - **镜像**: Ubuntu 22.04 server 64bit
   - **系统盘**: 40GB 高IO
   - **网络**: 默认VPC，自动分配弹性公网IP
   - **带宽**: 按流量计费，5Mbps
   - **安全组**: 开放 22(SSH), 80(HTTP), 443(HTTPS), 8080(后端API) 端口

4. **应用代金券**:
   - 配置完成后，进入"确认订单"页面
   - 在订单详情中找到"优惠券"或"代金券"选项
   - 点击"使用优惠券"
   - 从列表中选择官方发放的代金券（会显示代金券金额和使用条件）
   - 确认代金券已应用，查看抵扣后的实际支付金额
   - **重要**: 以支付页面显示的最终金额为准

5. **确认并支付**:
   - 检查配置和价格是否正确
   - 勾选同意服务协议
   - 点击"立即购买"
   - 完成支付（如果代金券足够，可能无需支付或只需支付少量差额）

#### 方式2：从华为云控制台购买

1. 登录华为云控制台: https://console.huaweicloud.com/
2. 在顶部搜索框搜索"ECS"
3. 进入"弹性云服务器 ECS"
4. 点击"购买弹性云服务器"
5. 按上述配置参数选择
6. 在支付页面应用代金券
7. 完成购买

#### 代金券使用注意事项

- **查看代金券详情**: 在"费用中心 → 代金券管理"中查看你的代金券
  - 代金券金额
  - 使用条件（如满减门槛）
  - 适用产品范围
  - 有效期（注意代金券过期时间）
- **确保符合使用条件**: 购买的配置和金额需要满足代金券的使用要求
- **优先使用即将过期的代金券**: 系统通常会自动选择最优代金券组合
- **保留购买凭证**: 购买成功后保存订单截图和发票

### 3.3 记录服务器信息

购买成功后，记录以下信息（**务必保存好**）:

```
ECS 公网IP: xxx.xxx.xxx.xxx
服务器用户名: root
服务器密码: (购买时设置的密码)
区域: cn-east-3
```

### 3.4 部署后端 API（简易版）

#### 方式 A: 使用 Node.js + Express（推荐）

**通过 SSH 连接服务器**:

```bash
ssh root@你的服务器IP
```

**安装 Node.js**:

```bash
# 更新软件源
apt update

# 安装 Node.js 和 npm
apt install -y nodejs npm

# 验证安装
node -v  # 应显示版本号
npm -v
```

**创建后端项目**:

```bash
# 创建项目目录
mkdir /opt/harmonyexpense-api
cd /opt/harmonyexpense-api

# 初始化项目
npm init -y

# 安装依赖
npm install express body-parser cors
```

**创建 API 服务**:

创建文件 `/opt/harmonyexpense-api/server.js`:

```javascript
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 8080;
const DATA_DIR = path.join(__dirname, 'data');

// 中间件
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));

// 确保数据目录存在
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR);
}

// 健康检查接口
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 上传数据接口
app.post('/api/v1/sync/upload', (req, res) => {
  try {
    const { userId, data, timestamp } = req.body;

    if (!userId || !data) {
      return res.status(400).json({
        success: false,
        message: '缺少必要参数'
      });
    }

    // 保存数据到文件
    const filename = `user_${userId}_${Date.now()}.json`;
    const filepath = path.join(DATA_DIR, filename);

    fs.writeFileSync(filepath, JSON.stringify({
      userId,
      data,
      timestamp,
      uploadedAt: new Date().toISOString()
    }));

    console.log(`[上传成功] 用户${userId} - ${filename}`);

    res.json({
      success: true,
      message: '上传成功',
      syncId: filename
    });
  } catch (error) {
    console.error('[上传失败]', error);
    res.status(500).json({
      success: false,
      message: '服务器错误'
    });
  }
});

// 下载数据接口
app.get('/api/v1/sync/download', (req, res) => {
  try {
    const userId = req.query.userId || req.headers['user-id'];

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: '缺少用户ID'
      });
    }

    // 查找该用户最新的数据文件
    const files = fs.readdirSync(DATA_DIR)
      .filter(f => f.startsWith(`user_${userId}_`))
      .sort()
      .reverse();

    if (files.length === 0) {
      return res.json({
        bills: [],
        accounts: [],
        categories: [],
        budgets: [],
        tags: [],
        timestamp: new Date().toISOString()
      });
    }

    // 读取最新文件
    const latestFile = files[0];
    const filepath = path.join(DATA_DIR, latestFile);
    const fileData = JSON.parse(fs.readFileSync(filepath, 'utf8'));

    console.log(`[下载成功] 用户${userId} - ${latestFile}`);

    // 返回数据内容
    const parsedData = typeof fileData.data === 'string'
      ? JSON.parse(fileData.data)
      : fileData.data;

    res.json(parsedData);
  } catch (error) {
    console.error('[下载失败]', error);
    res.status(500).json({
      success: false,
      message: '服务器错误'
    });
  }
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
  console.log(`========================================`);
  console.log(`HarmonyExpense API 服务已启动`);
  console.log(`监听端口: ${PORT}`);
  console.log(`访问地址: http://你的服务器IP:${PORT}`);
  console.log(`健康检查: http://你的服务器IP:${PORT}/health`);
  console.log(`========================================`);
});
```

**启动服务**:

```bash
# 启动服务
node server.js

# 如果要后台运行，使用 pm2
npm install -g pm2
pm2 start server.js --name harmonyexpense-api
pm2 save
pm2 startup
```

**测试 API**:

```bash
# 在本地电脑或服务器上测试
curl http://你的服务器IP:8080/health
```

应该返回:
```json
{"status":"ok","timestamp":"2025-12-20T..."}
```

### 3.5 配置防火墙（重要）

在华为云控制台:

1. 进入 ECS 实例详情
2. 点击"安全组"标签
3. 点击"配置规则"
4. 添加入站规则:
   - **端口**: 8080
   - **协议**: TCP
   - **源地址**: 0.0.0.0/0
   - **描述**: API 服务端口

---

## 第四步：在项目中创建配置文件

### 4.1 创建华为云 API 配置文件

**位置**: `entry/src/main/ets/config/ApiConfig.ets`

**操作步骤**:

1. 在 DevEco Studio 中，找到 `entry/src/main/ets` 目录
2. 右键点击 → 新建 → Directory（目录）
3. 输入名称: `config`
4. 右键点击 `config` 目录 → 新建 → ArkTS File
5. 输入名称: `ApiConfig`

**复制以下代码到文件中**:

```typescript
/**
 * 华为云 API 配置文件
 * 这里存放所有的 API 地址和密钥
 */
export class ApiConfig {
  // ===== 重要：把下面的值替换成你自己的华为云配置 =====

  // 华为云 ECS 服务器公网IP（第三步获取的）
  static readonly SERVER_IP = '替换成你的ECS公网IP';

  // API 端口（默认 8080）
  static readonly SERVER_PORT = 8080;

  // 华为云区域（例如: cn-east-3）
  static readonly REGION = 'cn-east-3';

  // 完整的 API 基础 URL
  static readonly API_BASE_URL = `http://${ApiConfig.SERVER_IP}:${ApiConfig.SERVER_PORT}`;

  // 如果配置了域名和 HTTPS，使用以下格式：
  // static readonly API_BASE_URL = 'https://api.yourapp.cn-east-3.myhuaweicloud.com';

  // API 端点路径
  static readonly ENDPOINTS = {
    SYNC_UPLOAD: '/api/v1/sync/upload',
    SYNC_DOWNLOAD: '/api/v1/sync/download',
    HEALTH_CHECK: '/health'
  };

  // 请求超时时间（毫秒）
  static readonly TIMEOUT = 30000;  // 30秒

  // 是否启用日志
  static readonly ENABLE_LOG = true;
}
```

**替换示例**:

```typescript
// 替换前
static readonly SERVER_IP = '替换成你的ECS公网IP';

// 替换后（使用你自己的服务器 IP）
static readonly SERVER_IP = '121.36.123.456';
```

### 4.2 创建网络请求工具（华为云版）

**位置**: `entry/src/main/ets/http/HttpClient.ets`

**操作步骤**:

1. 在 `entry/src/main/ets` 目录下创建 `http` 目录
2. 在 `http` 目录中创建 `HttpClient.ets` 文件

**复制以下代码**:

```typescript
/**
 * HTTP 网络请求工具（华为云版）
 * 封装了所有的网络请求方法
 */
import http from '@ohos.net.http';
import { ApiConfig } from '../config/ApiConfig';

export class HttpClient {
  /**
   * 发送 POST 请求（上传数据到华为云）
   * @param path API 路径，例如: '/api/v1/sync/upload'
   * @param data 要上传的数据
   * @returns 服务器返回的结果
   */
  static async post(path: string, data: Record<string, Object>): Promise<Object> {
    // 第 1 步：创建 HTTP 请求对象
    const httpRequest = http.createHttp();

    try {
      // 第 2 步：拼接完整的 URL
      const fullUrl = ApiConfig.API_BASE_URL + path;

      if (ApiConfig.ENABLE_LOG) {
        console.log('[华为云HTTP] 正在请求:', fullUrl);
        console.log('[华为云HTTP] 请求数据:', JSON.stringify(data));
      }

      // 第 3 步：准备请求头
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        'User-Agent': 'HarmonyExpense/1.0'
      };

      // 第 4 步：发送请求到华为云 ECS
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(data),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: ApiConfig.TIMEOUT,
        readTimeout: ApiConfig.TIMEOUT
      });

      // 第 5 步：检查是否成功
      if (response.responseCode === 200) {
        if (ApiConfig.ENABLE_LOG) {
          console.log('[华为云HTTP] 请求成功');
        }
        return JSON.parse(response.result as string);
      } else {
        console.error('[华为云HTTP] 请求失败:', response.responseCode);
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }
    } catch (error) {
      console.error('[华为云HTTP] 网络错误:', error);
      throw error;
    } finally {
      // 第 6 步：清理资源
      httpRequest.destroy();
    }
  }

  /**
   * 发送 GET 请求（从华为云获取数据）
   * @param path API 路径
   * @param params 查询参数（可选）
   * @returns 服务器返回的结果
   */
  static async get(path: string, params?: Record<string, string>): Promise<Object> {
    const httpRequest = http.createHttp();

    try {
      // 构建完整 URL（带查询参数）
      let fullUrl = ApiConfig.API_BASE_URL + path;

      if (params) {
        const queryString = Object.keys(params)
          .map(key => `${key}=${encodeURIComponent(params[key])}`)
          .join('&');
        fullUrl += `?${queryString}`;
      }

      if (ApiConfig.ENABLE_LOG) {
        console.log('[华为云HTTP] 正在请求:', fullUrl);
      }

      const headers: Record<string, string> = {
        'User-Agent': 'HarmonyExpense/1.0'
      };

      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.GET,
        header: headers,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: ApiConfig.TIMEOUT,
        readTimeout: ApiConfig.TIMEOUT
      });

      if (response.responseCode === 200) {
        if (ApiConfig.ENABLE_LOG) {
          console.log('[华为云HTTP] 请求成功');
        }
        return JSON.parse(response.result as string);
      } else {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }
    } catch (error) {
      console.error('[华为云HTTP] 网络错误:', error);
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 健康检查（测试华为云服务器是否正常）
   */
  static async healthCheck(): Promise<boolean> {
    try {
      const result = await this.get(ApiConfig.ENDPOINTS.HEALTH_CHECK);
      const status = (result as Record<string, string>).status;
      return status === 'ok';
    } catch (error) {
      console.error('[华为云HTTP] 健康检查失败:', error);
      return false;
    }
  }
}
```

---

## 第五步：替换 Mock 实现（连接华为云）

**操作步骤**:

1. 在 `entry/src/main/ets` 目录下创建 `http` 目录
2. 在 `http` 目录中创建 `HttpClient.ets` 文件

**复制以下代码**:

```typescript
/**
 * HTTP 网络请求工具
 * 封装了所有的网络请求方法
 */
import http from '@ohos.net.http';
import { ApiConfig } from '../config/ApiConfig';

export class HttpClient {
  /**
   * 发送 POST 请求（上传数据）
   * @param path API 路径，例如: '/sync/upload'
   * @param data 要上传的数据
   * @returns 服务器返回的结果
   */
  static async post(path: string, data: Record<string, Object>): Promise<Object> {
    // 第 1 步：创建 HTTP 请求对象
    const httpRequest = http.createHttp();

    try {
      // 第 2 步：拼接完整的 URL
      const fullUrl = ApiConfig.API_BASE_URL + path;
      console.log('[HTTP] 正在请求:', fullUrl);

      // 第 3 步：准备请求头（告诉服务器我们的身份）
      const headers: Record<string, string> = {
        'X-LC-Id': ApiConfig.APP_ID,           // 应用 ID
        'X-LC-Key': ApiConfig.APP_KEY,         // 应用密钥
        'Content-Type': 'application/json'      // 数据格式
      };

      // 第 4 步：发送请求
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.POST,        // POST 方法（上传）
        header: headers,                        // 请求头
        extraData: JSON.stringify(data),        // 数据（转成文本）
        expectDataType: http.HttpDataType.STRING, // 期望返回文本
        connectTimeout: ApiConfig.TIMEOUT,      // 连接超时
        readTimeout: ApiConfig.TIMEOUT          // 读取超时
      });

      // 第 5 步：检查是否成功
      if (response.responseCode === 200) {
        console.log('[HTTP] 请求成功');
        // 把返回的文本转回对象
        return JSON.parse(response.result as string);
      } else {
        console.error('[HTTP] 请求失败:', response.responseCode);
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }
    } catch (error) {
      console.error('[HTTP] 网络错误:', error);
      throw error;
    } finally {
      // 第 6 步：清理资源
      httpRequest.destroy();
    }
  }

  /**
   * 发送 GET 请求（获取数据）
   * @param path API 路径
   * @returns 服务器返回的结果
   */
  static async get(path: string): Promise<Object> {
    const httpRequest = http.createHttp();

    try {
      const fullUrl = ApiConfig.API_BASE_URL + path;
      console.log('[HTTP] 正在请求:', fullUrl);

      const headers: Record<string, string> = {
        'X-LC-Id': ApiConfig.APP_ID,
        'X-LC-Key': ApiConfig.APP_KEY
      };

      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.GET,
        header: headers,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: ApiConfig.TIMEOUT,
        readTimeout: ApiConfig.TIMEOUT
      });

      if (response.responseCode === 200) {
        console.log('[HTTP] 请求成功');
        return JSON.parse(response.result as string);
      } else {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }
    } catch (error) {
      console.error('[HTTP] 网络错误:', error);
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }
}
```

---

## 第五步：替换 Mock 实现（连接华为云）

### 5.1 修改 CloudSyncService

**文件位置**: `entry/src/main/ets/service/CloudSyncService.ets`

#### 5.1.1 添加导入语句

**在文件最顶部**（第 1 行之前）添加:

```typescript
import { HttpClient } from '../http/HttpClient';
import { ApiConfig } from '../config/ApiConfig';
```

**完整示例**:

```typescript
import { HttpClient } from '../http/HttpClient';  // ← 新增这行
import { ApiConfig } from '../config/ApiConfig';  // ← 新增这行
import { DatabaseManager } from '../database/DatabaseManager';
import { CloudSyncRecordDAO } from '../dao/CloudSyncRecordDAO';
// ... 其他导入
```

#### 5.1.2 找到 Mock 上传方法

**按 Ctrl+F 搜索**: `mockCloudUpload`

你会找到这段代码（大约在第 429 行）:

```typescript
private static async mockCloudUpload(data: string, userId: number): Promise<CloudApiResponse> {
  console.log(`[Mock] 上传数据到云端 (userId: ${userId})`);
  // ... Mock 代码
  return { success: true, message: 'Mock upload successful' };
}
```

#### 5.1.3 替换成华为云真实上传

**把整个方法替换成**:

```typescript
/**
 * 上传数据到华为云（真实实现）
 */
private static async mockCloudUpload(data: string, userId: number): Promise<CloudApiResponse> {
  console.log(`[华为云上传] 开始上传数据 (userId: ${userId})`);

  try {
    // 准备上传到华为云的数据
    const uploadData: Record<string, Object> = {
      userId: userId,
      data: data,
      timestamp: new Date().toISOString()
    };

    // 调用华为云 API
    const result = await HttpClient.post(ApiConfig.ENDPOINTS.SYNC_UPLOAD, uploadData);

    console.log('[华为云上传] 上传成功');
    return {
      success: true,
      message: '上传成功',
      syncId: (result as Record<string, Object>).syncId as string
    };
  } catch (error) {
    console.error('[华为云上传] 上传失败:', error);
    return {
      success: false,
      message: `上传失败: ${error instanceof Error ? error.message : '未知错误'}`
    };
  }
}
```

#### 5.1.4 找到 Mock 下载方法

**按 Ctrl+F 搜索**: `mockCloudDownload`

你会找到这段代码（大约在第 449 行）:

```typescript
private static async mockCloudDownload(userId: number): Promise<CloudDataPackage> {
  console.log(`[Mock] 从云端下载数据 (userId: ${userId})`);
  // ... Mock 代码
  return { bills: [], accounts: [], ... };
}
```

#### 5.1.5 替换成华为云真实下载

**把整个方法替换成**:

```typescript
/**
 * 从华为云下载数据（真实实现）
 */
private static async mockCloudDownload(userId: number): Promise<CloudDataPackage> {
  console.log(`[华为云下载] 开始下载数据 (userId: ${userId})`);

  try {
    // 从华为云服务器获取数据
    const result = await HttpClient.get(
      ApiConfig.ENDPOINTS.SYNC_DOWNLOAD,
      { userId: userId.toString() }
    );

    console.log('[华为云下载] 下载成功');

    // 解析返回的数据
    const cloudData = result as CloudDataPackage;

    return cloudData;
  } catch (error) {
    console.error('[华为云下载] 下载失败:', error);
    // 失败时返回空数据
    return {
      bills: [],
      accounts: [],
      categories: [],
      budgets: [],
      tags: [],
      timestamp: new Date().toISOString()
    };
  }
}
```

### 5.2 保存文件

**重要**: 按 `Ctrl+S` 保存所有修改的文件！

---

## 第六步：配置网络权限

### 6.1 打开权限配置文件

**文件位置**: `entry/src/main/module.json5`

**在 DevEco Studio 中打开这个文件**

### 6.2 找到 requestPermissions 部分

搜索（Ctrl+F）: `requestPermissions`

你应该能找到类似这样的代码:

```json
"requestPermissions": [
  // 可能已经有一些权限
]
```

### 6.3 添加网络权限

**在 `requestPermissions` 数组中添加**:

```json
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "$string:internet_permission",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "always"
    }
  },
  {
    "name": "ohos.permission.GET_NETWORK_INFO",
    "reason": "$string:network_info_permission",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "always"
    }
  }
]
```

### 6.4 添加权限说明文本

**文件位置**: `entry/src/main/resources/base/element/string.json`

**打开文件后，在 `string` 数组中添加**:

```json
{
  "name": "internet_permission",
  "value": "需要访问网络以同步数据"
},
{
  "name": "network_info_permission",
  "value": "需要获取网络状态"
}
```

**完整示例**:

```json
{
  "string": [
    {
      "name": "app_name",
      "value": "HarmonyExpense"
    },
    {
      "name": "internet_permission",
      "value": "需要访问网络以同步数据"
    },
    {
      "name": "network_info_permission",
      "value": "需要获取网络状态"
    }
  ]
}
```

---

## 第七步：测试华为云 API

### 7.1 先测试华为云服务器健康

**在应用启动时测试**:

在 `entry/src/main/ets/entryability/EntryAbility.ets` 的 `onCreate` 方法中添加:

```typescript
import { HttpClient } from '../http/HttpClient';

onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  // ... 现有代码

  // 测试华为云服务器连接
  HttpClient.healthCheck().then(isHealthy => {
    if (isHealthy) {
      console.log('[启动检查] 华为云服务器连接正常 ✓');
    } else {
      console.error('[启动检查] 华为云服务器连接失败 ✗');
    }
  });
}
```

### 7.2 编译运行项目

1. 在 DevEco Studio 顶部工具栏，点击"运行"按钮（绿色三角形）
2. 等待编译完成（可能需要 1-3 分钟）
3. 应用会自动安装到模拟器或真机上

### 7.3 触发云同步

**在应用中**:

1. 打开设置页面
2. 找到"云端同步"选项
3. 点击"立即同步"按钮

### 7.4 查看日志

**在 DevEco Studio 中**:

1. 点击底部的 "Log" 标签
2. 查找以下日志:

**成功的日志**:

```
[启动检查] 华为云服务器连接正常 ✓
[华为云HTTP] 正在请求: http://121.36.123.456:8080/api/v1/sync/upload
[华为云HTTP] 请求成功
[华为云上传] 上传成功
```

**失败的日志**:

```
[华为云HTTP] 网络错误: ...
[华为云上传] 上传失败: ...
```

### 7.5 在华为云服务器查看数据

**方法1: 通过 SSH 查看文件**:

```bash
# SSH 连接到服务器
ssh root@你的服务器IP

# 查看数据文件
cd /opt/harmonyexpense-api/data
ls -lh

# 查看最新的数据文件
cat user_1_*.json | tail -n 1 | jq .
```

**方法2: 通过 API 查询**:

在浏览器或 Postman 中访问:

```
http://你的服务器IP:8080/api/v1/sync/download?userId=1
```

**预期返回**:

```json
{
  "bills": [...],
  "accounts": [...],
  "categories": [...],
  "budgets": [...],
  "tags": [],
  "timestamp": "2025-12-20T10:30:00.000Z"
}
```

---

## 常见错误解决（华为云版）

### 错误 1: 找不到 @ohos.net.http

**错误信息**:

```
Cannot find module '@ohos.net.http'
```

**解决方法**:

1. 打开 `oh-package.json5`
2. 检查 `dependencies` 中是否有网络模块
3. 如果没有，运行命令: `ohpm install`

### 错误 2: 无法连接到华为云服务器

**错误信息**:

```
Network request failed / Connection timeout
```

**原因**: 服务器无法访问或防火墙未配置

**解决方法**:

1. **检查服务器是否运行**:
   ```bash
   ssh root@你的服务器IP
   pm2 list  # 查看服务状态
   pm2 logs harmonyexpense-api  # 查看日志
   ```

2. **检查防火墙规则**:
   - 登录华为云控制台
   - 进入 ECS → 安全组
   - 确保 8080 端口已开放

3. **测试服务器连接**:
   ```bash
   # 在本地电脑测试
   curl http://你的服务器IP:8080/health
   ```

4. **检查 ApiConfig.ets 中的 IP 地址**:
   - 确保使用的是公网 IP，不是私网 IP
   - 确保没有多余的空格

### 错误 3: HTTP 400 错误

**错误信息**:

```
HTTP 400: Bad Request
```

**原因**: 请求参数错误

**解决方法**:

1. 检查上传的数据格式是否正确
2. 确保 userId 不为空
3. 查看服务器日志获取详细错误信息:
   ```bash
   pm2 logs harmonyexpense-api --lines 50
   ```

### 错误 4: HTTP 500 服务器错误

**错误信息**:

```
HTTP 500: Internal Server Error
```

**原因**: 服务器后端代码出错

**解决方法**:

1. SSH 登录服务器查看日志:
   ```bash
   pm2 logs harmonyexpense-api
   ```

2. 检查数据目录权限:
   ```bash
   ls -la /opt/harmonyexpense-api/data
   chmod 755 /opt/harmonyexpense-api/data
   ```

3. 重启服务:
   ```bash
   pm2 restart harmonyexpense-api
   ```

### 错误 5: 权限被拒绝

**错误信息**:

```
Permission denied
```

**解决方法**:

1. 检查 `module.json5` 中是否添加了 `INTERNET` 权限
2. 卸载应用后重新安装
3. 在设备设置中手动授予网络权限

### 错误 6: 华为云服务器磁盘空间不足

**错误信息**:

```
ENOSPC: no space left on device
```

**解决方法**:

1. 检查磁盘使用情况:
   ```bash
   df -h
   ```

2. 清理旧的数据文件:
   ```bash
   cd /opt/harmonyexpense-api/data
   # 删除7天前的文件
   find . -name "user_*.json" -mtime +7 -delete
   ```

3. 在华为云控制台扩容系统盘

---

## 验证成功的标准（华为云版）

### 所有这些都正常，说明配置成功:

1. **启动健康检查通过**

   ```
   [启动检查] 华为云服务器连接正常 ✓
   ```
2. **上传日志显示成功**

   ```
   [华为云上传] 上传成功
   ```
3. **华为云服务器有数据文件**

   - SSH 连接后能看到 `user_*.json` 文件
   - 文件内容包含正确的账单数据
   - userId 正确

4. **下载功能正常**

   - 能从华为云下载数据
   - 数据格式正确
   - 能在应用中显示

5. **没有错误提示**

   - 应用不崩溃
   - 没有红色错误日志
   - 同步按钮可以正常点击

---

## 进阶：配置 HTTPS 和域名（可选）

### 为什么需要 HTTPS？

**当前问题**: HTTP 明文传输，不安全

**解决方案**: 配置华为云 ELB + SSL 证书

### 实现步骤（简要）

1. **购买域名**（例如：阿里云/腾讯云）

2. **在华为云 DNS 解析域名**:
   - 服务: 云解析服务 DNS
   - 添加 A 记录指向 ECS 公网 IP

3. **申请 SSL 证书**:
   - 服务: 证书管理服务 CCM
   - 申请免费 SSL 证书
   - 绑定域名

4. **配置 ELB 负载均衡**:
   - 创建 ELB 实例
   - 添加 HTTPS 监听器（443端口）
   - 绑定 SSL 证书
   - 后端服务器指向 ECS 的 8080 端口

5. **修改 ApiConfig.ets**:
   ```typescript
   static readonly API_BASE_URL = 'https://api.yourapp.com';
   ```

---

## 更多学习资源（华为云版）

### 官方文档

- 华为云文档: https://support.huaweicloud.com/
- HarmonyOS 网络请求: https://developer.harmonyos.com/cn/docs/documentation/doc-guides/net-http-0000001333625025
- 华为云 ECS: https://support.huaweicloud.com/ecs/
- 华为云 OBS: https://support.huaweicloud.com/obs/

### 视频教程

- 搜索"HarmonyOS 网络请求教程"
- 搜索"华为云 ECS 部署教程"
- 搜索"Node.js Express API 开发"

### 获取帮助

1. **查看日志**: 90% 的问题都能从日志中找到答案
   - 客户端日志：DevEco Studio Log 窗口
   - 服务器日志：`pm2 logs harmonyexpense-api`

2. **检查拼写**: 确保没有拼写错误

3. **对比代码**: 与本指南的代码逐行对比

4. **搜索错误信息**: 把错误信息复制到百度/Google

5. **华为云工单**: 如果是华为云服务问题，可以提交工单

---

## 完成检查清单（华为云版）

**完成配置前，逐一确认**:

- [ ] 已注册华为云账号并实名认证
- [ ] 已购买华为云 ECS 服务器
- [ ] 已在 ECS 上部署 Node.js API 服务
- [ ] 已配置安全组开放 8080 端口
- [ ] 测试 `/health` 接口返回正常
- [ ] 已创建 `ApiConfig.ets` 文件并填入 ECS IP
- [ ] 已创建 `HttpClient.ets` 文件
- [ ] 已修改 `CloudSyncService.ets` 的两个方法
- [ ] 已添加网络权限到 `module.json5`
- [ ] 已添加权限说明到 `string.json`
- [ ] 已保存所有文件（Ctrl+S）
- [ ] 已编译运行项目
- [ ] 启动健康检查通过
- [ ] 测试同步功能正常
- [ ] 华为云服务器能看到数据文件

**全部打勾 = 配置成功！🎉**

---

## 成本控制建议

### 按量付费 vs 包年包月

| 计费方式 | 适用场景 | 优势 | 月成本 |
|---------|---------|------|--------|
| **按量付费** | 测试开发阶段 | 灵活，随时释放 | ¥100-150 |
| **包年包月** | 生产环境 | 便宜30-40% | ¥70-100 |

### 节省成本技巧

1. **使用华为云新用户优惠**
   - 首次购买 ECS 可享受折扣
   - 关注华为云官网活动

2. **合理配置带宽**
   - 开发测试：1-2 Mbps 足够
   - 生产环境：按流量计费更划算

3. **定期清理数据**
   - 设置定时任务删除旧数据
   - 避免磁盘空间浪费

4. **使用华为云免费额度**
   - OBS 存储：50GB 免费额度
   - CDN 流量：50GB 免费额度

---

## 最后的话

1. **不要着急**: 第一次配置可能需要 3-4 小时，很正常
2. **仔细检查**: 大多数错误都是配置错误或拼写错误
3. **善用日志**: 客户端和服务器日志是你最好的朋友
4. **保存密钥**: ECS 密码、SSH 密钥不要泄露给别人
5. **定期备份**: 重要数据要定期备份到 OBS
6. **监控服务器**: 关注服务器 CPU、内存、磁盘使用情况

**祝你配置成功！** 🚀

**华为云 + HarmonyOS = 完美组合！** ☁️
