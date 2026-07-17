import 'package:securepass_pro/core/platform/platform_service.dart';
import 'package:securepass_pro/domain/entities/security_status.dart';
import 'package:securepass_pro/domain/enums/diagnostic_status.dart';
import 'package:securepass_pro/domain/enums/privacy_mode.dart';
import 'package:securepass_pro/domain/enums/security_profile.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/services/configuration_service.dart';

class SecurityService {
  SecurityService._();
  static final SecurityService _instance = SecurityService._();
  static SecurityService get instance => _instance;

  bool _initialized = false;
  SecurityProfile _currentProfile = SecurityProfile.balanced;
  static const String _profileKey = 'security_profile_setting';

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadProfile();
    _initialized = true;
    AppLogger.instance.info('Security service initialized: profile=${_currentProfile.name}', category: 'SECURITY');
  }

  Future<void> _loadProfile() async {
    final profileStr = PreferencesStorage.instance.getString(_profileKey);
    if (profileStr != null) {
      _currentProfile = SecurityProfile.values.firstWhere(
        (e) => e.name == profileStr,
        orElse: () => SecurityProfile.balanced,
      );
    }
  }

  Future<SecurityStatus> getSecurityStatus() async {
    final checks = await _runAllChecks();
    final overall = _determineOverallHealth(checks);
    return SecurityStatus(
      overallHealth: overall,
      checks: checks,
      lastVerified: DateTime.now(),
      profileName: _currentProfile.label,
    );
  }

  Future<void> setSecurityProfile(SecurityProfile profile) async {
    _currentProfile = profile;
    await PreferencesStorage.instance.setString(_profileKey, profile.name);
    AppLogger.instance.info('Security profile set to: ${profile.name}', category: 'SECURITY');
  }

  SecurityProfile getSecurityProfile() => _currentProfile;

  Future<bool> verifyIntegrity() async {
    final checks = await _runAllChecks();
    return !checks.any((c) => c.status == DiagnosticStatus.error);
  }

  Map<String, dynamic> getSecurityDiagnostics() {
    return {
      'profile': _currentProfile.name,
      'profileDescription': _currentProfile.description,
      'initialized': _initialized,
      'platform': PlatformService.instance.platformName,
      'isDesktop': PlatformService.instance.isDesktop,
      'isMobile': PlatformService.instance.isMobile,
      'checkedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<SecurityCheck> runSecurityCheck(String checkName) async {
    final checks = await _runAllChecks();
    try {
      return checks.firstWhere((c) => c.name == checkName);
    } catch (_) {
      return SecurityCheck(
        name: checkName,
        description: 'Unknown check',
        status: DiagnosticStatus.unknown,
        details: 'Check not found',
      );
    }
  }

  Future<List<SecurityCheck>> _runAllChecks() async {
    return [
      _checkConfigIntegrity(),
      _checkStorageIntegrity(),
      _checkClipboardSecurity(),
      _checkPrivacyMode(),
      _checkOfflineMode(),
      _checkSecurityProfile(),
      _checkPlatformSecurity(),
    ];
  }

  SecurityCheck _checkConfigIntegrity() {
    final config = ConfigurationService.instance.getFullConfig();
    final isValid = config.containsKey('security_profile') && config.containsKey('privacy_mode');
    return SecurityCheck(
      name: 'config_integrity',
      description: 'Configuration data integrity',
      status: isValid ? DiagnosticStatus.healthy : DiagnosticStatus.warning,
      details: isValid ? 'Configuration is intact' : 'Some configuration keys are missing',
    );
  }

  SecurityCheck _checkStorageIntegrity() {
    final keys = PreferencesStorage.instance.getKeys();
    return SecurityCheck(
      name: 'storage_integrity',
      description: 'Storage system integrity',
      status: DiagnosticStatus.healthy,
      details: 'Storage operational with ${keys.length} keys',
    );
  }

  SecurityCheck _checkClipboardSecurity() {
    final autoClear = ConfigurationService.instance.clipboardAutoClearSeconds;
    return SecurityCheck(
      name: 'clipboard_security',
      description: 'Clipboard auto-clear configuration',
      status: autoClear > 0 ? DiagnosticStatus.healthy : DiagnosticStatus.warning,
      details: autoClear > 0
          ? 'Clipboard auto-clear enabled at ${autoClear}s'
          : 'Clipboard auto-clear is disabled',
    );
  }

  SecurityCheck _checkPrivacyMode() {
    final mode = ConfigurationService.instance.privacyMode;
    return SecurityCheck(
      name: 'privacy_mode',
      description: 'Privacy mode level',
      status: mode == PrivacyMode.standard ? DiagnosticStatus.warning : DiagnosticStatus.healthy,
      details: 'Privacy mode: ${mode.label}',
    );
  }

  SecurityCheck _checkOfflineMode() {
    final offline = ConfigurationService.instance.offlineMode;
    return SecurityCheck(
      name: 'offline_mode',
      description: 'Offline mode status',
      status: offline ? DiagnosticStatus.healthy : DiagnosticStatus.warning,
      details: offline ? 'Offline mode is enabled' : 'Offline mode is disabled - data may leave device',
    );
  }

  SecurityCheck _checkSecurityProfile() {
    return SecurityCheck(
      name: 'security_profile',
      description: 'Active security profile',
      status: _currentProfile == SecurityProfile.maximum || _currentProfile == SecurityProfile.paranoid
          ? DiagnosticStatus.healthy
          : _currentProfile == SecurityProfile.balanced
              ? DiagnosticStatus.healthy
              : DiagnosticStatus.warning,
      details: 'Profile: ${_currentProfile.label} - ${_currentProfile.description}',
    );
  }

  SecurityCheck _checkPlatformSecurity() {
    final platform = PlatformService.instance;
    return SecurityCheck(
      name: 'platform_security',
      description: 'Platform security capabilities',
      status: DiagnosticStatus.healthy,
      details: '${platform.platformName} - biometrics: ${platform.supportsBiometrics}, secureStorage: ${platform.supportsSecureStorage}',
    );
  }

  DiagnosticStatus _determineOverallHealth(List<SecurityCheck> checks) {
    if (checks.any((c) => c.status == DiagnosticStatus.error)) return DiagnosticStatus.error;
    if (checks.any((c) => c.status == DiagnosticStatus.warning)) return DiagnosticStatus.warning;
    return DiagnosticStatus.healthy;
  }

  List<String> getSecurityRecommendations() {
    final recommendations = <String>[];

    if (_currentProfile == SecurityProfile.balanced) {
      recommendations.add('Consider upgrading to Maximum or Paranoid profile for enhanced security');
    }
    if (!ConfigurationService.instance.offlineMode) {
      recommendations.add('Enable offline mode to prevent network data leaks');
    }
    if (ConfigurationService.instance.privacyMode == PrivacyMode.standard) {
      recommendations.add('Enable Strict or Lockdown privacy mode');
    }
    if (ConfigurationService.instance.clipboardAutoClearSeconds == 0) {
      recommendations.add('Enable clipboard auto-clear to prevent data exposure');
    }

    if (_currentProfile == SecurityProfile.maximum && ConfigurationService.instance.offlineMode) {
      recommendations.add('Security configuration looks strong');
    }

    return recommendations;
  }
}
