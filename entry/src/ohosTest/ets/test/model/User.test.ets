import { describe, it, expect } from '@ohos/hypium';
import { User, UserJSON } from '../../../../main/ets/model/User';

export default function UserTest(): void {
  describe('User.validate()', () => {
    it('valid_user_should_pass', 0, () => {
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

    it('invalid_user_should_fail_(empty_username)', 0, () => {
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

    it('invalid_user_should_fail_(empty_email)', 0, () => {
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

    it('invalid_user_should_fail_(empty_passwordHash)', 0, () => {
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

    it('invalid_user_should_fail_(invalid_is_deleted)', 0, () => {
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

  describe('User.toJSON()_and_fromJSON()', () => {
    it('toJSON_should_return_correct_structure', 0, () => {
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

    it('fromJSON_should_create_correct_User_instance', 0, () => {
      const json: UserJSON = {
        userId: 2,
        username: 'lisi',
        email: 'lisi@example.com',
        passwordHash: 'hashed_pwd2',
        createdAt: '2025-11-05T10:00:00',
        updatedAt: '2025-11-05T11:00:00',
        is_deleted: 0
      };
      const user = User.fromJSON(json);
      expect(user.userId).assertEqual(2);
      expect(user.username).assertEqual('lisi');
      expect(user.email).assertEqual('lisi@example.com');
    });
  });
}

