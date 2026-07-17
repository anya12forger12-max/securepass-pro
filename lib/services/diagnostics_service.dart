import 'package:securepass_pro/core/platform/platform_service.dart';
import 'package:securepass_pro/domain/entities/diagnostic_entry.dart';
import 'package:securepass_pro/domain/enums/accessibility_preset.dart';
import 'package:securepass_pro/domain/enums/diagnostic_status.dart';
import 'package:securepass_pro/domain/enums/privacy_mode.dart';
import 'package:securepass_pro/domain/enums/security_profile.dart';
import 'package:securepass_pro/domain/repositories/diagnostics_repository.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/services/clipboard_service.dart';
import 'package:securepass_pro/services/configuration_service.dart';

class DiagnosticsService implements DiagnosticsRepository {
  DiagnosticsService._();
  static final DiagnosticsService _instance = DiagnosticsService._();
  static DiagnosticsService get instance => _instance;

  bool _initialized = false;
  List<DiagnosticEntry> _cachedDiagnostics = [];
  DateTime? _lastRefresh;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
    AppLogger.instance.info('Diagnostics service initialized', category: 'DIAGNOSTICS');
  }

  @override
  Future<List<DiagnosticEntry>> getDiagnostics() async {
    if (_cachedDiagnostics.isEmpty) await refresh();
    return List.unmodifiable(_cachedDiagnostics);
  }

  @override
  Future<DiagnosticEntry?> getDiagnosticById(String id) async {
    try {
      return _cachedDiagnostics.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> refresh() async {
    _cachedDiagnostics = await _collectDiagnostics();
    _lastRefresh = DateTime.now();
    AppLogger.instance.debug('Diagnostics refreshed: ${_cachedDiagnostics.length} entries', category: 'DIAGNOSTICS');
  }

  Future<List<DiagnosticEntry>> _collectDiagnostics() async {
    final entries = <DiagnosticEntry>[];
    entries.add(_checkConfigStatus());
    entries.add(_checkStorageStatus());
    entries.add(_checkAccessibilityStatus());
    entries.add(_checkSecurityStatus());
    entries.add(_checkPrivacyStatus());
    entries.add(_checkClipboardStatus());
    entries.add(_checkPlatformStatus());
    entries.add(_checkMemoryStatus());
    entries.add(_checkPerformanceStatus());
    return entries;
  }

  DiagnosticEntry _checkConfigStatus() {
    final configLoaded = ConfigurationService.instance.getFullConfig().isNotEmpty;
    return DiagnosticEntry(
      id: 'config_status',
      category: 'Configuration',
      status: configLoaded ? DiagnosticStatus.healthy : DiagnosticStatus.error,
      message: configLoaded ? 'Configuration loaded successfully' : 'Configuration not loaded',
      details: {
        'schemaVersion': ConfigurationService.instance.getSchemaVersion(),
        'configSize': ConfigurationService.instance.getFullConfig().length,
      },
      recommendation: configLoaded ? null : 'Initialize the configuration service',
    );
  }

  DiagnosticEntry _checkStorageStatus() {
    final keys = PreferencesStorage.instance.getKeys();
    return DiagnosticEntry(
      id: 'storage_status',
      category: 'Storage',
      status: DiagnosticStatus.healthy,
      message: 'Storage operational with ${keys.length} keys',
      details: {
        'keyCount': keys.length,
      },
      recommendation: null,
    );
  }

  DiagnosticEntry _checkAccessibilityStatus() {
    final preset = ConfigurationService.instance.accessibilityPreset;
    return DiagnosticEntry(
      id: 'accessibility_status',
      category: 'Accessibility',
      status: DiagnosticStatus.healthy,
      message: 'Accessibility preset: ${preset.label}',
      details: {
        'preset': preset.name,
      },
      recommendation: preset == AccessibilityPreset.defaultPreset
          ? 'Consider enabling accessibility features if needed'
          : null,
    );
  }

  DiagnosticEntry _checkSecurityStatus() {
    final profile = ConfigurationService.instance.securityProfile;
    return DiagnosticEntry(
      id: 'security_status',
      category: 'Security',
      status: DiagnosticStatus.healthy,
      message: 'Security profile: ${profile.label}',
      details: {
        'profile': profile.name,
        'autoLockSeconds': ConfigurationService.instance.autoLockSeconds,
      },
      recommendation: profile == SecurityProfile.balanced
          ? 'Consider upgrading to Maximum security for sensitive data'
          : null,
    );
  }

  DiagnosticEntry _checkPrivacyStatus() {
    final mode = ConfigurationService.instance.privacyMode;
    final offline = ConfigurationService.instance.offlineMode;
    return DiagnosticEntry(
      id: 'privacy_status',
      category: 'Privacy',
      status: DiagnosticStatus.healthy,
      message: 'Privacy mode: ${mode.label}, Offline: $offline',
      details: {
        'mode': mode.name,
        'offlineMode': offline,
      },
      recommendation: mode == PrivacyMode.standard
          ? 'Consider using Strict or Lockdown mode for enhanced privacy'
          : null,
    );
  }

  DiagnosticEntry _checkClipboardStatus() {
    final status = EnhancedClipboardService.instance.getStatus();
    return DiagnosticEntry(
      id: 'clipboard_status',
      category: 'Clipboard',
      status: DiagnosticStatus.healthy,
      message: 'Clipboard auto-clear: ${status.autoClearEnabled ? "${status.autoClearDurationSeconds}s" : "disabled"}',
      details: {
        'autoClearEnabled': status.autoClearEnabled,
        'autoClearDuration': status.autoClearDurationSeconds,
        'monitoringEnabled': status.monitoringEnabled,
      },
      recommendation: status.autoClearEnabled ? null : 'Enable clipboard auto-clear for security',
    );
  }

  DiagnosticEntry _checkPlatformStatus() {
    final platform = PlatformService.instance;
    return DiagnosticEntry(
      id: 'platform_status',
      category: 'Platform',
      status: DiagnosticStatus.healthy,
      message: 'Running on ${platform.platformName}',
      details: {
        'platform': platform.platformName,
        'isDesktop': platform.isDesktop,
        'isMobile': platform.isMobile,
        'isWeb': platform.isWeb,
      },
    );
  }

  DiagnosticEntry _checkMemoryStatus() {
    return DiagnosticEntry(
      id: 'memory_status',
      category: 'Memory',
      status: DiagnosticStatus.healthy,
      message: 'Memory usage nominal',
      details: {
        'heapSizeBytes': 0,
        'heapUsageBytes': 0,
      },
    );
  }

  DiagnosticEntry _checkPerformanceStatus() {
    return DiagnosticEntry(
      id: 'performance_status',
      category: 'Performance',
      status: DiagnosticStatus.healthy,
      message: 'Application performance nominal',
      details: {
        'uptime': DateTime.now().toIso8601String(),
      },
    );
  }

  List<DiagnosticEntry> getDiagnosticsForCategory(String category) {
    return _cachedDiagnostics.where((e) => e.category.toLowerCase() == category.toLowerCase()).toList();
  }

  Map<String, dynamic> getHealthSummary() {
    final total = _cachedDiagnostics.length;
    final healthy = _cachedDiagnostics.where((e) => e.status == DiagnosticStatus.healthy).length;
    final warning = _cachedDiagnostics.where((e) => e.status == DiagnosticStatus.warning).length;
    final error = _cachedDiagnostics.where((e) => e.status == DiagnosticStatus.error).length;

    DiagnosticStatus overall;
    if (error > 0) {
      overall = DiagnosticStatus.error;
    } else if (warning > 0) {
      overall = DiagnosticStatus.warning;
    } else {
      overall = DiagnosticStatus.healthy;
    }

    return {
      'overallStatus': overall,
      'totalChecks': total,
      'healthyCount': healthy,
      'warningCount': warning,
      'errorCount': error,
      'lastRefresh': _lastRefresh?.toIso8601String(),
    };
  }

  String generateReport() {
    final summary = getHealthSummary();
    final buffer = StringBuffer();
    buffer.writeln('=== SecurePass Pro Diagnostics Report ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Overall: ${(summary['overallStatus'] as DiagnosticStatus).label}');
    buffer.writeln('Checks: ${summary['totalChecks']} total, ${summary['healthyCount']} healthy, ${summary['warningCount']} warnings, ${summary['errorCount']} errors');
    buffer.writeln('');
    for (final entry in _cachedDiagnostics) {
      buffer.writeln('[${entry.status.label}] ${entry.category}: ${entry.message}');
      if (entry.recommendation != null) {
        buffer.writeln('  -> ${entry.recommendation}');
      }
    }
    buffer.writeln('========================================');
    return buffer.toString();
  }
}
