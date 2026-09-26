import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/services/workspace_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // importWorkspace persists through PreferencesStorage, so the backing
    // store has to exist before the service can save anything.
    SharedPreferences.setMockInitialValues({});
    await PreferencesStorage.instance.init();
  });

  test('imports the flat shape that BackupService.exportBackup writes',
      () async {
    final restored = await WorkspaceService.instance.importWorkspace({
      'id': 'ws-flat-1',
      'name': 'Flat Shape',
      'description': 'from toMap()',
      'isActive': false,
    });

    expect(restored, isNotNull);
    expect(restored!.name, 'Flat Shape');
    expect(restored.description, 'from toMap()');
  });

  test('preserves the workspace id so vault entries keep resolving',
      () async {
    final restored = await WorkspaceService.instance.importWorkspace({
      'id': 'ws-stable-id',
      'name': 'Stable',
    });

    expect(restored!.id, 'ws-stable-id',
        reason: 'vault entries reference their workspace by id, so a restore '
            'must not mint a new one');
  });

  test('still accepts the legacy nested {"workspace": {...}} shape', () async {
    final restored = await WorkspaceService.instance.importWorkspace({
      'workspace': {'name': 'Nested', 'description': 'legacy'},
    });

    expect(restored, isNotNull);
    expect(restored!.name, 'Nested');
    expect(restored.description, 'legacy');
  });

  test('re-importing the same backup is idempotent, not duplicated', () async {
    final first = await WorkspaceService.instance
        .importWorkspace({'id': 'ws-idem', 'name': 'Idempotent'});
    final second = await WorkspaceService.instance
        .importWorkspace({'id': 'ws-idem', 'name': 'Idempotent'});

    expect(second!.id, first!.id);
    final matches = WorkspaceService.instance
        .getWorkspaces()
        .where((w) => w.id == 'ws-idem');
    expect(matches, hasLength(1),
        reason: 'restoring the same backup twice must not duplicate entries');
  });

  test('a malformed workspace is rejected without throwing', () async {
    final restored = await WorkspaceService.instance.importWorkspace({
      'id': 'ws-bad',
      // no name
    });

    expect(restored, isNull);
  });
}
