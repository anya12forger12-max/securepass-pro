import 'package:securepass_pro/domain/enums/accessibility_preset.dart';
import 'package:securepass_pro/domain/enums/app_theme_mode.dart';
import 'package:securepass_pro/domain/enums/privacy_mode.dart';
import 'package:securepass_pro/domain/enums/security_profile.dart';
import 'package:securepass_pro/domain/enums/settings_category.dart';
import 'package:securepass_pro/infrastructure/config/app_config_manager.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class ConfigurationService {
  ConfigurationService._();
  static final ConfigurationService _instance = ConfigurationService._();
  static ConfigurationService get instance => _instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await AppConfigManager.instance.load();
    _initialized = true;
    AppLogger.instance.info('Configuration service initialized', category: 'CONFIG');
  }

  Future<void> load() async {
    await AppConfigManager.instance.load();
  }

  Future<void> save() async {
    await AppConfigManager.instance.save();
  }

  T? getValue<T>(String key, {T? defaultValue}) {
    return AppConfigManager.instance.getValue<T>(key, defaultValue: defaultValue);
  }

  Future<void> setValue<T>(String key, T value) async {
    await AppConfigManager.instance.setValue<T>(key, value);
  }

  AppThemeMode get themeMode {
    final value = getValue<String>('theme_mode', defaultValue: 'system');
    return AppThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await setValue('theme_mode', mode.name);
  }

  PrivacyMode get privacyMode {
    final value = getValue<String>('privacy_mode', defaultValue: 'standard');
    return PrivacyMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PrivacyMode.standard,
    );
  }

  Future<void> setPrivacyMode(PrivacyMode mode) async {
    await setValue('privacy_mode', mode.name);
  }

  SecurityProfile get securityProfile {
    final value = getValue<String>('security_profile', defaultValue: 'balanced');
    return SecurityProfile.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SecurityProfile.balanced,
    );
  }

  Future<void> setSecurityProfile(SecurityProfile profile) async {
    await setValue('security_profile', profile.name);
  }

  AccessibilityPreset get accessibilityPreset {
    final value = getValue<String>('accessibility_preset', defaultValue: 'defaultPreset');
    return AccessibilityPreset.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccessibilityPreset.defaultPreset,
    );
  }

  Future<void> setAccessibilityPreset(AccessibilityPreset preset) async {
    await setValue('accessibility_preset', preset.name);
  }

  bool get offlineMode => getValue<bool>('offline_mode', defaultValue: true) ?? true;

  Future<void> setOfflineMode(bool enabled) async {
    await setValue('offline_mode', enabled);
  }

  bool get telemetryEnabled => getValue<bool>('telemetry_enabled', defaultValue: false) ?? false;

  Future<void> setTelemetry(bool enabled) async {
    await setValue('telemetry_enabled', enabled);
  }

  bool get analyticsEnabled => getValue<bool>('analytics_enabled', defaultValue: false) ?? false;

  Future<void> setAnalytics(bool enabled) async {
    await setValue('analytics_enabled', enabled);
  }

  int get clipboardAutoClearSeconds =>
      getValue<int>('clipboard_auto_clear_seconds', defaultValue: 30) ?? 30;

  Future<void> setClipboardAutoClearSeconds(int seconds) async {
    await setValue('clipboard_auto_clear_seconds', seconds);
  }

  int get autoLockSeconds =>
      getValue<int>('auto_lock_seconds', defaultValue: 300) ?? 300;

  Future<void> setAutoLockSeconds(int seconds) async {
    await setValue('auto_lock_seconds', seconds);
  }

  String get language => getValue<String>('language', defaultValue: 'en') ?? 'en';

  Future<void> setLanguage(String lang) async {
    await setValue('language', lang);
  }

  bool get onboardingCompleted =>
      getValue<bool>('onboarding_completed', defaultValue: false) ?? false;

  Future<void> setOnboardingCompleted(bool completed) async {
    await setValue('onboarding_completed', completed);
  }

  Future<void> resetCategory(SettingsCategory category) async {
    switch (category) {
      case SettingsCategory.appearance:
        await setValue('theme_mode', 'system');
        await setValue('accessibility_preset', 'defaultPreset');
      case SettingsCategory.privacy:
        await setValue('privacy_mode', 'standard');
        await setValue('offline_mode', true);
        await setValue('telemetry_enabled', false);
        await setValue('analytics_enabled', false);
      case SettingsCategory.security:
        await setValue('security_profile', 'balanced');
        await setValue('auto_lock_seconds', 300);
      case SettingsCategory.clipboard:
        await setValue('clipboard_auto_clear_seconds', 30);
      case SettingsCategory.general:
        await setValue('language', 'en');
        await setValue('onboarding_completed', false);
      case _:
        AppLogger.instance.info('No defaults for category: ${category.label}', category: 'CONFIG');
    }
    AppLogger.instance.info('Reset category: ${category.label}', category: 'CONFIG');
  }

  Future<Map<String, dynamic>> exportConfig() async {
    return AppConfigManager.instance.exportConfig();
  }

  Future<void> importConfig(Map<String, dynamic> data) async {
    await AppConfigManager.instance.importConfig(data);
  }

  int getSchemaVersion() {
    return getValue<int>('_schemaVersion', defaultValue: 1) ?? 1;
  }

  Map<String, dynamic> getFullConfig() {
    return AppConfigManager.instance.config;
  }
}
