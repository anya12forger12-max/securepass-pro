import 'package:logging/logging.dart';
import 'package:securepass_pro/core/utils/sanitizer.dart';
import 'package:securepass_pro/domain/enums/log_level.dart';

class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.category,
  });

  final DateTime timestamp;
  final String level;
  final String message;
  final String category;

  @override
  String toString() => '[${timestamp.toIso8601String()}] [$level] [$category] $message';
}

class AppLogger {
  AppLogger._();
  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;

  final Logger _logger = Logger('SecurePassPro');
  final List<LogEntry> _logBuffer = [];
  static const int _maxBufferSize = 500;
  LogLevel _minLevel = LogLevel.debug;

  void setMinLevel(LogLevel level) => _minLevel = level;

  void debug(String message, {String category = 'APP'}) {
    _log(LogLevel.debug, message, category);
  }

  void info(String message, {String category = 'APP'}) {
    _log(LogLevel.info, message, category);
  }

  void warning(String message, {String category = 'APP'}) {
    _log(LogLevel.warning, message, category);
  }

  void error(String message, {String category = 'APP', Object? error}) {
    _log(LogLevel.error, message, category);
  }

  void severe(String message, {String category = 'APP', Object? error}) {
    _log(LogLevel.severe, message, category);
  }

  void _log(LogLevel level, String message, String category) {
    if (level.value < _minLevel.value) return;
    final sanitized = LogSanitizer.sanitize(message);
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level.label,
      message: sanitized,
      category: category,
    );
    _logBuffer.add(entry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
    _logger.log(Level(level.label, level.value), '[$category] $sanitized');
  }

  List<LogEntry> getLogs({LogLevel? minLevel}) {
    final effectiveLevel = minLevel ?? _minLevel;
    return List.unmodifiable(
      _logBuffer.where((e) {
        final entryLevel = LogLevel.values.firstWhere(
          (l) => l.label == e.level,
          orElse: () => LogLevel.debug,
        );
        return entryLevel.value >= effectiveLevel.value;
      }),
    );
  }

  List<LogEntry> get exportLogs => List.unmodifiable(_logBuffer);

  void clearLogs() => _logBuffer.clear();
}
