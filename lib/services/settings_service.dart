import 'dart:convert';

import 'package:securepass_pro/domain/enums/settings_category.dart';
import 'package:securepass_pro/domain/repositories/settings_repository.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

class SettingDefinition {
  const SettingDefinition({
    required this.key,
    required this.defaultValue,
    required this.type,
    this.isSecure = false,
    this.category = SettingsCategory.general,
    this.description = '',
    this.label = '',
  });

  final String key;
  final dynamic defaultValue;
  final Type type;
  final bool isSecure;
  final SettingsCategory category;
  final String description;
  final String label;
}

class SettingsService implements SettingsRepository {
  SettingsService._();
  static final SettingsService _instance = SettingsService._();
  static SettingsService get instance => _instance;

  bool _initialized = false;
  final Map<String, SettingDefinition> _schema = {};

  Future<void> initialize() async {
    if (_initialized) return;
    _registerDefaults();
    _initialized = true;
    AppLogger.instance.info('Settings service initialized with ${_schema.length} definitions', category: 'SETTINGS');
  }

  void _registerDefaults() {
    const defaults = [
      SettingDefinition(
        key: 'theme_mode',
        defaultValue: 'system',
        type: String,
        category: SettingsCategory.appearance,
        description: 'Application theme mode',
        label: 'Theme Mode',
      ),
      SettingDefinition(
        key: 'privacy_mode',
        defaultValue: 'standard',
        type: String,
        category: SettingsCategory.privacy,
        description: 'Privacy protection level',
        label: 'Privacy Mode',
      ),
      SettingDefinition(
        key: 'security_profile',
        defaultValue: 'balanced',
        type: String,
        category: SettingsCategory.security,
        description: 'Security profile',
        label: 'Security Profile',
      ),
      SettingDefinition(
        key: 'accessibility_preset',
        defaultValue: 'defaultPreset',
        type: String,
        category: SettingsCategory.accessibility,
        description: 'Accessibility preset',
        label: 'Accessibility Preset',
      ),
      SettingDefinition(
        key: 'offline_mode',
        defaultValue: true,
        type: bool,
        category: SettingsCategory.privacy,
        description: 'Enable offline mode',
        label: 'Offline Mode',
      ),
      SettingDefinition(
        key: 'telemetry_enabled',
        defaultValue: false,
        type: bool,
        category: SettingsCategory.privacy,
        description: 'Enable telemetry',
        label: 'Telemetry',
      ),
      SettingDefinition(
        key: 'analytics_enabled',
        defaultValue: false,
        type: bool,
        category: SettingsCategory.privacy,
        description: 'Enable analytics',
        label: 'Analytics',
      ),
      SettingDefinition(
        key: 'clipboard_auto_clear_seconds',
        defaultValue: 30,
        type: int,
        category: SettingsCategory.clipboard,
        description: 'Clipboard auto-clear duration in seconds',
        label: 'Clipboard Auto-Clear',
      ),
      SettingDefinition(
        key: 'auto_lock_seconds',
        defaultValue: 300,
        type: int,
        category: SettingsCategory.security,
        description: 'Auto-lock timeout in seconds',
        label: 'Auto-Lock Timeout',
      ),
      SettingDefinition(
        key: 'language',
        defaultValue: 'en',
        type: String,
        category: SettingsCategory.general,
        description: 'Application language',
        label: 'Language',
      ),
      SettingDefinition(
        key: 'onboarding_completed',
        defaultValue: false,
        type: bool,
        category: SettingsCategory.general,
        description: 'Whether onboarding is completed',
        label: 'Onboarding Complete',
      ),
      SettingDefinition(
        key: 'password_length',
        defaultValue: 16,
        type: int,
        category: SettingsCategory.generation,
        description: 'Default password length',
        label: 'Password Length',
      ),
      SettingDefinition(
        key: 'use_uppercase',
        defaultValue: true,
        type: bool,
        category: SettingsCategory.generation,
        description: 'Include uppercase characters',
        label: 'Uppercase Characters',
      ),
      SettingDefinition(
        key: 'use_lowercase',
        defaultValue: true,
        type: bool,
        category: SettingsCategory.generation,
        description: 'Include lowercase characters',
        label: 'Lowercase Characters',
      ),
      SettingDefinition(
        key: 'use_numbers',
        defaultValue: true,
        type: bool,
        category: SettingsCategory.generation,
        description: 'Include numbers',
        label: 'Numbers',
      ),
      SettingDefinition(
        key: 'use_symbols',
        defaultValue: true,
        type: bool,
        category: SettingsCategory.generation,
        description: 'Include symbols',
        label: 'Symbols',
      ),
      SettingDefinition(
        key: 'workspace_name',
        defaultValue: 'Default',
        type: String,
        category: SettingsCategory.workspace,
        description: 'Default workspace name',
        label: 'Workspace Name',
      ),
      SettingDefinition(
        key: 'enable_diagnostics',
        defaultValue: true,
        type: bool,
        category: SettingsCategory.diagnostics,
        description: 'Enable diagnostics collection',
        label: 'Enable Diagnostics',
      ),
      SettingDefinition(
        key: 'developer_mode',
        defaultValue: false,
        type: bool,
        category: SettingsCategory.developer,
        description: 'Enable developer mode',
        label: 'Developer Mode',
      ),
    ];

    for (final def in defaults) {
      _schema[def.key] = def;
    }
  }

  Future<void> registerSetting(SettingDefinition definition) async {
    _schema[definition.key] = definition;
  }

  @override
  Future<T?> getValue<T>(String key, {T? defaultValue}) async {
    final def = _schema[key];
    final stored = PreferencesStorage.instance.getString(key);
    if (stored == null) {
      return def?.defaultValue as T? ?? defaultValue;
    }
    try {
      final decoded = jsonDecode(stored);
      if (decoded is T) return decoded;
      return def?.defaultValue as T? ?? defaultValue;
    } catch (_) {
      try {
        return stored as T?;
      } catch (_) {
        return def?.defaultValue as T? ?? defaultValue;
      }
    }
  }

  Future<T?> getTypedValue<T>(String key, {T? defaultValue}) async {
    final def = _schema[key];
    final stored = PreferencesStorage.instance.getString(key);
    if (stored == null) {
      return def?.defaultValue as T? ?? defaultValue;
    }
    try {
      final decoded = jsonDecode(stored);
      if (decoded is T) return decoded;
      return def?.defaultValue as T? ?? defaultValue;
    } catch (_) {
      return def?.defaultValue as T? ?? defaultValue;
    }
  }

  @override
  Future<void> setValue<T>(String key, T value) async {
    _schema[key] ??= SettingDefinition(
      key: key,
      defaultValue: value,
      type: T,
    );
    await PreferencesStorage.instance.setString(key, jsonEncode(value));
    AppLogger.instance.debug('Setting updated: $key', category: 'SETTINGS');
  }

  @override
  Future<void> remove(String key) async {
    await PreferencesStorage.instance.remove(key);
    AppLogger.instance.debug('Setting removed: $key', category: 'SETTINGS');
  }

  @override
  Future<void> clear() async {
    await PreferencesStorage.instance.clear();
    AppLogger.instance.info('All settings cleared', category: 'SETTINGS');
  }

  @override
  Future<Map<String, dynamic>> exportAll() async {
    final keys = PreferencesStorage.instance.getKeys();
    final export = <String, dynamic>{};
    for (final key in keys) {
      final def = _schema[key];
      if (def != null && def.isSecure) continue;
      final value = PreferencesStorage.instance.getString(key);
      if (value != null) {
        try {
          export[key] = jsonDecode(value);
        } catch (_) {
          export[key] = value;
        }
      }
    }
    export['_exportedAt'] = DateTime.now().toIso8601String();
    export['_schemaVersion'] = 1;
    return export;
  }

  @override
  Future<void> importAll(Map<String, dynamic> data) async {
    data.removeWhere((key, value) => key.startsWith('_'));
    for (final entry in data.entries) {
      final def = _schema[entry.key];
      if (def != null && def.isSecure) continue;
      final value = entry.value;
      if (value is String) {
        await PreferencesStorage.instance.setString(entry.key, value);
      } else {
        await PreferencesStorage.instance.setString(entry.key, jsonEncode(value));
      }
    }
    AppLogger.instance.info('Settings imported: ${data.length} entries', category: 'SETTINGS');
  }

  @override
  Future<void> resetToDefaults() async {
    for (final def in _schema.values) {
      if (def.isSecure) continue;
      await PreferencesStorage.instance.setString(def.key, jsonEncode(def.defaultValue));
    }
    AppLogger.instance.info('Settings reset to defaults', category: 'SETTINGS');
  }

  List<SettingDefinition> getSettingsForCategory(SettingsCategory category) {
    return _schema.values.where((def) => def.category == category).toList();
  }

  List<SettingDefinition> searchSettings(String query) {
    if (query.isEmpty) return _schema.values.toList();
    final lowerQuery = query.toLowerCase();
    return _schema.values.where((def) {
      return def.label.toLowerCase().contains(lowerQuery) ||
          def.description.toLowerCase().contains(lowerQuery) ||
          def.key.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  SettingDefinition? getDefinition(String key) => _schema[key];

  Map<String, SettingDefinition> get allDefinitions => Map.unmodifiable(_schema);
}
