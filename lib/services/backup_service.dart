import 'dart:convert';

import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/domain/entities/backup_metadata.dart';
import 'package:securepass_pro/domain/enums/backup_status.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/services/configuration_service.dart';
import 'package:securepass_pro/services/workspace_service.dart';
import 'package:uuid/uuid.dart';

class BackupService {
  BackupService._();
  static final BackupService _instance = BackupService._();
  static BackupService get instance => _instance;

  bool _initialized = false;
  final List<BackupMetadata> _backups = [];
  static const String _storageKey = 'backups_data';

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadFromStorage();
    _initialized = true;
    AppLogger.instance.info('Backup service initialized with ${_backups.length} backups', category: 'BACKUP');
  }

  Future<void> _loadFromStorage() async {
    final data = PreferencesStorage.instance.getString(_storageKey);
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          _backups.add(BackupMetadata(
            id: map['id'] as String,
            name: map['name'] as String,
            version: map['version'] as String,
            sizeBytes: map['sizeBytes'] as int,
            createdAt: DateTime.parse(map['createdAt'] as String),
            status: BackupStatus.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => BackupStatus.pending,
            ),
            isEncrypted: map['isEncrypted'] as bool? ?? false,
          ));
        }
      } catch (e) {
        AppLogger.instance.error('Failed to load backups', category: 'BACKUP');
      }
    }
  }

  Future<void> _saveToStorage() async {
    final data = _backups.map((b) => {
      'id': b.id,
      'name': b.name,
      'version': b.version,
      'sizeBytes': b.sizeBytes,
      'createdAt': b.createdAt.toIso8601String(),
      'status': b.status.name,
      'isEncrypted': b.isEncrypted,
    }).toList();
    await PreferencesStorage.instance.setString(_storageKey, jsonEncode(data));
  }

  Future<BackupMetadata> createBackup({
    String? name,
    bool includeSettings = true,
    bool includeWorkspaces = true,
    bool includePreferences = true,
    bool isEncrypted = false,
  }) async {
    final id = const Uuid().v4();
    final backupName = name ?? 'Backup ${DateTime.now().toIso8601String()}';

    int estimatedSize = 0;
    if (includeSettings) {
      final config = ConfigurationService.instance.getFullConfig();
      estimatedSize += jsonEncode(config).length;
    }
    if (includeWorkspaces) {
      final workspaces = WorkspaceService.instance.getWorkspaces();
      for (final ws in workspaces) {
        estimatedSize += jsonEncode(ws.toMap()).length;
      }
    }
    if (includePreferences) {
      estimatedSize += 256;
    }

    final metadata = BackupMetadata(
      id: id,
      name: backupName,
      version: AppConstants.appVersion,
      sizeBytes: estimatedSize,
      status: BackupStatus.success,
      isEncrypted: isEncrypted,
    );

    _backups.insert(0, metadata);
    await _saveToStorage();
    AppLogger.instance.info('Backup created: $backupName (${metadata.sizeDisplay})', category: 'BACKUP');
    return metadata;
  }

  List<BackupMetadata> getBackups() => List.unmodifiable(_backups);

  Future<void> deleteBackup(String id) async {
    _backups.removeWhere((b) => b.id == id);
    await _saveToStorage();
    AppLogger.instance.info('Backup deleted: $id', category: 'BACKUP');
  }

  Future<Map<String, dynamic>> exportBackup(String id) async {
    final backup = _backups.firstWhere((b) => b.id == id);
    final exportData = <String, dynamic>{
      'metadata': {
        'id': backup.id,
        'name': backup.name,
        'version': backup.version,
        'sizeBytes': backup.sizeBytes,
        'createdAt': backup.createdAt.toIso8601String(),
        'status': backup.status.name,
        'isEncrypted': backup.isEncrypted,
      },
      'data': <String, dynamic>{},
      'exportedAt': DateTime.now().toIso8601String(),
    };

    if (!backup.isEncrypted) {
      exportData['data'] = {
        'config': ConfigurationService.instance.getFullConfig(),
        'workspaces': WorkspaceService.instance.getWorkspaces().map((w) => w.toMap()).toList(),
      };
    }

    return exportData;
  }

  BackupMetadata? getBackupById(String id) {
    try {
      return _backups.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
