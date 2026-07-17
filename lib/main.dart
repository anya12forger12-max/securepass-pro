import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:securepass_pro/navigation/app_router.dart';
import 'package:securepass_pro/themes/theme_state.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/infrastructure/config/app_config_manager.dart';
import 'package:securepass_pro/services/configuration_service.dart';
import 'package:securepass_pro/services/settings_service.dart';
import 'package:securepass_pro/services/privacy_service.dart';
import 'package:securepass_pro/services/security_service.dart';
import 'package:securepass_pro/services/diagnostics_service.dart';
import 'package:securepass_pro/services/logging_service.dart';
import 'package:securepass_pro/services/notification_service.dart';
import 'package:securepass_pro/services/workspace_service.dart';
import 'package:securepass_pro/services/history_service.dart';
import 'package:securepass_pro/services/favorites_service.dart';
import 'package:securepass_pro/services/recipe_service.dart';
import 'package:securepass_pro/services/tag_service.dart';
import 'package:securepass_pro/services/statistics_service.dart';
import 'package:securepass_pro/services/search_service.dart';
import 'package:securepass_pro/services/command_service.dart';
import 'package:securepass_pro/services/password_policy_service.dart';
import 'package:securepass_pro/services/password_analysis_service.dart';
import 'package:securepass_pro/services/export_service.dart';
import 'package:securepass_pro/services/import_service.dart';
import 'package:securepass_pro/services/qr_service.dart';
import 'package:securepass_pro/services/productivity_service.dart';
import 'package:securepass_pro/services/plugin_service.dart';
import 'package:securepass_pro/services/lifecycle_service.dart';
import 'package:securepass_pro/services/backup_service.dart';
import 'package:securepass_pro/services/encryption_service.dart';
import 'package:securepass_pro/services/storage_service.dart';
import 'package:securepass_pro/services/update_service.dart';
import 'package:securepass_pro/services/restore_service.dart';

import 'package:securepass_pro/infrastructure/event_bus/event_bus.dart';
import 'package:securepass_pro/infrastructure/feature_flags/feature_flag_system.dart';
import 'package:securepass_pro/infrastructure/module_registry/module_registry.dart';
import 'package:securepass_pro/infrastructure/service_registry/service_registry.dart';
import 'package:securepass_pro/infrastructure/migration/migration_engine.dart';
import 'package:securepass_pro/infrastructure/performance/performance_tracker.dart';
import 'package:securepass_pro/infrastructure/compatibility/compatibility_framework.dart';
import 'package:securepass_pro/infrastructure/extension_api/sdk_registry.dart';
import 'package:securepass_pro/infrastructure/lifecycle/lifecycle_manager.dart';
import 'package:securepass_pro/infrastructure/dependency_graph/dependency_graph.dart';
import 'package:securepass_pro/infrastructure/capabilities/capability_system.dart';
import 'package:securepass_pro/infrastructure/permissions/permission_framework.dart';
import 'package:securepass_pro/infrastructure/observability/observability_system.dart';
import 'package:securepass_pro/infrastructure/metrics/metrics_engine.dart';
import 'package:securepass_pro/infrastructure/configuration/config_evolution.dart';
import 'package:securepass_pro/core/errors/error_management.dart';
import 'package:securepass_pro/infrastructure/versioning/version_manager.dart';
import 'package:securepass_pro/infrastructure/versioning/semantic_version.dart';
import 'package:securepass_pro/infrastructure/advanced_event_system/advanced_event_bus.dart';
import 'package:securepass_pro/infrastructure/task_engine/task_engine.dart';
import 'package:securepass_pro/infrastructure/cache/cache_system.dart';
import 'package:securepass_pro/infrastructure/resources/resource_manager.dart';
import 'package:securepass_pro/infrastructure/search_platform/search_engine.dart';
import 'package:securepass_pro/infrastructure/command_platform/command_engine.dart';
import 'package:securepass_pro/infrastructure/composition/composition_engine.dart';
import 'package:securepass_pro/infrastructure/marketplace/module_manifest.dart';
import 'package:securepass_pro/infrastructure/ui_platform/ui_platform.dart';
import 'package:securepass_pro/infrastructure/accessibility_platform/accessibility_platform.dart';
import 'package:securepass_pro/infrastructure/api_maturity/api_maturity.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeInfrastructure();
  await _initializeServices();

  runApp(const ProviderScope(child: SecurePassApp()));
}

Future<void> _initializeInfrastructure() async {
  final logger = AppLogger.instance;
  final observability = ObservabilitySystem.instance;
  final metrics = MetricsEngine.instance;
  final perfTracker = PerformanceTracker.instance;

  observability.initialize();
  perfTracker.initialize();
  metrics.incrementCounter('app_startup');

  final startupStopwatch = Stopwatch()..start();

  EventBus.instance;
  FeatureFlagSystem.instance.initialize();
  ModuleRegistry.instance.initialize();
  ServiceRegistry.instance.initialize();
  LifecycleManager.instance.register('app', description: 'Application root');
  DependencyGraph.instance;
  CapabilityRegistry.instance;
  PermissionRegistry.instance.initialize();
  MigrationEngine.instance;
  ConfigEvolutionManager.instance.initialize();
  CompatibilityFramework.instance;
  SdkRegistry.instance;
  ErrorManagement.instance.initialize();
  VersionManager.instance;

  AdvancedEventBus.instance;
  TaskEngine.instance.initialize();
  CacheSystem.instance.initialize();
  ResourceManager.instance.initialize();
  SearchEngine.instance.initialize();
  CommandEngine.instance.initialize();
  CompositionEngine.instance.initialize();
  MarketplaceFoundation.instance;
  UIPlatform.instance.initialize();
  AccessibilityPlatform.instance.initialize();
  ApiMaturity.instance.initializeDefaults();

  startupStopwatch.stop();
  perfTracker.recordTiming('infrastructure_init', 'startup', startupStopwatch);
  observability.recordStartup('Infrastructure', startupStopwatch.elapsed);

  logger.info('V2 infrastructure initialized in ${startupStopwatch.elapsedMilliseconds}ms');
}

Future<void> _initializeServices() async {
  final logger = AppLogger.instance;
  final observability = ObservabilitySystem.instance;
  final perfTracker = PerformanceTracker.instance;
  final serviceRegistry = ServiceRegistry.instance;

  logger.info('Initializing SecurePass Pro services...');

  final servicesStopwatch = Stopwatch()..start();

  await PreferencesStorage.instance.init();
  serviceRegistry.register('preferences_storage', PreferencesStorage.instance, description: 'SharedPreferences wrapper');
  await AppConfigManager.instance.load();
  serviceRegistry.register('app_config', AppConfigManager.instance, description: 'App configuration manager');

  await ConfigurationService.instance.initialize();
  serviceRegistry.register('configuration', ConfigurationService.instance, description: 'Configuration service');

  await SettingsService.instance.initialize();
  serviceRegistry.register('settings', SettingsService.instance, description: 'Settings service');

  LoggingService.instance.initialize();
  serviceRegistry.register('logging', LoggingService.instance, description: 'Logging service');

  await StorageService.instance.initialize();
  serviceRegistry.register('storage', StorageService.instance, description: 'Storage service', dependencies: ['preferences_storage']);

  EncryptionService.instance.initialize();
  serviceRegistry.register('encryption', EncryptionService.instance, description: 'Encryption service');

  await HistoryService().initialize();
  serviceRegistry.register('history', HistoryService(), description: 'History service', dependencies: ['storage']);

  await FavoritesService().initialize();
  serviceRegistry.register('favorites', FavoritesService(), description: 'Favorites service', dependencies: ['storage']);

  await RecipeService().initialize();
  serviceRegistry.register('recipes', RecipeService(), description: 'Recipe service', dependencies: ['storage']);

  await TagService().initialize();
  serviceRegistry.register('tags', TagService(), description: 'Tag service', dependencies: ['storage']);

  await StatisticsService().initialize();
  serviceRegistry.register('statistics', StatisticsService(), description: 'Statistics service', dependencies: ['storage']);

  await WorkspaceService.instance.initialize();
  serviceRegistry.register('workspace', WorkspaceService.instance, description: 'Workspace service', dependencies: ['storage']);

  await PrivacyService.instance.initialize();
  serviceRegistry.register('privacy', PrivacyService.instance, description: 'Privacy service', dependencies: ['configuration']);

  await SecurityService.instance.initialize();
  serviceRegistry.register('security', SecurityService.instance, description: 'Security service', dependencies: ['configuration']);

  await DiagnosticsService.instance.initialize();
  serviceRegistry.register('diagnostics', DiagnosticsService.instance, description: 'Diagnostics service', dependencies: ['configuration', 'security']);

  NotificationService.instance.initialize();
  serviceRegistry.register('notifications', NotificationService.instance, description: 'Notification service');

  await PasswordPolicyService.instance.initialize();
  serviceRegistry.register('password_policy', PasswordPolicyService.instance, description: 'Password policy service');

  PasswordAnalysisService.instance.initialize();
  serviceRegistry.register('password_analysis', PasswordAnalysisService.instance, description: 'Password analysis service', dependencies: ['password_policy']);

  SearchService.instance.initialize();
  serviceRegistry.register('search', SearchService.instance, description: 'Search service');

  CommandService.instance.initialize();
  serviceRegistry.register('commands', CommandService.instance, description: 'Command service');

  await ProductivityService.instance.initialize();
  serviceRegistry.register('productivity', ProductivityService.instance, description: 'Productivity service');

  await ExportService.instance.initialize();
  serviceRegistry.register('export', ExportService.instance, description: 'Export service');

  await ImportService.instance.initialize();
  serviceRegistry.register('import', ImportService.instance, description: 'Import service');

  await QrService.instance.initialize();
  serviceRegistry.register('qr', QrService.instance, description: 'QR service');

  await BackupService.instance.initialize();
  serviceRegistry.register('backup', BackupService.instance, description: 'Backup service', dependencies: ['configuration', 'workspace']);

  PluginService.instance.initialize();
  serviceRegistry.register('plugins', PluginService.instance, description: 'Plugin service');

  LifecycleService.instance.initialize();
  serviceRegistry.register('lifecycle', LifecycleService.instance, description: 'App lifecycle service');

  await UpdateService.instance.initialize();
  serviceRegistry.register('update', UpdateService.instance, description: 'Update service');

  RestoreService.instance.initialize();
  serviceRegistry.register('restore', RestoreService.instance, description: 'Restore service', dependencies: ['configuration', 'workspace']);

  servicesStopwatch.stop();
  perfTracker.recordTiming('services_init', 'startup', servicesStopwatch);
  observability.recordStartup('All Services', servicesStopwatch.elapsed);

  _registerModules();

  logger.info('All services initialized successfully in ${servicesStopwatch.elapsedMilliseconds}ms');
}

void _registerModules() {
  final moduleRegistry = ModuleRegistry.instance;

  moduleRegistry.register(
    const ModuleMetadata(
      id: 'core',
      name: 'Core',
      version: SemanticVersion(major: 1, minor: 0, patch: 0),
      description: 'Core application module',
      capabilities: ['generation', 'analysis', 'security', 'storage'],
    ),
  );

  moduleRegistry.register(
    const ModuleMetadata(
      id: 'password_generator',
      name: 'Password Generator',
      version: SemanticVersion(major: 1, minor: 0, patch: 0),
      description: 'Password generation module',
      dependencies: ['core'],
      capabilities: ['generation'],
    ),
  );

  moduleRegistry.register(
    const ModuleMetadata(
      id: 'passphrase_generator',
      name: 'Passphrase Generator',
      version: SemanticVersion(major: 1, minor: 0, patch: 0),
      description: 'Passphrase generation module',
      dependencies: ['core'],
      capabilities: ['generation'],
    ),
  );

  moduleRegistry.register(
    const ModuleMetadata(
      id: 'pin_generator',
      name: 'PIN Generator',
      version: SemanticVersion(major: 1, minor: 0, patch: 0),
      description: 'PIN generation module',
      dependencies: ['core'],
      capabilities: ['generation'],
    ),
  );

  moduleRegistry.register(
    const ModuleMetadata(
      id: 'uuid_generator',
      name: 'UUID Generator',
      version: SemanticVersion(major: 1, minor: 0, patch: 0),
      description: 'UUID generation module',
      dependencies: ['core'],
      capabilities: ['generation'],
    ),
  );

  moduleRegistry.register(
    const ModuleMetadata(
      id: 'vault',
      name: 'Vault',
      version: SemanticVersion(major: 1, minor: 0, patch: 0),
      description: 'Credential vault module',
      dependencies: ['core'],
      capabilities: ['storage', 'security'],
      permissions: ['vault', 'clipboard'],
    ),
  );

  moduleRegistry.register(
    const ModuleMetadata(
      id: 'workspace',
      name: 'Workspace',
      version: SemanticVersion(major: 1, minor: 0, patch: 0),
      description: 'Workspace management module',
      dependencies: ['core'],
      capabilities: ['workspace'],
      permissions: ['workspace'],
    ),
  );

  moduleRegistry.register(
    const ModuleMetadata(
      id: 'export_import',
      name: 'Export & Import',
      version: SemanticVersion(major: 1, minor: 0, patch: 0),
      description: 'Data export and import module',
      dependencies: ['core'],
      capabilities: ['import', 'export'],
      permissions: ['export', 'import'],
    ),
  );

  moduleRegistry.register(
    const ModuleMetadata(
      id: 'theme_studio',
      name: 'Theme Studio',
      version: SemanticVersion(major: 1, minor: 0, patch: 0),
      description: 'Theme customization module',
      dependencies: ['core'],
      capabilities: ['theme'],
    ),
  );

  moduleRegistry.register(
    const ModuleMetadata(
      id: 'diagnostics',
      name: 'Diagnostics',
      version: SemanticVersion(major: 1, minor: 0, patch: 0),
      description: 'System diagnostics module',
      dependencies: ['core'],
      capabilities: ['diagnostics'],
      permissions: ['diagnostics'],
    ),
  );
}

class SecurePassApp extends ConsumerWidget {
  const SecurePassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'SecurePass Pro',
      debugShowCheckedModeBanner: false,
      theme: ref.read(themeProvider.notifier).lightTheme,
      darkTheme: ref.read(themeProvider.notifier).darkTheme,
      themeMode: ref.read(themeProvider.notifier).flutterThemeMode,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
