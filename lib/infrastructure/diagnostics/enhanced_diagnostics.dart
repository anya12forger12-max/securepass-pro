import 'package:securepass_pro/infrastructure/performance/performance_tracker.dart';
import 'package:securepass_pro/infrastructure/module_registry/module_registry.dart';
import 'package:securepass_pro/infrastructure/task_engine/task_engine.dart';
import 'package:securepass_pro/infrastructure/cache/cache_system.dart';
import 'package:securepass_pro/infrastructure/composition/composition_engine.dart';
import 'package:securepass_pro/infrastructure/resources/resource_manager.dart';
import 'package:securepass_pro/infrastructure/search_platform/search_engine.dart';
import 'package:securepass_pro/infrastructure/accessibility_platform/accessibility_platform.dart';

class TimelineEntry {
  const TimelineEntry({required this.timestamp, required this.category, required this.label, this.durationMs = 0, this.metadata = const {}});
  final DateTime timestamp;
  final String category;
  final String label;
  final double durationMs;
  final Map<String, dynamic> metadata;
}

class EnhancedDiagnostics {
  EnhancedDiagnostics._();
  static final EnhancedDiagnostics instance = EnhancedDiagnostics._();

  final List<TimelineEntry> _startupTimeline = [];
  final List<TimelineEntry> _moduleTimeline = [];
  final List<TimelineEntry> _memoryTimeline = [];
  final List<TimelineEntry> _workspaceTimeline = [];

  void recordStartup(String label, Duration duration, {Map<String, dynamic> metadata = const {}}) {
    _startupTimeline.add(TimelineEntry(
      timestamp: DateTime.now(), category: 'startup', label: label,
      durationMs: duration.inMicroseconds / 1000.0, metadata: metadata,
    ));
  }

  void recordModuleEvent(String label, Duration duration, {Map<String, dynamic> metadata = const {}}) {
    _moduleTimeline.add(TimelineEntry(
      timestamp: DateTime.now(), category: 'module', label: label,
      durationMs: duration.inMicroseconds / 1000.0, metadata: metadata,
    ));
  }

  void recordMemory(String label, {int bytes = 0}) {
    _memoryTimeline.add(TimelineEntry(
      timestamp: DateTime.now(), category: 'memory', label: label,
      metadata: {'bytes': bytes},
    ));
  }

  void recordWorkspace(String label, Duration duration, {Map<String, dynamic> metadata = const {}}) {
    _workspaceTimeline.add(TimelineEntry(
      timestamp: DateTime.now(), category: 'workspace', label: label,
      durationMs: duration.inMicroseconds / 1000.0, metadata: metadata,
    ));
  }

  List<TimelineEntry> getStartupTimeline() => List.unmodifiable(_startupTimeline);
  List<TimelineEntry> getModuleTimeline() => List.unmodifiable(_moduleTimeline);
  List<TimelineEntry> getMemoryTimeline() => List.unmodifiable(_memoryTimeline);
  List<TimelineEntry> getWorkspaceTimeline() => List.unmodifiable(_workspaceTimeline);

  Map<String, dynamic> getPerformanceTimeline() {
    return PerformanceTracker.instance.getDiagnostics();
  }

  Map<String, dynamic> getModuleDiagnostics() {
    return ModuleRegistry.instance.getDiagnostics();
  }

  Map<String, dynamic> getConfigurationDiagnostics() {
    return {'status': 'healthy'};
  }

  Map<String, dynamic> getPluginDiagnostics() {
    return {'totalPlugins': 0, 'activePlugins': 0};
  }

  Map<String, dynamic> getAccessibilityDiagnostics() {
    return AccessibilityPlatform.instance.getDiagnostics();
  }

  Map<String, dynamic> getWorkspaceDiagnostics() {
    return {
      'timelineEntries': _workspaceTimeline.length,
      'recentEntries': _workspaceTimeline.take(5).map((e) => {
        'label': e.label,
        'durationMs': e.durationMs,
        'timestamp': e.timestamp.toIso8601String(),
      }).toList(),
    };
  }

  Map<String, dynamic> getFullReport() {
    return {
      'startupTimeline': _startupTimeline.map((e) => {
        'label': e.label,
        'durationMs': e.durationMs,
        'timestamp': e.timestamp.toIso8601String(),
      }).toList(),
      'moduleTimeline': _moduleTimeline.length,
      'memoryTimeline': _memoryTimeline.length,
      'workspaceTimeline': _workspaceTimeline.length,
      'performance': getPerformanceTimeline(),
      'modules': getModuleDiagnostics(),
      'accessibility': getAccessibilityDiagnostics(),
      'taskEngine': TaskEngine.instance.getDiagnostics(),
      'cache': CacheSystem.instance.getDiagnostics(),
      'composition': CompositionEngine.instance.getDiagnostics(),
      'resources': ResourceManager.instance.getDiagnostics(),
      'search': SearchEngine.instance.getDiagnostics(),
    };
  }

  void clear() {
    _startupTimeline.clear();
    _moduleTimeline.clear();
    _memoryTimeline.clear();
    _workspaceTimeline.clear();
  }
}
