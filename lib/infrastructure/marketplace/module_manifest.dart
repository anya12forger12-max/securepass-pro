import 'package:securepass_pro/infrastructure/versioning/semantic_version.dart';

enum ManifestStatus { valid, invalid, warning }

class ModuleManifest {
  const ModuleManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    this.description = '',
    this.homepage = '',
    this.license = '',
    this.minAppVersion = '1.0.0',
    this.maxAppVersion,
    this.dependencies = const [],
    this.capabilities = const [],
    this.permissions = const [],
    this.keywords = const [],
    this.entryPoint = 'main.dart',
    this.metadata = const {},
  });

  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final String homepage;
  final String license;
  final String minAppVersion;
  final String? maxAppVersion;
  final List<ManifestDependency> dependencies;
  final List<String> capabilities;
  final List<String> permissions;
  final List<String> keywords;
  final String entryPoint;
  final Map<String, dynamic> metadata;

  SemanticVersion get parsedVersion => SemanticVersion.parse(version);
  SemanticVersion get parsedMinAppVersion => SemanticVersion.parse(minAppVersion);
  SemanticVersion? get parsedMaxAppVersion => maxAppVersion != null ? SemanticVersion.parse(maxAppVersion!) : null;

  factory ModuleManifest.fromMap(Map<String, dynamic> map) {
    return ModuleManifest(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      version: map['version'] as String? ?? '1.0.0',
      author: map['author'] as String? ?? '',
      description: map['description'] as String? ?? '',
      homepage: map['homepage'] as String? ?? '',
      license: map['license'] as String? ?? '',
      minAppVersion: map['minAppVersion'] as String? ?? '1.0.0',
      maxAppVersion: map['maxAppVersion'] as String?,
      dependencies: (map['dependencies'] as List<dynamic>?)
          ?.map((d) => ManifestDependency.fromMap(d as Map<String, dynamic>))
          .toList() ?? [],
      capabilities: (map['capabilities'] as List<dynamic>?)?.cast<String>() ?? [],
      permissions: (map['permissions'] as List<dynamic>?)?.cast<String>() ?? [],
      keywords: (map['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
      entryPoint: map['entryPoint'] as String? ?? 'main.dart',
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'version': version,
    'author': author,
    'description': description,
    'homepage': homepage,
    'license': license,
    'minAppVersion': minAppVersion,
    'maxAppVersion': maxAppVersion,
    'dependencies': dependencies.map((d) => d.toMap()).toList(),
    'capabilities': capabilities,
    'permissions': permissions,
    'keywords': keywords,
    'entryPoint': entryPoint,
    'metadata': metadata,
  };
}

class ManifestDependency {
  const ManifestDependency({required this.id, required this.versionRange, this.optional = false});
  final String id;
  final String versionRange;
  final bool optional;

  factory ManifestDependency.fromMap(Map<String, dynamic> map) {
    return ManifestDependency(
      id: map['id'] as String? ?? '',
      versionRange: map['versionRange'] as String? ?? '*',
      optional: map['optional'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'versionRange': versionRange, 'optional': optional};
}

class ManifestValidation {
  const ManifestValidation({required this.status, this.errors = const [], this.warnings = const []});
  final ManifestStatus status;
  final List<String> errors;
  final List<String> warnings;
  bool get isValid => status != ManifestStatus.invalid;
}

class MarketplaceFoundation {
  MarketplaceFoundation._();
  static final MarketplaceFoundation instance = MarketplaceFoundation._();

  final Map<String, ModuleManifest> _manifests = {};

  void registerManifest(ModuleManifest manifest) {
    _manifests[manifest.id] = manifest;
  }

  void unregisterManifest(String moduleId) {
    _manifests.remove(moduleId);
  }

  ModuleManifest? getManifest(String moduleId) => _manifests[moduleId];
  List<ModuleManifest> getAllManifests() => List.unmodifiable(_manifests.values);

  ManifestValidation validateManifest(ModuleManifest manifest) {
    final errors = <String>[];
    final warnings = <String>[];
    if (manifest.id.isEmpty) errors.add('Module ID is required');
    if (manifest.name.isEmpty) errors.add('Module name is required');
    if (manifest.author.isEmpty) warnings.add('Author is missing');
    try {
      SemanticVersion.parse(manifest.version);
    } catch (_) {
      errors.add('Invalid version format');
    }
    try {
      SemanticVersion.parse(manifest.minAppVersion);
    } catch (_) {
      errors.add('Invalid minAppVersion format');
    }
    for (final dep in manifest.dependencies) {
      if (dep.id.isEmpty) errors.add('Dependency ID cannot be empty');
    }
    return ManifestValidation(
      status: errors.isEmpty ? (warnings.isEmpty ? ManifestStatus.valid : ManifestStatus.warning) : ManifestStatus.invalid,
      errors: errors,
      warnings: warnings,
    );
  }

  bool checkCompatibility(ModuleManifest manifest, SemanticVersion appVersion) {
    if (appVersion.compareTo(manifest.parsedMinAppVersion) < 0) return false;
    if (manifest.parsedMaxAppVersion != null && appVersion.compareTo(manifest.parsedMaxAppVersion!) > 0) return false;
    return true;
  }

  List<ManifestDependency> resolveDependencies(String moduleId) {
    final manifest = _manifests[moduleId];
    if (manifest == null) return [];
    return manifest.dependencies;
  }

  bool validateDependencies(String moduleId, [Set<String>? visited]) {
    visited = visited ?? {};
    if (visited.contains(moduleId)) return false;
    visited.add(moduleId);
    final manifest = _manifests[moduleId];
    if (manifest == null) return false;
    for (final dep in manifest.dependencies) {
      if (!dep.optional && !_manifests.containsKey(dep.id)) return false;
      if (!dep.optional && !validateDependencies(dep.id, visited)) return false;
    }
    return true;
  }

  ModuleManifest? negotiateVersion(String moduleId, SemanticVersion appVersion) {
    final manifest = _manifests[moduleId];
    if (manifest == null) return null;
    if (checkCompatibility(manifest, appVersion)) return manifest;
    return null;
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalManifests': _manifests.length,
      'validManifests': _manifests.values.where((m) => validateManifest(m).isValid).length,
      'modules': _manifests.keys.toList(),
    };
  }
}
