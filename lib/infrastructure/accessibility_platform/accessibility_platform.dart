enum AccessibilityLevel { basic, standard, enhanced, maximum }

class AccessibilityProfile {
  const AccessibilityProfile({
    required this.id,
    required this.name,
    this.level = AccessibilityLevel.standard,
    this.textScaleFactor = 1.0,
    this.enableHighContrast = false,
    this.enableReducedMotion = false,
    this.enableScreenReader = false,
    this.enableLargeText = false,
    this.enableDyslexiaFriendly = false,
    this.minTouchTarget = 44.0,
    this.enableHapticFeedback = true,
    this.enableSemanticLabels = true,
    this.metadata = const {},
  });

  final String id;
  final String name;
  final AccessibilityLevel level;
  final double textScaleFactor;
  final bool enableHighContrast;
  final bool enableReducedMotion;
  final bool enableScreenReader;
  final bool enableLargeText;
  final bool enableDyslexiaFriendly;
  final double minTouchTarget;
  final bool enableHapticFeedback;
  final bool enableSemanticLabels;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'level': level.name,
    'textScaleFactor': textScaleFactor,
    'enableHighContrast': enableHighContrast,
    'enableReducedMotion': enableReducedMotion,
    'enableScreenReader': enableScreenReader,
    'enableLargeText': enableLargeText,
    'enableDyslexiaFriendly': enableDyslexiaFriendly,
    'minTouchTarget': minTouchTarget,
    'enableHapticFeedback': enableHapticFeedback,
    'enableSemanticLabels': enableSemanticLabels,
  };

  factory AccessibilityProfile.fromMap(Map<String, dynamic> map) {
    return AccessibilityProfile(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      level: AccessibilityLevel.values.firstWhere(
        (e) => e.name == map['level'],
        orElse: () => AccessibilityLevel.standard,
      ),
      textScaleFactor: (map['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
      enableHighContrast: map['enableHighContrast'] as bool? ?? false,
      enableReducedMotion: map['enableReducedMotion'] as bool? ?? false,
      enableScreenReader: map['enableScreenReader'] as bool? ?? false,
      enableLargeText: map['enableLargeText'] as bool? ?? false,
      enableDyslexiaFriendly: map['enableDyslexiaFriendly'] as bool? ?? false,
      minTouchTarget: (map['minTouchTarget'] as num?)?.toDouble() ?? 44.0,
      enableHapticFeedback: map['enableHapticFeedback'] as bool? ?? true,
      enableSemanticLabels: map['enableSemanticLabels'] as bool? ?? true,
    );
  }
}

class AccessibilityValidation {
  const AccessibilityValidation({
    required this.passed,
    this.issues = const [],
    this.score = 100,
  });

  final bool passed;
  final List<String> issues;
  final int score;
}

class ComponentAccessibilityMetadata {
  const ComponentAccessibilityMetadata({
    required this.componentId,
    this.semanticsLabel = '',
    this.semanticsHint = '',
    this.isFocusable = true,
    this.supportsScreenReader = true,
    this.minimumTapTarget = 44.0,
    this.tags = const [],
  });

  final String componentId;
  final String semanticsLabel;
  final String semanticsHint;
  final bool isFocusable;
  final bool supportsScreenReader;
  final double minimumTapTarget;
  final List<String> tags;
}

class AccessibilityPlatform {
  AccessibilityPlatform._();
  static final AccessibilityPlatform instance = AccessibilityPlatform._();

  AccessibilityProfile _currentProfile = const AccessibilityProfile(id: 'default', name: 'Default');
  final Map<String, AccessibilityProfile> _profiles = {};
  final Map<String, ComponentAccessibilityMetadata> _componentMetadata = {};
  final List<AccessibilityValidation> _validationHistory = [];
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _registerDefaults();
    _initialized = true;
  }

  void _registerDefaults() {
    registerProfile(const AccessibilityProfile(
      id: 'default', name: 'Default', level: AccessibilityLevel.standard,
    ));
    registerProfile(const AccessibilityProfile(
      id: 'high_contrast', name: 'High Contrast', level: AccessibilityLevel.enhanced,
      enableHighContrast: true, textScaleFactor: 1.2,
    ));
    registerProfile(const AccessibilityProfile(
      id: 'screen_reader', name: 'Screen Reader', level: AccessibilityLevel.maximum,
      enableScreenReader: true, enableSemanticLabels: true, enableHapticFeedback: true,
    ));
    registerProfile(const AccessibilityProfile(
      id: 'reduced_motion', name: 'Reduced Motion', level: AccessibilityLevel.enhanced,
      enableReducedMotion: true,
    ));
    registerProfile(const AccessibilityProfile(
      id: 'large_text', name: 'Large Text', level: AccessibilityLevel.enhanced,
      enableLargeText: true, textScaleFactor: 1.5,
    ));
    registerProfile(const AccessibilityProfile(
      id: 'dyslexia_friendly', name: 'Dyslexia Friendly', level: AccessibilityLevel.enhanced,
      enableDyslexiaFriendly: true, textScaleFactor: 1.1,
    ));
  }

  void registerProfile(AccessibilityProfile profile) {
    _profiles[profile.id] = profile;
  }

  void unregisterProfile(String profileId) {
    _profiles.remove(profileId);
  }

  void setProfile(String profileId) {
    final profile = _profiles[profileId];
    if (profile != null) _currentProfile = profile;
  }

  AccessibilityProfile get currentProfile => _currentProfile;
  List<AccessibilityProfile> getAllProfiles() => List.unmodifiable(_profiles.values);

  void registerComponentMetadata(ComponentAccessibilityMetadata metadata) {
    _componentMetadata[metadata.componentId] = metadata;
  }

  ComponentAccessibilityMetadata? getComponentMetadata(String componentId) {
    return _componentMetadata[componentId];
  }

  AccessibilityValidation validateComponent(String componentId) {
    final metadata = _componentMetadata[componentId];
    if (metadata == null) {
      return const AccessibilityValidation(passed: false, issues: ['No accessibility metadata'], score: 0);
    }
    final issues = <String>[];
    if (metadata.semanticsLabel.isEmpty) issues.add('Missing semantics label');
    if (metadata.minimumTapTarget < _currentProfile.minTouchTarget) {
      issues.add('Tap target too small: ${metadata.minimumTapTarget}px < ${_currentProfile.minTouchTarget}px');
    }
    return AccessibilityValidation(
      passed: issues.isEmpty,
      issues: issues,
      score: issues.isEmpty ? 100 : (100 - issues.length * 20).clamp(0, 100),
    );
  }

  AccessibilityValidation validateAll() {
    final allIssues = <String>[];
    var totalScore = 0;
    for (final componentId in _componentMetadata.keys) {
      final result = validateComponent(componentId);
      allIssues.addAll(result.issues);
      totalScore += result.score;
    }
    final count = _componentMetadata.length;
    final avgScore = count > 0 ? totalScore ~/ count : 100;
    final validation = AccessibilityValidation(
      passed: allIssues.isEmpty,
      issues: allIssues,
      score: avgScore,
    );
    _validationHistory.add(validation);
    return validation;
  }

  int getScore() {
    final result = validateAll();
    return result.score;
  }

  List<AccessibilityValidation> getValidationHistory() => List.unmodifiable(_validationHistory);

  Map<String, dynamic> getDiagnostics() {
    return {
      'currentProfile': _currentProfile.name,
      'totalProfiles': _profiles.length,
      'registeredComponents': _componentMetadata.length,
      'validationRuns': _validationHistory.length,
      'lastScore': _validationHistory.isNotEmpty ? _validationHistory.last.score : null,
    };
  }
}
