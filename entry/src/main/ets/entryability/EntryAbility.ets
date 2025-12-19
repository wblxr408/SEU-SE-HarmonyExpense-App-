/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import hilog from '@ohos.hilog'
import UIAbility from '@ohos.app.ability.UIAbility'
import Window from '@ohos.window'
import type Want  from '@ohos.app.ability.Want';
import { DatabaseManager } from '../database/DatabaseManager'
import { AccountDAO } from '../dao/AccountDAO'
import { CategoryDAO } from '../dao/CategoryDAO'
import { Account } from '../model/Account'
import { Category } from '../model/Category'
import { AbilityConstant } from '@kit.AbilityKit';
import { BusinessError} from '@kit.BasicServicesKit';
import { LogConfig } from '../common/AppConfig';
import { BreakpointSystem } from '../common/BreakpointSystem';

export default class EntryAbility extends UIAbility {
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  async onCreate(want:Want, launchParam:AbilityConstant.LaunchParam) {
    // Initialize PersistentStorage for API Key
    PersistentStorage.PersistProp('LLM_API_KEY', 'sk-db4d76d137084e459292cb477ccde584');

    hilog.isLoggable(LogConfig.DOMAIN, LogConfig.TAG, hilog.LogLevel.INFO)
    hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '%{public}s', 'Ability onCreate')
    hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '%{public}s', 'want param:' + JSON.stringify(want) ?? '')
    hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '%{public}s', 'launchParam:' + JSON.stringify(launchParam) ?? '')
    
    // 统一初始化数据库（使用DatabaseManager）
    try {
      const context = this.context;
      
      // 使用DatabaseManager统一初始化
      await DatabaseManager.initDatabase(context);
      
      hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '✅ 数据库初始化成功');

      // 添加临时的外键依赖数据
      // BillDAO里面有validateForeignKeys检查，需要至少一个账户和分类
      await this.insertMockPrerequisites();

    } catch (error) {
      hilog.error(LogConfig.DOMAIN, LogConfig.TAG, '❌ 数据库初始化失败: %{public}s', JSON.stringify(error));
    }
  }

  onDestroy() {
    hilog.isLoggable(LogConfig.DOMAIN, LogConfig.TAG, hilog.LogLevel.INFO)
    hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '%{public}s', 'Ability onDestroy')
  }

  onWindowStageCreate(windowStage: Window.WindowStage) {
    // Main window is created, set main page for this ability
    hilog.isLoggable(LogConfig.DOMAIN, LogConfig.TAG, hilog.LogLevel.INFO);
    hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '%{public}s', 'Ability onWindowStageCreate')
    
    // 注册响应式断点系统
    this.breakpointSystem.register();

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.isLoggable(LogConfig.DOMAIN, LogConfig.TAG, hilog.LogLevel.ERROR);
        hilog.error(LogConfig.DOMAIN, LogConfig.TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '')
        return
      }
      hilog.isLoggable(LogConfig.DOMAIN, LogConfig.TAG, hilog.LogLevel.INFO)
      hilog.info(LogConfig.DOMAIN, LogConfig.TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '')
    })
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    hilog.isLoggable(LogConfig.DOMAIN, LogConfig.TAG, hilog.LogLevel.INFO)
    hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '%{public}s', 'Ability onWindowStageDestroy')
    
    // 注销响应式断点系统
    this.breakpointSystem.unregister();
  }

  onForeground() {
    // Ability has brought to foreground
    hilog.isLoggable(LogConfig.DOMAIN, LogConfig.TAG, hilog.LogLevel.INFO)
    hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '%{public}s', 'Ability onForeground')
  }

  onBackground() {
    // Ability has back to background
    hilog.isLoggable(LogConfig.DOMAIN, LogConfig.TAG, hilog.LogLevel.INFO)
    hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '%{public}s', 'Ability onBackground')
  }
  /**
   * 插入模拟数据（用于开发测试）
   * 确保数据库中至少有一个账户和分类，满足外键约束
   */
  private async insertMockPrerequisites(): Promise<void> {
    // 1. 插入模拟账户
    try {
      const existingAccount = await AccountDAO.getById(1);
      if (!existingAccount) {
        const mockAccount = new Account();
        mockAccount.userId = 1;
        mockAccount.name = '模拟现金账户';
        mockAccount.type = 'cash';
        mockAccount.balance = 10000;
        mockAccount.createdAt = new Date().toISOString();
        mockAccount.updatedAt = new Date().toISOString();

        await AccountDAO.insert(mockAccount);
        hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '✅ 模拟账户插入成功');
      } else {
        hilog.info(LogConfig.DOMAIN, LogConfig.TAG, 'ℹ️ 模拟账户已存在，跳过插入');
      }
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(LogConfig.DOMAIN, LogConfig.TAG, '❌ 插入模拟账户失败: code=%{public}d, msg=%{public}s', e.code, e.message);
    }

    // 2. 插入模拟分类
    try {
      const existingCategory = await CategoryDAO.getById(1, 1);
      if (!existingCategory) {
        const mockCategory = new Category();
        mockCategory.userId = 1;
        mockCategory.name = '模拟餐饮';
        mockCategory.type = 'expense';
        mockCategory.icon = '🍽️';
        mockCategory.color = '#FF6B6B';
        mockCategory.parentCategoryId = 0;
        mockCategory.createdAt = new Date().toISOString();
        mockCategory.updatedAt = new Date().toISOString();

        await CategoryDAO.insert(mockCategory);
        hilog.info(LogConfig.DOMAIN, LogConfig.TAG, '✅ 模拟分类插入成功');
      } else {
        hilog.info(LogConfig.DOMAIN, LogConfig.TAG, 'ℹ️ 模拟分类已存在，跳过插入');
      }
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(LogConfig.DOMAIN, LogConfig.TAG, '❌ 插入模拟分类失败: code=%{public}d, msg=%{public}s', e.code, e.message);
    }
  }
}
