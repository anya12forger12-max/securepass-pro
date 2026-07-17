import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class EncryptedStorage {
  EncryptedStorage._();
  static final EncryptedStorage _instance = EncryptedStorage._();
  static EncryptedStorage get instance => _instance;

  static const String _prefix = 'enc_';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.instance.info('Encrypted storage initialized (plain mode)', category: 'STORAGE');
  }

  SharedPreferences get _effectivePrefs {
    if (_prefs == null) {
      throw StateError('EncryptedStorage not initialized. Call init() first.');
    }
    return _prefs!;
  }

  Future<void> store(String key, String value) async {
    final encoded = base64Encode(utf8.encode(value));
    await _effectivePrefs.setString('$_prefix$key', encoded);
    AppLogger.instance.debug('Stored encrypted value for key: $key', category: 'STORAGE');
  }

  Future<String?> retrieve(String key) async {
    final encoded = _effectivePrefs.getString('$_prefix$key');
    if (encoded == null) return null;
    return utf8.decode(base64Decode(encoded));
  }

  Future<void> remove(String key) async {
    await _effectivePrefs.remove('$_prefix$key');
  }

  Future<bool> contains(String key) async {
    return _effectivePrefs.containsKey('$_prefix$key');
  }

  Future<void> clear() async {
    final keys = _effectivePrefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await _effectivePrefs.remove(key);
    }
    AppLogger.instance.info('Encrypted storage cleared', category: 'STORAGE');
  }

  Future<int> getSize() async {
    final keys = _effectivePrefs.getKeys().where((k) => k.startsWith(_prefix));
    int total = 0;
    for (final key in keys) {
      final value = _effectivePrefs.getString(key);
      total += key.length + (value?.length ?? 0);
    }
    return total;
  }
}
