class StatisticsData {
  const StatisticsData({
    this.totalGenerated = 0,
    this.totalByType = const {},
    this.averageLength = 0,
    this.averageEntropy = 0,
    this.totalExports = 0,
    this.totalImports = 0,
    this.totalClipboardCopies = 0,
    this.totalRecipesUsed = 0,
    this.totalPoliciesUsed = 0,
    this.recentActivity = const [],
  });

  final int totalGenerated;
  final Map<String, int> totalByType;
  final double averageLength;
  final double averageEntropy;
  final int totalExports;
  final int totalImports;
  final int totalClipboardCopies;
  final int totalRecipesUsed;
  final int totalPoliciesUsed;
  final List<ActivityEntry> recentActivity;
}

class ActivityEntry {
  const ActivityEntry({
    required this.action,
    required this.type,
    required this.timestamp,
    this.details = '',
  });

  final String action;
  final String type;
  final DateTime timestamp;
  final String details;
}
