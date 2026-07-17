import 'package:securepass_pro/infrastructure/versioning/semantic_version.dart';

class VersionManager {
  VersionManager._();
  static final VersionManager instance = VersionManager._();

  SemanticVersion _appVersion = SemanticVersion.v1_0_0;
  final Map<String, SemanticVersion> _componentVersions = {};
  final Map<String, VersionRange> _compatibilityMatrix = {};

  SemanticVersion get appVersion => _appVersion;
  Map<String, SemanticVersion> get componentVersions => Map.unmodifiable(_componentVersions);

  void setAppVersion(SemanticVersion version) {
    _appVersion = version;
  }

  void setComponentVersion(String componentId, SemanticVersion version) {
    _componentVersions[componentId] = version;
  }

  SemanticVersion? getComponentVersion(String componentId) {
    return _componentVersions[componentId];
  }

  void registerCompatibility(String componentId, VersionRange range) {
    _compatibilityMatrix[componentId] = range;
  }

  bool isCompatible(String componentId, SemanticVersion version) {
    final range = _compatibilityMatrix[componentId];
    if (range == null) return true;
    return range.contains(version);
  }

  bool isBackwardCompatible(SemanticVersion oldVersion, SemanticVersion newVersion) {
    if (oldVersion.isZero || newVersion.isZero) return false;
    return newVersion.isBackwardCompatibleWith(oldVersion);
  }

  Map<String, dynamic> getVersionReport() {
    return {
      'appVersion': _appVersion.toString(),
      'components': _componentVersions.map((k, v) => MapEntry(k, v.toString())),
      'compatibility': _compatibilityMatrix.map(
        (k, v) => MapEntry(k, {'min': v.min?.toString(), 'max': v.max?.toString()}),
      ),
    };
  }
}
