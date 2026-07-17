import 'dart:convert';

import 'package:securepass_pro/domain/entities/history_entry.dart';
import 'package:securepass_pro/domain/entities/statistics_data.dart';
import 'package:securepass_pro/domain/enums/generator_type.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._();

  factory HistoryService() => _instance;

  HistoryService._();

  static const String _storageKey = 'credential_history';

  final List<HistoryEntry> _entries = [];
  bool _isEnabled = false;
  int _maxEntries = 1000;

  bool get isEnabled => _isEnabled;
  int get maxEntries => _maxEntries;

  Future<void> initialize() async {
    _load();
    _pruneExpired();
    AppLogger.instance.info(
      'HistoryService initialized with ${_entries.length} entries',
      category: 'HistoryService',
    );
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    _save();
    AppLogger.instance.debug(
      'History ${enabled ? "enabled" : "disabled"}',
      category: 'HistoryService',
    );
  }

  void setMaxEntries(int max) {
    _maxEntries = max;
    _trimToMax();
    _save();
  }

  void addEntry(HistoryEntry entry) {
    if (!_isEnabled) {
      AppLogger.instance.debug(
        'History disabled, skipping entry',
        category: 'HistoryService',
      );
      return;
    }

    _entries.insert(0, entry);
    _trimToMax();
    _save();
    AppLogger.instance.debug(
      'Added history entry ${entry.id}',
      category: 'HistoryService',
    );
  }

  void removeEntry(String id) {
    final beforeLength = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    if (_entries.length < beforeLength) {
      _save();
      AppLogger.instance.debug(
        'Removed history entry $id',
        category: 'HistoryService',
      );
    }
  }

  void bulkRemove(List<String> ids) {
    final idSet = ids.toSet();
    _entries.removeWhere((e) => idSet.contains(e.id));
    _save();
    AppLogger.instance.debug(
      'Bulk removed ${ids.length} history entries',
      category: 'HistoryService',
    );
  }

  void clearAll() {
    _entries.clear();
    _save();
    AppLogger.instance.info(
      'Cleared all history entries',
      category: 'HistoryService',
    );
  }

  HistoryEntry? getEntryById(String id) {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<HistoryEntry> getEntries({
    String? workspaceId,
    GeneratorType? type,
    String? tag,
    String? query,
    bool? isFavorite,
    int? limit,
    int? offset,
  }) {
    var results = List<HistoryEntry>.from(_entries);

    if (workspaceId != null) {
      results = results.where((e) => e.workspaceId == workspaceId).toList();
    }

    if (type != null) {
      results = results.where((e) => e.generatorType == type).toList();
    }

    if (tag != null) {
      results = results.where((e) => e.tags.contains(tag)).toList();
    }

    if (isFavorite != null) {
      results = results.where((e) => e.isFavorite == isFavorite).toList();
    }

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((e) {
        return e.value.toLowerCase().contains(lowerQuery) ||
            e.label.toLowerCase().contains(lowerQuery) ||
            e.generatorType.name.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (offset != null && offset > 0) {
      if (offset >= results.length) return [];
      results = results.sublist(offset);
    }

    if (limit != null && limit > 0 && results.length > limit) {
      results = results.sublist(0, limit);
    }

    return results;
  }

  List<HistoryEntry> searchEntries(String query) {
    final lowerQuery = query.toLowerCase();
    return _entries.where((e) {
      return e.value.toLowerCase().contains(lowerQuery) ||
          e.label.toLowerCase().contains(lowerQuery) ||
          e.generatorType.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  StatisticsData getStatistics() {
    int totalGenerated = _entries.length;
    final Map<String, int> totalByType = {};
    double totalLength = 0;

    for (final entry in _entries) {
      final typeName = entry.generatorType.name;
      totalByType[typeName] = (totalByType[typeName] ?? 0) + 1;
      totalLength += entry.value.length;
    }

    final avgLength =
        totalGenerated > 0 ? totalLength / totalGenerated : 0.0;

    final recentActivity = _entries.take(50).map((e) {
      return ActivityEntry(
        action: 'generated',
        type: e.generatorType.name,
        timestamp: e.createdAt,
        details: e.label,
      );
    }).toList();

    return StatisticsData(
      totalGenerated: totalGenerated,
      totalByType: totalByType,
      averageLength: avgLength,
      averageEntropy: 0,
      totalExports: 0,
      totalImports: 0,
      totalClipboardCopies: 0,
      totalRecipesUsed: 0,
      totalPoliciesUsed: 0,
      recentActivity: recentActivity,
    );
  }

  Map<String, dynamic> exportAsMap() {
    return {
      'isEnabled': _isEnabled,
      'maxEntries': _maxEntries,
      'entries': _entries.map((e) => e.toMap()).toList(),
    };
  }

  Future<void> importFromMap(Map<String, dynamic> data) async {
    _isEnabled = data['isEnabled'] as bool? ?? false;
    _maxEntries = data['maxEntries'] as int? ?? 1000;

    final entriesJson = data['entries'] as List<dynamic>?;
    if (entriesJson != null) {
      _entries.clear();
      for (final entryMap in entriesJson) {
        try {
          final entry =
              HistoryEntry.fromMap(Map<String, dynamic>.from(entryMap as Map));
          _entries.add(entry);
        } catch (e) {
          AppLogger.instance.warning(
            'Failed to import history entry: $e',
            category: 'HistoryService',
          );
        }
      }
    }

    _trimToMax();
    _save();
    AppLogger.instance.info(
      'Imported ${_entries.length} history entries',
      category: 'HistoryService',
    );
  }

  void _trimToMax() {
    while (_entries.length > _maxEntries) {
      _entries.removeLast();
    }
  }

  void _pruneExpired() {
    final now = DateTime.now();
    final beforeCount = _entries.length;
    _entries.removeWhere(
        (e) => e.expiresAt != null && e.expiresAt!.isBefore(now));
    final removedCount = beforeCount - _entries.length;
    if (removedCount > 0) {
      AppLogger.instance.info(
        'Pruned $removedCount expired history entries',
        category: 'HistoryService',
      );
      _save();
    }
  }

  void _save() {
    try {
      final data = jsonEncode(exportAsMap());
      PreferencesStorage.instance.setString(_storageKey, data);
    } catch (e) {
      AppLogger.instance.error(
        'Failed to save history: $e',
        category: 'HistoryService',
      );
    }
  }

  void _load() {
    try {
      final data = PreferencesStorage.instance.getString(_storageKey);
      if (data == null || data.isEmpty) return;

      final json = jsonDecode(data) as Map<String, dynamic>;
      _isEnabled = json['isEnabled'] as bool? ?? false;
      _maxEntries = json['maxEntries'] as int? ?? 1000;

      final entriesJson = json['entries'] as List<dynamic>?;
      if (entriesJson != null) {
        _entries.clear();
        for (final entryMap in entriesJson) {
          try {
            final entry =
                HistoryEntry.fromMap(Map<String, dynamic>.from(entryMap as Map));
            _entries.add(entry);
          } catch (e) {
            AppLogger.instance.warning(
              'Failed to load history entry: $e',
              category: 'HistoryService',
            );
          }
        }
      }
    } catch (e) {
      AppLogger.instance.error(
        'Failed to load history: $e',
        category: 'HistoryService',
      );
    }
  }
}
