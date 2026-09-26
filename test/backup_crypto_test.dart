import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/services/configuration_service.dart';
import 'package:securepass_pro/services/encryption_service.dart';
import 'package:securepass_pro/services/import_service.dart';
import 'package:securepass_pro/services/restore_service.dart';

const _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

Map<String, String> _secureStore = {};

void _installSecureStorageMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
        switch (call.method) {
          case 'read':
            return _secureStore[(call.arguments as Map)['key'] as String?];
          case 'readAll':
            return _secureStore;
          case 'write':
            final args = call.arguments as Map;
            _secureStore[args['key'] as String] = args['value'] as String;
            return null;
          case 'delete':
            _secureStore.remove((call.arguments as Map)['key'] as String?);
            return null;
          case 'containsKey':
            return _secureStore.containsKey(
              (call.arguments as Map)['key'] as String?,
            );
          case 'isProtectedDataAvailable':
            return true;
          default:
            return null;
        }
      });
}

String _corruptLastChar(String base64) {
  final swapped = base64.substring(0, base64.length - 1) +
      (base64.endsWith('A') ? 'B' : 'A');
  return swapped;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // EncryptionService is a process-wide singleton guarded by _initialized, so
  // it is initialized exactly once here and the persisted key captured.
  late String persistedMasterKey;
  setUpAll(() async {
    _secureStore = {};
    _installSecureStorageMock();
    await EncryptionService.instance.initialize();
    persistedMasterKey = _secureStore['enc_aes_master_key_v1'] ?? '';
  });

  group('EncryptionService cryptographic implementation', () {
    test('round-trips plaintext through AES-256-GCM', () async {
      const secret = 'correct horse battery staple';
      final cipher = await EncryptionService.instance.encrypt(secret);
      expect(cipher, isNot(contains(secret)));
      expect(await EncryptionService.instance.decrypt(cipher), secret);
    });

    test('uses a unique nonce for every encryption operation', () async {
      final a = await EncryptionService.instance.encrypt('same plaintext');
      final b = await EncryptionService.instance.encrypt('same plaintext');
      expect(a, isNot(b), reason: 'identical plaintext must not repeat ciphertext');
      expect(await EncryptionService.instance.decrypt(a), 'same plaintext');
      expect(await EncryptionService.instance.decrypt(b), 'same plaintext');
    });

    test('rejects a tampered ciphertext (authentication tag check)', () async {
      final cipher = await EncryptionService.instance.encrypt('vault secret');
      final tampered = _corruptLastChar(cipher);
      expect(
        () => EncryptionService.instance.decrypt(tampered),
        throwsA(isA<EncryptionException>()),
        reason: 'tampered ciphertext must fail authentication, not return plaintext',
      );
    });

    test('rejects a tampered authentication tag', () async {
      final cipher = await EncryptionService.instance.encrypt('vault secret');
      final raw = base64Decode(cipher);
      raw[raw.length - 1] ^= 0xFF;
      expect(
        () => EncryptionService.instance.decrypt(base64Encode(raw)),
        throwsA(isA<EncryptionException>()),
      );
    });

    test('rejects truncated ciphertext', () async {
      final cipher = await EncryptionService.instance.encrypt('vault secret');
      final truncated = base64Encode(base64Decode(cipher).sublist(0, 10));
      expect(
        () => EncryptionService.instance.decrypt(truncated),
        throwsA(isA<EncryptionException>()),
      );
    });

    test('rejects invalid base64 with a typed error', () async {
      expect(
        () => EncryptionService.instance.decrypt('!!!not base64!!!'),
        throwsA(isA<EncryptionException>()),
      );
    });

    test('fails closed when the ciphertext is empty', () async {
      expect(
        () => EncryptionService.instance.decrypt(''),
        throwsA(isA<EncryptionException>()),
      );
    });

    test('persists the master key in secure storage, never in plaintext logs',
        () async {
      expect(persistedMasterKey, isNotEmpty,
          reason: 'master key must be persisted');
      expect(base64Decode(persistedMasterKey).length, 32,
          reason: 'AES-256 = 32 byte key');
    });
  });

  group('Encrypted backup envelope robustness', () {
    Future<String> validBackup() async {
      final cipher = await EncryptionService.instance.encrypt(
        jsonEncode({
          'vault': [
            {'title': 'GitHub', 'value': 's3cr3t-token'},
          ],
          'favorites': <dynamic>[],
          'history': <dynamic>[],
        }),
      );
      return jsonEncode({
        'v': 1,
        'enc': true,
        'data': cipher,
      });
    }

    test('valid backup restores successfully', () async {
      final result = await ImportService.instance
          .importFromJson(await validBackup());
      expect(result.success, isTrue);
      expect(result.successfulItems, greaterThan(0));
    });

    test('modified ciphertext is rejected, not imported', () async {
      final envelope = jsonDecode(await validBackup()) as Map<String, dynamic>;
      envelope['data'] = _corruptLastChar(envelope['data'] as String);
      final result =
          await ImportService.instance.importFromJson(jsonEncode(envelope));
      expect(result.success, isFalse);
      expect(result.successfulItems, 0);
    });

    test('modified authentication tag is rejected', () async {
      final envelope = jsonDecode(await validBackup()) as Map<String, dynamic>;
      final raw = base64Decode(envelope['data'] as String);
      raw[raw.length - 1] ^= 0xFF;
      envelope['data'] = base64Encode(raw);
      final result =
          await ImportService.instance.importFromJson(jsonEncode(envelope));
      expect(result.success, isFalse);
    });

    test('truncated backup is rejected', () async {
      final envelope = jsonDecode(await validBackup()) as Map<String, dynamic>;
      final raw = base64Decode(envelope['data'] as String);
      envelope['data'] = base64Encode(raw.sublist(0, raw.length ~/ 2));
      final result =
          await ImportService.instance.importFromJson(jsonEncode(envelope));
      expect(result.success, isFalse);
    });

    test('invalid base64 payload is rejected', () async {
      final result = await ImportService.instance.importFromJson(
        jsonEncode({'v': 1, 'enc': true, 'data': '@@@not-base64@@@'}),
      );
      expect(result.success, isFalse);
    });

    test('empty file is rejected', () async {
      final result = await ImportService.instance.importFromJson('');
      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('random non-SecurePass file is rejected without crashing', () async {
      const foreign = '{"some":"unrelated json","n":42}';
      final result = await ImportService.instance.importFromJson(foreign);
      expect(result.success, isFalse);
    });

    test('unsupported envelope version is rejected', () async {
      final envelope = jsonDecode(await validBackup()) as Map<String, dynamic>;
      envelope['v'] = 99;
      final result =
          await ImportService.instance.importFromJson(jsonEncode(envelope));
      expect(result.success, isFalse,
          reason: 'a future/unknown envelope version must not be imported blindly');
    });

    test('very large backup is handled without crashing', () async {
      final entries = List.generate(
        2000,
        (i) => {'title': 'entry-$i', 'value': 'v$i' * 20},
      );
      final cipher = await EncryptionService.instance.encrypt(
        jsonEncode({'vault': entries}),
      );
      final result = await ImportService.instance.importFromJson(
        jsonEncode({'v': 1, 'enc': true, 'data': cipher}),
      );
      expect(result.success, isTrue);
      expect(result.successfulItems, 2000);
    });

    test('duplicate restore is idempotent and does not crash', () async {
      final backup = await validBackup();
      final first = await ImportService.instance.importFromJson(backup);
      final second = await ImportService.instance.importFromJson(backup);
      expect(first.success, isTrue);
      expect(second.success, isTrue);
    });
  });

  group('Backup version compatibility handling', () {
    test('unknown version is rejected with a controlled error', () {
      final status = RestoreService.instance.getCompatibilityStatus({
        'metadata': {
          'name': 'x',
          'version': '999.0.0',
        },
      });
      expect(status, isNot('compatible'));
    });

    test('malformed backup is reported rather than throwing', () {
      final status = RestoreService.instance.getCompatibilityStatus({
        'metadata': 'not-a-map',
      });
      expect(status, anyOf('incompatible', isNull));
    });

    test('validateBackup rejects non-map metadata without throwing', () {
      expect(
        () => RestoreService.instance.validateBackup({
          'metadata': 'not-a-map',
        }),
        returnsNormally,
      );
      expect(
        RestoreService.instance.validateBackup({
          'metadata': 'not-a-map',
        }),
        isFalse,
      );
    });
  });

  group('App-produced backup round-trip', () {
    test('a backup produced by BackupService shape is understood by the '
        'production restore path', () async {
      // Shape emitted by BackupService.exportBackup.
      final cipher = await EncryptionService.instance.encrypt(
        jsonEncode({
          'config': <String, dynamic>{'theme': 'dark'},
          'workspaces': <dynamic>[],
          'vault': [
            {'title': 'GitHub', 'value': 'tok', 'type': 'password'},
          ],
          'folders': <dynamic>[],
        }),
      );
      final appBackup = jsonEncode({
        'metadata': {'id': 'b1', 'name': 'b', 'version': '2.2.26+31'},
        'data': jsonEncode({
          'v': 1,
          'enc': true,
          'data': cipher,
        }),
        'exportedAt': '2026-01-01T00:00:00.000',
      });

      final result =
          await ImportService.instance.importFromJson(appBackup);
      expect(
        result.success,
        isTrue,
        reason: 'the app\'s own backup must restore; error was '
            '${result.errorMessage}',
      );
      final vaultItems = result.importedItems
          .where((i) => i.type == 'vault' && i.name == 'GitHub')
          .toList();
      expect(vaultItems, hasLength(1),
          reason: 'the vault entry in the backup must be imported');
      expect(vaultItems.single.success, isTrue);

      // config/workspaces ship in the same payload, so accepting those keys
      // must actually apply them rather than validate-and-drop.
      final configItems = result.importedItems.where((i) => i.type == 'config');
      expect(configItems, hasLength(1),
          reason: 'the app settings in the backup must be applied');
      expect(configItems.single.success, isTrue);
      expect(ConfigurationService.instance.getFullConfig()['theme'], 'dark');
    });

    test('a backup this device cannot decrypt fails honestly, not silently',
        () async {
      // Encrypt under a key this device does not hold, i.e. what restoring a
      // backup from another device actually looks like. The ciphertext is
      // well-formed, so only a real AES-GCM tag check can reject it.
      final foreignKey = SecretKey(
        List<int>.generate(32, (i) => (i * 7 + 3) & 0xFF),
      );
      final foreignBox = await AesGcm.with256bits().encrypt(
        utf8.encode(jsonEncode({
          'vault': <dynamic>[],
        })),
        secretKey: foreignKey,
      );

      final result = await ImportService.instance.importFromJson(
        jsonEncode({
          'metadata': {'id': 'b2', 'name': 'b', 'version': '2.2.28+33'},
          'data': jsonEncode({
            'v': 1,
            'enc': true,
            'data': base64Encode(foreignBox.concatenation()),
          }),
        }),
      );

      expect(result.success, isFalse,
          reason: 'an undecryptable backup must not be reported as restored');
      expect(result.errorMessage, isNotNull);
      expect(result.successfulItems, 0,
          reason: 'nothing may be counted as imported from a failed decrypt');
    });
  });
}
