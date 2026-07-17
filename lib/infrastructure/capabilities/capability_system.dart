class Capability {
  const Capability({
    required this.id,
    required this.name,
    this.description = '',
    this.version = '1.0.0',
    this.metadata = const {},
  });

  final String id;
  final String name;
  final String description;
  final String version;
  final Map<String, dynamic> metadata;
}

class CapabilityRegistry {
  CapabilityRegistry._();
  static final CapabilityRegistry instance = CapabilityRegistry._();

  final Map<String, List<Capability>> _moduleCapabilities = {};
  final Map<String, Capability> _allCapabilities = {};

  static const String generation = 'generation';
  static const String analysis = 'analysis';
  static const String import_ = 'import';
  static const String export = 'export';
  static const String theme = 'theme';
  static const String accessibility = 'accessibility';
  static const String diagnostics = 'diagnostics';
  static const String automation = 'automation';
  static const String workspace = 'workspace';
  static const String developer = 'developer';
  static const String enterprise = 'enterprise';
  static const String security = 'security';
  static const String storage = 'storage';
  static const String notification = 'notification';
  static const String plugin = 'plugin';

  void registerCapability(String moduleId, Capability capability) {
    _moduleCapabilities.putIfAbsent(moduleId, () => []).add(capability);
    _allCapabilities[capability.id] = capability;
  }

  void unregisterCapability(String moduleId, String capabilityId) {
    _moduleCapabilities[moduleId]?.removeWhere((c) => c.id == capabilityId);
    _allCapabilities.remove(capabilityId);
  }

  void unregisterModule(String moduleId) {
    final capabilities = _moduleCapabilities.remove(moduleId) ?? [];
    for (final cap in capabilities) {
      _allCapabilities.remove(cap.id);
    }
  }

  List<Capability> getCapabilitiesForModule(String moduleId) {
    return List.unmodifiable(_moduleCapabilities[moduleId] ?? []);
  }

  List<Capability> getModulesWithCapability(String capabilityId) {
    return _allCapabilities.values.where((c) => c.id == capabilityId).toList();
  }

  List<String> getModulesProviding(String capabilityId) {
    return _moduleCapabilities.entries
        .where((e) => e.value.any((c) => c.id == capabilityId))
        .map((e) => e.key)
        .toList();
  }

  bool moduleHasCapability(String moduleId, String capabilityId) {
    return _moduleCapabilities[moduleId]?.any((c) => c.id == capabilityId) ?? false;
  }

  List<Capability> getAllCapabilities() => List.unmodifiable(_allCapabilities.values);
  Set<String> getAvailableCapabilityIds() => Set.unmodifiable(_allCapabilities.keys);

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalCapabilities': _allCapabilities.length,
      'modulesWithCapabilities': _moduleCapabilities.length,
      'capabilityTypes': {
        for (final entry in _moduleCapabilities.entries)
          entry.key: entry.value.map((c) => c.id).toList(),
      },
      'allCapabilityIds': _allCapabilities.keys.toList(),
    };
  }
}
