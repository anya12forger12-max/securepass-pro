import 'package:securepass_pro/domain/entities/privacy_report.dart';
import 'package:securepass_pro/domain/enums/privacy_mode.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/services/storage_service.dart';

class PrivacyService {
  PrivacyService._();
  static final PrivacyService _instance = PrivacyService._();
  static PrivacyService get instance => _instance;

  bool _initialized = false;
  PrivacyMode _currentMode = PrivacyMode.standard;
  bool _offlineMode = true;
  bool _telemetryEnabled = false;
  bool _analyticsEnabled = false;

  static const String _modeKey = 'privacy_mode_setting';
  static const String _offlineKey = 'privacy_offline_mode';
  static const String _telemetryKey = 'privacy_telemetry';
  static const String _analyticsKey = 'privacy_analytics';

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadSettings();
    _initialized = true;
    AppLogger.instance.info('Privacy service initialized: mode=${_currentMode.name}', category: 'PRIVACY');
  }

  Future<void> _loadSettings() async {
    final modeStr = PreferencesStorage.instance.getString(_modeKey);
    if (modeStr != null) {
      _currentMode = PrivacyMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => PrivacyMode.standard,
      );
    }
    _offlineMode = PreferencesStorage.instance.getBool(_offlineKey) ?? true;
    _telemetryEnabled = PreferencesStorage.instance.getBool(_telemetryKey) ?? false;
    _analyticsEnabled = PreferencesStorage.instance.getBool(_analyticsKey) ?? false;
  }

  Future<PrivacyReport> getPrivacyReport() async {
    final categories = getDataCategories();
    final recommendations = getRecommendations();
    return PrivacyReport(
      generatedAt: DateTime.now(),
      dataCategories: categories,
      offlineModeEnabled: _offlineMode,
      telemetryEnabled: _telemetryEnabled,
      analyticsEnabled: _analyticsEnabled,
      recommendations: recommendations,
    );
  }

  Future<void> setPrivacyMode(PrivacyMode mode) async {
    _currentMode = mode;
    await PreferencesStorage.instance.setString(_modeKey, mode.name);
    AppLogger.instance.info('Privacy mode set to: ${mode.name}', category: 'PRIVACY');
  }

  PrivacyMode getPrivacyMode() => _currentMode;

  Future<void> setOfflineMode(bool enabled) async {
    _offlineMode = enabled;
    await PreferencesStorage.instance.setBool(_offlineKey, enabled);
    AppLogger.instance.info('Offline mode set to: $enabled', category: 'PRIVACY');
  }

  bool isOfflineMode() => _offlineMode;

  Future<void> setTelemetry(bool enabled) async {
    _telemetryEnabled = enabled;
    await PreferencesStorage.instance.setBool(_telemetryKey, enabled);
    AppLogger.instance.info('Telemetry set to: $enabled', category: 'PRIVACY');
  }

  Future<void> setAnalytics(bool enabled) async {
    _analyticsEnabled = enabled;
    await PreferencesStorage.instance.setBool(_analyticsKey, enabled);
    AppLogger.instance.info('Analytics set to: $enabled', category: 'PRIVACY');
  }

  Future<void> clearAllLocalData() async {
    await StorageService.instance.clear();
    AppLogger.instance.info('All local data cleared', category: 'PRIVACY');
  }

  List<PrivacyDataCategory> getDataCategories() {
    return const [
      PrivacyDataCategory(
        name: 'App Settings',
        description: 'Application configuration and preferences',
        isStored: true,
        canBeCleared: true,
        count: 1,
      ),
      PrivacyDataCategory(
        name: 'Usage History',
        description: 'Tracks which features are used',
        isStored: false,
        canBeCleared: false,
        count: 0,
      ),
      PrivacyDataCategory(
        name: 'Generated Passwords',
        description: 'Previously generated passwords',
        isStored: false,
        canBeCleared: false,
        count: 0,
      ),
      PrivacyDataCategory(
        name: 'Clipboard Data',
        description: 'Temporary clipboard contents with auto-clear',
        isStored: false,
        canBeCleared: true,
        count: 0,
      ),
      PrivacyDataCategory(
        name: 'Diagnostics Logs',
        description: 'Internal diagnostic information',
        isStored: true,
        canBeCleared: true,
        count: 0,
      ),
      PrivacyDataCategory(
        name: 'Search History',
        description: 'Search queries and indexed items',
        isStored: true,
        canBeCleared: true,
        count: 0,
      ),
      PrivacyDataCategory(
        name: 'Command History',
        description: 'Recently executed commands',
        isStored: true,
        canBeCleared: true,
        count: 0,
      ),
      PrivacyDataCategory(
        name: 'Workspace Data',
        description: 'Workspace metadata and configuration',
        isStored: true,
        canBeCleared: true,
        count: 0,
      ),
      PrivacyDataCategory(
        name: 'Backup Data',
        description: 'Local backup files',
        isStored: true,
        canBeCleared: true,
        count: 0,
      ),
      PrivacyDataCategory(
        name: 'Theme Preferences',
        description: 'Theme and visual settings',
        isStored: true,
        canBeCleared: true,
        count: 1,
      ),
      PrivacyDataCategory(
        name: 'Accessibility Preferences',
        description: 'Accessibility settings and presets',
        isStored: true,
        canBeCleared: true,
        count: 1,
      ),
    ];
  }

  Map<String, dynamic> exportPrivacySettings() {
    return {
      'privacyMode': _currentMode.name,
      'offlineMode': _offlineMode,
      'telemetryEnabled': _telemetryEnabled,
      'analyticsEnabled': _analyticsEnabled,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importPrivacySettings(Map<String, dynamic> data) async {
    if (data.containsKey('privacyMode')) {
      final modeStr = data['privacyMode'] as String;
      final mode = PrivacyMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => PrivacyMode.standard,
      );
      await setPrivacyMode(mode);
    }
    if (data.containsKey('offlineMode')) {
      await setOfflineMode(data['offlineMode'] as bool);
    }
    if (data.containsKey('telemetryEnabled')) {
      await setTelemetry(data['telemetryEnabled'] as bool);
    }
    if (data.containsKey('analyticsEnabled')) {
      await setAnalytics(data['analyticsEnabled'] as bool);
    }
  }

  List<String> getRecommendations() {
    final recommendations = <String>[];

    if (_currentMode == PrivacyMode.standard) {
      recommendations.add('Consider using Strict or Lockdown privacy mode for enhanced protection');
    }
    if (!_offlineMode) {
      recommendations.add('Enable offline mode to prevent data transmission');
    }
    if (_telemetryEnabled) {
      recommendations.add('Disable telemetry to prevent usage data collection');
    }
    if (_analyticsEnabled) {
      recommendations.add('Disable analytics to prevent data analysis');
    }

    if (_currentMode == PrivacyMode.lockdown && _offlineMode && !_telemetryEnabled && !_analyticsEnabled) {
      recommendations.add('Privacy settings are well configured for maximum protection');
    }

    return recommendations;
  }
}
