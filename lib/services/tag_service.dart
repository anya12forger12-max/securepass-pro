import 'dart:convert';

import 'package:securepass_pro/domain/entities/tag.dart';
import 'package:securepass_pro/domain/enums/tag_color.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

class TagService {
  static final TagService _instance = TagService._();

  factory TagService() => _instance;

  TagService._();

  static const String _storageKey = 'app_tags';
  static const List<Map<String, dynamic>> _defaultTags = [
    {'name': 'important', 'color': 'blue'},
    {'name': 'work', 'color': 'blue'},
    {'name': 'personal', 'color': 'blue'},
    {'name': 'security', 'color': 'blue'},
  ];

  final List<Tag> _tags = [];

  int get count => _tags.length;

  Future<void> initialize() async {
    _load();
    _seedDefaultTags();
    AppLogger.instance.info(
      'TagService initialized with ${_tags.length} tags',
      category: 'TagService',
    );
  }

  void addTag(Tag tag) {
    final exists =
        _tags.any((t) => t.name.toLowerCase() == tag.name.toLowerCase());
    if (exists) {
      AppLogger.instance.warning(
        'Tag "${tag.name}" already exists',
        category: 'TagService',
      );
      return;
    }

    _tags.add(tag);
    _save();
    AppLogger.instance.debug(
      'Added tag ${tag.id}',
      category: 'TagService',
    );
  }

  void updateTag(Tag tag) {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index == -1) {
      AppLogger.instance.warning(
        'Tag ${tag.id} not found for update',
        category: 'TagService',
      );
      return;
    }

    _tags[index] = tag;
    _save();
    AppLogger.instance.debug(
      'Updated tag ${tag.id}',
      category: 'TagService',
    );
  }

  void removeTag(String id) {
    final beforeLength = _tags.length;
    _tags.removeWhere((t) => t.id == id);
    if (_tags.length < beforeLength) {
      _save();
      AppLogger.instance.debug(
        'Removed tag $id',
        category: 'TagService',
      );
    }
  }

  List<Tag> getTags() => List.unmodifiable(_tags);

  Tag? getTagById(String id) {
    try {
      return _tags.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Tag? getTagByName(String name) {
    try {
      return _tags.firstWhere(
          (t) => t.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  List<Tag> searchTags(String query) {
    if (query.isEmpty) return getTags();

    final lowerQuery = query.toLowerCase();
    return _tags.where((t) {
      return t.name.toLowerCase().contains(lowerQuery) ||
          t.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Map<String, dynamic> exportAsMap() {
    return {
      'tags': _tags.map((t) => t.toMap()).toList(),
    };
  }

  Future<void> importFromMap(Map<String, dynamic> data) async {
    final tagsJson = data['tags'] as List<dynamic>?;
    if (tagsJson != null) {
      _tags.clear();
      for (final tagMap in tagsJson) {
        try {
          final tag =
              Tag.fromMap(Map<String, dynamic>.from(tagMap as Map));
          _tags.add(tag);
        } catch (e) {
          AppLogger.instance.warning(
            'Failed to import tag: $e',
            category: 'TagService',
          );
        }
      }
    }

    _save();
    AppLogger.instance.info(
      'Imported ${_tags.length} tags',
      category: 'TagService',
    );
  }

  void _seedDefaultTags() {
    bool changed = false;
    for (final tagData in _defaultTags) {
      final name = tagData['name'] as String;
      final exists =
          _tags.any((t) => t.name.toLowerCase() == name.toLowerCase());
      if (!exists) {
        final tag = Tag(
          id: 'default_$name',
          name: name,
          color: TagColor.blue,
          createdAt: DateTime.now(),
        );
        _tags.add(tag);
        changed = true;
      }
    }
    if (changed) {
      _save();
    }
  }

  void _save() {
    try {
      final data = jsonEncode(exportAsMap());
      PreferencesStorage.instance.setString(_storageKey, data);
    } catch (e) {
      AppLogger.instance.error(
        'Failed to save tags: $e',
        category: 'TagService',
      );
    }
  }

  void _load() {
    try {
      final data = PreferencesStorage.instance.getString(_storageKey);
      if (data == null || data.isEmpty) return;

      final json = jsonDecode(data) as Map<String, dynamic>;
      final tagsJson = json['tags'] as List<dynamic>?;
      if (tagsJson != null) {
        _tags.clear();
        for (final tagMap in tagsJson) {
          try {
            final tag =
                Tag.fromMap(Map<String, dynamic>.from(tagMap as Map));
            _tags.add(tag);
          } catch (e) {
            AppLogger.instance.warning(
              'Failed to load tag: $e',
              category: 'TagService',
            );
          }
        }
      }
    } catch (e) {
      AppLogger.instance.error(
        'Failed to load tags: $e',
        category: 'TagService',
      );
    }
  }
}
