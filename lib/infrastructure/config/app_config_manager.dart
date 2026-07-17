import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class AppConfigManager {
  AppConfigManager._();
  static final AppConfigManager _instance = AppConfigManager._();
  static AppConfigManager get instance => _instance;

  static const String _configKey = 'app_config';
  static const String _schemaVersionKey = 'config_schema_version';
  static const int _currentSchemaVersion = 1;

  Map<String, dynamic> _config = {};
  bool _isLoaded = false;

  Map<String, dynamic> get config => Map.unmodifiable(_config);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schemaVersion = prefs.getInt(_schemaVersionKey) ?? 0;

      if (schemaVersion < _currentSchemaVersion) {
        await _migrate(schemaVersion, prefs);
      }

      final configJson = prefs.getString(_configKey);
      if (configJson != null) {
        _config = Map<String, dynamic>.from(jsonDecode(configJson) as Map);
      } else {
        _config = _generateDefaults();
        await save();
      }
      _isLoaded = true;
      AppLogger.instance.info('Configuration loaded (schema v$_currentSchemaVersion)', category: 'CONFIG');
    } catch (e) {
      AppLogger.instance.error('Failed to load config, using defaults', category: 'CONFIG');
      _config = _generateDefaults();
      _isLoaded = true;
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configKey, jsonEncode(_config));
      await prefs.setInt(_schemaVersionKey, _currentSchemaVersion);
      AppLogger.instance.debug('Configuration saved', category: 'CONFIG');
    } catch (e) {
      AppLogger.instance.error('Failed to save config', category: 'CONFIG');
    }
  }

  T? getValue<T>(String key, {T? defaultValue}) {
    final value = _config[key];
    if (value is T) return value;
    return defaultValue;
  }

  Future<void> setValue<T>(String key, T value) async {
    _config[key] = value;
    await save();
  }

  Future<void> remove(String key) async {
    _config.remove(key);
    await save();
  }

  Map<String, dynamic> _generateDefaults() => {
    'app_name': 'SecurePass Pro',
    'version': '1.0.0',
    'theme_mode': 'system',
    'privacy_mode': 'standard',
    'security_profile': 'balanced',
    'accessibility_preset': 'default',
    'offline_mode': true,
    'telemetry_enabled': false,
    'analytics_enabled': false,
    'clipboard_auto_clear_seconds': 30,
    'auto_lock_seconds': 300,
    'language': 'en',
    'onboarding_completed': false,
  };

  Future<void> resetToDefaults() async {
    _config = _generateDefaults();
    await save();
    AppLogger.instance.info('Configuration reset to defaults', category: 'CONFIG');
  }

  Future<Map<String, dynamic>> exportConfig() async {
    final export = Map<String, dynamic>.from(_config);
    export.removeWhere((key, value) => key.contains('secret') || key.contains('password'));
    export['_schemaVersion'] = _currentSchemaVersion;
    export['_exportedAt'] = DateTime.now().toIso8601String();
    return export;
  }

  Future<void> importConfig(Map<String, dynamic> data) async {
    data.removeWhere((key, value) => key.startsWith('_'));
    _config = Map<String, dynamic>.from(data);
    await save();
    AppLogger.instance.info('Configuration imported', category: 'CONFIG');
  }

  Future<void> _migrate(int fromVersion, SharedPreferences prefs) async {
    AppLogger.instance.info('Migrating config from v$fromVersion to v$_currentSchemaVersion', category: 'CONFIG');
    final defaults = _generateDefaults();
    for (final entry in defaults.entries) {
      if (!_config.containsKey(entry.key)) {
        _config[entry.key] = entry.value;
      }
    }
    await save();
  }
}
