import 'dart:convert';

import 'package:securepass_pro/domain/entities/favorite_item.dart';
import 'package:securepass_pro/domain/enums/generator_type.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._();

  factory FavoritesService() => _instance;

  FavoritesService._();

  static const String _storageKey = 'favorites';

  final List<FavoriteItem> _favorites = [];

  int get count => _favorites.length;

  Future<void> initialize() async {
    _load();
    AppLogger.instance.info(
      'FavoritesService initialized with ${_favorites.length} favorites',
      category: 'FavoritesService',
    );
  }

  void addFavorite(FavoriteItem item) {
    final exists = _favorites.any((f) => f.value == item.value);
    if (exists) {
      AppLogger.instance.debug(
        'Favorite already exists for value',
        category: 'FavoritesService',
      );
      return;
    }

    _favorites.insert(0, item);
    _save();
    AppLogger.instance.debug(
      'Added favorite ${item.id}',
      category: 'FavoritesService',
    );
  }

  void removeFavorite(String id) {
    final beforeLength = _favorites.length;
    _favorites.removeWhere((f) => f.id == id);
    if (_favorites.length < beforeLength) {
      _save();
      AppLogger.instance.debug(
        'Removed favorite $id',
        category: 'FavoritesService',
      );
    }
  }

  bool isFavorited(String value) {
    return _favorites.any((f) => f.value == value);
  }

  FavoriteItem? getFavoriteByValue(String value) {
    try {
      return _favorites.firstWhere((f) => f.value == value);
    } catch (_) {
      return null;
    }
  }

  List<FavoriteItem> getFavorites({
    GeneratorType? type,
    String? query,
  }) {
    var results = List<FavoriteItem>.from(_favorites);

    if (type != null) {
      results = results.where((f) => f.generatorType == type).toList();
    }

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((f) {
        return f.value.toLowerCase().contains(lowerQuery) ||
            f.label.toLowerCase().contains(lowerQuery) ||
            f.generatorType.name.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return results;
  }

  List<FavoriteItem> getAllFavorites() => List.unmodifiable(_favorites);

  void clearFavorites() {
    _favorites.clear();
    _save();
    AppLogger.instance.info(
      'Cleared all favorites',
      category: 'FavoritesService',
    );
  }

  Map<String, dynamic> exportAsMap() {
    return {
      'favorites': _favorites.map(_favoriteToMap).toList(),
    };
  }

  Future<void> importFromMap(Map<String, dynamic> data) async {
    final favoritesJson = data['favorites'] as List<dynamic>?;
    if (favoritesJson != null) {
      _favorites.clear();
      for (final item in favoritesJson) {
        try {
          final favorite = _favoriteFromMap(
              Map<String, dynamic>.from(item as Map));
          _favorites.add(favorite);
        } catch (e) {
          AppLogger.instance.warning(
            'Failed to import favorite: $e',
            category: 'FavoritesService',
          );
        }
      }
    }

    _save();
    AppLogger.instance.info(
      'Imported ${_favorites.length} favorites',
      category: 'FavoritesService',
    );
  }

  Map<String, dynamic> _favoriteToMap(FavoriteItem item) {
    return {
      'id': item.id,
      'value': item.value,
      'generatorType': item.generatorType.name,
      'label': item.label,
      'metadata': item.metadata,
      'createdAt': item.createdAt.toIso8601String(),
    };
  }

  FavoriteItem _favoriteFromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'] as String,
      value: map['value'] as String,
      generatorType: GeneratorType.values.firstWhere(
        (e) => e.name == map['generatorType'],
        orElse: () => GeneratorType.password,
      ),
      label: map['label'] as String? ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  void _save() {
    try {
      final data = jsonEncode(exportAsMap());
      PreferencesStorage.instance.setString(_storageKey, data);
    } catch (e) {
      AppLogger.instance.error(
        'Failed to save favorites: $e',
        category: 'FavoritesService',
      );
    }
  }

  void _load() {
    try {
      final data = PreferencesStorage.instance.getString(_storageKey);
      if (data == null || data.isEmpty) return;

      final json = jsonDecode(data) as Map<String, dynamic>;
      final favoritesJson = json['favorites'] as List<dynamic>?;
      if (favoritesJson != null) {
        _favorites.clear();
        for (final item in favoritesJson) {
          try {
            final favorite = _favoriteFromMap(
                Map<String, dynamic>.from(item as Map));
            _favorites.add(favorite);
          } catch (e) {
            AppLogger.instance.warning(
              'Failed to load favorite: $e',
              category: 'FavoritesService',
            );
          }
        }
      }
    } catch (e) {
      AppLogger.instance.error(
        'Failed to load favorites: $e',
        category: 'FavoritesService',
      );
    }
  }
}
