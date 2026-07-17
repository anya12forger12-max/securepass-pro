enum ResourceType { font, icon, image, localization, theme, plugin, workspace, documentation, cache, temporary }

class ResourceMetadata {
  const ResourceMetadata({
    required this.id,
    required this.type,
    required this.name,
    this.path = '',
    this.sizeBytes = 0,
    this.loaded = false,
    this.tags = const [],
  });

  final String id;
  final ResourceType type;
  final String name;
  final String path;
  final int sizeBytes;
  final bool loaded;
  final List<String> tags;

  ResourceMetadata copyWith({bool? loaded}) => ResourceMetadata(
    id: id, type: type, name: name, path: path, sizeBytes: sizeBytes,
    loaded: loaded ?? this.loaded, tags: tags,
  );
}

class ResourceManager {
  ResourceManager._();
  static final ResourceManager instance = ResourceManager._();

  final Map<String, ResourceMetadata> _resources = {};
  final Map<String, dynamic> _loadedResources = {};
  final Set<String> _tempResources = {};
  int _totalMemoryBytes = 0;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
  }

  void register(ResourceMetadata resource) {
    _resources[resource.id] = resource;
  }

  void unregister(String resourceId) {
    _resources.remove(resourceId);
    _loadedResources.remove(resourceId);
    _tempResources.remove(resourceId);
  }

  T? getResource<T>(String resourceId) {
    return _loadedResources[resourceId] as T?;
  }

  void loadResource(String resourceId, dynamic resource) {
    _loadedResources[resourceId] = resource;
    final meta = _resources[resourceId];
    if (meta != null) {
      _resources[resourceId] = meta.copyWith(loaded: true);
      _totalMemoryBytes += meta.sizeBytes;
    }
  }

  void unloadResource(String resourceId) {
    _loadedResources.remove(resourceId);
    final meta = _resources[resourceId];
    if (meta != null) {
      _resources[resourceId] = meta.copyWith(loaded: false);
      _totalMemoryBytes -= meta.sizeBytes;
      if (_totalMemoryBytes < 0) _totalMemoryBytes = 0;
    }
  }

  void registerTemp(String resourceId, dynamic resource) {
    _tempResources.add(resourceId);
    _loadedResources[resourceId] = resource;
  }

  void cleanupTemp() {
    for (final id in _tempResources) {
      _loadedResources.remove(id);
    }
    _tempResources.clear();
  }

  List<ResourceMetadata> getResourcesByType(ResourceType type) {
    return _resources.values.where((r) => r.type == type).toList();
  }

  List<ResourceMetadata> getLoadedResources() {
    return _resources.values.where((r) => r.loaded).toList();
  }

  List<ResourceMetadata> getUnloadedResources() {
    return _resources.values.where((r) => !r.loaded).toList();
  }

  void loadAllOfType(ResourceType type) {
    for (final resource in getResourcesByType(type)) {
      if (!resource.loaded) {
        loadResource(resource.id, resource.path);
      }
    }
  }

  int get totalMemoryBytes => _totalMemoryBytes;
  int get resourceCount => _resources.length;
  int get loadedCount => _loadedResources.length;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> getDiagnostics() {
    final byType = <String, int>{};
    for (final type in ResourceType.values) {
      byType[type.name] = getResourcesByType(type).length;
    }
    return {
      'totalResources': _resources.length,
      'loadedResources': _loadedResources.length,
      'tempResources': _tempResources.length,
      'totalMemoryBytes': _totalMemoryBytes,
      'totalMemoryDisplay': _formatBytes(_totalMemoryBytes),
      'resourcesByType': byType,
    };
  }
}
