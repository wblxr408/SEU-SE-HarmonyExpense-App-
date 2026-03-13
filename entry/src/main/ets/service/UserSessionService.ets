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
import preferences from '@ohos.data.preferences';
import { GlobalContext } from '../common/GlobalContext';
import {BusinessError} from '@ohos.base'
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

  toJSON(): string {
    return JSON.stringify({
      userId: this.userId,
      username: this.username,
      email: this.email,
      loginTime: this.loginTime,
      lastActiveTime: this.lastActiveTime,
      token: this.token
    });
  }

  static fromJSON(json: string): SessionInfo | null {
    interface SessionData {
      userId: number;
      username: string;
      email: string;
      loginTime: string;
      lastActiveTime: string;
      token?: string;
    }
    try {
      const data = JSON.parse(json) as SessionData;
      return new SessionInfo(
        data.userId,
        data.username,
        data.email,
        data.loginTime,
        data.lastActiveTime,
        data.token
      );
    } catch {
      return null;
    }
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
  private static readonly SESSION_PREFERENCES_NAME: string = 'user_session_prefs';
  private static readonly SALT_LENGTH: number = 16;
  private static readonly PBKDF2_ITERATIONS: number = 100000;

  /**
   * 初始化首选项
   */
  private static async initPreferences(): Promise<preferences.Preferences | null> {
    try {
      const context = GlobalContext.getContext();
      if (!context) {
        return null;
      }
      return await preferences.getPreferences(context, UserSessionService.SESSION_PREFERENCES_NAME);
    } catch (error) {
      console.error('[UserSessionService] 初始化首选项失败:', error);
      return null;
    }
  }

  /**
   * 保存会话到持久化存储
   */
  private static async saveSessionToStorage(session: SessionInfo): Promise<void> {
    try {
      const prefs = await UserSessionService.initPreferences();
      if (prefs) {
        await prefs.put('current_session', session.toJSON());
        await prefs.flush();
      }
    } catch (error) {
      console.error('[UserSessionService] 保存会话失败:', error);
    }
  }

  /**
   * 从持久化存储加载会话
   */
  private static async loadSessionFromStorage(): Promise<SessionInfo | null> {
    try {
      const prefs = await UserSessionService.initPreferences();
      if (prefs) {
        const sessionJson = await prefs.getSync('current_session', '') as string;
        if (sessionJson) {
          return SessionInfo.fromJSON(sessionJson);
        }
      }
    } catch (error) {
      console.error('[UserSessionService] 加载会话失败:', error);
    }
    return null;
  }

  /**
   * 清除持久化会话
   */
  private static async clearSessionFromStorage(): Promise<void> {
    try {
      const prefs = await UserSessionService.initPreferences();
      if (prefs) {
        await prefs.delete('current_session');
        await prefs.flush();
      }
    } catch (error) {
      console.error('[UserSessionService] 清除会话失败:', error);
    }
  }

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

      // 2. 验证密码（使用盐值验证）
      const passwordHash: string = await UserSessionService.hashPasswordWithSalt(password, user.passwordHash);
      if (user.passwordHash !== passwordHash) {
        return new LoginResult(false, '密码错误');
      }

      // 3. 创建会话
      const now: string = new Date().toISOString();
      const newSession: SessionInfo = new SessionInfo(
        user.userId,
        user.username,
        user.email,
        now,
        now,
        await UserSessionService.generateSecureToken(user.userId)
      );

      UserSessionService.currentSession = newSession;

      // 4. 持久化会话
      await UserSessionService.saveSessionToStorage(newSession);

      console.log(`[UserSessionService] 用户登录成功: ${user.username} (ID: ${user.userId})`);

      return new LoginResult(true, '登录成功', newSession);
    } catch (error) {
      console.error('[UserSessionService] 登录失败:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      return new LoginResult(false, `登录失败: ${errorMsg}`);
    }
  }

  /**
   * 用户登出
   */
  static async logout(): Promise<void> {
    if (UserSessionService.currentSession) {
      console.log(`[UserSessionService] 用户登出: ${UserSessionService.currentSession.username}`);
      UserSessionService.currentSession = null;
      await UserSessionService.clearSessionFromStorage();
    }
  }

  /**
   * 获取当前登录用户ID
   * @returns 用户ID，未登录返回null
   */
  static async getCurrentUserId(): Promise<number | null> {
    const session = await UserSessionService.getCurrentSession();
    return session?.userId ?? null;
  }

  /**
   * 获取当前会话信息
   * @returns 会话信息，未登录返回null
   */
  static async getCurrentSession(): Promise<SessionInfo | null> {
    // 如果内存中有会话，直接返回
    if (UserSessionService.currentSession) {
      // 检查会话是否过期
      if (UserSessionService.isSessionExpired()) {
        await UserSessionService.logout();
        return null;
      }
      // 更新最后活跃时间
      UserSessionService.currentSession.lastActiveTime = new Date().toISOString();
      await UserSessionService.saveSessionToStorage(UserSessionService.currentSession);
      return UserSessionService.currentSession;
    }

    // 从持久化存储加载
    const storedSession = await UserSessionService.loadSessionFromStorage();
    if (storedSession && !UserSessionService.isSessionExpired(storedSession)) {
      UserSessionService.currentSession = storedSession;
      return storedSession;
    }

    return null;
  }

  /**
   * 检查会话是否过期
   */
  private static isSessionExpired(session?: SessionInfo): boolean {
    const targetSession = session || UserSessionService.currentSession;
    if (!targetSession) {
      return true;
    }

    const now: number = Date.now();
    const lastActive: number = new Date(targetSession.lastActiveTime).getTime();
    return (now - lastActive) > UserSessionService.SESSION_TIMEOUT;
  }

  /**
   * 检查是否已登录
   * @returns 是否已登录
   */
  static async isLoggedIn(): Promise<boolean> {
    const session = await UserSessionService.getCurrentSession();
    return session !== null;
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
      // 1. 验证邮箱格式
      if (!UserSessionService.validateEmail(email)) {
        return new LoginResult(false, '邮箱格式不正确');
      }

      // 2. 检查邮箱是否已存在
      const users: User[] = await UserDAO.getAll();
      const existingUser: User | undefined = users.find(u => u.email === email);
      if (existingUser) {
        return new LoginResult(false, '邮箱已被注册');
      }

      // 3. 创建用户（使用盐值哈希）
      const passwordHash: string = await UserSessionService.hashPassword(password);
      const user: User = new User(0, username, email, passwordHash);
      await UserDAO.insert(user);

      console.log(`[UserSessionService] 用户注册成功: ${username}`);

      // 4. 自动登录
      return await UserSessionService.login(email, password);
    } catch (error) {
      console.error('[UserSessionService] 注册失败:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      return new LoginResult(false, `注册失败: ${errorMsg}`);
    }
  }

  /**
   * 验证邮箱格式
   */
  private static validateEmail(email: string): boolean {
    // 更严格的邮箱验证
    const emailRegex: RegExp = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    const maxLength = 254;
    return email.length > 0 && email.length <= maxLength && emailRegex.test(email);
  }

  /**
   * 密码哈希（带随机盐值）
   * @param password 明文密码
   * @param existingHash 现有哈希（可选，用于验证）
   * @returns 密码哈希（格式：salt:hash）
   */
  private static async hashPassword(password: string, existingHash?: string): Promise<string> {
    try {
      let saltHex: string;
      let storedHash: string;

      if (existingHash && existingHash.includes(':')) {
        // 验证模式：提取盐值
        const parts = existingHash.split(':');
        saltHex = parts[0];
        storedHash = parts[1];
      } else {
        // 新密码模式：生成随机盐值
        saltHex =await UserSessionService.generateSecureSalt();
        storedHash = '';
      }

      const saltBytes: Uint8Array = UserSessionService.hexToBytes(saltHex);
      const passwordBytes: Uint8Array = new util.TextEncoder().encodeInto(password);

      // // 使用PBKDF2
      // const kdf = cryptoFramework.createKdf({
      //   algName: 'PBKDF2',
      //   spec: {
      //     algName: 'PBKDF2',
      //     salt: { data: saltBytes },
      //     iterations: UserSessionService.PBKDF2_ITERATIONS,
      //     keyLen: 32,
      //     digest: 'SHA256'
      //   }
      // });
      //
      // const derivedKey = await kdf.generateKey(passwordBytes);
      // const hashBytes = derivedKey.getEncoded();
      // const hashHex = UserSessionService.bytesToHex(new Uint8Array(hashBytes.data));
const kdf = cryptoFramework.createKdf('PBKDF2|SHA256');
const spec: cryptoFramework.PBKDF2Spec={
  algName: 'PBKDF2',
  password: passwordBytes,
  salt: saltBytes,
  iterations: UserSessionService.PBKDF2_ITERATIONS,
  keySize: 32

};
      const secret = await new Promise<cryptoFramework.DataBlob>((resolve, reject) => {
        kdf.generateSecret(spec, (err: BusinessError, data: cryptoFramework.DataBlob) => {
          if (err) {
            reject(err);
          } else {
            resolve(data);
          }
        });
      });

      const hashBytes = new Uint8Array(secret.data);
      const hashHex = UserSessionService.bytesToHex(hashBytes);

      if (existingHash) {
        return `${saltHex}:${storedHash}`;
      }
      return `${saltHex}:${hashHex}`;
    } catch (error) {
      console.error('[UserSessionService] 密码哈希失败:', error);
      // 降级方案：简单哈希（不推荐生产环境使用）
      const encoder = new util.TextEncoder();
      const bytes = encoder.encodeInto(password + 'fallback_salt');
      const md = cryptoFramework.createMd('SHA256');
      await md.update({ data: bytes });
      const hashResult = await md.digest();
      const hashArray = Array.from(new Uint8Array(hashResult.data));
      return `fallback:${hashArray.map(b => b.toString(16).padStart(2, '0')).join('')}`;
    }
  }

  /**
   * 使用盐值验证密码
   */
  private static async hashPasswordWithSalt(password: string, storedHash: string): Promise<string> {
    try {
      if (!storedHash.includes(':')) {
        // 旧格式兼容
        const encoder = new util.TextEncoder();
        const bytes = encoder.encodeInto(password);
        const md = cryptoFramework.createMd('SHA256');
        await md.update({ data: bytes });
        const hashResult = await md.digest();
        const hashArray = Array.from(new Uint8Array(hashResult.data));
        return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
      }

      const parts = storedHash.split(':');
      const saltHex = parts[0];
      const expectedHash = parts[1];

      const saltBytes = UserSessionService.hexToBytes(saltHex);
      const passwordBytes = new util.TextEncoder().encodeInto(password);

      const kdf = cryptoFramework.createKdf('PBKDF2|SHA256');
      const spec: cryptoFramework.PBKDF2Spec = {
        algName: 'PBKDF2',
        password: passwordBytes,
        salt: saltBytes,
        iterations: UserSessionService.PBKDF2_ITERATIONS,
        keySize: 32 // 32字节 = 256位
      };

      const secret = await new Promise<cryptoFramework.DataBlob>((resolve, reject) => {
        kdf.generateSecret(spec, (err: BusinessError, data: cryptoFramework.DataBlob) => {
          if (err) {
            reject(err);
          } else {
            resolve(data);
          }
        });
      });

      const hashBytes = new Uint8Array(secret.data);
      const hashHex = UserSessionService.bytesToHex(hashBytes);

      return `${saltHex}:${hashHex}`;
    } catch (error) {
      console.error('[UserSessionService] 密码验证失败:', error);
      throw new Error(error instanceof Error ? error.message : String(error));
    }
  }

  /**
   * 生成加密安全的随机盐值
   */
  // private static generateSecureSalt(): string {
  //   const random = new Uint8Array(UserSessionService.SALT_LENGTH);
  //   cryptoFramework.generateRandomRandom({ size: UserSessionService.SALT_LENGTH }, (error, data) => {
  //     if (!error && data) {
  //       for (let i = 0; i < UserSessionService.SALT_LENGTH; i++) {
  //         random[i] = data[i];
  //       }
  //     }
  //   });
  //   return UserSessionService.bytesToHex(random);
  // }
  private static async generateSecureSalt(): Promise<string> {
    try {
      const random = cryptoFramework.createRandom();
      const randomData: cryptoFramework.DataBlob = await random.generateRandom(UserSessionService.SALT_LENGTH);
      return UserSessionService.bytesToHex(new Uint8Array(randomData.data));
    } catch (error) {
      console.error('[UserSessionService] 生成盐值失败:', error);
      // 降级方案：使用非加密随机数（仅用于演示）
      const fallback = new Uint8Array(UserSessionService.SALT_LENGTH);
      for (let i = 0; i < fallback.length; i++) {
        fallback[i] = Math.floor(Math.random() * 256);
      }
      return UserSessionService.bytesToHex(fallback);
    }
  }
  /**
   * 生成安全的会话令牌
   * @param userId 用户ID
   * @returns 令牌
   */
  // private static generateSecureToken(userId: number): string {
  //   const timestamp: number = Date.now();
  //   const randomBytes = new Uint8Array(16);
  //   cryptoFramework.generateRandomRandom({ size: 16 }, (error, data) => {
  //     if (!error && data) {
  //       for (let i = 0; i < 16; i++) {
  //         randomBytes[i] = data[i];
  //       }
  //     }
  //   });
  //   const randomHex = UserSessionService.bytesToHex(randomBytes);
  //   return `${userId}_${timestamp}_${randomHex}`;
  // }
  private static async generateSecureToken(userId: number): Promise<string> {
    const timestamp: number = Date.now();
    try {
      const random = cryptoFramework.createRandom();
      const randomData: cryptoFramework.DataBlob = await random.generateRandom(16);
      const randomHex = UserSessionService.bytesToHex(new Uint8Array(randomData.data));
      return `${userId}_${timestamp}_${randomHex}`;
    } catch (error) {
      console.error('[UserSessionService] 生成令牌失败:', error);
      // 降级方案：使用时间戳和随机数组合
      return `${userId}_${timestamp}_${Math.random().toString(36).substring(2)}`;
    }
  }
  /**
   * 字节数组转十六进制字符串
   */
  private static bytesToHex(bytes: Uint8Array): string {
    return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
  }

  /**
   * 十六进制字符串转字节数组
   */
  private static hexToBytes(hex: string): Uint8Array {
    const bytes = new Uint8Array(hex.length / 2);
    for (let i = 0; i < hex.length; i += 2) {
      bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16);
    }
    return bytes;
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
      const newSession: SessionInfo = new SessionInfo(
        user.userId,
        user.username,
        user.email,
        now,
        now,
        await UserSessionService.generateSecureToken(user.userId)
      );

      UserSessionService.currentSession = newSession;
      await UserSessionService.saveSessionToStorage(newSession);

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
  static async getSessionRemainingTime(): Promise<number> {
    const session = await UserSessionService.getCurrentSession();
    if (!session) {
      return 0;
    }

    const now: number = Date.now();
    const lastActive: number = new Date(session.lastActiveTime).getTime();
    const remaining: number = UserSessionService.SESSION_TIMEOUT - (now - lastActive);
    return Math.max(0, remaining);
  }

  /**
   * 更新用户资料（昵称和头像）
   * @param nickname 新昵称
   * @param avatarPath 新头像路径
   */
  static async updateProfile(nickname: string, avatarPath: string): Promise<boolean> {
    const session = await UserSessionService.getCurrentSession();
    if (!session) {
      console.error('[UserSessionService] 未登录，无法更新资料');
      return false;
    }

    try {
      await UserDAO.updateProfile(session.userId, nickname, avatarPath);
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
    const session = await UserSessionService.getCurrentSession();
    if (!session) {
      return new OperationResult(false, '未登录');
    }

    try {
      const user: User | null = await UserDAO.getById(session.userId);
      if (!user) {
        return new OperationResult(false, '用户不存在');
      }

      // 验证旧密码
      const oldHash: string = await UserSessionService.hashPasswordWithSalt(oldPassword, user.passwordHash);
      if (user.passwordHash !== oldHash) {
        return new OperationResult(false, '旧密码错误');
      }

      // 更新新密码（自动生成新盐值）
      const newHash: string = await UserSessionService.hashPassword(newPassword);
      await UserDAO.updatePassword(session.userId, newHash);
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
    const session = await UserSessionService.getCurrentSession();
    if (!session) {
      return new OperationResult(false, '未登录');
    }

    // 严格验证邮箱格式
    if (!UserSessionService.validateEmail(newEmail)) {
      return new OperationResult(false, '邮箱格式不正确');
    }

    try {
      // 检查邮箱是否已被其他用户使用
      const users: User[] = await UserDAO.getAll();
      const existing: User | undefined = users.find(u => u.email === newEmail && u.userId !== session.userId);
      if (existing) {
        return new OperationResult(false, '该邮箱已被其他用户使用');
      }

      await UserDAO.updateEmail(session.userId, newEmail);
      // 更新会话中的邮箱
      session.email = newEmail;
      await UserSessionService.saveSessionToStorage(session);
      console.log('[UserSessionService] 邮箱更新成功');
      return new OperationResult(true, '邮箱更新成功');
    } catch (error) {
      console.error('[UserSessionService] 邮箱更新失败:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      return new OperationResult(false, `邮箱更新失败: ${errorMsg}`);
    }
  }
}