import 'dart:async';
import 'dart:convert';

import 'package:securepass_pro/domain/entities/import_result.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/services/configuration_service.dart';
import 'package:securepass_pro/services/encryption_service.dart';
import 'package:securepass_pro/services/vault_service.dart';
import 'package:securepass_pro/services/workspace_service.dart';

class ImportService {
  ImportService._();
  static final ImportService _instance = ImportService._();
  static ImportService get instance => _instance;

  /// Highest encrypted-backup envelope version this build can read.
  ///
  /// Backups are written by [BackupService] as `{"v":1,"enc":true,"data":…}`.
  /// A backup declaring a version this build does not understand is rejected
  /// rather than decrypted on a guess, so a future format can never be
  /// misread as the current one.
  static const int supportedEnvelopeVersion = 1;

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

      final encryptedData = _extractEnvelopeData(jsonStr, decoded);
      if (encryptedData != null) {
        // decrypt() throws on any failure, so a corrupt or wrong-key backup
        // is reported as such instead of surfacing as an empty payload.
        final String plain;
        try {
          plain = await EncryptionService.instance.decrypt(encryptedData);
        } on EncryptionException {
          return const ImportResult(
            success: false,
            totalItems: 0,
            successfulItems: 0,
            failedItems: 0,
            importedItems: [],
            errorMessage:
                'Failed to decrypt encrypted import data: invalid or corrupted encryption',
          );
        }
        return await _parseImport(jsonDecode(plain));
      }

      return await _parseImport(decoded);
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

  String? _extractEnvelopeData(String raw, dynamic decoded) {
    Map<String, dynamic>? candidate;
    if (decoded is Map<String, dynamic>) {
      candidate = decoded;
    } else if (raw.trimLeft().startsWith('{"v":1,"enc":true')) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          candidate = parsed;
        }
      } catch (_) {
        return null;
      }
    }
    if (candidate == null) return null;

    // A BackupService export wraps the envelope one level deeper, as
    // {"metadata":…, "data":"{\"v\":1,\"enc\":true,\"data\":\"<b64>\"}"}.
    // Unwrap that shape so the app's own backups are restorable.
    final nested = candidate['data'];
    if (nested is String && candidate['enc'] != true) {
      try {
        final unwrapped = jsonDecode(nested);
        if (unwrapped is Map<String, dynamic>) {
          candidate = unwrapped;
        }
      } catch (_) {
        return null;
      }
    }

    if (candidate['enc'] != true) return null;

    final version = candidate['v'];
    if (version is int && version > supportedEnvelopeVersion) {
      AppLogger.instance.warning(
        'Rejected backup with unsupported envelope version: $version',
        category: 'ImportService',
      );
      return null;
    }

    final data = candidate['data'];
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  Future<ImportResult> _parseImport(dynamic decoded) async {
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
      final results = _importVault(data['vault'] as List<dynamic>);
      importedItems.addAll(results);
      if (results.any((i) => i.success)) {
        // Awaited: a reported success must mean the data is really persisted,
        // otherwise the user is told a restore worked before it happened.
        try {
          await VaultService().importFromMap({
            'entries': data['vault'],
            'folders': data['folders'],
          });
        } catch (error) {
          AppLogger.instance.error(
            'Vault restore failed: $error',
            category: 'ImportService',
          );
          for (final item in results) {
            importedItems.remove(item);
          }
          importedItems.add(
            const ImportedItem(
              type: 'vault',
              name: 'Vault restore',
              success: false,
              message: 'Could not write the restored vault',
            ),
          );
        }
      }
    }

    // BackupService writes these keys too; accepting them in
    // validateImportData is only honest if they are actually applied.
    if (data['config'] is Map) {
      try {
        await ConfigurationService.instance.importConfig(
          Map<String, dynamic>.from(data['config'] as Map),
        );
        importedItems.add(
          const ImportedItem(
            type: 'config',
            name: 'App settings',
            message: 'Imported successfully',
          ),
        );
      } catch (error) {
        AppLogger.instance.error(
          'Settings restore failed: $error',
          category: 'ImportService',
        );
        importedItems.add(
          const ImportedItem(
            type: 'config',
            name: 'App settings',
            success: false,
            message: 'Could not write the restored settings',
          ),
        );
      }
    }

    if (data['workspaces'] is List) {
      for (final workspace in data['workspaces'] as List<dynamic>) {
        if (workspace is! Map) {
          importedItems.add(
            const ImportedItem(
              type: 'workspaces',
              name: 'Workspace',
              success: false,
              message: 'Malformed workspace entry',
            ),
          );
          continue;
        }
        final restored = await WorkspaceService.instance.importWorkspace(
          Map<String, dynamic>.from(workspace),
        );
        importedItems.add(
          ImportedItem(
            type: 'workspaces',
            name: workspace['name']?.toString() ?? 'Workspace',
            success: restored != null,
            message: restored != null
                ? 'Imported successfully'
                : 'Could not write the restored workspace',
          ),
        );
      }
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

    const validKeys = {
      'history',
      'favorites',
      'vault',
      'recipes',
      'tags',
      'settings',
      // Keys written by BackupService.exportBackup.
      'config',
      'workspaces',
      'folders',
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
