import 'package:securepass_pro/infrastructure/versioning/semantic_version.dart';

enum CompatibilityStatus { compatible, incompatible, deprecated, unknown }

class CompatibilityEntry {
  const CompatibilityEntry({
    required this.componentId,
    required this.componentVersion,
    required this.compatibleVersions,
    this.status = CompatibilityStatus.compatible,
    this.notes = '',
  });

  final String componentId;
  final SemanticVersion componentVersion;
  final VersionRange compatibleVersions;
  final CompatibilityStatus status;
  final String notes;
}

class CompatibilityCheckResult {
  const CompatibilityCheckResult({
    required this.componentId,
    required this.componentVersion,
    required this.appVersion,
    required this.status,
    this.message = '',
  });

  final String componentId;
  final SemanticVersion componentVersion;
  final SemanticVersion appVersion;
  final CompatibilityStatus status;
  final String message;
}

class CompatibilityFramework {
  CompatibilityFramework._();
  static final CompatibilityFramework instance = CompatibilityFramework._();

  final Map<String, CompatibilityEntry> _entries = {};
  final List<CompatibilityCheckResult> _checkHistory = [];

  void register(CompatibilityEntry entry) {
    _entries[entry.componentId] = entry;
  }

  void unregister(String componentId) {
    _entries.remove(componentId);
  }

  CompatibilityCheckResult checkCompatibility(String componentId, SemanticVersion appVersion) {
    final entry = _entries[componentId];
    if (entry == null) {
      return CompatibilityCheckResult(
        componentId: componentId,
        componentVersion: SemanticVersion.zero,
        appVersion: appVersion,
        status: CompatibilityStatus.unknown,
        message: 'Component not registered',
      );
    }
    final isCompatible = entry.compatibleVersions.contains(appVersion);
    final result = CompatibilityCheckResult(
      componentId: componentId,
      componentVersion: entry.componentVersion,
      appVersion: appVersion,
      status: isCompatible ? entry.status : CompatibilityStatus.incompatible,
      message: isCompatible
          ? 'Compatible with app version $appVersion'
          : 'Incompatible with app version $appVersion',
    );
    _checkHistory.add(result);
    return result;
  }

  List<CompatibilityCheckResult> checkAll(SemanticVersion appVersion) {
    return _entries.keys.map((id) => checkCompatibility(id, appVersion)).toList();
  }

  bool isVersion1BackupCompatible(Map<String, dynamic> backupData) {
    final version = backupData['version'] as String?;
    if (version == null) return true;
    try {
      final backupVersion = SemanticVersion.parse(version);
      return backupVersion.isBackwardCompatibleWith(SemanticVersion.v1_0_0);
    } catch (_) {
      return true;
    }
  }

  bool isVersion1WorkspaceCompatible(Map<String, dynamic> workspaceData) {
    return workspaceData.containsKey('id') && workspaceData.containsKey('name');
  }

  bool isVersion1ThemeCompatible(Map<String, dynamic> themeData) {
    return themeData.containsKey('mode') || themeData.containsKey('theme_mode');
  }

  bool isVersion1AccessibilityCompatible(Map<String, dynamic> profileData) {
    return profileData.containsKey('preset') || profileData.containsKey('accessibility_preset');
  }

  List<CompatibilityCheckResult> getCheckHistory() => List.unmodifiable(_checkHistory);

  Map<String, dynamic> getDiagnostics() {
    return {
      'registeredComponents': _entries.length,
      'checksPerformed': _checkHistory.length,
      'incompatibleComponents': _checkHistory.where((c) => c.status == CompatibilityStatus.incompatible).length,
      'components': {
        for (final entry in _entries.entries)
          entry.key: {
            'version': entry.value.componentVersion.toString(),
            'status': entry.value.status.name,
          },
      },
    };
  }
}
