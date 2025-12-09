/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * ...
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
import { AbilityConstant } from '@kit.AbilityKit';

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO)
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate')

    // 初始化所有的数据库
    try {
      let context = this.context;
      await AccountDAO.initDatabase(context);
      await CategoryDAO.initDatabase(context);
      await BillDAO.initDatabase(context);
      await BudgetDAO.initDatabase(context);
      await StatisticsDAO.initDatabase(context);
      await UserDAO.initDatabase(context);

      hilog.info(0x0000, 'testTag', '所有数据库和表初始化成功');

      // 【已删除】: await this.insertMockPrerequisites();
      // 不再需要插入针对 UserID=1 的模拟数据，因为现在要由用户自己注册/登录产生数据。

    } catch (error) {
      hilog.error(0x00, 'testTag', '数据库初始化失败: %{public}s', JSON.stringify(error));
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

    // 【修改】: 将入口页面改为登录页 'pages/LoginPage'
    // 之前是 'pages/Index'
    windowStage.loadContent('pages/LoginPage', (err, data) => {
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
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO)
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy')
  }

  onForeground() {
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO)
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground')
  }

  onBackground() {
    hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.INFO)
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground')
  }


}