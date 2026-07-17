enum ConfigValidationStatus { valid, warning, error, migrated }

class ConfigSchemaVersion {
  const ConfigSchemaVersion({
    required this.version,
    required this.description,
    this.migrationRequired = false,
  });

  final int version;
  final String description;
  final bool migrationRequired;
}

class ConfigValidationResult {
  const ConfigValidationResult({
    required this.status,
    this.issues = const [],
    this.warnings = const [],
    this.migratedKeys = const [],
  });

  final ConfigValidationStatus status;
  final List<String> issues;
  final List<String> warnings;
  final List<String> migratedKeys;

  bool get isValid => status == ConfigValidationStatus.valid || status == ConfigValidationStatus.migrated;
}

class ConfigMigration {
  const ConfigMigration({
    required this.fromVersion,
    required this.toVersion,
    required this.description,
    required this.migrate,
  });

  final int fromVersion;
  final int toVersion;
  final String description;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> config) migrate;
}

class ConfigEvolutionManager {
  ConfigEvolutionManager._();
  static final ConfigEvolutionManager instance = ConfigEvolutionManager._();

  int _currentSchemaVersion = 1;
  final List<ConfigSchemaVersion> _schemaVersions = [];
  final List<ConfigMigration> _migrations = [];
  final List<ConfigValidationResult> _validationHistory = [];

  int get currentSchemaVersion => _currentSchemaVersion;

  void initialize() {
    _schemaVersions.add(const ConfigSchemaVersion(
      version: 1,
      description: 'Initial configuration schema',
    ));
  }

  void registerSchemaVersion(ConfigSchemaVersion version) {
    _schemaVersions.add(version);
  }

  void registerMigration(ConfigMigration migration) {
    _migrations.add(migration);
  }

  ConfigValidationResult validateConfig(Map<String, dynamic> config) {
    final issues = <String>[];
    final warnings = <String>[];

    for (final key in config.keys) {
      if (key.startsWith('_')) continue;
      if (config[key] == null) {
        warnings.add('Null value for key: $key');
      }
    }

    final requiredKeys = ['app_name', 'version', 'theme_mode', 'privacy_mode'];
    for (final key in requiredKeys) {
      if (!config.containsKey(key)) {
        issues.add('Missing required key: $key');
      }
    }

    final result = ConfigValidationResult(
      status: issues.isEmpty
          ? (warnings.isEmpty ? ConfigValidationStatus.valid : ConfigValidationStatus.warning)
          : ConfigValidationStatus.error,
      issues: issues,
      warnings: warnings,
    );
    _validationHistory.add(result);
    return result;
  }

  Future<Map<String, dynamic>> migrateConfig(Map<String, dynamic> config, int targetVersion) async {
    var current = Map<String, dynamic>.from(config);
    final applicable = _migrations
        .where((m) => m.fromVersion >= _currentSchemaVersion && m.toVersion <= targetVersion)
        .toList()
      ..sort((a, b) => a.fromVersion.compareTo(b.fromVersion));
    for (final migration in applicable) {
      try {
        current = await migration.migrate(current);
      } catch (_) {}
    }
    _currentSchemaVersion = targetVersion;
    return current;
  }

  Future<bool> rollbackConfig(Map<String, dynamic> config, int targetVersion) async {
    final applicable = _migrations
        .where((m) => m.toVersion > targetVersion && m.fromVersion <= _currentSchemaVersion)
        .toList()
      ..sort((a, b) => b.fromVersion.compareTo(a.fromVersion));
    if (applicable.isEmpty) return false;
    _currentSchemaVersion = targetVersion;
    return true;
  }

  Map<String, dynamic> repairConfig(Map<String, dynamic> config) {
    final repaired = Map<String, dynamic>.from(config);
    repaired.removeWhere((key, value) => key.startsWith('_') && key != '_schemaVersion');
    for (final key in config.keys) {
      if (config[key] is String && (config[key] as String).isEmpty) {
        repaired.remove(key);
      }
    }
    return repaired;
  }

  ConfigValidationResult getValidationReport() {
    if (_validationHistory.isEmpty) {
      return const ConfigValidationResult(status: ConfigValidationStatus.valid);
    }
    return _validationHistory.last;
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'currentSchemaVersion': _currentSchemaVersion,
      'registeredVersions': _schemaVersions.length,
      'registeredMigrations': _migrations.length,
      'validationHistory': _validationHistory.length,
    };
  }
}
