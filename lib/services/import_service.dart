import 'dart:convert';

import 'package:securepass_pro/domain/entities/import_result.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class ImportService {
  ImportService._();
  static final ImportService _instance = ImportService._();
  static ImportService get instance => _instance;

  int _importCount = 0;

  Future<void> initialize() async {
    AppLogger.instance.info(
      'ImportService initialized',
      category: 'ImportService',
    );
  }

  Future<ImportResult> importFromJson(String jsonStr) async {
    AppLogger.instance.debug(
      'Importing from JSON',
      category: 'ImportService',
    );

    try {
      final decoded = jsonDecode(jsonStr);

      Map<String, dynamic> data;
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data') && decoded['data'] is Map) {
          data = Map<String, dynamic>.from(decoded['data'] as Map);
        } else {
          data = decoded;
        }
      } else {
        return const ImportResult(
          success: false,
          totalItems: 0,
          successfulItems: 0,
          failedItems: 0,
          importedItems: [],
          errorMessage: 'Invalid JSON structure: expected an object',
        );
      }

      if (!validateImportData(data)) {
        return const ImportResult(
          success: false,
          totalItems: 0,
          successfulItems: 0,
          failedItems: 0,
          importedItems: [],
          errorMessage: 'Required data fields missing or invalid',
        );
      }

      final importedItems = <ImportedItem>[];

      if (data.containsKey('history') && data['history'] is List) {
        importedItems.addAll(
          _importHistory(data['history'] as List<dynamic>),
        );
      }

      if (data.containsKey('favorites') && data['favorites'] is List) {
        importedItems.addAll(
          _importFavorites(data['favorites'] as List<dynamic>),
        );
      }

      if (data.containsKey('vault') && data['vault'] is List) {
        importedItems.addAll(
          _importVault(data['vault'] as List<dynamic>),
        );
      }

      if (data.containsKey('recipes') && data['recipes'] is List) {
        importedItems.addAll(
          _importRecipes(data['recipes'] as List<dynamic>),
        );
      }

      if (data.containsKey('tags') && data['tags'] is List) {
        importedItems.addAll(
          _importTags(data['tags'] as List<dynamic>),
        );
      }

      if (data.containsKey('settings') && data['settings'] is Map) {
        importedItems.addAll(
          _importSettings(data['settings'] as Map<String, dynamic>),
        );
      }

      final successful = importedItems.where((i) => i.success).length;
      final failed = importedItems.where((i) => !i.success).length;

      _importCount++;

      AppLogger.instance.info(
        'Import completed: $successful successful, $failed failed',
        category: 'ImportService',
      );

      return ImportResult(
        success: failed == 0,
        totalItems: importedItems.length,
        successfulItems: successful,
        failedItems: failed,
        importedItems: importedItems,
      );
    } catch (e) {
      AppLogger.instance.error(
        'Import failed: $e',
        category: 'ImportService',
      );
      return ImportResult(
        success: false,
        totalItems: 0,
        successfulItems: 0,
        failedItems: 0,
        importedItems: const [],
        errorMessage: 'Failed to parse import data: $e',
      );
    }
  }

  Future<ImportResult> importFromCsv(String csvStr) async {
    AppLogger.instance.debug(
      'Importing from CSV',
      category: 'ImportService',
    );

    try {
      final lines = csvStr.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        return const ImportResult(
          success: false,
          totalItems: 0,
          successfulItems: 0,
          failedItems: 0,
          importedItems: [],
          errorMessage: 'CSV is empty',
        );
      }

      final importedItems = <ImportedItem>[];
      final headers = _parseCsvLine(lines.first);

      for (var i = 1; i < lines.length; i++) {
        final values = _parseCsvLine(lines[i]);
        final map = <String, dynamic>{};
        for (var j = 0; j < headers.length && j < values.length; j++) {
          map[headers[j]] = values[j];
        }

        final name = map['name'] ?? map['label'] ?? map['title'] ?? '';

        importedItems.add(
          ImportedItem(
            type: 'history',
            name: name.toString(),
            message: 'Imported from CSV row $i',
          ),
        );
      }

      final successful = importedItems.where((i) => i.success).length;

      _importCount++;

      AppLogger.instance.info(
        'CSV import completed: $successful items',
        category: 'ImportService',
      );

      return ImportResult(
        success: true,
        totalItems: importedItems.length,
        successfulItems: successful,
        failedItems: 0,
        importedItems: importedItems,
      );
    } catch (e) {
      AppLogger.instance.error(
        'CSV import failed: $e',
        category: 'ImportService',
      );
      return ImportResult(
        success: false,
        totalItems: 0,
        successfulItems: 0,
        failedItems: 0,
        importedItems: const [],
        errorMessage: 'Failed to parse CSV: $e',
      );
    }
  }

  bool validateImportData(Map<String, dynamic> data) {
    if (data.isEmpty) return false;

    final validKeys = {
      'history',
      'favorites',
      'vault',
      'recipes',
      'tags',
      'settings',
    };

    return data.keys.any(validKeys.contains);
  }

  int getImportCount() => _importCount;

  List<ImportedItem> _importHistory(List<dynamic> items) {
    final results = <ImportedItem>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) {
        results.add(ImportedItem(
          type: 'history',
          name: 'item_$i',
          success: false,
          message: 'Invalid entry format',
        ));
        continue;
      }

      final entry = Map<String, dynamic>.from(item);
      if (!_validateHistoryEntry(entry)) {
        results.add(ImportedItem(
          type: 'history',
          name: entry['label']?.toString() ?? 'item_$i',
          success: false,
          message: 'Missing required fields',
        ));
        continue;
      }

      results.add(ImportedItem(
        type: 'history',
        name: entry['label']?.toString() ?? entry['value']?.toString() ?? '',
        message: 'Imported successfully',
      ));
    }

    return results;
  }

  List<ImportedItem> _importFavorites(List<dynamic> items) {
    final results = <ImportedItem>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) {
        results.add(ImportedItem(
          type: 'favorites',
          name: 'item_$i',
          success: false,
          message: 'Invalid entry format',
        ));
        continue;
      }

      final entry = Map<String, dynamic>.from(item);
      final name = entry['label']?.toString() ??
          entry['value']?.toString() ??
          'item_$i';

      results.add(ImportedItem(
        type: 'favorites',
        name: name,
        message: 'Imported successfully',
      ));
    }

    return results;
  }

  List<ImportedItem> _importVault(List<dynamic> items) {
    final results = <ImportedItem>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) {
        results.add(ImportedItem(
          type: 'vault',
          name: 'item_$i',
          success: false,
          message: 'Invalid entry format',
        ));
        continue;
      }

      final entry = Map<String, dynamic>.from(item);
      if (!_validateVaultEntry(entry)) {
        results.add(ImportedItem(
          type: 'vault',
          name: entry['title']?.toString() ?? 'item_$i',
          success: false,
          message: 'Missing required fields (title, value)',
        ));
        continue;
      }

      results.add(ImportedItem(
        type: 'vault',
        name: entry['title']?.toString() ?? '',
        message: 'Imported successfully',
      ));
    }

    return results;
  }

  List<ImportedItem> _importRecipes(List<dynamic> items) {
    final results = <ImportedItem>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) {
        results.add(ImportedItem(
          type: 'recipes',
          name: 'item_$i',
          success: false,
          message: 'Invalid entry format',
        ));
        continue;
      }

      final entry = Map<String, dynamic>.from(item);
      if (!_validateRecipe(entry)) {
        results.add(ImportedItem(
          type: 'recipes',
          name: entry['name']?.toString() ?? 'item_$i',
          success: false,
          message: 'Missing required fields (name, generatorType)',
        ));
        continue;
      }

      results.add(ImportedItem(
        type: 'recipes',
        name: entry['name']?.toString() ?? '',
        message: 'Imported successfully',
      ));
    }

    return results;
  }

  List<ImportedItem> _importTags(List<dynamic> items) {
    final results = <ImportedItem>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) {
        results.add(ImportedItem(
          type: 'tags',
          name: 'item_$i',
          success: false,
          message: 'Invalid entry format',
        ));
        continue;
      }

      final entry = Map<String, dynamic>.from(item);
      if (!_validateTag(entry)) {
        results.add(ImportedItem(
          type: 'tags',
          name: entry['name']?.toString() ?? 'item_$i',
          success: false,
          message: 'Missing required field (name)',
        ));
        continue;
      }

      results.add(ImportedItem(
        type: 'tags',
        name: entry['name']?.toString() ?? '',
        message: 'Imported successfully',
      ));
    }

    return results;
  }

  List<ImportedItem> _importSettings(Map<String, dynamic> data) {
    final results = <ImportedItem>[];

    for (final entry in data.entries) {
      results.add(ImportedItem(
        type: 'settings',
        name: entry.key,
        message: 'Setting imported',
      ));
    }

    return results;
  }

  bool _validateHistoryEntry(Map<String, dynamic> entry) {
    return entry.containsKey('value') && entry['value'] != null;
  }

  bool _validateVaultEntry(Map<String, dynamic> entry) {
    return entry.containsKey('title') &&
        entry['title'] != null &&
        entry.containsKey('value') &&
        entry['value'] != null;
  }

  bool _validateRecipe(Map<String, dynamic> recipe) {
    return recipe.containsKey('name') &&
        recipe['name'] != null &&
        recipe.containsKey('generatorType') &&
        recipe['generatorType'] != null;
  }

  bool _validateTag(Map<String, dynamic> tag) {
    return tag.containsKey('name') && tag['name'] != null;
  }

  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          current.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          values.add(current.toString());
          current = StringBuffer();
        } else {
          current.write(char);
        }
      }
    }

    values.add(current.toString());
    return values;
  }
}
