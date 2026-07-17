import 'package:securepass_pro/infrastructure/module_registry/module_registry.dart';
import 'package:securepass_pro/infrastructure/service_registry/service_registry.dart';
import 'package:securepass_pro/infrastructure/feature_flags/feature_flag_system.dart';
import 'package:securepass_pro/infrastructure/dependency_graph/dependency_graph.dart';
import 'package:securepass_pro/infrastructure/lifecycle/lifecycle_manager.dart';
import 'package:securepass_pro/infrastructure/performance/performance_tracker.dart';
import 'package:securepass_pro/infrastructure/metrics/metrics_engine.dart';
import 'package:securepass_pro/infrastructure/observability/observability_system.dart';
import 'package:securepass_pro/infrastructure/configuration/config_evolution.dart';

class DeveloperTools {
  DeveloperTools._();
  static final DeveloperTools instance = DeveloperTools._();

  Map<String, dynamic> getArchitectureExplorer() {
    return {
      'moduleRegistry': ModuleRegistry.instance.getDiagnostics(),
      'serviceRegistry': ServiceRegistry.instance.getDiagnostics(),
      'dependencyGraph': DependencyGraph.instance.getDiagnostics(),
      'lifecycle': LifecycleManager.instance.getDiagnostics(),
    };
  }

  Map<String, dynamic> getDependencyViewer() {
    return DependencyGraph.instance.getDiagnostics();
  }

  Map<String, dynamic> getLifecycleViewer() {
    return LifecycleManager.instance.getDiagnostics();
  }

  Map<String, dynamic> getConfigurationInspector() {
    return {
      'configEvolution': ConfigEvolutionManager.instance.getDiagnostics(),
    };
  }

  Map<String, dynamic> getFeatureFlagInspector() {
    return FeatureFlagSystem.instance.getDiagnostics();
  }

  Map<String, dynamic> getPermissionInspector() {
    return {};
  }

  Map<String, dynamic> getModuleInspector() {
    return ModuleRegistry.instance.getDiagnostics();
  }

  Map<String, dynamic> getServiceInspector() {
    return ServiceRegistry.instance.getDiagnostics();
  }

  Map<String, dynamic> getSdkExplorer() {
    return {};
  }

  Map<String, dynamic> getPerformanceDashboard() {
    return PerformanceTracker.instance.getDiagnostics();
  }

  Map<String, dynamic> getMetricsDashboard() {
    return MetricsEngine.instance.getDiagnostics();
  }

  Map<String, dynamic> getObservabilityDashboard() {
    return ObservabilitySystem.instance.getDiagnostics();
  }

  Map<String, dynamic> getFullDeveloperReport() {
    return {
      'architecture': getArchitectureExplorer(),
      'dependencies': getDependencyViewer(),
      'lifecycle': getLifecycleViewer(),
      'configuration': getConfigurationInspector(),
      'featureFlags': getFeatureFlagInspector(),
      'modules': getModuleInspector(),
      'services': getServiceInspector(),
      'performance': getPerformanceDashboard(),
      'metrics': getMetricsDashboard(),
      'observability': getObservabilityDashboard(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}
