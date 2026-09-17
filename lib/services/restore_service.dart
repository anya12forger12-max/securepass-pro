import 'dart:convert';

import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/services/configuration_service.dart';
import 'package:securepass_pro/services/encryption_service.dart';
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
      final data = await _decodeData(backupData['data']);

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

  Future<Map<String, dynamic>> _decodeData(dynamic rawData) async {
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }
    if (rawData is String) {
      final envelope = jsonDecode(rawData);
      if (envelope is Map<String, dynamic> &&
          envelope['enc'] == true &&
          envelope['data'] is String) {
        final plaintext =
            await EncryptionService.instance.decrypt(envelope['data'] as String);
        if (plaintext.isEmpty) {
          throw const FormatException('Decrypted backup is empty or corrupt');
        }
        final decoded = jsonDecode(plaintext);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    }
    throw const FormatException('Unsupported backup data format');
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
