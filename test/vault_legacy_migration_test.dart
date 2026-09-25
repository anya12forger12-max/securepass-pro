import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/services/vault_service.dart';

const _vaultKey = 'enc_vault_entries';
const _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

Map<String, String> _written = {};

void _seedLegacyVault(String pin) {
  const salt = 'a1b2c3d4e5f60718';
  final legacyHash = sha256.convert(utf8.encode('$salt:$pin')).toString();
  _written = {
    _vaultKey: jsonEncode({
      'entries': <dynamic>[],
      'folders': <dynamic>[],
      'vaultPin': legacyHash,
      'salt': salt,
      'autoLockSeconds': 300,
    }),
  };
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
    switch (call.method) {
      case 'read':
        return _written[(call.arguments as Map)['key'] as String?];
      case 'readAll':
        return _written;
      case 'write':
        final args = call.arguments as Map;
        _written[args['key'] as String] = args['value'] as String;
        return null;
      case 'delete':
        _written.remove((call.arguments as Map)['key'] as String?);
        return null;
      case 'containsKey':
        return _written.containsKey(
          (call.arguments as Map)['key'] as String?,
        );
      case 'isProtectedDataAvailable':
        return true;
      default:
        return null;
    }
  });
}

String? get _storedVaultPin {
  final raw = _written[_vaultKey];
  if (raw == null) return null;
  return (jsonDecode(raw) as Map<String, dynamic>)['vaultPin'] as String?;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy sha256 vault unlocks then upgrades to pbkdf2 in place', () async {
    const pin = '2468';
    _seedLegacyVault(pin);

    final vault = VaultService();
    vault.pbkdf2IterationsOverride = 1000;
    await vault.initialize();

    expect(vault.hasPin, isTrue);
    expect(vault.isLocked, isTrue);
    expect(_storedVaultPin, isNot(startsWith('pbkdf2:')));

    expect(await vault.unlock('1111'), isFalse);
    expect(vault.isLocked, isTrue);
    expect(_storedVaultPin, isNot(startsWith('pbkdf2:')), reason: 'wrong pin must not upgrade the stored hash');

    expect(await vault.unlock(pin), isTrue);
    expect(vault.isLocked, isFalse);
    expect(_storedVaultPin, startsWith('pbkdf2:'), reason: 'correct legacy pin upgrades the persisted hash');

    vault.lock();
    expect(await vault.unlock('9999'), isFalse);
    expect(await vault.unlock(pin), isTrue);
    expect(vault.isLocked, isFalse);
  });
}