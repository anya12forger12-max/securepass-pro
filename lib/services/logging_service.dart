import 'dart:convert';

import 'package:securepass_pro/domain/enums/log_level.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class LoggingService {
  LoggingService._();
  static final LoggingService _instance = LoggingService._();
  static LoggingService get instance => _instance;

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    AppLogger.instance.info('Logging service initialized', category: 'LOGGING');
  }

  void log(String category, LogLevel level, String message) {
    switch (level) {
      case LogLevel.debug:
        AppLogger.instance.debug(message, category: category);
      case LogLevel.info:
        AppLogger.instance.info(message, category: category);
      case LogLevel.warning:
        AppLogger.instance.warning(message, category: category);
      case LogLevel.error:
        AppLogger.instance.error(message, category: category);
      case LogLevel.severe:
        AppLogger.instance.severe(message, category: category);
    }
  }

  void debug(String category, String message) =>
      AppLogger.instance.debug(message, category: category);

  void info(String category, String message) =>
      AppLogger.instance.info(message, category: category);

  void warning(String category, String message) =>
      AppLogger.instance.warning(message, category: category);

  void error(String category, String message) =>
      AppLogger.instance.error(message, category: category);

  void severe(String category, String message) =>
      AppLogger.instance.severe(message, category: category);

  List<LogEntry> getLogsForCategory(String category) {
    return AppLogger.instance.getLogs().where((e) => e.category == category).toList();
  }

  List<LogEntry> getAllLogs() => AppLogger.instance.getLogs();

  void clearLogs() {
    AppLogger.instance.clearLogs();
    AppLogger.instance.info('Logs cleared', category: 'LOGGING');
  }

  String exportSanitizedLogs() {
    final logs = getAllLogs();
    final exportData = logs.map((e) => {
      'timestamp': e.timestamp.toIso8601String(),
      'level': e.level,
      'category': e.category,
      'message': e.message,
    }).toList();
    return jsonEncode({
      'exportedAt': DateTime.now().toIso8601String(),
      'count': exportData.length,
      'logs': exportData,
    });
  }
}
