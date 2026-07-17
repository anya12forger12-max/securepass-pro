import 'dart:async';

import 'app_error.dart';

class ErrorRecoveryAction {
  const ErrorRecoveryAction({
    required this.label,
    required this.action,
  });

  final String label;
  final Future<void> Function() action;
}

class ErrorReport {
  ErrorReport({
    required this.error,
    this.recoveryActions = const [],
    this.userMessage,
  });

  final AppError error;
  final List<ErrorRecoveryAction> recoveryActions;
  final String? userMessage;

  String get displayMessage => userMessage ?? _sanitizeMessage(error.message);

  static String _sanitizeMessage(String message) {
    final patterns = [
      RegExp(r'password[=:]\s*\S+', caseSensitive: false),
      RegExp(r'token[=:]\s*\S+', caseSensitive: false),
      RegExp(r'secret[=:]\s*\S+', caseSensitive: false),
      RegExp(r'key[=:]\s*\S+', caseSensitive: false),
      RegExp(r'credential[=:]\s*\S+', caseSensitive: false),
      RegExp(r'Bearer\s+\S+', caseSensitive: false),
    ];

    var sanitized = message;
    for (final pattern in patterns) {
      sanitized = sanitized.replaceAllMapped(pattern, (match) {
        final parts = match.group(0)!.split(RegExp(r'[=:\s]+'));
        if (parts.length >= 2) {
          return '${parts[0]}=[REDACTED]';
        }
        return '[REDACTED]';
      });
    }
    return sanitized;
  }
}

class ErrorHandler {
  ErrorHandler._();
  static final ErrorHandler _instance = ErrorHandler._();
  static ErrorHandler get instance => _instance;

  final List<void Function(AppError)> _listeners = [];
  final List<ErrorReport> _errorLog = [];
  int _maxLogSize = 100;

  void addListener(void Function(AppError) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(AppError) listener) {
    _listeners.remove(listener);
  }

  void setMaxLogSize(int size) {
    _maxLogSize = size;
    while (_errorLog.length > _maxLogSize) {
      _errorLog.removeAt(0);
    }
  }

  ErrorReport handle(AppError error, {String? userMessage}) {
    final report = ErrorReport(
      error: error,
      userMessage: userMessage,
      recoveryActions: _suggestRecovery(error),
    );

    _errorLog.add(report);
    if (_errorLog.length > _maxLogSize) {
      _errorLog.removeAt(0);
    }

    for (final listener in _listeners) {
      try {
        listener(error);
      } catch (_) {
        // Listeners must not crash the handler
      }
    }

    return report;
  }

  ErrorReport handleException(
    Object error, {
    StackTrace? stackTrace,
    String? userMessage,
  }) {
    if (error is AppError) {
      return handle(
        error,
        userMessage: userMessage,
      );
    }

    final appError = _wrapException(error, stackTrace);
    return handle(appError, userMessage: userMessage);
  }

  AppError _wrapException(Object error, StackTrace? stackTrace) {
    final message = error is Exception ? error.toString() : error.toString();
    return PlatformError(
      message: message,
      severity: ErrorSeverity.error,
      stackTrace: stackTrace,
      originalError: error,
    );
  }

  List<ErrorRecoveryAction> _suggestRecovery(AppError error) {
    return switch (error) {
      ValidationError() => [
          const ErrorRecoveryAction(
            label: 'Review input',
            action: _noopAction,
          ),
        ],
      SecurityError() => [
          const ErrorRecoveryAction(
            label: 'Re-authenticate',
            action: _noopAction,
          ),
          const ErrorRecoveryAction(
            label: 'Contact administrator',
            action: _noopAction,
          ),
        ],
      StorageError() => [
          const ErrorRecoveryAction(
            label: 'Retry operation',
            action: _noopAction,
          ),
          const ErrorRecoveryAction(
            label: 'Check storage space',
            action: _noopAction,
          ),
        ],
      NetworkError() => [
          const ErrorRecoveryAction(
            label: 'Check connection',
            action: _noopAction,
          ),
          const ErrorRecoveryAction(
            label: 'Retry',
            action: _noopAction,
          ),
        ],
      PlatformError() => [
          const ErrorRecoveryAction(
            label: 'Restart application',
            action: _noopAction,
          ),
        ],
      ConfigurationError() => [
          const ErrorRecoveryAction(
            label: 'Reset configuration',
            action: _noopAction,
          ),
          const ErrorRecoveryAction(
            label: 'Reinstall application',
            action: _noopAction,
          ),
        ],
    };
  }

  static Future<void> _noopAction() async {}

  List<ErrorReport> get errorLog => List.unmodifiable(_errorLog);

  ErrorReport? get lastError =>
      _errorLog.isNotEmpty ? _errorLog.last : null;

  void clearLog() {
    _errorLog.clear();
  }

  Future<T> guard<T>(
    Future<T> Function() operation, {
    required T fallback,
    String? context,
  }) async {
    try {
      return await operation();
    } on AppError catch (error) {
      handle(error);
      return fallback;
    } catch (error) {
      handleException(error);
      return fallback;
    }
  }

  Stream<T> guardStream<T>(
    Stream<T> stream, {
    String? context,
  }) async* {
    yield* stream.handleError((Object error, StackTrace stackTrace) {
      if (error is AppError) {
        handle(error);
      } else {
        handleException(error, stackTrace: stackTrace);
      }
    });
  }
}
