class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease = '',
    this.buildMetadata = '',
  });

  final int major;
  final int minor;
  final int patch;
  final String preRelease;
  final String buildMetadata;

  static const SemanticVersion zero = SemanticVersion(major: 0, minor: 0, patch: 0);
  static const SemanticVersion v1_0_0 = SemanticVersion(major: 1, minor: 0, patch: 0);
  static const SemanticVersion v2_0_0 = SemanticVersion(major: 2, minor: 0, patch: 0);

  factory SemanticVersion.parse(String version) {
    final withoutMetadata = version.split('+').first;
    final parts = withoutMetadata.split('-');
    final versionParts = parts.first.split('.');
    if (versionParts.length < 3) {
      throw FormatException('Invalid semantic version: $version');
    }
    return SemanticVersion(
      major: int.parse(versionParts[0]),
      minor: int.parse(versionParts[1]),
      patch: int.parse(versionParts[2]),
      preRelease: parts.length > 1 ? parts.sublist(1).join('-') : '',
      buildMetadata: version.contains('+') ? version.split('+').last : '',
    );
  }

  String get majorVersion => '$major.0.0';
  String get minorVersion => '$major.$minor.0';

  bool get isPreRelease => preRelease.isNotEmpty;
  bool get isStable => !isPreRelease;
  bool get isZero => major == 0 && minor == 0 && patch == 0;

  SemanticVersion incrementMajor() => SemanticVersion(major: major + 1, minor: 0, patch: 0);
  SemanticVersion incrementMinor() => SemanticVersion(major: major, minor: minor + 1, patch: 0);
  SemanticVersion incrementPatch() => SemanticVersion(major: major, minor: minor, patch: patch + 1);

  bool isBackwardCompatibleWith(SemanticVersion other) {
    if (isZero || other.isZero) return false;
    if (major != other.major) return false;
    return true;
  }

  bool isCompatibleWith(SemanticVersion other) {
    return major == other.major;
  }

  bool satisfiesRange(SemanticVersion min, SemanticVersion max) {
    return compareTo(min) >= 0 && compareTo(max) <= 0;
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    if (preRelease.isEmpty && other.preRelease.isNotEmpty) return 1;
    if (preRelease.isNotEmpty && other.preRelease.isEmpty) return -1;
    return preRelease.compareTo(other.preRelease);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticVersion &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          preRelease == other.preRelease;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);

  @override
  String toString() {
    final buffer = StringBuffer('$major.$minor.$patch');
    if (preRelease.isNotEmpty) buffer.write('-$preRelease');
    if (buildMetadata.isNotEmpty) buffer.write('+$buildMetadata');
    return buffer.toString();
  }
}

class VersionRange {
  const VersionRange({this.min, this.max, this.minInclusive = true, this.maxInclusive = true});

  final SemanticVersion? min;
  final SemanticVersion? max;
  final bool minInclusive;
  final bool maxInclusive;

  bool contains(SemanticVersion version) {
    if (min != null) {
      final cmp = version.compareTo(min!);
      if (minInclusive ? cmp < 0 : cmp <= 0) return false;
    }
    if (max != null) {
      final cmp = version.compareTo(max!);
      if (maxInclusive ? cmp > 0 : cmp >= 0) return false;
    }
    return true;
  }

  factory VersionRange.exact(SemanticVersion version) =>
      VersionRange(min: version, max: version);

  factory VersionRange.atLeast(SemanticVersion min) =>
      VersionRange(min: min);

  factory VersionRange.between(SemanticVersion min, SemanticVersion max) =>
      VersionRange(min: min, max: max);
}
