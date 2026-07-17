import 'dart:convert';

import 'package:securepass_pro/domain/entities/statistics_data.dart';
import 'package:securepass_pro/domain/enums/generator_type.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._();

  factory StatisticsService() => _instance;

  StatisticsService._();

  static const String _storageKey = 'app_statistics';
  static const int _maxActivityEntries = 500;

  final Map<String, int> _totalByType = {};
  int _totalExports = 0;
  int _totalImports = 0;
  int _totalClipboardCopies = 0;
  int _totalRecipesUsed = 0;
  int _totalPoliciesUsed = 0;
  final List<ActivityEntry> _recentActivity = [];

  int get totalGenerated =>
      _totalByType.values.fold(0, (sum, count) => sum + count);

  Future<void> initialize() async {
    _load();
    AppLogger.instance.info(
      'StatisticsService initialized with $totalGenerated generations',
      category: 'StatisticsService',
    );
  }

  void recordGeneration(GeneratorType type, double length, double entropy) {
    final typeName = type.name;
    _totalByType[typeName] = (_totalByType[typeName] ?? 0) + 1;

    _addActivity(ActivityEntry(
      action: 'generated',
      type: typeName,
      timestamp: DateTime.now(),
      details: 'length=$length,entropy=$entropy',
    ));

    _save();
  }

  void recordExport() {
    _totalExports++;
    _addActivity(ActivityEntry(
      action: 'exported',
      type: 'export',
      timestamp: DateTime.now(),
      details: '',
    ));
    _save();
  }

  void recordImport() {
    _totalImports++;
    _addActivity(ActivityEntry(
      action: 'imported',
      type: 'import',
      timestamp: DateTime.now(),
      details: '',
    ));
    _save();
  }

  void recordClipboardCopy() {
    _totalClipboardCopies++;
    _save();
  }

  void recordRecipeUsed() {
    _totalRecipesUsed++;
    _addActivity(ActivityEntry(
      action: 'used_recipe',
      type: 'recipe',
      timestamp: DateTime.now(),
      details: '',
    ));
    _save();
  }

  void recordPolicyUsed() {
    _totalPoliciesUsed++;
    _addActivity(ActivityEntry(
      action: 'used_policy',
      type: 'policy',
      timestamp: DateTime.now(),
      details: '',
    ));
    _save();
  }

  StatisticsData getStatistics() {
    return StatisticsData(
      totalGenerated: totalGenerated,
      totalByType: Map<String, int>.from(_totalByType),
      averageLength: 0,
      averageEntropy: 0,
      totalExports: _totalExports,
      totalImports: _totalImports,
      totalClipboardCopies: _totalClipboardCopies,
      totalRecipesUsed: _totalRecipesUsed,
      totalPoliciesUsed: _totalPoliciesUsed,
      recentActivity: List<ActivityEntry>.unmodifiable(_recentActivity),
    );
  }

  List<ActivityEntry> getActivity({int limit = 50}) {
    if (limit >= _recentActivity.length) {
      return List<ActivityEntry>.unmodifiable(_recentActivity);
    }
    return List<ActivityEntry>.unmodifiable(
        _recentActivity.sublist(_recentActivity.length - limit));
  }

  void clearStatistics() {
    _totalByType.clear();
    _totalExports = 0;
    _totalImports = 0;
    _totalClipboardCopies = 0;
    _totalRecipesUsed = 0;
    _totalPoliciesUsed = 0;
    _recentActivity.clear();
    _save();
    AppLogger.instance.info(
      'Statistics cleared',
      category: 'StatisticsService',
    );
  }

  Map<String, dynamic> exportAsMap() {
    return {
      'totalByType': _totalByType,
      'totalExports': _totalExports,
      'totalImports': _totalImports,
      'totalClipboardCopies': _totalClipboardCopies,
      'totalRecipesUsed': _totalRecipesUsed,
      'totalPoliciesUsed': _totalPoliciesUsed,
      'recentActivity': _recentActivity
          .map((a) => {
                'action': a.action,
                'type': a.type,
                'timestamp': a.timestamp.toIso8601String(),
                'details': a.details,
              })
          .toList(),
    };
  }

  Future<void> importFromMap(Map<String, dynamic> data) async {
    final byType = data['totalByType'] as Map<String, dynamic>?;
    if (byType != null) {
      _totalByType.clear();
      for (final entry in byType.entries) {
        _totalByType[entry.key] = entry.value as int;
      }
    }

    _totalExports = data['totalExports'] as int? ?? 0;
    _totalImports = data['totalImports'] as int? ?? 0;
    _totalClipboardCopies = data['totalClipboardCopies'] as int? ?? 0;
    _totalRecipesUsed = data['totalRecipesUsed'] as int? ?? 0;
    _totalPoliciesUsed = data['totalPoliciesUsed'] as int? ?? 0;

    final activityJson = data['recentActivity'] as List<dynamic>?;
    if (activityJson != null) {
      _recentActivity.clear();
      for (final activityMap in activityJson) {
        try {
          final map = Map<String, dynamic>.from(activityMap as Map);
          _recentActivity.add(ActivityEntry(
            action: map['action'] as String,
            type: map['type'] as String,
            timestamp: DateTime.parse(map['timestamp'] as String),
            details: map['details'] as String? ?? '',
          ));
        } catch (e) {
          AppLogger.instance.warning(
            'Failed to import activity entry: $e',
            category: 'StatisticsService',
          );
        }
      }
    }

    _save();
    AppLogger.instance.info(
      'Imported statistics: $totalGenerated generations',
      category: 'StatisticsService',
    );
  }

  void _addActivity(ActivityEntry entry) {
    _recentActivity.add(entry);
    if (_recentActivity.length > _maxActivityEntries) {
      _recentActivity.removeRange(
          0, _recentActivity.length - _maxActivityEntries);
    }
  }

  void _save() {
    try {
      final data = jsonEncode(exportAsMap());
      PreferencesStorage.instance.setString(_storageKey, data);
    } catch (e) {
      AppLogger.instance.error(
        'Failed to save statistics: $e',
        category: 'StatisticsService',
      );
    }
  }

  void _load() {
    try {
      final data = PreferencesStorage.instance.getString(_storageKey);
      if (data == null || data.isEmpty) return;

      final json = jsonDecode(data) as Map<String, dynamic>;

      final byType = json['totalByType'] as Map<String, dynamic>?;
      if (byType != null) {
        _totalByType.clear();
        for (final entry in byType.entries) {
          _totalByType[entry.key] = entry.value as int;
        }
      }

      _totalExports = json['totalExports'] as int? ?? 0;
      _totalImports = json['totalImports'] as int? ?? 0;
      _totalClipboardCopies = json['totalClipboardCopies'] as int? ?? 0;
      _totalRecipesUsed = json['totalRecipesUsed'] as int? ?? 0;
      _totalPoliciesUsed = json['totalPoliciesUsed'] as int? ?? 0;

      final activityJson = json['recentActivity'] as List<dynamic>?;
      if (activityJson != null) {
        _recentActivity.clear();
        for (final activityMap in activityJson) {
          try {
            final map = Map<String, dynamic>.from(activityMap as Map);
            _recentActivity.add(ActivityEntry(
              action: map['action'] as String,
              type: map['type'] as String,
              timestamp: DateTime.parse(map['timestamp'] as String),
              details: map['details'] as String? ?? '',
            ));
          } catch (e) {
            AppLogger.instance.warning(
              'Failed to load activity entry: $e',
              category: 'StatisticsService',
            );
          }
        }
      }
    } catch (e) {
      AppLogger.instance.error(
        'Failed to load statistics: $e',
        category: 'StatisticsService',
      );
    }
  }
}
