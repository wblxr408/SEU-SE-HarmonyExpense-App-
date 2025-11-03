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
import { AccountDAO } from '../dao/AccountDAO'
import { BillDAO } from '../dao/BillDAO'
import { CategoryDAO } from '../dao/CategoryDAO'
import { BudgetDAO } from '../dao/BudgetDAO'
import { StatisticsDAO } from '../dao/StatisticsDAO'
import { UserDAO } from '../dao/UserDAO'
import { Account } from '../model/Account'
import { Category } from '../model/Category'
import { Ability, AbilityConstant } from '@kit.AbilityKit';
import { BusinessError} from '@kit.BasicServicesKit';

export default class EntryAbility extends UIAbility {
  async onCreate(want:Want, launchParam:AbilityConstant.LaunchParam) {
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO)
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate')
    hilog.info(0x0000, 'testTag', '%{public}s', 'want param:' + JSON.stringify(want) ?? '')
    hilog.info(0x0000, 'testTag', '%{public}s', 'launchParam:' + JSON.stringify(launchParam) ?? '')
  //初始化所有的数据库
    try{
    let context = this.context;
      await AccountDAO.initDatabase(context);
      await CategoryDAO.initDatabase(context);
      await BillDAO.initDatabase(context);
      await BudgetDAO.initDatabase(context);
      await StatisticsDAO.initDatabase(context);
      await UserDAO.initDatabase(context);

      hilog.info(0x0000, 'testTag', '所有数据库和表初始化成功');

      //添加临时的外键依赖数据，BillDAO里面有validateForeignKeys检查
      //所以必须保证数据库当中至少有一个账户和分类否则失败
      await this.insertMockPrerequisites();

    }catch (error){
      hilog.error(0x00,'testTag','数据库初始化失败: %{public}s', JSON.stringify(error));
    }
  }

  onDestroy() {
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO)
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy')
  }

  onWindowStageCreate(windowStage: Window.WindowStage) {
    // Main window is created, set main page for this ability
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate')

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.ERROR);
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '')
        return
      }
      hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO)
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '')
    })
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO)
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy')
  }

  onForeground() {
    // Ability has brought to foreground
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO)
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground')
  }

  onBackground() {
    // Ability has back to background
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO)
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground')
  }
  async insertMockPrerequisites() {
    // 1. 插入一个模拟账户 (Account)
    try {
      // 检查是否已经存在，避免重复插入 (使用 AccountDAO.ets 中的 getById)
      const existingAccount = await AccountDAO.getById(1); // 假设我们用 ID 1
      if (!existingAccount) {
        const mockAccount = new Account();
        // 注意：DAO 里的 account_id 是自增主键，这里不需要设置
        mockAccount.userId = 1; // 模拟用户1
        mockAccount.name = '模拟现金账户';
        mockAccount.type = 'cash';
        mockAccount.balance = 10000;
        mockAccount.createdAt = new Date().toISOString();
        mockAccount.updatedAt = new Date().toISOString();

        await AccountDAO.insert(mockAccount);
        hilog.info(0x0000, 'testTag', '模拟账户插入成功');
      } else {
        hilog.info(0x0000, 'testTag', '模拟账户已存在，跳过插入');
      }
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(0x0000, 'testTag', '插入模拟账户失败: %{public}s', `code=${e.code}, msg=${e.message}`);
    }

    // 2. 插入一个模拟分类 (Category)
    try {
      // 检查是否已经存在 (使用 CategoryDAO.ets 中的 getById)
      // 签名是: getById(userId: number, categoryId: number)
      const existingCategory = await CategoryDAO.getById(1, 1); // 假设用户ID 1, 分类ID 1
      if (!existingCategory) {
        const mockCategory = new Category();
        // category_id 也是自增主键
        mockCategory.userId = 1; // 模拟用户1
        mockCategory.name = '模拟餐饮';
        mockCategory.type = 'expense';
        mockCategory.icon = '🍽️';
        mockCategory.color = '#FF6B6B';
        mockCategory.parentCategoryId = 0;
        mockCategory.createdAt = new Date().toISOString();
        mockCategory.updatedAt = new Date().toISOString();

        await CategoryDAO.insert(mockCategory);
        hilog.info(0x0000, 'testTag', '模拟分类插入成功');
      } else {
        hilog.info(0x0000, 'testTag', '模拟分类已存在，跳过插入');
      }
    } catch (err) {
      let e = err as BusinessError;
      hilog.error(0x0000, 'testTag', '插入模拟分类失败: %{public}s', `code=${e.code}, msg=${e.message}`);
    }
  }
}
