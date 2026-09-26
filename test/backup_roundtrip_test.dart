import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/domain/entities/vault_entry.dart';
import 'package:securepass_pro/domain/enums/vault_entry_type.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/services/backup_service.dart';
import 'package:securepass_pro/services/encryption_service.dart';
import 'package:securepass_pro/services/import_service.dart';
import 'package:securepass_pro/services/vault_service.dart';
import 'package:securepass_pro/services/workspace_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // An in-memory stand-in for the real key store, so EncryptionService gets
    // a genuine persisted key exactly as it does on a device.
    final secureStore = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        switch (call.method) {
          case 'read':
            return secureStore[(call.arguments as Map)['key'] as String?];
          case 'readAll':
            return secureStore;
          case 'write':
            final args = call.arguments as Map;
            secureStore[args['key'] as String] = args['value'] as String;
            return null;
          case 'delete':
            secureStore.remove((call.arguments as Map)['key'] as String?);
            return null;
          case 'containsKey':
            return secureStore.containsKey(
              (call.arguments as Map)['key'] as String?,
            );
          case 'isProtectedDataAvailable':
            return true;
          default:
            return null;
        }
      },
    );
    await PreferencesStorage.instance.init();
    await EncryptionService.instance.initialize();
  });

  setUp(() async {
    final vault = VaultService();
    vault.importFromMap({'entries': <dynamic>[], 'folders': <dynamic>[]});
    await Future<void>.delayed(Duration.zero);
  });

  test('an app-produced backup restores into the real vault', () async {
    final vault = VaultService();
    // A real workspace the entries belong to, so the backup actually carries
    // one and the restore has something to bring back.
    final workspace = await WorkspaceService.instance
        .createWorkspace('Work accounts', 'work logins');
    vault.addEntry(
      VaultEntry(
        id: 'entry-1',
        title: 'GitHub',
        type: VaultEntryType.password,
        value: 's3cr3t-p@ss',
        workspaceId: workspace.id,
        username: 'anya',
        isFavorite: true,
      ),
    );
    vault.addEntry(
      VaultEntry(
        id: 'entry-2',
        title: 'Bank',
        type: VaultEntryType.password,
        value: 'another-s3cret',
        workspaceId: 'default',
      ),
    );
    expect(vault.getEntries().length, 2);

    // Produce a backup exactly the way the app's settings screen does.
    final backup = await BackupService.instance.createBackup();
    expect(backup.isEncrypted, isTrue);
    final exported = await BackupService.instance.exportBackup(backup.id);
    expect(exported, isNotNull);

    final json = jsonEncode(exported);
    expect(json.contains('s3cr3t-p@ss'), isFalse,
        reason: 'the exported envelope must not contain plaintext secrets');

    // Wipe the vault, then restore from the envelope.
    await vault.importFromMap({'entries': <dynamic>[], 'folders': <dynamic>[]});
    expect(vault.getEntries().isEmpty, isTrue);

    final result = await ImportService.instance.importFromJson(json);
    expect(result.successfulItems, greaterThan(0));

    // The real proof: the entries are actually readable again.
    final restored = vault.getEntries();
    expect(restored.length, 2, reason: 'the restore must be awaited, not fire-and-forget');
    expect(
      restored.map((e) => e.title),
      containsAll(<String>['GitHub', 'Bank']),
    );
    final github = restored.firstWhere((e) => e.title == 'GitHub');
    expect(github.value, 's3cr3t-p@ss');
    expect(github.username, 'anya');
    expect(github.isFavorite, isTrue);

    // The workspace the entries belong to is restored too, keeping its id so
    // the entries' workspaceId references still resolve instead of orphaning.
    final restoredWorkspaces = WorkspaceService.instance.getWorkspaces();
    final restoredWorkspace =
        restoredWorkspaces.where((w) => w.id == workspace.id);
    expect(restoredWorkspace, hasLength(1),
        reason: 'the workspace in the backup must be restored under its own id');
    expect(restoredWorkspace.single.name, 'Work accounts');
  });

  test('workspaces restore with their original id so vault links survive',
      () async {
    final workspace = await WorkspaceService.instance
        .importWorkspace(<String, dynamic>{
      'id': 'ws-original-id',
      'name': 'Work',
      'description': 'work accounts',
    });
    expect(workspace, isNotNull);
    expect(workspace!.id, 'ws-original-id',
        reason: 'the id must be preserved or restored vault entries orphan');

    // The nested {"workspace": {...}} shape other importers produce still works.
    final nested = await WorkspaceService.instance.importWorkspace(
      <String, dynamic>{
        'workspace': <String, dynamic>{'name': 'Nested', 'description': 'x'},
      },
    );
    expect(nested, isNotNull);
    expect(nested!.name, 'Nested');

    // Re-importing the same backup is idempotent, not a duplicate.
    final before = WorkspaceService.instance.getWorkspaces().length;
    final again = await WorkspaceService.instance
        .importWorkspace(<String, dynamic>{'id': 'ws-original-id', 'name': 'Work'});
    expect(again, isNotNull);
    expect(WorkspaceService.instance.getWorkspaces().length, before);

    // A malformed entry is rejected cleanly instead of throwing.
    final bad = await WorkspaceService.instance
        .importWorkspace(<String, dynamic>{'no-name-here': true});
    expect(bad, isNull);
  });

  test('the app envelope is recognised after a version bump guard', () async {
    final vault = VaultService();
    vault.addEntry(
      VaultEntry(
        id: 'entry-3',
        title: 'Email',
        type: VaultEntryType.password,
        value: 'mail-s3cret',
        workspaceId: 'default',
      ),
    );

    final backup = await BackupService.instance.createBackup();
    final exported = await BackupService.instance.exportBackup(backup.id);
    final decoded = jsonDecode(
      (jsonDecode(jsonEncode(exported)) as Map)['data'] as String,
    ) as Map<String, dynamic>;
    expect(decoded['v'], 1, reason: 'the app must stamp the envelope version');
    expect(decoded['enc'], isTrue);
    // The envelope itself only carries v/enc/data; the payload that includes
    // the vault is the ciphertext, so it has to be decrypted to be inspected.
    expect(decoded.containsKey('vault'), isFalse);
    final plaintext =
        await EncryptionService.instance.decrypt(decoded['data'] as String);
    final payload = jsonDecode(plaintext) as Map<String, dynamic>;
    expect(payload.containsKey('vault'), isTrue);
    expect(payload.containsKey('folders'), isTrue);
    expect(payload['vault'], isNotEmpty);

    await vault.importFromMap({'entries': <dynamic>[], 'folders': <dynamic>[]});
    final result = await ImportService.instance
        .importFromJson(jsonEncode(exported));
    expect(result.successfulItems, greaterThan(0));
    expect(
      vault.getEntries().any((e) => e.title == 'Email'),
      isTrue,
    );
  });
}
