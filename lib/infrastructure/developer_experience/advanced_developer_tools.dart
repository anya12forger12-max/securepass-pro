import 'package:securepass_pro/infrastructure/module_registry/module_registry.dart';
import 'package:securepass_pro/infrastructure/service_registry/service_registry.dart';
import 'package:securepass_pro/infrastructure/dependency_graph/dependency_graph.dart';
import 'package:securepass_pro/infrastructure/lifecycle/lifecycle_manager.dart';
import 'package:securepass_pro/infrastructure/task_engine/task_engine.dart';
import 'package:securepass_pro/infrastructure/cache/cache_system.dart';
import 'package:securepass_pro/infrastructure/composition/composition_engine.dart';
import 'package:securepass_pro/infrastructure/feature_flags/feature_flag_system.dart';
import 'package:securepass_pro/infrastructure/performance/performance_tracker.dart';
import 'package:securepass_pro/infrastructure/metrics/metrics_engine.dart';
import 'package:securepass_pro/infrastructure/observability/observability_system.dart';
import 'package:securepass_pro/infrastructure/configuration/config_evolution.dart';
import 'package:securepass_pro/infrastructure/search_platform/search_engine.dart';
import 'package:securepass_pro/infrastructure/command_platform/command_engine.dart';
import 'package:securepass_pro/infrastructure/resources/resource_manager.dart';
import 'package:securepass_pro/infrastructure/advanced_event_system/advanced_event_bus.dart';
import 'package:securepass_pro/infrastructure/diagnostics/enhanced_diagnostics.dart';

class AdvancedDeveloperTools {
  AdvancedDeveloperTools._();
  static final AdvancedDeveloperTools instance = AdvancedDeveloperTools._();

  Map<String, dynamic> exploreDependencies() => DependencyGraph.instance.getDiagnostics();
  Map<String, dynamic> exploreEvents() => AdvancedEventBus.instance.getMetrics();
  Map<String, dynamic> exploreLifecycle() => LifecycleManager.instance.getDiagnostics();
  Map<String, dynamic> exploreTasks() => TaskEngine.instance.getDiagnostics();
  Map<String, dynamic> exploreCache() => CacheSystem.instance.getDiagnostics();
  Map<String, dynamic> exploreConfiguration() => ConfigEvolutionManager.instance.getDiagnostics();
  Map<String, dynamic> explorePerformance() => PerformanceTracker.instance.getDiagnostics();
  Map<String, dynamic> exploreMetrics() => MetricsEngine.instance.getDiagnostics();
  Map<String, dynamic> exploreModules() => ModuleRegistry.instance.getDiagnostics();
  Map<String, dynamic> exploreServices() => ServiceRegistry.instance.getDiagnostics();
  Map<String, dynamic> exploreComposition() => CompositionEngine.instance.getDiagnostics();
  Map<String, dynamic> exploreResources() => ResourceManager.instance.getDiagnostics();
  Map<String, dynamic> exploreSearch() => SearchEngine.instance.getDiagnostics();
  Map<String, dynamic> exploreCommands() => CommandEngine.instance.getDiagnostics();
  Map<String, dynamic> exploreFeatureFlags() => FeatureFlagSystem.instance.getDiagnostics();
  Map<String, dynamic> exploreObservability() => ObservabilitySystem.instance.getDiagnostics();
  Map<String, dynamic> exploreDiagnostics() => EnhancedDiagnostics.instance.getFullReport();

  Map<String, dynamic> getFullArchitectureReport() {
    return {
      'modules': exploreModules(),
      'services': exploreServices(),
      'dependencies': exploreDependencies(),
      'lifecycle': exploreLifecycle(),
      'featureFlags': exploreFeatureFlags(),
      'composition': exploreComposition(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> getFullPlatformReport() {
    return {
      'events': exploreEvents(),
      'tasks': exploreTasks(),
      'cache': exploreCache(),
      'configuration': exploreConfiguration(),
      'performance': explorePerformance(),
      'metrics': exploreMetrics(),
      'resources': exploreResources(),
      'search': exploreSearch(),
      'commands': exploreCommands(),
      'observability': exploreObservability(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> getCompleteReport() {
    return {
      'architecture': getFullArchitectureReport(),
      'platform': getFullPlatformReport(),
      'diagnostics': exploreDiagnostics(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}
