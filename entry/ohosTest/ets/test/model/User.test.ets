import { describe, it, expect } from '@ohos/hypium';
import { User, UserJSON } from '../../../../src/main/ets/model/User';

export default function UserTest(): void {
  describe('User.validate()', () => {
    it('valid user should pass', 0, () => {
      const user = new User(
        1,
        'zhangsan',
        'zhangsan@example.com',
        'hashed_password',
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        0
      );
      expect(user.validate()).assertTrue();
    });

    it('invalid user should fail (empty username)', 0, () => {
      const user = new User(
        0,
        '',
        'test@example.com',
        'hashed_password',
        '',
        '',
        0
      );
      expect(user.validate()).assertFalse();
    });

    it('invalid user should fail (empty email)', 0, () => {
      const user = new User(
        0,
        'testuser',
        '',
        'hashed_password',
        '',
        '',
        0
      );
      expect(user.validate()).assertFalse();
    });

    it('invalid user should fail (empty passwordHash)', 0, () => {
      const user = new User(
        0,
        'testuser',
        'test@example.com',
        '',
        '',
        '',
        0
      );
      expect(user.validate()).assertFalse();
    });

    it('invalid user should fail (invalid is_deleted)', 0, () => {
      const user = new User(
        1,
        'zhangsan',
        'zhangsan@example.com',
        'hashed_password',
        '2025-11-05T10:00:00',
        '2025-11-05T10:00:00',
        2
      );
      expect(user.validate()).assertFalse();
    });
  });

  describe('User.toJSON() and fromJSON()', () => {
    it('toJSON should return correct structure', 0, () => {
      const user = new User(
        1,
        'testuser',
        'test@example.com',
        'hashed_pwd',
        '2025-11-05T10:00:00',
        '2025-11-05T11:00:00',
        0
      );
      const json = user.toJSON();
      expect(json.userId).assertEqual(1);
      expect(json.username).assertEqual('testuser');
      expect(json.email).assertEqual('test@example.com');
    });

    it('fromJSON should create correct User instance', 0, () => {
      const json: UserJSON = {
        userId: 2,
        username: 'lisi',
        email: 'lisi@example.com',
        passwordHash: 'hashed_pwd2',
        createdAt: '2025-11-05T10:00:00',
        updatedAt: '2025-11-05T11:00:00',
        isDeleted: 0
      };
      const user = User.fromJSON(json);
      expect(user.userId).assertEqual(2);
      expect(user.username).assertEqual('lisi');
      expect(user.email).assertEqual('lisi@example.com');
    });
  });
}

