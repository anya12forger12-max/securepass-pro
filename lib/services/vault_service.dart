import 'dart:convert';

import 'package:securepass_pro/domain/entities/vault_entry.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

class VaultService {
  static final VaultService _instance = VaultService._();

  factory VaultService() => _instance;

  VaultService._();

  static const String _storageKey = 'vault_entries';

  final List<VaultEntry> _entries = [];
  final Set<String> _folders = {};
  bool _isLocked = true;
  String? _vaultPin;
  int _autoLockSeconds = 300;
  DateTime? _lastUnlockTime;

  bool get isLocked => _isLocked;
  int get autoLockSeconds => _autoLockSeconds;
  Set<String> get folders => Set.unmodifiable(_folders);

  Future<void> initialize() async {
    _load();
    AppLogger.instance.info(
      'VaultService initialized with ${_entries.length} entries, ${_folders.length} folders',
      category: 'VaultService',
    );
  }

  void addEntry(VaultEntry entry) {
    _entries.add(entry);
    if (entry.folder.isNotEmpty) {
      _folders.add(entry.folder);
    }
    _save();
    AppLogger.instance.debug(
      'Added vault entry ${entry.id}',
      category: 'VaultService',
    );
  }

  void updateEntry(VaultEntry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      AppLogger.instance.warning(
        'Vault entry ${entry.id} not found for update',
        category: 'VaultService',
      );
      return;
    }

    _entries[index] = entry;
    if (entry.folder.isNotEmpty) {
      _folders.add(entry.folder);
    }
    _rebuildFolders();
    _save();
    AppLogger.instance.debug(
      'Updated vault entry ${entry.id}',
      category: 'VaultService',
    );
  }

  void removeEntry(String id) {
    final beforeLength = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    if (_entries.length < beforeLength) {
      _rebuildFolders();
      _save();
      AppLogger.instance.debug(
        'Removed vault entry $id',
        category: 'VaultService',
      );
    }
  }

  void bulkRemove(List<String> ids) {
    final idSet = ids.toSet();
    _entries.removeWhere((e) => idSet.contains(e.id));
    _rebuildFolders();
    _save();
    AppLogger.instance.debug(
      'Bulk removed ${ids.length} vault entries',
      category: 'VaultService',
    );
  }

  VaultEntry? getEntryById(String id) {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<VaultEntry> getEntries({
    String? workspaceId,
    String? folder,
    String? tag,
    String? query,
    bool? isFavorite,
  }) {
    var results = List<VaultEntry>.from(_entries);

    if (workspaceId != null) {
      results = results.where((e) => e.workspaceId == workspaceId).toList();
    }

    if (folder != null) {
      results = results.where((e) => e.folder == folder).toList();
    }

    if (tag != null) {
      results = results.where((e) => e.tags.contains(tag)).toList();
    }

    if (isFavorite != null) {
      results = results.where((e) => e.isFavorite == isFavorite).toList();
    }

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((e) {
        return e.title.toLowerCase().contains(lowerQuery) ||
            e.username.toLowerCase().contains(lowerQuery) ||
            e.url.toLowerCase().contains(lowerQuery) ||
            e.notes.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  List<VaultEntry> searchEntries(String query) {
    final lowerQuery = query.toLowerCase();
    return _entries.where((e) {
      return e.title.toLowerCase().contains(lowerQuery) ||
          e.username.toLowerCase().contains(lowerQuery) ||
          e.url.toLowerCase().contains(lowerQuery) ||
          e.notes.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Set<String> getFolders() => Set.unmodifiable(_folders);

  void createFolder(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      AppLogger.instance.warning(
        'Cannot create empty folder',
        category: 'VaultService',
      );
      return;
    }
    _folders.add(trimmed);
    _save();
    AppLogger.instance.debug(
      'Created folder "$trimmed"',
      category: 'VaultService',
    );
  }

  void deleteFolder(String name) {
    if (_folders.remove(name)) {
      for (final entry in _entries) {
        if (entry.folder == name) {
          final updated = entry.copyWith(folder: '');
          final index = _entries.indexWhere((e) => e.id == entry.id);
          if (index != -1) {
            _entries[index] = updated;
          }
        }
      }
      _save();
      AppLogger.instance.debug(
        'Deleted folder "$name"',
        category: 'VaultService',
      );
    }
  }

  void setVaultPin(String pin) {
    _vaultPin = _hashPin(pin);
    _save();
    AppLogger.instance.info(
      'Vault PIN set',
      category: 'VaultService',
    );
  }

  bool verifyVaultPin(String pin) {
    if (_vaultPin == null) return false;
    return _vaultPin == _hashPin(pin);
  }

  void setAutoLockSeconds(int seconds) {
    _autoLockSeconds = seconds;
    _save();
  }

  void lock() {
    _isLocked = true;
    _lastUnlockTime = null;
    AppLogger.instance.info(
      'Vault locked',
      category: 'VaultService',
    );
  }

  bool unlock(String pin) {
    if (!verifyVaultPin(pin)) {
      AppLogger.instance.warning(
        'Failed unlock attempt',
        category: 'VaultService',
      );
      return false;
    }

    _isLocked = false;
    _lastUnlockTime = DateTime.now();
    AppLogger.instance.info(
      'Vault unlocked',
      category: 'VaultService',
    );
    return true;
  }

  bool get shouldAutoLock {
    if (_isLocked || _lastUnlockTime == null) return false;
    return DateTime.now().difference(_lastUnlockTime!).inSeconds >=
        _autoLockSeconds;
  }

  Map<String, dynamic> exportAsMap() {
    return {
      'entries': _entries.map((e) => e.toMap()).toList(),
      'folders': _folders.toList(),
      'autoLockSeconds': _autoLockSeconds,
    };
  }

  Future<void> importFromMap(Map<String, dynamic> data) async {
    final entriesJson = data['entries'] as List<dynamic>?;
    if (entriesJson != null) {
      _entries.clear();
      for (final entryMap in entriesJson) {
        try {
          final entry =
              VaultEntry.fromMap(Map<String, dynamic>.from(entryMap as Map));
          _entries.add(entry);
        } catch (e) {
          AppLogger.instance.warning(
            'Failed to import vault entry: $e',
            category: 'VaultService',
          );
        }
      }
    }

    final foldersList = data['folders'] as List<dynamic>?;
    if (foldersList != null) {
      _folders.clear();
      for (final folder in foldersList) {
        _folders.add(folder as String);
      }
    }

    _autoLockSeconds = data['autoLockSeconds'] as int? ?? 300;
    _rebuildFolders();
    _save();
    AppLogger.instance.info(
      'Imported ${_entries.length} vault entries, ${_folders.length} folders',
      category: 'VaultService',
    );
  }

  void _rebuildFolders() {
    final activeFolders = <String>{};
    for (final entry in _entries) {
      if (entry.folder.isNotEmpty) {
        activeFolders.add(entry.folder);
      }
    }
    _folders.addAll(activeFolders);
  }

  String _hashPin(String pin) {
    int hash = 0;
    for (int i = 0; i < pin.length; i++) {
      hash = ((hash << 5) - hash + pin.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  void _save() {
    try {
      final data = jsonEncode({
        'entries': _entries.map((e) => e.toMap()).toList(),
        'folders': _folders.toList(),
        'vaultPin': _vaultPin,
        'autoLockSeconds': _autoLockSeconds,
        'isLocked': _isLocked,
      });
      PreferencesStorage.instance.setString(_storageKey, data);
    } catch (e) {
      AppLogger.instance.error(
        'Failed to save vault: $e',
        category: 'VaultService',
      );
    }
  }

  void _load() {
    try {
      final data = PreferencesStorage.instance.getString(_storageKey);
      if (data == null || data.isEmpty) return;

      final json = jsonDecode(data) as Map<String, dynamic>;
      _vaultPin = json['vaultPin'] as String?;
      _autoLockSeconds = json['autoLockSeconds'] as int? ?? 300;
      _isLocked = json['isLocked'] as bool? ?? true;

      final entriesJson = json['entries'] as List<dynamic>?;
      if (entriesJson != null) {
        _entries.clear();
        for (final entryMap in entriesJson) {
          try {
            final entry =
                VaultEntry.fromMap(Map<String, dynamic>.from(entryMap as Map));
            _entries.add(entry);
          } catch (e) {
            AppLogger.instance.warning(
              'Failed to load vault entry: $e',
              category: 'VaultService',
            );
          }
        }
      }

      final foldersList = json['folders'] as List<dynamic>?;
      if (foldersList != null) {
        _folders.clear();
        for (final folder in foldersList) {
          _folders.add(folder as String);
        }
      }
    } catch (e) {
      AppLogger.instance.error(
        'Failed to load vault: $e',
        category: 'VaultService',
      );
    }
  }
}
