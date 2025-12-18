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

/**
 * 应用常量定义
 * 
 * 注意：本文件保留用于向后兼容，部分常量已废弃
 */

/**
 * 圆形半径常量（用于UI组件）
 */
export let CIRCLE_RADIUS: number = 80;

/**
 * @deprecated v1.2.0 已废弃 - 不再使用单例用户ID
 * 
 * 请使用 UserSessionService 获取当前登录用户
 * 
 * 迁移指南：
 * ```typescript
 * // 旧代码
 * import { CURRENT_USER_ID } from '../common/Constants';
 * const userId = CURRENT_USER_ID;
 * 
 * // 新代码
 * import { UserSessionService } from '../service/UserSessionService';
 * const userId = UserSessionService.getCurrentUserId();
 * 
 * // 兼容处理（如果未登录，使用默认值1）
 * const userId = UserSessionService.getCurrentUserId() || 1;
 * ```
 * 
 * 相关文档：
 * - README说明/高级功能实现文档.md
 * - README说明/高级功能快速开始.md
 */
export const CURRENT_USER_ID: number = 1;