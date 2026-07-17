enum FeaturePriority { critical, high, normal, low, deferred }

enum FeatureLoadStrategy { eager, lazy, onDemand, conditional }

class FeatureDescriptor {
  const FeatureDescriptor({
    required this.id,
    required this.name,
    this.description = '',
    this.version = '1.0.0',
    this.priority = FeaturePriority.normal,
    this.loadStrategy = FeatureLoadStrategy.eager,
    this.dependencies = const [],
    this.conflictsWith = const [],
    this.condition = '',
    this.isEnabled = true,
    this.metadata = const {},
  });

  final String id;
  final String name;
  final String description;
  final String version;
  final FeaturePriority priority;
  final FeatureLoadStrategy loadStrategy;
  final List<String> dependencies;
  final List<String> conflictsWith;
  final String condition;
  final bool isEnabled;
  final Map<String, dynamic> metadata;
}

class FeatureEntry {
  FeatureEntry({required this.descriptor});
  final FeatureDescriptor descriptor;
  bool isLoaded = false;
  bool isActive = false;
  DateTime? loadedAt;
  DateTime? activatedAt;
  double loadTimeMs = 0;
}

class CompositionEngine {
  CompositionEngine._();
  static final CompositionEngine instance = CompositionEngine._();

  final Map<String, FeatureEntry> _features = {};
  final List<String> _loadOrder = [];
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
  }

  void registerFeature(FeatureDescriptor feature) {
    if (_features.containsKey(feature.id)) return;
    _features[feature.id] = FeatureEntry(descriptor: feature);
    _resolveLoadOrder();
  }

  void unregisterFeature(String featureId) {
    _features.remove(featureId);
    _loadOrder.remove(featureId);
  }

  Future<void> loadFeature(String featureId) async {
    final entry = _features[featureId];
    if (entry == null || entry.isLoaded) return;
    if (!entry.descriptor.isEnabled) return;

    for (final depId in entry.descriptor.dependencies) {
      final dep = _features[depId];
      if (dep == null || !dep.descriptor.isEnabled) {
        return; // Dependency missing or disabled
      }
      if (!dep.isLoaded) await loadFeature(depId);
    }

    for (final conflictId in entry.descriptor.conflictsWith) {
      final conflict = _features[conflictId];
      if (conflict != null && conflict.isActive) {
        return; // Conflict active
      }
    }

    final sw = Stopwatch()..start();
    entry.isLoaded = true;
    entry.loadedAt = DateTime.now();
    sw.stop();
    entry.loadTimeMs = sw.elapsedMicroseconds / 1000.0;
  }

  Future<void> activateFeature(String featureId) async {
    final entry = _features[featureId];
    if (entry == null || !entry.isLoaded) {
      await loadFeature(featureId);
    }
    final loaded = _features[featureId];
    if (loaded != null && loaded.isLoaded) {
      loaded.isActive = true;
      loaded.activatedAt = DateTime.now();
    }
  }

  void deactivateFeature(String featureId) {
    final entry = _features[featureId];
    if (entry != null) {
      entry.isActive = false;
    }
  }

  Future<void> loadAll() async {
    _resolveLoadOrder();
    for (final featureId in _loadOrder) {
      await loadFeature(featureId);
    }
  }

  Future<void> activateAll() async {
    for (final featureId in _loadOrder) {
      await activateFeature(featureId);
    }
  }

  void replaceFeature(String oldFeatureId, FeatureDescriptor newDescriptor) {
    final wasActive = _features[oldFeatureId]?.isActive ?? false;
    _features.remove(oldFeatureId);
    registerFeature(newDescriptor);
    if (wasActive) {
      activateFeature(newDescriptor.id);
    }
  }

  void _resolveLoadOrder() {
    _loadOrder.clear();
    final visited = <String>{};
    void visit(String id) {
      if (visited.contains(id)) return;
      visited.add(id);
      final entry = _features[id];
      if (entry != null) {
        for (final depId in entry.descriptor.dependencies) {
          visit(depId);
        }
      }
      _loadOrder.add(id);
    }

    final sorted = _features.entries.toList()
      ..sort((a, b) => a.value.descriptor.priority.index.compareTo(b.value.descriptor.priority.index));
    for (final entry in sorted) {
      visit(entry.key);
    }
  }

  FeatureEntry? getFeature(String featureId) => _features[featureId];
  List<FeatureEntry> getAllFeatures() => List.unmodifiable(_features.values);
  List<FeatureEntry> getActiveFeatures() => _features.values.where((f) => f.isActive).toList();
  List<FeatureEntry> getLoadedFeatures() => _features.values.where((f) => f.isLoaded).toList();
  bool isFeatureActive(String featureId) => _features[featureId]?.isActive ?? false;
  List<String> getLoadOrder() => List.unmodifiable(_loadOrder);

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalFeatures': _features.length,
      'activeFeatures': getActiveFeatures().length,
      'loadedFeatures': getLoadedFeatures().length,
      'loadOrder': _loadOrder,
      'features': {
        for (final entry in _features.entries)
          entry.key: {
            'priority': entry.value.descriptor.priority.name,
            'loadStrategy': entry.value.descriptor.loadStrategy.name,
            'isLoaded': entry.value.isLoaded,
            'isActive': entry.value.isActive,
            'loadTimeMs': entry.value.loadTimeMs,
          },
      },
    };
  }
}
