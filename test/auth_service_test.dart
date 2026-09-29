import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/features/login/domain/auth_service.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesStorage.instance.init();
    AuthService().pbkdf2IterationsOverride = 1000;
  });

  String legacyHash(String email, String password) {
    return base64Encode(utf8.encode('securepass_login:$email:$password'));
  }

  test('createAccount stores a salted PBKDF2 digest, not recoverable plaintext',
      () async {
    await AuthService().createAccount('new@example.com', 'password123');

    final stored =
        PreferencesStorage.instance.getString(AppConstants.loginPinKey);
    expect(stored, isNotNull);
    expect(stored!.startsWith('pbkdf2:'), isTrue);
    expect(
      stored.contains(
        base64Encode(
          utf8.encode('securepass_login:new@example.com:password123'),
        ),
      ),
      isFalse,
      reason: 'the stored value must not contain the recoverable legacy form',
    );
    expect(
      PreferencesStorage.instance.getString(AppConstants.loginEmailKey),
      'new@example.com',
    );
    expect(
      PreferencesStorage.instance.getBool(AppConstants.onboardingCompleteKey),
      isTrue,
    );
  });

  test('verify accepts correct credentials and rejects wrong password',
      () async {
    await AuthService().createAccount('a@b.com', 'password123');

    expect(await AuthService().verify('a@b.com', 'password123'), isTrue);
    expect(await AuthService().verify('a@b.com', 'wrongpassword'), isFalse);
    expect(
      await AuthService().verify('other@b.com', 'password123'),
      isFalse,
    );
  });

  test('every createAccount derives a fresh random salt', () async {
    await AuthService().createAccount('a@b.com', 'password123');
    final first =
        PreferencesStorage.instance.getString(AppConstants.loginPinKey);
    await AuthService().createAccount('a@b.com', 'password123');
    final second =
        PreferencesStorage.instance.getString(AppConstants.loginPinKey);
    expect(first, isNot(equals(second)));
  });

  test('legacy base64 credential verifies and is migrated to PBKDF2', () async {
    await PreferencesStorage.instance.setString(
      AppConstants.loginPinKey,
      legacyHash('old@example.com', 'password123'),
    );

    expect(await AuthService().verify('old@example.com', 'password123'), isTrue);
    final stored =
        PreferencesStorage.instance.getString(AppConstants.loginPinKey);
    expect(stored!.startsWith('pbkdf2:'), isTrue);
    expect(
      PreferencesStorage.instance.getString(AppConstants.loginEmailKey),
      'old@example.com',
    );
  });

  test('legacy credential rejects wrong password without migrating', () async {
    await PreferencesStorage.instance.setString(
      AppConstants.loginPinKey,
      legacyHash('old@example.com', 'password123'),
    );

    expect(
      await AuthService().verify('old@example.com', 'wrongpassword'),
      isFalse,
    );
    final stored =
        PreferencesStorage.instance.getString(AppConstants.loginPinKey);
    expect(stored!.startsWith('pbkdf2:'), isFalse);
    expect(
      PreferencesStorage.instance.getString(AppConstants.loginEmailKey),
      isNull,
    );
  });

  test('verify returns false for a corrupt stored value without throwing',
      () async {
    await PreferencesStorage.instance.setString(
      AppConstants.loginPinKey,
      'not-base64-or-pbkdf2!!!',
    );

    expect(await AuthService().verify('a@b.com', 'password123'), isFalse);
  });

  test('verify returns false when no account exists', () async {
    expect(await AuthService().verify('a@b.com', 'password123'), isFalse);
  });
}