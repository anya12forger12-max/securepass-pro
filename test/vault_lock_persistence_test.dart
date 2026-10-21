import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/services/vault_service.dart';

/// Regression test for the vault lock not surviving a restart.
///
/// `VaultService.lock()` used to set the in-memory `_isLocked` flag without
/// writing it to the persisted vault blob. `_persist()` writes `isLocked` and
/// `_load()` restores it, so the blob kept the stale `isLocked:false` that
/// `setVaultPin()` had written, and the next launch opened the vault
/// **unlocked** - even though the user had a vault PIN set and had just
/// pressed "Apply & lock vault now" (whose SnackBar claims the vault is
/// locked).
///
/// The test drives the real service against a stateful secure-storage mock
/// and then reads back the very blob the next launch would read, applying
/// the same decision `VaultService._load()` applies.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const storageKey = 'enc_vault_entries';
  late Map<String, String> store;

  setUp(() {
    store = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      switch (call.method) {
        case 'write':
          store[args['key'] as String] = args['value'] as String;
          return null;
        case 'read':
          return store[args['key'] as String];
        case 'readAll':
          return Map<String, String>.from(store);
        case 'delete':
          store.remove(args['key'] as String);
          return null;
        case 'containsKey':
          return store.containsKey(args['key'] as String);
        case 'isProtectedDataAvailable':
          return true;
        default:
          return null;
      }
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
  });

  /// The blob the next launch would read.
  Map<String, dynamic> persistedBlob() =>
      jsonDecode(store[storageKey]!) as Map<String, dynamic>;

  /// The exact decision `VaultService._load()` makes on start-up.
  bool isLockedOnNextLaunch(Map<String, dynamic> blob) {
    final vaultPin = blob['vaultPin'] as String?;
    return vaultPin != null ? (blob['isLocked'] as bool? ?? true) : false;
  }

  /// The persist is intentionally fire-and-forget, so wait for the write.
  Future<void> waitForBlob(Future<bool> Function() condition) async {
    for (var i = 0; i < 200; i++) {
      if (await condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('the persisted vault blob never reached the expected state');
  }

  test('the vault lock state is persisted, so a locked vault stays locked', () async {
    final vault = VaultService();
    vault.pbkdf2IterationsOverride = 1000;
    await vault.initialize();
    await vault.setVaultPin('2468');

    // Setting the PIN persists the blob while the vault is unlocked.
    expect(vault.isLocked, isFalse);
    expect(persistedBlob()['isLocked'], isFalse);
    expect(isLockedOnNextLaunch(persistedBlob()), isFalse);

    // The user locks the vault ("Apply & lock vault now").
    vault.lock();
    expect(vault.isLocked, isTrue);

    // The lock must reach disk, otherwise the next launch unlocks the vault.
    await waitForBlob(() async => persistedBlob()['isLocked'] == true);
    expect(persistedBlob()['isLocked'], isTrue);
    expect(
      isLockedOnNextLaunch(persistedBlob()),
      isTrue,
      reason: 'a vault locked by the user must come back locked after a restart',
    );

    // Unlocking mirrors the state back, so an unlocked vault stays unlocked.
    expect(await vault.unlock('2468'), isTrue);
    expect(vault.isLocked, isFalse);
    await waitForBlob(() async => persistedBlob()['isLocked'] == false);
    expect(isLockedOnNextLaunch(persistedBlob()), isFalse);
  });
}
