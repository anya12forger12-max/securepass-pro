import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' hide Hmac;
import 'package:cryptography/cryptography.dart';
import 'package:securepass_pro/domain/entities/vault_entry.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/encrypted_storage.dart';

class VaultService {
  static final VaultService _instance = VaultService._();

  factory VaultService() => _instance;

  VaultService._();

  static const String _storageKey = 'vault_entries';
  static const int _pbkdf2Iterations = 210000;
  static const int _pbkdf2Bits = 256;
  static const String _pbkdf2Prefix = 'pbkdf2:';

  bool _initialized = false;
  final List<VaultEntry> _entries = [];
  final Set<String> _folders = {};
  bool _isLocked = true;
  String? _vaultPin;
  String? _hashChars;
  int _autoLockSeconds = 300;
  DateTime? _lastUnlockTime;

  bool get isLocked => _isLocked;
  int get autoLockSeconds => _autoLockSeconds;
  Set<String> get folders => Set.unmodifiable(_folders);

  Future<void> initialize() async {
    if (_initialized) return;
    await _load();
    _initialized = true;
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

  Future<void> setVaultPin(String pin) async {
    _hashChars = _randomSalt();
    _vaultPin = await _derivePbkdf2('$_hashChars:$pin');
    await _persist();
    AppLogger.instance.info(
      'Vault PIN set',
      category: 'VaultService',
    );
  }

  Future<bool> verifyVaultPin(String pin) async {
    final stored = _vaultPin;
    if (stored == null) return false;
    final salt = _storedSalt;
    if (salt == null) {
      AppLogger.instance.warning(
        'Vault not initialized: no salt persisted',
        category: 'VaultService',
      );
      return false;
    }
    return _verifyPin(stored, pin, salt);
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

  Future<bool> unlock(String pin) async {
    if (!await verifyVaultPin(pin)) {
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

  Future<String> _derivePbkdf2(String password) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _pbkdf2Bits,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: utf8.encode(password),
    );
    final bytes = await key.extractBytes();
    return '$_pbkdf2Prefix${base64Encode(bytes)}';
  }

  Future<bool> _verifyPin(
    String stored,
    String pin,
    String salt,
  ) async {
    if (stored.startsWith(_pbkdf2Prefix)) {
      final expectedB64 = stored.substring(_pbkdf2Prefix.length);
      final derived = await _derivePbkdf2('$salt:$pin');
      final derivedB64 = derived.substring(_pbkdf2Prefix.length);
      return _constantTimeEquals(expectedB64, derivedB64);
    }

    final legacyHash =
        sha256.convert(utf8.encode('$salt:$pin')).toString();
    if (!_constantTimeEquals(stored.toLowerCase(), legacyHash)) {
      return false;
    }

    _vaultPin = await _derivePbkdf2('$salt:$pin');
    await _persist();
    return true;
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  String? get _storedSalt => _hashChars;

  String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  void _save() {
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      final data = jsonEncode({
        'entries': _entries.map((e) => e.toMap()).toList(),
        'folders': _folders.toList(),
        'vaultPin': _vaultPin,
        'salt': _hashChars,
        'autoLockSeconds': _autoLockSeconds,
        'isLocked': _isLocked,
      });
      await EncryptedStorage.instance.store(_storageKey, data);
    } catch (e) {
      AppLogger.instance.error(
        'Failed to save vault: $e',
        category: 'VaultService',
      );
    }
  }

  Future<void> _load() async {
    try {
      final data = await EncryptedStorage.instance.retrieve(_storageKey);
      if (data == null || data.isEmpty) return;

      final json = jsonDecode(data) as Map<String, dynamic>;
      _vaultPin = json['vaultPin'] as String?;
      _hashChars = json['salt'] as String?;
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
