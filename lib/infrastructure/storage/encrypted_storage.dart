import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class EncryptedStorage {
  EncryptedStorage._();
  static final EncryptedStorage _instance = EncryptedStorage._();
  static EncryptedStorage get instance => _instance;

  static const String _prefix = 'enc_';

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  Future<void> init() async {
    AppLogger.instance.info(
      'Encrypted storage initialized (keystore-backed)',
      category: 'STORAGE',
    );
  }

  Future<void> store(String key, String value) async {
    await _secureStorage.write(key: '$_prefix$key', value: value);
    AppLogger.instance.debug('Stored encrypted value for key: $key', category: 'STORAGE');
  }

  Future<String?> retrieve(String key) async {
    return _secureStorage.read(key: '$_prefix$key');
  }

  Future<void> remove(String key) async {
    await _secureStorage.delete(key: '$_prefix$key');
  }

  Future<bool> contains(String key) async {
    final value = await _secureStorage.read(key: '$_prefix$key');
    return value != null;
  }

  Future<void> clear() async {
    final dictionary = await _secureStorage.readAll();
    for (final entry in dictionary.keys) {
      if (entry.startsWith(_prefix)) {
        await _secureStorage.delete(key: entry);
      }
    }
    AppLogger.instance.info('Encrypted storage cleared', category: 'STORAGE');
  }

  Future<int> getSize() async {
    final dictionary = await _secureStorage.readAll();
    int total = 0;
    for (final entry in dictionary.entries) {
      if (entry.key.startsWith(_prefix)) {
        total += entry.key.length + entry.value.length;
      }
    }
    return total;
  }
}