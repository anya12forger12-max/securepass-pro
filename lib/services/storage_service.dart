import 'package:securepass_pro/domain/enums/storage_type.dart';
import 'package:securepass_pro/domain/repositories/storage_repository.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/encrypted_storage.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

class StorageService implements StorageRepository {
  StorageService._();
  static final StorageService _instance = StorageService._();
  static StorageService get instance => _instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await PreferencesStorage.instance.init();
    await EncryptedStorage.instance.init();
    _initialized = true;
    AppLogger.instance.info('Storage service initialized', category: 'STORAGE');
  }

  @override
  Future<String?> read(String key, {StorageType type = StorageType.preferences}) async {
    switch (type) {
      case StorageType.preferences:
      case StorageType.cache:
      case StorageType.session:
        return PreferencesStorage.instance.getString(key);
      case StorageType.encrypted:
        return EncryptedStorage.instance.retrieve(key);
    }
  }

  @override
  Future<void> write(String key, String value, {StorageType type = StorageType.preferences}) async {
    switch (type) {
      case StorageType.preferences:
      case StorageType.cache:
      case StorageType.session:
        await PreferencesStorage.instance.setString(key, value);
      case StorageType.encrypted:
        await EncryptedStorage.instance.store(key, value);
    }
    AppLogger.instance.debug('Written to ${type.label}: $key', category: 'STORAGE');
  }

  @override
  Future<void> delete(String key, {StorageType type = StorageType.preferences}) async {
    switch (type) {
      case StorageType.preferences:
      case StorageType.cache:
      case StorageType.session:
        await PreferencesStorage.instance.remove(key);
      case StorageType.encrypted:
        await EncryptedStorage.instance.remove(key);
    }
    AppLogger.instance.debug('Deleted from ${type.label}: $key', category: 'STORAGE');
  }

  @override
  Future<void> clear({StorageType? type}) async {
    if (type == null) {
      await PreferencesStorage.instance.clear();
      await EncryptedStorage.instance.clear();
      AppLogger.instance.info('All storage cleared', category: 'STORAGE');
      return;
    }
    switch (type) {
      case StorageType.preferences:
      case StorageType.cache:
      case StorageType.session:
        await PreferencesStorage.instance.clear();
      case StorageType.encrypted:
        await EncryptedStorage.instance.clear();
    }
    AppLogger.instance.info('${type.label} storage cleared', category: 'STORAGE');
  }

  @override
  Future<bool> contains(String key, {StorageType type = StorageType.preferences}) async {
    switch (type) {
      case StorageType.preferences:
      case StorageType.cache:
      case StorageType.session:
        return PreferencesStorage.instance.containsKey(key);
      case StorageType.encrypted:
        return EncryptedStorage.instance.contains(key);
    }
  }

  @override
  Future<int> getSize({StorageType type = StorageType.preferences}) async {
    switch (type) {
      case StorageType.preferences:
      case StorageType.cache:
      case StorageType.session:
        return PreferencesStorage.instance.getSize();
      case StorageType.encrypted:
        return EncryptedStorage.instance.getSize();
    }
  }

  Future<Map<String, dynamic>> getStorageReport() async {
    final prefSize = await getSize(type: StorageType.preferences);
    final encSize = await getSize(type: StorageType.encrypted);
    return {
      'preferences': prefSize,
      'cache': 0,
      'session': 0,
      'encrypted': encSize,
      'totalBytes': prefSize + encSize,
      'totalDisplay': _formatBytes(prefSize + encSize),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}
