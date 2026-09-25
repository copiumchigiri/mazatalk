import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/features/auth/data/local_auth_repository.dart';
import 'package:mazatalk/features/profile/data/local_child_repository.dart';
import 'package:mazatalk/features/profile/domain/child_profile.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalAuthRepository', () {
    test('signUp creates a persistent account and signs it in', () async {
      final repo = LocalAuthRepository();
      final result = await repo.signUp(
        email: 'Mom@Example.com',
        password: 'secret1',
      );
      expect(result.isSuccess, isTrue);
      expect(result.accountId, 'mom@example.com');
      expect(result.parentName, 'mom');

      // A fresh repository instance (≈ app restart) sees the same account.
      final restored = await LocalAuthRepository().restoreSession();
      expect(restored, isNotNull);
      expect(restored!.accountId, 'mom@example.com');

      final login = await LocalAuthRepository().login(
        email: 'mom@example.com',
        password: 'secret1',
      );
      expect(login.isSuccess, isTrue);
    });

    test(
      'signUp rejects invalid email, short password, and duplicates',
      () async {
        final repo = LocalAuthRepository();
        expect(
          (await repo.signUp(email: 'notanemail', password: 'secret1')).error,
          isNotNull,
        );
        expect(
          (await repo.signUp(email: 'a@b.com', password: '123')).error,
          isNotNull,
        );

        expect(
          (await repo.signUp(email: 'a@b.com', password: 'secret1')).isSuccess,
          isTrue,
        );
        final dup = await repo.signUp(email: 'A@B.com', password: 'other12');
        expect(dup.error, contains('аль хэдийн'));
      },
    );

    test(
      'login fails identically for unknown email and wrong password',
      () async {
        final repo = LocalAuthRepository();
        await repo.signUp(email: 'a@b.com', password: 'secret1');
        final wrongPassword = await repo.login(
          email: 'a@b.com',
          password: 'nope123',
        );
        final unknownEmail = await repo.login(
          email: 'ghost@b.com',
          password: 'secret1',
        );
        expect(wrongPassword.isSuccess, isFalse);
        expect(unknownEmail.isSuccess, isFalse);
        expect(wrongPassword.error, unknownEmail.error);
      },
    );

    test('logout clears the session but keeps the account', () async {
      final repo = LocalAuthRepository();
      await repo.signUp(email: 'a@b.com', password: 'secret1');
      await repo.logout();
      expect(await repo.restoreSession(), isNull);
      final login = await repo.login(email: 'a@b.com', password: 'secret1');
      expect(login.isSuccess, isTrue);
    });

    test('resetPassword replaces the old password', () async {
      final repo = LocalAuthRepository();
      await repo.signUp(email: 'a@b.com', password: 'secret1');
      expect(
        await repo.resetPassword(email: 'a@b.com', newPassword: 'newpass1'),
        isTrue,
      );
      expect(
        await repo.resetPassword(email: 'ghost@b.com', newPassword: 'whatever'),
        isFalse,
      );
      expect(
        (await repo.login(email: 'a@b.com', password: 'secret1')).isSuccess,
        isFalse,
      );
      expect(
        (await repo.login(email: 'a@b.com', password: 'newpass1')).isSuccess,
        isTrue,
      );
    });

    test('demo account works out of the box', () async {
      final login = await LocalAuthRepository().login(
        email: 'admin@gmail.com',
        password: 'Password',
      );
      expect(login.isSuccess, isTrue);
      expect(login.parentName, 'admin');
    });

    test(
      'provider sign-in creates a passwordless account and reuses it',
      () async {
        final repo = LocalAuthRepository();
        final first = await repo.signInWithProvider(
          accountId: 'phone-99119911',
        );
        expect(first.isSuccess, isTrue);

        final again = await repo.signInWithProvider(
          accountId: 'phone-99119911',
        );
        expect(again.accountId, first.accountId);

        // Passwordless accounts can't be logged into with a password.
        final passwordLogin = await repo.login(
          email: 'phone-99119911',
          password: 'anything',
        );
        expect(passwordLogin.isSuccess, isFalse);
      },
    );
  });

  group('per-account child storage', () {
    test('children saved under one account are invisible to another', () async {
      const repoA = LocalChildRepository(accountId: 'a@b.com');
      const repoB = LocalChildRepository(accountId: 'c@d.com');

      await repoA.saveChildren([
        const ChildProfile(id: 'c1', name: 'Anu', age: 5),
      ]);

      expect((await repoA.loadChildren()).map((c) => c.name), ['Anu']);
      expect(await repoB.loadChildren(), isEmpty);
    });

    test('signed-out repository reads empty and writes nowhere', () async {
      const signedOut = LocalChildRepository();
      await signedOut.saveChildren([
        const ChildProfile(id: 'c1', name: 'X', age: 4),
      ]);
      expect(await signedOut.loadChildren(), isEmpty);
    });
  });
}
