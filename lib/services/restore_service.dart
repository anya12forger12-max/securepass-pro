import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/services/configuration_service.dart';
import 'package:securepass_pro/services/workspace_service.dart';

class RestoreService {
  RestoreService._();
  static final RestoreService _instance = RestoreService._();
  static RestoreService get instance => _instance;

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    AppLogger.instance.info('Restore service initialized', category: 'RESTORE');
  }

  Future<bool> restoreFromBackup(Map<String, dynamic> backupData) async {
    if (!validateBackup(backupData)) {
      AppLogger.instance.error('Invalid backup data', category: 'RESTORE');
      return false;
    }

    try {
      final data = backupData['data'] as Map<String, dynamic>? ?? {};

      if (data.containsKey('config')) {
        final config = data['config'] as Map<String, dynamic>;
        await ConfigurationService.instance.importConfig(config);
      }

      if (data.containsKey('workspaces')) {
        final workspaces = data['workspaces'] as List;
        for (final ws in workspaces) {
          await WorkspaceService.instance.importWorkspace(ws as Map<String, dynamic>);
        }
      }

      AppLogger.instance.info('Backup restored successfully', category: 'RESTORE');
      return true;
    } catch (e) {
      AppLogger.instance.error('Restore failed: $e', category: 'RESTORE');
      return false;
    }
  }

  bool validateBackup(Map<String, dynamic> backupData) {
    if (backupData.isEmpty) return false;

    final metadata = backupData['metadata'] as Map<String, dynamic>?;
    if (metadata == null) return false;

    final version = metadata['version'] as String?;
    if (version == null || version.isEmpty) return false;

    final name = metadata['name'] as String?;
    if (name == null || name.isEmpty) return false;

    return true;
  }

  Map<String, dynamic> previewBackup(Map<String, dynamic> backupData) {
    if (!validateBackup(backupData)) {
      return {'valid': false, 'error': 'Invalid backup format'};
    }

    final metadata = backupData['metadata'] as Map<String, dynamic>? ?? {};
    final data = backupData['data'] as Map<String, dynamic>? ?? {};

    return {
      'valid': true,
      'name': metadata['name'] ?? 'Unknown',
      'version': metadata['version'] ?? 'Unknown',
      'createdAt': metadata['createdAt'] ?? 'Unknown',
      'isEncrypted': metadata['isEncrypted'] ?? false,
      'hasConfig': data.containsKey('config'),
      'hasWorkspaces': data.containsKey('workspaces'),
      'workspaceCount': (data['workspaces'] as List?)?.length ?? 0,
    };
  }

  String getCompatibilityStatus(Map<String, dynamic> backupData) {
    if (!validateBackup(backupData)) return 'incompatible';

    final metadata = backupData['metadata'] as Map<String, dynamic>? ?? {};
    final backupVersion = metadata['version'] as String? ?? '0.0.0';

    const currentVersion = '1.0.0';

    if (backupVersion == currentVersion) return 'compatible';
    if (backupVersion.compareTo(currentVersion) < 0) return 'compatible';
    return 'may_require_update';
  }
}
