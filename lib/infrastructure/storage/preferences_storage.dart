import 'package:shared_preferences/shared_preferences.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class PreferencesStorage {
  PreferencesStorage._();
  static final PreferencesStorage _instance = PreferencesStorage._();
  static PreferencesStorage get instance => _instance;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.instance.info('Preferences storage initialized', category: 'STORAGE');
  }

  SharedPreferences get _effectivePrefs {
    if (_prefs == null) {
      throw StateError('PreferencesStorage not initialized. Call init() first.');
    }
    return _prefs!;
  }

  String? getString(String key) => _effectivePrefs.getString(key);
  Future<bool> setString(String key, String value) async {
    final result = await _effectivePrefs.setString(key, value);
    AppLogger.instance.debug('Set string: $key', category: 'STORAGE');
    return result;
  }

  int? getInt(String key) => _effectivePrefs.getInt(key);
  Future<bool> setInt(String key, int value) async => _effectivePrefs.setInt(key, value);

  bool? getBool(String key) => _effectivePrefs.getBool(key);
  Future<bool> setBool(String key, bool value) async => _effectivePrefs.setBool(key, value);

  double? getDouble(String key) => _effectivePrefs.getDouble(key);
  Future<bool> setDouble(String key, double value) async => _effectivePrefs.setDouble(key, value);

  List<String>? getStringList(String key) => _effectivePrefs.getStringList(key);
  Future<bool> setStringList(String key, List<String> value) async => _effectivePrefs.setStringList(key, value);

  Future<bool> remove(String key) async => _effectivePrefs.remove(key);
  Future<void> clear() async => await _effectivePrefs.clear();
  Set<String> getKeys() => _effectivePrefs.getKeys();
  bool containsKey(String key) => _effectivePrefs.containsKey(key);

  Future<int> getSize() async {
    final keys = _effectivePrefs.getKeys();
    int total = 0;
    for (final key in keys) {
      final value = _effectivePrefs.get(key);
      total += key.length;
      if (value is String) total += value.length;
      total += 8;
    }
    return total;
  }
}
