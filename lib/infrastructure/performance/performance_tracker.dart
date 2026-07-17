import 'dart:async';
import 'dart:io';

class PerformanceMetric {
  const PerformanceMetric({
    required this.name,
    required this.category,
    required this.value,
    this.unit = 'ms',
    this.timestamp,
    this.metadata = const {},
  });

  final String name;
  final String category;
  final double value;
  final String unit;
  final DateTime? timestamp;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'value': value,
    'unit': unit,
    'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    'metadata': metadata,
  };
}

class PerformanceBaseline {
  const PerformanceBaseline({
    required this.name,
    required this.target,
    this.warningThreshold,
    this.criticalThreshold,
    this.unit = 'ms',
  });

  final String name;
  final double target;
  final double? warningThreshold;
  final double? criticalThreshold;
  final String unit;

  String evaluate(double value) {
    if (criticalThreshold != null && value > criticalThreshold!) return 'critical';
    if (warningThreshold != null && value > warningThreshold!) return 'warning';
    if (value > target * 1.5) return 'warning';
    return 'good';
  }
}

class PerformanceTracker {
  PerformanceTracker._();
  static final PerformanceTracker instance = PerformanceTracker._();

  final List<PerformanceMetric> _metrics = [];
  final Map<String, PerformanceBaseline> _baselines = {};
  int _maxMetrics = 1000;
  bool _enabled = true;

  void initialize() {
    _registerDefaultBaselines();
  }

  void _registerDefaultBaselines() {
    registerBaseline(const PerformanceBaseline(
      name: 'startup_time', target: 2000, warningThreshold: 3000, criticalThreshold: 5000, unit: 'ms',
    ));
    registerBaseline(const PerformanceBaseline(
      name: 'module_load', target: 100, warningThreshold: 200, criticalThreshold: 500, unit: 'ms',
    ));
    registerBaseline(const PerformanceBaseline(
      name: 'service_load', target: 50, warningThreshold: 100, criticalThreshold: 300, unit: 'ms',
    ));
    registerBaseline(const PerformanceBaseline(
      name: 'search_time', target: 50, warningThreshold: 100, criticalThreshold: 200, unit: 'ms',
    ));
    registerBaseline(const PerformanceBaseline(
      name: 'render_time', target: 16, warningThreshold: 32, criticalThreshold: 64, unit: 'ms',
    ));
    registerBaseline(const PerformanceBaseline(
      name: 'memory_usage', target: 100, warningThreshold: 200, criticalThreshold: 500, unit: 'MB',
    ));
    registerBaseline(const PerformanceBaseline(
      name: 'workspace_load', target: 200, warningThreshold: 500, criticalThreshold: 1000, unit: 'ms',
    ));
    registerBaseline(const PerformanceBaseline(
      name: 'export_time', target: 500, warningThreshold: 1000, criticalThreshold: 3000, unit: 'ms',
    ));
    registerBaseline(const PerformanceBaseline(
      name: 'import_time', target: 500, warningThreshold: 1000, criticalThreshold: 3000, unit: 'ms',
    ));
  }

  void registerBaseline(PerformanceBaseline baseline) {
    _baselines[baseline.name] = baseline;
  }

  void record(PerformanceMetric metric) {
    if (!_enabled) return;
    _metrics.add(metric);
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }
  }

  void recordTiming(String name, String category, Stopwatch stopwatch, {Map<String, dynamic> metadata = const {}}) {
    record(PerformanceMetric(
      name: name,
      category: category,
      value: stopwatch.elapsedMilliseconds.toDouble(),
      metadata: metadata,
    ));
  }

  Future<T> measure<T>(String name, String category, Future<T> Function() operation, {Map<String, dynamic> metadata = const {}}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      recordTiming(name, category, stopwatch, metadata: metadata);
      return result;
    } catch (e) {
      stopwatch.stop();
      record(PerformanceMetric(
        name: name,
        category: category,
        value: stopwatch.elapsedMilliseconds.toDouble(),
        metadata: {...metadata, 'error': e.toString()},
      ));
      rethrow;
    }
  }

  void recordMemoryUsage(String category) {
    try {
      final processInfo = ProcessInfo.currentRss;
      final mb = processInfo / (1024 * 1024);
      record(PerformanceMetric(
        name: 'memory_usage',
        category: category,
        value: mb,
        unit: 'MB',
      ));
    } catch (_) {}
  }

  List<PerformanceMetric> getMetrics({String? category, String? name, int? limit}) {
    var result = List<PerformanceMetric>.from(_metrics);
    if (category != null) result = result.where((m) => m.category == category).toList();
    if (name != null) result = result.where((m) => m.name == name).toList();
    if (limit != null && result.length > limit) result = result.sublist(result.length - limit);
    return result;
  }

  double? getAverageTime(String name, {int lastN = 100}) {
    final matching = _metrics.where((m) => m.name == name).toList();
    if (matching.isEmpty) return null;
    final recent = matching.length > lastN ? matching.sublist(matching.length - lastN) : matching;
    return recent.map((m) => m.value).reduce((a, b) => a + b) / recent.length;
  }

  PerformanceBaseline? getBaseline(String name) => _baselines[name];

  String evaluatePerformance(String name) {
    final baseline = _baselines[name];
    if (baseline == null) return 'unknown';
    final avg = getAverageTime(name);
    if (avg == null) return 'no_data';
    return baseline.evaluate(avg);
  }

  Map<String, dynamic> getPerformanceReport() {
    final categories = <String, List<PerformanceMetric>>{};
    for (final metric in _metrics) {
      categories.putIfAbsent(metric.category, () => []).add(metric);
    }
    final report = <String, dynamic>{
      'totalMetrics': _metrics.length,
      'categories': <String, dynamic>{},
    };
    for (final entry in categories.entries) {
      final names = <String, Map<String, dynamic>>{};
      for (final metric in entry.value) {
        names.putIfAbsent(metric.name, () => {
          'count': 0,
          'average': 0.0,
          'min': double.infinity,
          'max': double.negativeInfinity,
        });
        final stats = names[metric.name]!;
        stats['count'] = (stats['count'] as int) + 1;
        final avg = ((stats['average'] as double) * ((stats['count'] as int) - 1) + metric.value) / (stats['count'] as int);
        stats['average'] = avg;
        stats['min'] = (stats['min'] as double) < metric.value ? stats['min'] : metric.value;
        stats['max'] = (stats['max'] as double) > metric.value ? stats['max'] : metric.value;
      }
      report['categories'][entry.key] = names;
    }
    return report;
  }

  void clear() => _metrics.clear();
  set maxMetrics(int value) => _maxMetrics = value;
  set enabled(bool value) => _enabled = value;

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalMetrics': _metrics.length,
      'maxMetrics': _maxMetrics,
      'enabled': _enabled,
      'baselines': _baselines.length,
      'baselineStatus': {
        for (final entry in _baselines.entries)
          entry.key: evaluatePerformance(entry.key),
      },
    };
  }
}
