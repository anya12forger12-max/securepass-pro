class PrivacyDataCategory {
  const PrivacyDataCategory({
    required this.name,
    required this.description,
    required this.isStored,
    required this.canBeCleared,
    this.count = 0,
  });

  final String name;
  final String description;
  final bool isStored;
  final bool canBeCleared;
  final int count;
}

class PrivacyReport {
  const PrivacyReport({
    required this.generatedAt,
    required this.dataCategories,
    required this.offlineModeEnabled,
    required this.telemetryEnabled,
    required this.analyticsEnabled,
    this.recommendations = const [],
  });

  final DateTime generatedAt;
  final List<PrivacyDataCategory> dataCategories;
  final bool offlineModeEnabled;
  final bool telemetryEnabled;
  final bool analyticsEnabled;
  final List<String> recommendations;
}
