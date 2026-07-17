import 'package:securepass_pro/infrastructure/event_bus/event_bus.dart';

enum ObservabilityLevel { trace, debug, info, warning, error, fatal }

class ObservabilityEvent extends AppEvent {
  const ObservabilityEvent({
    required this.level,
    required this.category,
    required this.message,
    this.data = const {},
    super.source,
    super.timestamp,
  });

  final ObservabilityLevel level;
  final String category;
  final String message;
  final Map<String, dynamic> data;
}

class ObservabilityEntry {
  ObservabilityEntry({
    required this.level,
    required this.category,
    required this.message,
    this.data = const {},
    this.source = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final ObservabilityLevel level;
  final String category;
  final String message;
  final Map<String, dynamic> data;
  final String source;
  final DateTime timestamp;
}

class ObservabilitySystem {
  ObservabilitySystem._();
  static final ObservabilitySystem instance = ObservabilitySystem._();

  final List<ObservabilityEntry> _entries = [];
  final EventBus _eventBus = EventBus.instance;
  int _maxEntries = 2000;
  ObservabilityLevel _minLevel = ObservabilityLevel.info;
  bool _enabled = true;
  final Map<String, int> _categoryCounts = {};

  void initialize() {}

  void trace(String category, String message, {Map<String, dynamic> data = const {}, String source = ''}) {
    _record(ObservabilityLevel.trace, category, message, data: data, source: source);
  }

  void debug(String category, String message, {Map<String, dynamic> data = const {}, String source = ''}) {
    _record(ObservabilityLevel.debug, category, message, data: data, source: source);
  }

  void info(String category, String message, {Map<String, dynamic> data = const {}, String source = ''}) {
    _record(ObservabilityLevel.info, category, message, data: data, source: source);
  }

  void warning(String category, String message, {Map<String, dynamic> data = const {}, String source = ''}) {
    _record(ObservabilityLevel.warning, category, message, data: data, source: source);
  }

  void error(String category, String message, {Map<String, dynamic> data = const {}, String source = ''}) {
    _record(ObservabilityLevel.error, category, message, data: data, source: source);
  }

  void fatal(String category, String message, {Map<String, dynamic> data = const {}, String source = ''}) {
    _record(ObservabilityLevel.fatal, category, message, data: data, source: source);
  }

  void recordStartup(String component, Duration duration, {bool success = true}) {
    info('startup', '$component initialized in ${duration.inMilliseconds}ms',
      data: {'durationMs': duration.inMilliseconds, 'success': success, 'component': component},
      source: 'ObservabilitySystem',
    );
  }

  void recordModuleInit(String moduleId, Duration duration, {bool success = true}) {
    info('module_init', 'Module "$moduleId" initialized in ${duration.inMilliseconds}ms',
      data: {'moduleId': moduleId, 'durationMs': duration.inMilliseconds, 'success': success},
      source: 'ObservabilitySystem',
    );
  }

  void recordServiceInit(String serviceId, Duration duration, {bool success = true}) {
    info('service_init', 'Service "$serviceId" initialized in ${duration.inMilliseconds}ms',
      data: {'serviceId': serviceId, 'durationMs': duration.inMilliseconds, 'success': success},
      source: 'ObservabilitySystem',
    );
  }

  void recordPluginLoad(String pluginId, Duration duration, {bool success = true}) {
    info('plugin_load', 'Plugin "$pluginId" loaded in ${duration.inMilliseconds}ms',
      data: {'pluginId': pluginId, 'durationMs': duration.inMilliseconds, 'success': success},
      source: 'ObservabilitySystem',
    );
  }

  void recordFeatureActivation(String featureId, bool enabled) {
    info('feature_activation', 'Feature "$featureId" ${enabled ? "enabled" : "disabled"}',
      data: {'featureId': featureId, 'enabled': enabled},
      source: 'ObservabilitySystem',
    );
  }

  void recordPerformance(String metric, double value, {String unit = 'ms'}) {
    debug('performance', '$metric: ${value.toStringAsFixed(2)}$unit',
      data: {'metric': metric, 'value': value, 'unit': unit},
      source: 'ObservabilitySystem',
    );
  }

  void _record(ObservabilityLevel level, String category, String message, {
    Map<String, dynamic> data = const {},
    String source = '',
  }) {
    if (!_enabled || level.index < _minLevel.index) return;
    final entry = ObservabilityEntry(
      level: level,
      category: category,
      message: message,
      data: data,
      source: source,
    );
    _entries.add(entry);
    _categoryCounts[category] = (_categoryCounts[category] ?? 0) + 1;
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
    _eventBus.publish(ObservabilityEvent(
      level: level,
      category: category,
      message: message,
      data: data,
      source: source,
    ));
  }

  List<ObservabilityEntry> getEntries({
    ObservabilityLevel? minLevel,
    String? category,
    int? limit,
  }) {
    var result = List<ObservabilityEntry>.from(_entries);
    if (minLevel != null) {
      result = result.where((e) => e.level.index >= minLevel.index).toList();
    }
    if (category != null) {
      result = result.where((e) => e.category == category).toList();
    }
    if (limit != null && result.length > limit) {
      result = result.sublist(result.length - limit);
    }
    return result;
  }

  Map<String, int> getCategoryCounts() => Map.unmodifiable(_categoryCounts);

  void setMinLevel(ObservabilityLevel level) => _minLevel = level;
  void clear() {
    _entries.clear();
    _categoryCounts.clear();
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalEntries': _entries.length,
      'enabled': _enabled,
      'minLevel': _minLevel.name,
      'categoryCounts': _categoryCounts,
      'levelCounts': {
        for (final level in ObservabilityLevel.values)
          level.name: _entries.where((e) => e.level == level).length,
      },
    };
  }
}
