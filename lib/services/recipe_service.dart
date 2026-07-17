import 'dart:convert';

import 'package:securepass_pro/domain/entities/generation_config.dart';
import 'package:securepass_pro/domain/entities/passphrase_config.dart';
import 'package:securepass_pro/domain/entities/pin_config.dart';
import 'package:securepass_pro/domain/entities/recipe.dart';
import 'package:securepass_pro/domain/enums/character_set_type.dart';
import 'package:securepass_pro/domain/enums/generator_type.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

class RecipeService {
  static final RecipeService _instance = RecipeService._();

  factory RecipeService() => _instance;

  RecipeService._();

  static const String _storageKey = 'recipes';
  static const List<String> _defaultCategories = [
    'General',
    'Work',
    'Personal',
    'Development',
    'Security',
  ];

  final List<Recipe> _recipes = [];
  final Set<String> _categories = {};

  int get recipeCount => _recipes.length;
  Set<String> get categories => Set.unmodifiable(_categories);

  Future<void> initialize() async {
    _load();
    _seedDefaultCategories();
    AppLogger.instance.info(
      'RecipeService initialized with ${_recipes.length} recipes, ${_categories.length} categories',
      category: 'RecipeService',
    );
  }

  void addRecipe(Recipe recipe) {
    _recipes.add(recipe);
    _save();
    AppLogger.instance.debug(
      'Added recipe ${recipe.id}',
      category: 'RecipeService',
    );
  }

  void updateRecipe(Recipe recipe) {
    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (index == -1) {
      AppLogger.instance.warning(
        'Recipe ${recipe.id} not found for update',
        category: 'RecipeService',
      );
      return;
    }

    _recipes[index] = recipe;
    _save();
    AppLogger.instance.debug(
      'Updated recipe ${recipe.id}',
      category: 'RecipeService',
    );
  }

  void removeRecipe(String id) {
    final beforeLength = _recipes.length;
    _recipes.removeWhere((r) => r.id == id);
    if (_recipes.length < beforeLength) {
      _save();
      AppLogger.instance.debug(
        'Removed recipe $id',
        category: 'RecipeService',
      );
    }
  }

  Recipe? getRecipeById(String id) {
    try {
      return _recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Recipe> getRecipes({
    GeneratorType? type,
    String? query,
  }) {
    var results = List<Recipe>.from(_recipes);

    if (type != null) {
      results = results.where((r) => r.generatorType == type).toList();
    }

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((r) {
        return r.name.toLowerCase().contains(lowerQuery) ||
            r.description.toLowerCase().contains(lowerQuery) ||
            r.generatorType.name.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  Recipe duplicateRecipe(String id, String newName) {
    final original = getRecipeById(id);
    if (original == null) {
      AppLogger.instance.warning(
        'Recipe $id not found for duplication',
        category: 'RecipeService',
      );
      throw StateError('Recipe not found');
    }

    final now = DateTime.now();
    final duplicate = Recipe(
      id: now.millisecondsSinceEpoch.toString(),
      name: newName,
      generatorType: original.generatorType,
      description: original.description,
      passwordConfig: original.passwordConfig,
      passphraseConfig: original.passphraseConfig,
      pinConfig: original.pinConfig,
      batchSize: original.batchSize,
      createdAt: now,
      updatedAt: now,
    );

    _recipes.add(duplicate);
    _save();
    AppLogger.instance.debug(
      'Duplicated recipe $id as ${duplicate.id}',
      category: 'RecipeService',
    );
    return duplicate;
  }

  Set<String> getCategories() => Set.unmodifiable(_categories);

  void addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      AppLogger.instance.warning(
        'Cannot add empty category',
        category: 'RecipeService',
      );
      return;
    }

    if (_categories.add(trimmed)) {
      _save();
      AppLogger.instance.debug(
        'Added category "$trimmed"',
        category: 'RecipeService',
      );
    }
  }

  void removeCategory(String name) {
    if (_categories.remove(name)) {
      _save();
      AppLogger.instance.debug(
        'Removed category "$name"',
        category: 'RecipeService',
      );
    }
  }

  Map<String, dynamic> exportAsMap() {
    return {
      'recipes': _recipes.map(_recipeToMap).toList(),
      'categories': _categories.toList(),
    };
  }

  Future<void> importFromMap(Map<String, dynamic> data) async {
    final recipesJson = data['recipes'] as List<dynamic>?;
    if (recipesJson != null) {
      _recipes.clear();
      for (final recipeMap in recipesJson) {
        try {
          final recipe =
              _recipeFromMap(Map<String, dynamic>.from(recipeMap as Map));
          _recipes.add(recipe);
        } catch (e) {
          AppLogger.instance.warning(
            'Failed to import recipe: $e',
            category: 'RecipeService',
          );
        }
      }
    }

    final categoriesList = data['categories'] as List<dynamic>?;
    if (categoriesList != null) {
      _categories.clear();
      for (final category in categoriesList) {
        _categories.add(category as String);
      }
    }

    _save();
    AppLogger.instance.info(
      'Imported ${_recipes.length} recipes, ${_categories.length} categories',
      category: 'RecipeService',
    );
  }

  Map<String, dynamic> _recipeToMap(Recipe recipe) {
    return {
      'id': recipe.id,
      'name': recipe.name,
      'generatorType': recipe.generatorType.name,
      'description': recipe.description,
      'passwordConfig': recipe.passwordConfig != null
          ? _generationConfigToMap(recipe.passwordConfig!)
          : null,
      'passphraseConfig': recipe.passphraseConfig != null
          ? _passphraseConfigToMap(recipe.passphraseConfig!)
          : null,
      'pinConfig': recipe.pinConfig != null
          ? _pinConfigToMap(recipe.pinConfig!)
          : null,
      'batchSize': recipe.batchSize,
      'createdAt': recipe.createdAt.toIso8601String(),
      'updatedAt': recipe.updatedAt.toIso8601String(),
    };
  }

  Recipe _recipeFromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      name: map['name'] as String,
      generatorType: GeneratorType.values.firstWhere(
        (e) => e.name == map['generatorType'],
        orElse: () => GeneratorType.password,
      ),
      description: map['description'] as String? ?? '',
      passwordConfig: map['passwordConfig'] != null
          ? _generationConfigFromMap(
              Map<String, dynamic>.from(map['passwordConfig'] as Map))
          : null,
      passphraseConfig: map['passphraseConfig'] != null
          ? _passphraseConfigFromMap(
              Map<String, dynamic>.from(map['passphraseConfig'] as Map))
          : null,
      pinConfig: map['pinConfig'] != null
          ? _pinConfigFromMap(
              Map<String, dynamic>.from(map['pinConfig'] as Map))
          : null,
      batchSize: map['batchSize'] as int? ?? 1,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> _generationConfigToMap(GenerationConfig config) {
    return {
      'length': config.length,
      'charSets': config.charSets.map((c) => c.name).toList(),
      'exclusions': config.exclusions.toList(),
      'customChars': config.customChars,
      'minUppercase': config.minUppercase,
      'minLowercase': config.minLowercase,
      'minNumbers': config.minNumbers,
      'minSymbols': config.minSymbols,
      'minUniqueChars': config.minUniqueChars,
      'maxRepeated': config.maxRepeated,
      'noConsecutive': config.noConsecutive,
      'noSequential': config.noSequential,
      'mustStartWith': config.mustStartWith?.name,
      'mustEndWith': config.mustEndWith?.name,
    };
  }

  GenerationConfig _generationConfigFromMap(Map<String, dynamic> map) {
    final charSetsJson = map['charSets'] as List<dynamic>?;
    final charSets = charSetsJson != null
        ? charSetsJson.map((c) => CharacterSetType.values.firstWhere(
              (e) => e.name == c,
              orElse: () => CharacterSetType.uppercase,
            )).toSet()
        : const <CharacterSetType>{};

    final exclusionsJson = map['exclusions'] as List<dynamic>?;
    final exclusions = exclusionsJson?.cast<String>().toSet() ?? const <String>{};

    return GenerationConfig(
      length: map['length'] as int? ?? 24,
      charSets: charSets,
      exclusions: exclusions,
      customChars: map['customChars'] as String? ?? '',
      minUppercase: map['minUppercase'] as int? ?? 0,
      minLowercase: map['minLowercase'] as int? ?? 0,
      minNumbers: map['minNumbers'] as int? ?? 0,
      minSymbols: map['minSymbols'] as int? ?? 0,
      minUniqueChars: map['minUniqueChars'] as int? ?? 0,
      maxRepeated: map['maxRepeated'] as int? ?? 0,
      noConsecutive: map['noConsecutive'] as bool? ?? false,
      noSequential: map['noSequential'] as bool? ?? false,
      mustStartWith: map['mustStartWith'] != null
          ? CharacterSetType.values.firstWhere(
              (e) => e.name == map['mustStartWith'],
              orElse: () => CharacterSetType.uppercase,
            )
          : null,
      mustEndWith: map['mustEndWith'] != null
          ? CharacterSetType.values.firstWhere(
              (e) => e.name == map['mustEndWith'],
              orElse: () => CharacterSetType.uppercase,
            )
          : null,
    );
  }

  Map<String, dynamic> _passphraseConfigToMap(PassphraseConfig config) {
    return {
      'wordCount': config.wordCount,
      'separator': config.separator,
      'capitalize': config.capitalize,
      'includeNumber': config.includeNumber,
      'includeSymbol': config.includeSymbol,
      'prefix': config.prefix,
      'suffix': config.suffix,
      'wordListLanguage': config.wordListLanguage,
    };
  }

  PassphraseConfig _passphraseConfigFromMap(Map<String, dynamic> map) {
    return PassphraseConfig(
      wordCount: map['wordCount'] as int? ?? 6,
      separator: map['separator'] as String? ?? '-',
      capitalize: map['capitalize'] as bool? ?? false,
      includeNumber: map['includeNumber'] as bool? ?? false,
      includeSymbol: map['includeSymbol'] as bool? ?? false,
      prefix: map['prefix'] as String? ?? '',
      suffix: map['suffix'] as String? ?? '',
      wordListLanguage: map['wordListLanguage'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> _pinConfigToMap(PinConfig config) {
    return {
      'length': config.length,
      'avoidRepeated': config.avoidRepeated,
      'avoidSequential': config.avoidSequential,
    };
  }

  PinConfig _pinConfigFromMap(Map<String, dynamic> map) {
    return PinConfig(
      length: map['length'] as int? ?? 6,
      avoidRepeated: map['avoidRepeated'] as bool? ?? false,
      avoidSequential: map['avoidSequential'] as bool? ?? false,
    );
  }

  void _seedDefaultCategories() {
    bool changed = false;
    for (final category in _defaultCategories) {
      if (_categories.add(category)) {
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
        'Failed to save recipes: $e',
        category: 'RecipeService',
      );
    }
  }

  void _load() {
    try {
      final data = PreferencesStorage.instance.getString(_storageKey);
      if (data == null || data.isEmpty) return;

      final json = jsonDecode(data) as Map<String, dynamic>;

      final recipesJson = json['recipes'] as List<dynamic>?;
      if (recipesJson != null) {
        _recipes.clear();
        for (final recipeMap in recipesJson) {
          try {
            final recipe =
                _recipeFromMap(Map<String, dynamic>.from(recipeMap as Map));
            _recipes.add(recipe);
          } catch (e) {
            AppLogger.instance.warning(
              'Failed to load recipe: $e',
              category: 'RecipeService',
            );
          }
        }
      }

      final categoriesList = json['categories'] as List<dynamic>?;
      if (categoriesList != null) {
        _categories.clear();
        for (final category in categoriesList) {
          _categories.add(category as String);
        }
      }
    } catch (e) {
      AppLogger.instance.error(
        'Failed to load recipes: $e',
        category: 'RecipeService',
      );
    }
  }
}
