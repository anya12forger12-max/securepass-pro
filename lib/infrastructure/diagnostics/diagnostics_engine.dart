import 'package:securepass_pro/domain/entities/diagnostic_entry.dart';
import 'package:securepass_pro/domain/enums/diagnostic_status.dart';
import 'package:securepass_pro/infrastructure/module_registry/module_registry.dart';
import 'package:securepass_pro/infrastructure/service_registry/service_registry.dart';
import 'package:securepass_pro/infrastructure/feature_flags/feature_flag_system.dart';
import 'package:securepass_pro/infrastructure/permissions/permission_framework.dart';
import 'package:securepass_pro/infrastructure/extension_api/sdk_registry.dart';
import 'package:securepass_pro/infrastructure/configuration/config_evolution.dart';
import 'package:securepass_pro/infrastructure/migration/migration_engine.dart';
import 'package:securepass_pro/infrastructure/performance/performance_tracker.dart';
import 'package:securepass_pro/infrastructure/compatibility/compatibility_framework.dart';

class DiagnosticsEngine {
  DiagnosticsEngine._();
  static final DiagnosticsEngine instance = DiagnosticsEngine._();

  final List<DiagnosticEntry> _diagnostics = [];

  Future<List<DiagnosticEntry>> runFullDiagnostics() async {
    _diagnostics.clear();
    _checkServices();
    _checkModules();
    _checkFeatureFlags();
    _checkPermissions();
    _checkSdkRegistrations();
    _checkConfiguration();
    _checkMigrations();
    _checkPerformance();
    _checkCompatibility();
    return List.unmodifiable(_diagnostics);
  }

  void _checkServices() {
    final registry = ServiceRegistry.instance;
    final diagnostics = registry.getDiagnostics();
    final states = diagnostics['states'] as Map<String, dynamic>? ?? {};
    final failedCount = (states['failed'] ?? 0) as int;
    final activeCount = (states['active'] ?? 0) as int;
    _diagnostics.add(DiagnosticEntry(
      id: 'service_registry',
      category: 'Services',
      status: failedCount > 0 ? DiagnosticStatus.error : DiagnosticStatus.healthy,
      message: '$activeCount services active, $failedCount failed',
      details: diagnostics,
    ));
  }

  void _checkModules() {
    final registry = ModuleRegistry.instance;
    final diagnostics = registry.getDiagnostics();
    final states = diagnostics['states'] as Map<String, dynamic>? ?? {};
    final failedCount = states['failed'] ?? 0;
    final activeCount = states['active'] ?? 0;
    final circularDeps = diagnostics['circularDependencies'] as List? ?? [];
    _diagnostics.add(DiagnosticEntry(
      id: 'module_registry',
      category: 'Modules',
      status: (failedCount as int) > 0 || circularDeps.isNotEmpty
          ? DiagnosticStatus.error
          : DiagnosticStatus.healthy,
      message: '$activeCount modules active, ${circularDeps.length} circular dependencies',
      details: diagnostics,
    ));
  }

  void _checkFeatureFlags() {
    final flags = FeatureFlagSystem.instance;
    final diagnostics = flags.getDiagnostics();
    final totalFlags = diagnostics['totalFlags'] ?? 0;
    final enabledFlags = diagnostics['enabledFlags'] ?? 0;
    _diagnostics.add(DiagnosticEntry(
      id: 'feature_flags',
      category: 'Feature Flags',
      status: DiagnosticStatus.healthy,
      message: '$enabledFlags/$totalFlags feature flags enabled',
      details: diagnostics,
    ));
  }

  void _checkPermissions() {
    final permissions = PermissionRegistry.instance;
    final diagnostics = permissions.getDiagnostics();
    _diagnostics.add(DiagnosticEntry(
      id: 'permissions',
      category: 'Permissions',
      status: DiagnosticStatus.healthy,
      message: '${diagnostics['totalGrants'] ?? 0} permission grants registered',
      details: diagnostics,
    ));
  }

  void _checkSdkRegistrations() {
    final sdk = SdkRegistry.instance;
    final diagnostics = sdk.getDiagnostics();
    _diagnostics.add(DiagnosticEntry(
      id: 'sdk_registrations',
      category: 'SDK',
      status: DiagnosticStatus.healthy,
      message: '${diagnostics['totalRegistrations'] ?? 0} SDK registrations',
      details: diagnostics,
    ));
  }

  void _checkConfiguration() {
    final config = ConfigEvolutionManager.instance;
    final diagnostics = config.getDiagnostics();
    _diagnostics.add(DiagnosticEntry(
      id: 'configuration',
      category: 'Configuration',
      status: DiagnosticStatus.healthy,
      message: 'Schema version: ${config.currentSchemaVersion}',
      details: diagnostics,
    ));
  }

  void _checkMigrations() {
    final migration = MigrationEngine.instance;
    final diagnostics = migration.getDiagnostics();
    final failed = (diagnostics['failedMigrations'] ?? 0) as int;
    _diagnostics.add(DiagnosticEntry(
      id: 'migrations',
      category: 'Migration',
      status: failed > 0 ? DiagnosticStatus.error : DiagnosticStatus.healthy,
      message: '${diagnostics['completedMigrations'] ?? 0} completed, $failed failed',
      details: diagnostics,
    ));
  }

  void _checkPerformance() {
    final perf = PerformanceTracker.instance;
    final diagnostics = perf.getDiagnostics();
    _diagnostics.add(DiagnosticEntry(
      id: 'performance',
      category: 'Performance',
      status: DiagnosticStatus.healthy,
      message: '${diagnostics['totalMetrics'] ?? 0} metrics recorded',
      details: diagnostics,
    ));
  }

  void _checkCompatibility() {
    final compat = CompatibilityFramework.instance;
    final diagnostics = compat.getDiagnostics();
    _diagnostics.add(DiagnosticEntry(
      id: 'compatibility',
      category: 'Compatibility',
      status: DiagnosticStatus.healthy,
      message: '${diagnostics['registeredComponents'] ?? 0} components tracked',
      details: diagnostics,
    ));
  }

  DiagnosticEntry? getDiagnosticById(String id) {
    try {
      return _diagnostics.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<DiagnosticEntry> getDiagnosticsByCategory(String category) {
    return _diagnostics.where((d) => d.category == category).toList();
  }

  DiagnosticStatus getOverallHealth() {
    if (_diagnostics.isEmpty) return DiagnosticStatus.unknown;
    if (_diagnostics.any((d) => d.status == DiagnosticStatus.error)) return DiagnosticStatus.error;
    if (_diagnostics.any((d) => d.status == DiagnosticStatus.warning)) return DiagnosticStatus.warning;
    return DiagnosticStatus.healthy;
  }

  Map<String, dynamic> getFullReport() {
    return {
      'overallHealth': getOverallHealth().name,
      'totalChecks': _diagnostics.length,
      'healthy': _diagnostics.where((d) => d.status == DiagnosticStatus.healthy).length,
      'warnings': _diagnostics.where((d) => d.status == DiagnosticStatus.warning).length,
      'errors': _diagnostics.where((d) => d.status == DiagnosticStatus.error).length,
      'checks': _diagnostics.map((d) => d.toMap()).toList(),
    };
  }
}
