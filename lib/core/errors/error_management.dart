import 'package:securepass_pro/core/errors/app_error.dart';
import 'package:securepass_pro/infrastructure/event_bus/event_bus.dart';

enum RecoveryStrategy { retry, fallback, skip, abort, userAction }

class ErrorCategory {
  const ErrorCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.defaultRecovery = RecoveryStrategy.abort,
  });

  final String id;
  final String name;
  final String description;
  final RecoveryStrategy defaultRecovery;
}

class ErrorWithContext {
  const ErrorWithContext({
    required this.error,
    required this.category,
    this.context = const {},
    this.userMessage = '',
    this.developerMessage = '',
    this.recoveryStrategy,
  });

  final AppError error;
  final ErrorCategory category;
  final Map<String, dynamic> context;
  final String userMessage;
  final String developerMessage;
  final RecoveryStrategy? recoveryStrategy;

  RecoveryStrategy get effectiveRecovery => recoveryStrategy ?? category.defaultRecovery;
}

class ErrorEvent extends AppEvent {
  const ErrorEvent({
    required this.error,
    required this.category,
    required this.severity,
    super.source,
    super.timestamp,
  });

  final AppError error;
  final ErrorCategory category;
  final ErrorSeverity severity;
}

class ErrorManagement {
  ErrorManagement._();
  static final ErrorManagement instance = ErrorManagement._();

  final EventBus _eventBus = EventBus.instance;
  final List<ErrorWithContext> _errorLog = [];
  final Map<String, ErrorCategory> _categories = {};
  int _maxLogSize = 200;

  void initialize() {
    _registerDefaultCategories();
  }

  void _registerDefaultCategories() {
    registerCategory(const ErrorCategory(
      id: 'storage', name: 'Storage Errors',
      description: 'Errors related to data persistence',
      defaultRecovery: RecoveryStrategy.retry,
    ));
    registerCategory(const ErrorCategory(
      id: 'network', name: 'Network Errors',
      description: 'Errors related to network connectivity',
      defaultRecovery: RecoveryStrategy.fallback,
    ));
    registerCategory(const ErrorCategory(
      id: 'validation', name: 'Validation Errors',
      description: 'Errors related to input validation',
      defaultRecovery: RecoveryStrategy.userAction,
    ));
    registerCategory(const ErrorCategory(
      id: 'security', name: 'Security Errors',
      description: 'Errors related to security operations',
      defaultRecovery: RecoveryStrategy.abort,
    ));
    registerCategory(const ErrorCategory(
      id: 'migration', name: 'Migration Errors',
      description: 'Errors related to data migration',
      defaultRecovery: RecoveryStrategy.retry,
    ));
    registerCategory(const ErrorCategory(
      id: 'permission', name: 'Permission Errors',
      description: 'Errors related to permission checks',
      defaultRecovery: RecoveryStrategy.userAction,
    ));
    registerCategory(const ErrorCategory(
      id: 'configuration', name: 'Configuration Errors',
      description: 'Errors related to app configuration',
      defaultRecovery: RecoveryStrategy.fallback,
    ));
    registerCategory(const ErrorCategory(
      id: 'platform', name: 'Platform Errors',
      description: 'Errors related to platform capabilities',
      defaultRecovery: RecoveryStrategy.skip,
    ));
    registerCategory(const ErrorCategory(
      id: 'unknown', name: 'Unknown Errors',
      description: 'Uncategorized errors',
      defaultRecovery: RecoveryStrategy.abort,
    ));
  }

  void registerCategory(ErrorCategory category) {
    _categories[category.id] = category;
  }

  ErrorWithContext handleError(AppError error, {String categoryId = 'unknown', Map<String, dynamic> context = const {}}) {
    final category = _categories[categoryId] ?? _categories['unknown']!;
    final errorWithContext = ErrorWithContext(
      error: error,
      category: category,
      context: context,
      userMessage: _generateUserMessage(error),
      developerMessage: _generateDeveloperMessage(error, context),
    );
    _errorLog.add(errorWithContext);
    if (_errorLog.length > _maxLogSize) {
      _errorLog.removeAt(0);
    }
    _eventBus.publish(ErrorEvent(
      error: error,
      category: category,
      severity: error.severity,
      source: 'ErrorManagement',
    ));
    return errorWithContext;
  }

  String _generateUserMessage(AppError error) {
    return switch (error) {
      ValidationError() => 'Please check your input and try again.',
      StorageError() => 'There was a problem saving your data. Please try again.',
      SecurityError() => 'A security issue was detected. Please check your settings.',
      NetworkError() => 'Network connection issue. Please check your connection.',
      PlatformError() => 'This feature is not available on your device.',
      ConfigurationError() => 'There was a configuration issue. Please check settings.',
    };
  }

  String _generateDeveloperMessage(AppError error, Map<String, dynamic> context) {
    return '[${error.code}] ${error.message} | Context: $context';
  }

  List<ErrorWithContext> getErrorLog({String? categoryId, int? limit}) {
    var log = List<ErrorWithContext>.from(_errorLog);
    if (categoryId != null) log = log.where((e) => e.category.id == categoryId).toList();
    if (limit != null && log.length > limit) log = log.sublist(log.length - limit);
    return log;
  }

  ErrorCategory? getCategory(String id) => _categories[id];
  List<ErrorCategory> getAllCategories() => List.unmodifiable(_categories.values);
  void clearLog() => _errorLog.clear();

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalErrors': _errorLog.length,
      'categories': _categories.length,
      'errorsByCategory': {
        for (final cat in _categories.values)
          cat.id: _errorLog.where((e) => e.category.id == cat.id).length,
      },
      'errorsBySeverity': {
        for (final sev in ErrorSeverity.values)
          sev.name: _errorLog.where((e) => e.error.severity == sev).length,
      },
    };
  }
}
