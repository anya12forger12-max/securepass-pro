import 'dart:convert';

import 'package:securepass_pro/domain/entities/export_config.dart';
import 'package:securepass_pro/domain/enums/export_format.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/services/encryption_service.dart';

class ExportResult {
  const ExportResult({
    required this.content,
    required this.filename,
    required this.format,
    required this.sizeBytes,
    this.isEncrypted = false,
  });

  final String content;
  final String filename;
  final ExportFormat format;
  final int sizeBytes;
  final bool isEncrypted;
}

class ExportService {
  ExportService._();
  static final ExportService _instance = ExportService._();
  static ExportService get instance => _instance;

  int _exportCount = 0;
  String? _lastExportPath;

  Future<void> initialize() async {
    AppLogger.instance.info(
      'ExportService initialized',
      category: 'ExportService',
    );
  }

  Future<ExportResult> exportData(
    ExportConfig config,
    Map<String, dynamic> dataToExport,
  ) async {
    AppLogger.instance.debug(
      'Exporting data as ${config.format.label}',
      category: 'ExportService',
    );

    final maskedData =
        config.maskValues ? _maskData(dataToExport) : dataToExport;

    String content;
    switch (config.format) {
      case ExportFormat.txt:
        content = _formatAsTxt(maskedData, config);
      case ExportFormat.csv:
        content = _formatAsCsv(maskedData, config);
      case ExportFormat.json:
        content = _formatAsJson(maskedData, config);
      case ExportFormat.markdown:
        content = _formatAsMarkdown(maskedData, config);
      case ExportFormat.html:
        content = _formatAsHtml(maskedData, config);
      case ExportFormat.xml:
        content = _formatAsXml(maskedData, config);
      case ExportFormat.yaml:
        content = _formatAsYaml(maskedData, config);
      case ExportFormat.encryptedJson:
        final jsonContent = _formatAsJson(maskedData, config);
        content = EncryptionService.instance.encrypt(jsonContent);
    }

    final filename = generateFilename(config.format, 'export');
    final sizeBytes = utf8.encode(content).length;

    _exportCount++;
    _lastExportPath = filename;

    AppLogger.instance.info(
      'Export completed: $filename ($sizeBytes bytes)',
      category: 'ExportService',
    );

    return ExportResult(
      content: content,
      filename: filename,
      format: config.format,
      sizeBytes: sizeBytes,
      isEncrypted: config.format == ExportFormat.encryptedJson,
    );
  }

  String generateFilename(ExportFormat format, String prefix) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    return         '${prefix}_$timestamp.${format.extension}';
  }

  int getExportCount() => _exportCount;

  String? getLastExportPath() => _lastExportPath;

  String _formatAsTxt(Map<String, dynamic> data, ExportConfig config) {
    final buffer = StringBuffer();
    buffer.writeln('=== SecurePass Pro Export ===');
    buffer.writeln(
        'Date: ${DateTime.now().toIso8601String()}');
    if (config.includeMetadata) {
      buffer.writeln('Format: ${config.format.label}');
      buffer.writeln();
    }

    for (final entry in data.entries) {
      buffer.writeln();
      buffer.writeln('--- ${entry.key.toUpperCase()} ---');
      buffer.writeln();

      if (entry.value is List) {
        final list = entry.value as List;
        for (var i = 0; i < list.length; i++) {
          buffer.writeln('[$i]');
          if (list[i] is Map) {
            final map = list[i] as Map<String, dynamic>;
            for (final field in map.entries) {
              buffer.writeln('  ${field.key}: ${field.value}');
            }
          } else {
            buffer.writeln('  ${list[i]}');
          }
          buffer.writeln();
        }
      } else if (entry.value is Map) {
        final map = entry.value as Map<String, dynamic>;
        for (final field in map.entries) {
          buffer.writeln('  ${field.key}: ${field.value}');
        }
      } else {
        buffer.writeln('  ${entry.value}');
      }
    }

    buffer.writeln();
    buffer.writeln('=== End of Export ===');
    return buffer.toString();
  }

  String _formatAsCsv(Map<String, dynamic> data, ExportConfig config) {
    final buffer = StringBuffer();

    for (final entry in data.entries) {
      if (entry.value is List && (entry.value as List).isNotEmpty) {
        buffer.writeln('# Section: ${entry.key}');
        final list = entry.value as List;
        final firstItem = list.first;
        if (firstItem is Map) {
          final headers = (firstItem as Map<String, dynamic>).keys.toList();
          buffer.writeln(headers.map(_escapeCsv).join(','));
          for (final item in list) {
            if (item is Map) {
              final map = item as Map<String, dynamic>;
              final row = headers.map((h) {
                final val = map[h];
                return _escapeCsv(val?.toString() ?? '');
              }).toList();
              buffer.writeln(row.join(','));
            }
          }
        } else {
          buffer.writeln('value');
          for (final item in list) {
            buffer.writeln(_escapeCsv(item.toString()));
          }
        }
        buffer.writeln();
      } else if (entry.value is Map) {
        buffer.writeln('# Section: ${entry.key}');
        buffer.writeln('key,value');
        final map = entry.value as Map<String, dynamic>;
        for (final field in map.entries) {
          buffer.writeln(
              '${_escapeCsv(field.key)},${_escapeCsv(field.value?.toString() ?? '')}');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _formatAsJson(Map<String, dynamic> data, ExportConfig config) {
    final exportData = <String, dynamic>{
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    if (config.includeMetadata) {
      exportData['metadata'] = {
        'format': config.format.name,
        'maskValues': config.maskValues,
        'workspaceId': config.workspaceId,
      };
    }
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  String _formatAsMarkdown(Map<String, dynamic> data, ExportConfig config) {
    final buffer = StringBuffer();
    buffer.writeln('# SecurePass Pro Export');
    buffer.writeln();
    if (config.includeMetadata) {
      buffer.writeln(
          '**Exported:** ${DateTime.now().toIso8601String()}');
      buffer.writeln();
    }

    for (final entry in data.entries) {
      buffer.writeln('## ${entry.key}');
      buffer.writeln();

      if (entry.value is List && (entry.value as List).isNotEmpty) {
        final list = entry.value as List;
        final firstItem = list.first;
        if (firstItem is Map) {
          final headers =
              (firstItem as Map<String, dynamic>).keys.toList();
          buffer.writeln('| ${headers.join(' | ')} |');
          buffer.writeln('| ${headers.map((_) => '---').join(' | ')} |');
          for (final item in list) {
            if (item is Map) {
              final map = item as Map<String, dynamic>;
              final row = headers
                  .map((h) => map[h]?.toString() ?? '')
                  .toList();
              buffer.writeln('| ${row.join(' | ')} |');
            }
          }
        } else {
          buffer.writeln('| Value |');
          buffer.writeln('| --- |');
          for (final item in list) {
            buffer.writeln('| $item |');
          }
        }
        buffer.writeln();
      } else if (entry.value is Map) {
        buffer.writeln('| Key | Value |');
        buffer.writeln('| --- | --- |');
        final map = entry.value as Map<String, dynamic>;
        for (final field in map.entries) {
          buffer.writeln('| ${field.key} | ${field.value} |');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _formatAsHtml(Map<String, dynamic> data, ExportConfig config) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>SecurePass Pro Export</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 20px; color: #333; }');
    buffer.writeln('    h1 { color: #1a1a2e; border-bottom: 2px solid #e94560; padding-bottom: 8px; }');
    buffer.writeln('    h2 { color: #16213e; margin-top: 24px; }');
    buffer.writeln('    table { border-collapse: collapse; width: 100%; margin: 12px 0; }');
    buffer.writeln('    th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }');
    buffer.writeln('    th { background-color: #1a1a2e; color: white; }');
    buffer.writeln('    tr:nth-child(even) { background-color: #f2f2f2; }');
    buffer.writeln('    .meta { color: #666; font-size: 0.9em; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <h1>SecurePass Pro Export</h1>');
    if (config.includeMetadata) {
      buffer.writeln(
          '  <p class="meta">Exported: ${DateTime.now().toIso8601String()}</p>');
    }

    for (final entry in data.entries) {
      buffer.writeln('  <h2>${_escapeXml(entry.key)}</h2>');

      if (entry.value is List && (entry.value as List).isNotEmpty) {
        final list = entry.value as List;
        final firstItem = list.first;
        if (firstItem is Map) {
          final headers =
              (firstItem as Map<String, dynamic>).keys.toList();
          buffer.writeln('  <table>');
          buffer.writeln('    <thead><tr>');
          for (final h in headers) {
            buffer.writeln('      <th>${_escapeXml(h)}</th>');
          }
          buffer.writeln('    </tr></thead>');
          buffer.writeln('    <tbody>');
          for (final item in list) {
            if (item is Map) {
              final map = item as Map<String, dynamic>;
              buffer.writeln('      <tr>');
              for (final h in headers) {
                buffer.writeln(
                    '        <td>${_escapeXml(map[h]?.toString() ?? '')}</td>');
              }
              buffer.writeln('      </tr>');
            }
          }
          buffer.writeln('    </tbody>');
          buffer.writeln('  </table>');
        } else {
          buffer.writeln('  <table><thead><tr><th>Value</th></tr></thead><tbody>');
          for (final item in list) {
            buffer.writeln('    <tr><td>${_escapeXml(item.toString())}</td></tr>');
          }
          buffer.writeln('  </tbody></table>');
        }
      } else if (entry.value is Map) {
        final map = entry.value as Map<String, dynamic>;
        buffer.writeln('  <table><thead><tr><th>Key</th><th>Value</th></tr></thead><tbody>');
        for (final field in map.entries) {
          buffer.writeln(
              '    <tr><td>${_escapeXml(field.key)}</td><td>${_escapeXml(field.value?.toString() ?? '')}</td></tr>');
        }
        buffer.writeln('  </tbody></table>');
      }
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  String _formatAsXml(Map<String, dynamic> data, ExportConfig config) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<export>');

    if (config.includeMetadata) {
      buffer.writeln('  <metadata>');
      buffer.writeln('    <exportedAt>${DateTime.now().toIso8601String()}</exportedAt>');
      buffer.writeln('    <format>${_escapeXml(config.format.name)}</format>');
      buffer.writeln('  </metadata>');
    }

    buffer.writeln('  <data>');
    for (final entry in data.entries) {
      buffer.writeln('    <${entry.key}>');

      if (entry.value is List) {
        final list = entry.value as List;
        for (final item in list) {
          buffer.writeln('      <item>');
          if (item is Map) {
            final map = item as Map<String, dynamic>;
            for (final field in map.entries) {
              buffer.writeln(
                  '        <${field.key}>${_escapeXml(field.value?.toString() ?? '')}</${field.key}>');
            }
          } else {
            buffer.writeln('        <value>${_escapeXml(item.toString())}</value>');
          }
          buffer.writeln('      </item>');
        }
      } else if (entry.value is Map) {
        final map = entry.value as Map<String, dynamic>;
        for (final field in map.entries) {
          buffer.writeln(
              '      <${field.key}>${_escapeXml(field.value?.toString() ?? '')}</${field.key}>');
        }
      } else {
        buffer.writeln('      ${_escapeXml(entry.value?.toString() ?? '')}');
      }

      buffer.writeln('    </${entry.key}>');
    }
    buffer.writeln('  </data>');
    buffer.writeln('</export>');
    return buffer.toString();
  }

  String _formatAsYaml(Map<String, dynamic> data, ExportConfig config) {
    final buffer = StringBuffer();
    buffer.writeln('# SecurePass Pro Export');

    if (config.includeMetadata) {
      buffer.writeln('metadata:');
      buffer.writeln('  exportedAt: ${DateTime.now().toIso8601String()}');
      buffer.writeln('  format: ${config.format.name}');
      buffer.writeln();
    }

    buffer.writeln('data:');
    for (final entry in data.entries) {
      buffer.writeln('  ${entry.key}:');

      if (entry.value is List) {
        final list = entry.value as List;
        if (list.isEmpty) {
          buffer.writeln('    []');
        } else {
          for (final item in list) {
            if (item is Map) {
              final map = item as Map<String, dynamic>;
              var first = true;
              for (final field in map.entries) {
                final prefix = first ? '    - ' : '      ';
                buffer.writeln('$prefix${field.key}: ${_yamlEscape(field.value?.toString() ?? '')}');
                first = false;
              }
            } else {
              buffer.writeln('    - ${_yamlEscape(item.toString())}');
            }
          }
        }
      } else if (entry.value is Map) {
        final map = entry.value as Map<String, dynamic>;
        for (final field in map.entries) {
          buffer.writeln('      ${field.key}: ${_yamlEscape(field.value?.toString() ?? '')}');
        }
      } else {
        buffer.writeln('    ${_yamlEscape(entry.value?.toString() ?? '')}');
      }
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }

  String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _yamlEscape(String value) {
    if (value.isEmpty ||
        value.contains(':') ||
        value.contains('#') ||
        value.contains('\n') ||
        value.startsWith(' ') ||
        value.endsWith(' ') ||
        value == 'true' ||
        value == 'false' ||
        value == 'null') {
      return '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
    }
    return value;
  }

  String _maskValue(String value) {
    if (value.length <= 4) return '****';
    final visibleStart = value.substring(0, 2);
    final visibleEnd = value.substring(value.length - 2);
    final maskedLength = value.length - 4;
    return '$visibleStart${'*' * maskedLength}$visibleEnd';
  }

  Map<String, dynamic> _maskData(Map<String, dynamic> data) {
    final masked = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is List) {
        masked[entry.key] = (entry.value as List).map((item) {
          if (item is Map<String, dynamic>) {
            return _maskMap(item);
          }
          return _maskValue(item.toString());
        }).toList();
      } else if (entry.value is Map<String, dynamic>) {
        masked[entry.key] = _maskMap(entry.value as Map<String, dynamic>);
      } else {
        masked[entry.key] = entry.value;
      }
    }
    return masked;
  }

  Map<String, dynamic> _maskMap(Map<String, dynamic> map) {
    final masked = <String, dynamic>{};
    const sensitiveKeys = {
      'value',
      'password',
      'token',
      'secret',
      'key',
      'username',
    };
    for (final entry in map.entries) {
      if (sensitiveKeys.contains(entry.key.toLowerCase()) &&
          entry.value is String) {
        masked[entry.key] = _maskValue(entry.value as String);
      } else {
        masked[entry.key] = entry.value;
      }
    }
    return masked;
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
