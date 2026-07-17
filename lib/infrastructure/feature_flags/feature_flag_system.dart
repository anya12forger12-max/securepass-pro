enum FeatureFlagType { stable, experimental, developer, enterprise, deprecated }

enum FeatureFlagStatus { enabled, disabled, conditional }

class FeatureFlag {
  const FeatureFlag({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.defaultValue = false,
    this.status = FeatureFlagStatus.disabled,
    this.dependencies = const [],
    this.config = const {},
  });

  final String id;
  final String name;
  final FeatureFlagType type;
  final String description;
  final bool defaultValue;
  final FeatureFlagStatus status;
  final List<String> dependencies;
  final Map<String, dynamic> config;

  bool get isStable => type == FeatureFlagType.stable;
  bool get isExperimental => type == FeatureFlagType.experimental;
  bool get isDeveloper => type == FeatureFlagType.developer;
  bool get isEnterprise => type == FeatureFlagType.enterprise;
  bool get isDeprecated => type == FeatureFlagType.deprecated;

  FeatureFlag copyWith({
    FeatureFlagStatus? status,
    bool? defaultValue,
    Map<String, dynamic>? config,
  }) {
    return FeatureFlag(
      id: id,
      name: name,
      type: type,
      description: description,
      defaultValue: defaultValue ?? this.defaultValue,
      status: status ?? this.status,
      dependencies: dependencies,
      config: config ?? this.config,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'description': description,
    'defaultValue': defaultValue,
    'status': status.name,
    'dependencies': dependencies,
    'config': config,
  };

  factory FeatureFlag.fromMap(Map<String, dynamic> map) {
    return FeatureFlag(
      id: map['id'] as String,
      name: map['name'] as String,
      type: FeatureFlagType.values.firstWhere((e) => e.name == map['type']),
      description: (map['description'] as String?) ?? '',
      defaultValue: (map['defaultValue'] as bool?) ?? false,
      status: FeatureFlagStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FeatureFlagStatus.disabled,
      ),
      dependencies: (map['dependencies'] as List<dynamic>?)?.cast<String>() ?? const [],
      config: (map['config'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

class FeatureFlagOverride {
  const FeatureFlagOverride({
    required this.flagId,
    required this.value,
    this.reason = '',
    this.expiresAt,
  });

  final String flagId;
  final bool value;
  final String reason;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

class FeatureFlagSystem {
  FeatureFlagSystem._();
  static final FeatureFlagSystem instance = FeatureFlagSystem._();

  final Map<String, FeatureFlag> _flags = {};
  final Map<String, FeatureFlagOverride> _overrides = {};
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _registerDefaults();
    _initialized = true;
  }

  void _registerDefaults() {
    register(const FeatureFlag(
      id: 'v2_migration_framework',
      name: 'V2 Migration Framework',
      type: FeatureFlagType.stable,
      description: 'Enables the Version 2 migration framework',
      defaultValue: true,
      status: FeatureFlagStatus.enabled,
    ));
    register(const FeatureFlag(
      id: 'v2_feature_flags',
      name: 'V2 Feature Flags',
      type: FeatureFlagType.stable,
      description: 'Enables the feature flag system',
      defaultValue: true,
      status: FeatureFlagStatus.enabled,
    ));
    register(const FeatureFlag(
      id: 'v2_module_registry',
      name: 'V2 Module Registry',
      type: FeatureFlagType.stable,
      description: 'Enables the module registry',
      defaultValue: true,
      status: FeatureFlagStatus.enabled,
    ));
    register(const FeatureFlag(
      id: 'v2_service_registry',
      name: 'V2 Service Registry',
      type: FeatureFlagType.stable,
      description: 'Enables the service registry',
      defaultValue: true,
      status: FeatureFlagStatus.enabled,
    ));
    register(const FeatureFlag(
      id: 'v2_event_bus',
      name: 'V2 Event Bus',
      type: FeatureFlagType.stable,
      description: 'Enables the centralized event bus',
      defaultValue: true,
      status: FeatureFlagStatus.enabled,
    ));
    register(const FeatureFlag(
      id: 'v2_extension_api',
      name: 'V2 Extension API',
      type: FeatureFlagType.stable,
      description: 'Enables the extension API',
      defaultValue: true,
      status: FeatureFlagStatus.enabled,
    ));
    register(const FeatureFlag(
      id: 'experimental_ai_analysis',
      name: 'AI-Powered Analysis',
      type: FeatureFlagType.experimental,
      description: 'Experimental AI-based password analysis',
      dependencies: ['v2_extension_api'],
    ));
    register(const FeatureFlag(
      id: 'developer_diagnostics_ui',
      name: 'Developer Diagnostics UI',
      type: FeatureFlagType.developer,
      description: 'Advanced developer diagnostics panel',
    ));
    register(const FeatureFlag(
      id: 'enterprise_audit_log',
      name: 'Enterprise Audit Log',
      type: FeatureFlagType.enterprise,
      description: 'Enterprise-grade audit logging',
    ));
    register(const FeatureFlag(
      id: 'legacy_import_v0',
      name: 'Legacy Import v0',
      type: FeatureFlagType.deprecated,
      description: 'Support for v0 import format',
      status: FeatureFlagStatus.disabled,
    ));
  }

  void register(FeatureFlag flag) {
    _flags[flag.id] = flag;
  }

  void unregister(String id) {
    _flags.remove(id);
    _overrides.remove(id);
  }

  bool isEnabled(String id) {
    final override = _overrides[id];
    if (override != null && !override.isExpired) return override.value;
    final flag = _flags[id];
    if (flag == null) return false;
    if (flag.status == FeatureFlagStatus.disabled) return false;
    if (flag.status == FeatureFlagStatus.enabled) return _checkDependencies(flag);
    return flag.defaultValue && _checkDependencies(flag);
  }

  bool _checkDependencies(FeatureFlag flag) {
    for (final depId in flag.dependencies) {
      if (!isEnabled(depId)) return false;
    }
    return true;
  }

  void setOverride(FeatureFlagOverride override) {
    _overrides[override.flagId] = override;
  }

  void removeOverride(String flagId) {
    _overrides.remove(flagId);
  }

  FeatureFlag? getFlag(String id) => _flags[id];
  List<FeatureFlag> getAllFlags() => List.unmodifiable(_flags.values);
  List<FeatureFlag> getFlagsByType(FeatureFlagType type) =>
      _flags.values.where((f) => f.type == type).toList();
  Map<String, bool> evaluateAll() {
    return Map.fromEntries(_flags.keys.map((id) => MapEntry(id, isEnabled(id))));
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalFlags': _flags.length,
      'enabledFlags': _flags.keys.where(isEnabled).length,
      'overrides': _overrides.length,
      'flagsByType': {
        for (final type in FeatureFlagType.values)
          type.name: _flags.values.where((f) => f.type == type).length,
      },
      'flags': {
        for (final entry in _flags.entries)
          entry.key: {
            'type': entry.value.type.name,
            'enabled': isEnabled(entry.key),
            'status': entry.value.status.name,
          },
      },
    };
  }
}
