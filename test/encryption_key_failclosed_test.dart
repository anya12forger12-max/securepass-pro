import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/services/encryption_service.dart';

const _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
/// EncryptedStorage prefixes every key with 'enc_'.
const _keyStorageKey = 'enc_aes_master_key_v1';

/// This runs in its own file because EncryptionService is a process-wide
/// singleton guarded by _initialized, so each scenario needs a fresh process.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> store;
  bool failReads = false;
  bool failWrites = false;

  void installMock() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'read':
          if (failReads) {
            throw PlatformException(code: 'keystore_unavailable');
          }
          return store[(call.arguments as Map)['key'] as String?];
        case 'readAll':
          return store;
        case 'write':
          if (failWrites) {
            throw PlatformException(code: 'keystore_unavailable');
          }
          final args = call.arguments as Map;
          store[args['key'] as String] = args['value'] as String;
          return null;
        case 'containsKey':
          return store.containsKey((call.arguments as Map)['key'] as String?);
        case 'isProtectedDataAvailable':
          return true;
        default:
          return null;
      }
    });
  }

  setUp(() {
    store = <String, String>{};
    failReads = false;
    failWrites = false;
    installMock();
    EncryptionService.instance.resetForTest();
  });

  test('a first run creates and persists a key', () async {
    await EncryptionService.instance.initialize();

    expect(store.containsKey(_keyStorageKey), isTrue);
    final cipher = await EncryptionService.instance.encrypt('secret');
    expect(await EncryptionService.instance.decrypt(cipher), 'secret');
  });

  test('an unreadable key store does NOT silently replace the existing key',
      () async {
    // Seed a key as if the user already had an encrypted vault.
    final cryptographyKey = await AesGcm.with256bits().newSecretKey();
    final originalValue = base64Encode(await cryptographyKey.extractBytes());
    store[_keyStorageKey] = originalValue;
    const secret = 'the-only-copy-of-this';

    // Simulate a transient keystore failure on read.
    failReads = true;
    await EncryptionService.instance.initialize();

    // The stored key must be untouched: replacing it would make the existing
    // vault permanently undecryptable.
    expect(store[_keyStorageKey], originalValue,
        reason: 'a read failure must never destroy the only key');

    // The real proof of data survival: encrypt under the seeded key, let
    // startup fail, then restart and read that ciphertext back.
    final cipher = await AesGcm.with256bits().encrypt(
      utf8.encode(secret),
      secretKey: cryptographyKey,
    );

    // And the service refuses to encrypt rather than pretending to work.
    // (decrypt deliberately degrades to '' on any failure, so encrypt is the
    // assertion that proves the service really is unusable.)
    await expectLater(
      EncryptionService.instance.encrypt('new secret'),
      throwsA(isA<EncryptionException>()),
    );

    // Next launch, keystore healthy again: the original key is still there,
    // so the previously encrypted data is readable again.
    failReads = false;
    EncryptionService.instance.resetForTest();
    await EncryptionService.instance.initialize();
    expect(
      await EncryptionService.instance.decrypt(base64Encode(cipher.concatenation())),
      secret,
      reason: 'fail-closed must preserve recoverability, not just the key',
    );
  });

  test('a first-run write failure fails closed instead of crashing startup',
      () async {
    // Genuine first run, but the keystore write fails: initialize() must
    // not propagate (main.dart does not catch), and nothing usable may be
    // left behind.
    failWrites = true;
    await EncryptionService.instance.initialize();

    expect(store.containsKey(_keyStorageKey), isFalse);
    await expectLater(
      EncryptionService.instance.encrypt('x'),
      throwsA(isA<EncryptionException>()),
    );

    // Next launch with a healthy keystore: normal first-run provisioning.
    failWrites = false;
    EncryptionService.instance.resetForTest();
    await EncryptionService.instance.initialize();
    expect(store.containsKey(_keyStorageKey), isTrue);
    final cipher = await EncryptionService.instance.encrypt('secret');
    expect(await EncryptionService.instance.decrypt(cipher), 'secret');
  });

  test('a corrupt stored key is not replaced either', () async {
    store[_keyStorageKey] = 'this-is-not-valid-base64-!!!';

    await EncryptionService.instance.initialize();

    expect(store[_keyStorageKey], 'this-is-not-valid-base64-!!!',
        reason: 'an unreadable key is still the only key');
    await expectLater(
      EncryptionService.instance.encrypt('x'),
      throwsA(isA<EncryptionException>()),
    );
  });
}
