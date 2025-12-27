/**
 * 用户会话管理服务
 * 替代单例模式的 CURRENT_USER_ID，支持真实登录系统
 * 
 * 功能：
 * - 用户登录/登出
 * - 会话管理
 * - 当前用户信息获取
 */
import { UserDAO } from '../dao/UserDAO';
import { User } from '../model/User';
import cryptoFramework from '@ohos.security.cryptoFramework';
import util from '@ohos.util';

/**
 * 会话信息
 */
export class SessionInfo {
  userId: number = 0;
  username: string = '';
  email: string = '';
  loginTime: string = '';
  lastActiveTime: string = '';
  token?: string;

  constructor(
    userId: number,
    username: string,
    email: string,
    loginTime: string,
    lastActiveTime: string,
    token?: string
  ) {
    this.userId = userId;
    this.username = username;
    this.email = email;
    this.loginTime = loginTime;
    this.lastActiveTime = lastActiveTime;
    this.token = token;
  }
}

/**
 * 登录结果
 */
export class LoginResult {
  success: boolean = false;
  message: string = '';
  session?: SessionInfo;

  constructor(success: boolean, message: string, session?: SessionInfo) {
    this.success = success;
    this.message = message;
    this.session = session;
  }
}

/**
 * 操作结果（用于密码修改、邮箱更新等操作）
 */
export class OperationResult {
  success: boolean = false;
  message: string = '';

  constructor(success: boolean, message: string) {
    this.success = success;
    this.message = message;
  }
}

/**
 * 用户会话管理服务
 */
export class UserSessionService {
  private static currentSession: SessionInfo | null = null;
  private static readonly SESSION_TIMEOUT: number = 24 * 60 * 60 * 1000; // 24小时

  /**
   * 用户登录
   * @param email 邮箱
   * @param password 密码
   * @returns 登录结果
   */
  static async login(email: string, password: string): Promise<LoginResult> {
    try {
      // 1. 查询用户
      const users: User[] = await UserDAO.getAll();
      const user: User | undefined = users.find(u => u.email === email);

      if (!user) {
        return new LoginResult(false, '用户不存在');
      }

      // 2. 验证密码
      const passwordHash: string = await UserSessionService.hashPassword(password);
      if (user.passwordHash !== passwordHash) {
        return new LoginResult(false, '密码错误');
      }

      // 3. 创建会话
      const now: string = new Date().toISOString();
      UserSessionService.currentSession = new SessionInfo(
        user.userId,
        user.username,
        user.email,
        now,
        now,
        UserSessionService.generateToken(user.userId)
      );

      console.log(`[UserSessionService] 用户登录成功: ${user.username} (ID: ${user.userId})`);

      return new LoginResult(true, '登录成功', UserSessionService.currentSession);
    } catch (error) {
      console.error('[UserSessionService] 登录失败:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      return new LoginResult(false, `登录失败: ${errorMsg}`);
    }
  }

  /**
   * 用户登出
   */
  static logout(): void {
    if (UserSessionService.currentSession) {
      console.log(`[UserSessionService] 用户登出: ${UserSessionService.currentSession.username}`);
      UserSessionService.currentSession = null;
    }
  }

  /**
   * 获取当前登录用户ID
   * @returns 用户ID，未登录返回null
   */
  static getCurrentUserId(): number | null {
    if (!UserSessionService.isLoggedIn()) {
      return null;
    }
    return UserSessionService.currentSession!.userId;
  }

  /**
   * 获取当前会话信息
   * @returns 会话信息，未登录返回null
   */
  static getCurrentSession(): SessionInfo | null {
    if (!UserSessionService.isLoggedIn()) {
      return null;
    }
    return UserSessionService.currentSession;
  }

  /**
   * 检查是否已登录
   * @returns 是否已登录
   */
  static isLoggedIn(): boolean {
    if (!UserSessionService.currentSession) {
      return false;
    }

    // 检查会话是否过期
    const now: number = Date.now();
    const lastActive: number = new Date(UserSessionService.currentSession.lastActiveTime).getTime();
    if (now - lastActive > UserSessionService.SESSION_TIMEOUT) {
      console.log('[UserSessionService] 会话已过期');
      UserSessionService.currentSession = null;
      return false;
    }

    // 更新最后活跃时间
    UserSessionService.currentSession.lastActiveTime = new Date().toISOString();
    return true;
  }

  /**
   * 用户注册
   * @param username 用户名
   * @param email 邮箱
   * @param password 密码
   * @returns 注册结果
   */
  static async register(username: string, email: string, password: string): Promise<LoginResult> {
    try {
      // 1. 检查邮箱是否已存在
      const users: User[] = await UserDAO.getAll();
      const existingUser: User | undefined = users.find(u => u.email === email);
      if (existingUser) {
        return new LoginResult(false, '邮箱已被注册');
      }

      // 2. 创建用户
      const passwordHash: string = await UserSessionService.hashPassword(password);
      const user: User = new User(0, username, email, passwordHash);
      await UserDAO.insert(user);

      console.log(`[UserSessionService] 用户注册成功: ${username}`);

      // 3. 自动登录
      return await UserSessionService.login(email, password);
    } catch (error) {
      console.error('[UserSessionService] 注册失败:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      return new LoginResult(false, `注册失败: ${errorMsg}`);
    }
  }

  /**
   * 密码哈希（简化版，生产环境应使用更安全的方法）
   * @param password 明文密码
   * @returns 密码哈希
   */
  private static async hashPassword(password: string): Promise<string> {
    try {
      // 使用 SHA-256 哈希
      const md: cryptoFramework.Md = cryptoFramework.createMd('SHA256');
      const encoder: util.TextEncoder = new util.TextEncoder();
      const passwordBytes: Uint8Array = encoder.encodeInto(password);
      await md.update({ data: passwordBytes });
      const hashResult: cryptoFramework.DataBlob = await md.digest();

      // 转换为十六进制字符串
      const hashArray: number[] = Array.from(new Uint8Array(hashResult.data));
      return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    } catch (error) {
      console.error('[UserSessionService] 密码哈希失败:', error);
      // 降级方案：简单Base64编码
      const encoder: util.TextEncoder = new util.TextEncoder();
      const bytes: Uint8Array = encoder.encodeInto(password);
      const base64: util.Base64Helper = new util.Base64Helper();
      return base64.encodeToStringSync(bytes);
    }
  }

  /**
   * 生成会话令牌
   * @param userId 用户ID
   * @returns 令牌
   */
  private static generateToken(userId: number): string {
    const timestamp: number = Date.now();
    const random: string = Math.random().toString(36).substring(2);
    return `${userId}_${timestamp}_${random}`;
  }

  /**
   * 切换用户（用于测试或管理员功能）
   * @param userId 用户ID
   */
  static async switchUser(userId: number): Promise<boolean> {
    try {
      const user: User | null = await UserDAO.getById(userId);
      if (!user) {
        console.error(`[UserSessionService] 用户不存在: ${userId}`);
        return false;
      }

      const now: string = new Date().toISOString();
      UserSessionService.currentSession = new SessionInfo(
        user.userId,
        user.username,
        user.email,
        now,
        now,
        UserSessionService.generateToken(user.userId)
      );

      console.log(`[UserSessionService] 切换用户成功: ${user.username} (ID: ${user.userId})`);
      return true;
    } catch (error) {
      console.error('[UserSessionService] 切换用户失败:', error);
      return false;
    }
  }

  /**
   * 获取会话剩余时间（毫秒）
   * @returns 剩余时间，未登录返回0
   */
  static getSessionRemainingTime(): number {
    if (!UserSessionService.currentSession) {
      return 0;
    }

    const now: number = Date.now();
    const lastActive: number = new Date(UserSessionService.currentSession.lastActiveTime).getTime();
    const remaining: number = UserSessionService.SESSION_TIMEOUT - (now - lastActive);
    return Math.max(0, remaining);
  }

  /**
   * 更新用户资料（昵称和头像）
   * @param nickname 新昵称
   * @param avatarPath 新头像路径
   */
  static async updateProfile(nickname: string, avatarPath: string): Promise<boolean> {
    if (!UserSessionService.isLoggedIn()) {
      console.error('[UserSessionService] 未登录，无法更新资料');
      return false;
    }

    try {
      const userId: number = UserSessionService.currentSession!.userId;
      await UserDAO.updateProfile(userId, nickname, avatarPath);
      console.log('[UserSessionService] 资料更新成功');
      return true;
    } catch (error) {
      console.error('[UserSessionService] 更新资料失败:', error);
      return false;
    }
  }

  /**
   * 修改密码
   * @param oldPassword 旧密码
   * @param newPassword 新密码
   */
  static async changePassword(oldPassword: string, newPassword: string): Promise<OperationResult> {
    if (!UserSessionService.isLoggedIn()) {
      return new OperationResult(false, '未登录');
    }

    try {
      const userId: number = UserSessionService.currentSession!.userId;
      const user: User | null = await UserDAO.getById(userId);
      if (!user) {
        return new OperationResult(false, '用户不存在');
      }

      // 验证旧密码
      const oldHash: string = await UserSessionService.hashPassword(oldPassword);
      if (user.passwordHash !== oldHash) {
        return new OperationResult(false, '旧密码错误');
      }

      // 更新新密码
      const newHash: string = await UserSessionService.hashPassword(newPassword);
      await UserDAO.updatePassword(userId, newHash);
      console.log('[UserSessionService] 密码修改成功');
      return new OperationResult(true, '密码修改成功');
    } catch (error) {
      console.error('[UserSessionService] 密码修改失败:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      return new OperationResult(false, `密码修改失败: ${errorMsg}`);
    }
  }

  /**
   * 更新邮箱
   * @param newEmail 新邮箱
   */
  static async updateEmail(newEmail: string): Promise<OperationResult> {
    if (!UserSessionService.isLoggedIn()) {
      return new OperationResult(false, '未登录');
    }

    // 简单邮箱格式校验
    const emailRegex: RegExp = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(newEmail)) {
      return new OperationResult(false, '邮箱格式不正确');
    }

    try {
      const userId: number = UserSessionService.currentSession!.userId;

      // 检查邮箱是否已被其他用户使用
      const users: User[] = await UserDAO.getAll();
      const existing: User | undefined = users.find(u => u.email === newEmail && u.userId !== userId);
      if (existing) {
        return new OperationResult(false, '该邮箱已被其他用户使用');
      }

      await UserDAO.updateEmail(userId, newEmail);
      // 更新会话中的邮箱
      UserSessionService.currentSession!.email = newEmail;
      console.log('[UserSessionService] 邮箱更新成功');
      return new OperationResult(true, '邮箱更新成功');
    } catch (error) {
      console.error('[UserSessionService] 邮箱更新失败:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      return new OperationResult(false, `邮箱更新失败: ${errorMsg}`);
    }
  }
}

