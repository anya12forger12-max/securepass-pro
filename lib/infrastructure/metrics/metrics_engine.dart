enum MetricType { counter, gauge, histogram, summary }

class MetricValue {
  const MetricValue({
    required this.name,
    required this.type,
    required this.value,
    this.labels = const {},
    this.timestamp,
  });

  final String name;
  final MetricType type;
  final double value;
  final Map<String, String> labels;
  final DateTime? timestamp;

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type.name,
    'value': value,
    'labels': labels,
    'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
  };
}

class HistogramBucket {
  HistogramBucket({required this.le, this.count = 0});
  final double le;
  int count;
}

class MetricsEngine {
  MetricsEngine._();
  static final MetricsEngine instance = MetricsEngine._();

  final Map<String, double> _counters = {};
  final Map<String, double> _gauges = {};
  final Map<String, List<double>> _histograms = {};
  final List<MetricValue> _recentMetrics = [];
  final int _maxRecent = 500;

  void incrementCounter(String name, {double value = 1, Map<String, String> labels = const {}}) {
    final key = _makeKey(name, labels);
    _counters[key] = (_counters[key] ?? 0) + value;
    _record(MetricValue(name: name, type: MetricType.counter, value: _counters[key]!, labels: labels));
  }

  void setGauge(String name, double value, {Map<String, String> labels = const {}}) {
    final key = _makeKey(name, labels);
    _gauges[key] = value;
    _record(MetricValue(name: name, type: MetricType.gauge, value: value, labels: labels));
  }

  void observeHistogram(String name, double value, {Map<String, String> labels = const {}}) {
    final key = _makeKey(name, labels);
    _histograms.putIfAbsent(key, () => []).add(value);
    _record(MetricValue(name: name, type: MetricType.histogram, value: value, labels: labels));
  }

  double getCounter(String name, {Map<String, String> labels = const {}}) {
    return _counters[_makeKey(name, labels)] ?? 0;
  }

  double? getGauge(String name, {Map<String, String> labels = const {}}) {
    return _gauges[_makeKey(name, labels)];
  }

  List<double>? getHistogram(String name, {Map<String, String> labels = const {}}) {
    return _histograms[_makeKey(name, labels)];
  }

  double? getHistogramAverage(String name, {Map<String, String> labels = const {}}) {
    final values = getHistogram(name, labels: labels);
    if (values == null || values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Map<String, double> getAllCounters() => Map.unmodifiable(_counters);
  Map<String, double> getAllGauges() => Map.unmodifiable(_gauges);

  void _record(MetricValue metric) {
    _recentMetrics.add(metric);
    if (_recentMetrics.length > _maxRecent) {
      _recentMetrics.removeAt(0);
    }
  }

  List<MetricValue> getRecentMetrics({String? name, int? limit}) {
    var result = List<MetricValue>.from(_recentMetrics);
    if (name != null) result = result.where((m) => m.name == name).toList();
    if (limit != null && result.length > limit) result = result.sublist(result.length - limit);
    return result;
  }

  String _makeKey(String name, Map<String, String> labels) {
    if (labels.isEmpty) return name;
    final sorted = labels.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return '$name:${sorted.map((e) => '${e.key}=${e.value}').join(',')}';
  }

  void clear() {
    _counters.clear();
    _gauges.clear();
    _histograms.clear();
    _recentMetrics.clear();
  }

  Map<String, dynamic> getSnapshot() {
    return {
      'counters': Map<String, double>.unmodifiable(_counters),
      'gauges': Map<String, double>.unmodifiable(_gauges),
      'histograms': {
        for (final entry in _histograms.entries)
          entry.key: {
            'count': entry.value.length,
            'sum': entry.value.isEmpty ? 0.0 : entry.value.reduce((a, b) => a + b),
            'avg': entry.value.isEmpty ? 0.0 : entry.value.reduce((a, b) => a + b) / entry.value.length,
            'min': entry.value.isEmpty ? 0.0 : entry.value.reduce((a, b) => a < b ? a : b),
            'max': entry.value.isEmpty ? 0.0 : entry.value.reduce((a, b) => a > b ? a : b),
          },
      },
    };
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalCounters': _counters.length,
      'totalGauges': _gauges.length,
      'totalHistograms': _histograms.length,
      'recentMetricsCount': _recentMetrics.length,
      'snapshot': getSnapshot(),
    };
  }
}
