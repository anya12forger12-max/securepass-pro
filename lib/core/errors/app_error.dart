enum ErrorSeverity {
  info('INFO'),
  warning('WARNING'),
  error('ERROR'),
  critical('CRITICAL');

  const ErrorSeverity(this.label);
  final String label;

  bool get isSevere => this == ErrorSeverity.error || this == ErrorSeverity.critical;
}

sealed class AppError implements Exception {
  AppError({
    required this.message,
    required this.code,
    this.severity = ErrorSeverity.error,
    DateTime? timestamp,
    this.stackTrace,
    this.originalError,
  })  : timestamp = timestamp ?? DateTime.now();

  final String message;
  final String code;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final StackTrace? stackTrace;
  final Object? originalError;

  @override
  String toString() => '[$severity] ($code): $message';

  Map<String, dynamic> toMap() => {
        'message': message,
        'code': code,
        'severity': severity.label,
        'timestamp': timestamp.toIso8601String(),
        'type': runtimeType.toString(),
      };
}

final class ValidationError extends AppError {
  ValidationError({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.severity = ErrorSeverity.warning,
    super.timestamp,
    super.stackTrace,
    super.originalError,
    this.field,
    this.validatorName,
  });

  final String? field;
  final String? validatorName;

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (field != null) 'field': field,
        if (validatorName != null) 'validator': validatorName,
      };
}

final class SecurityError extends AppError {
  SecurityError({
    required super.message,
    super.code = 'SECURITY_ERROR',
    super.severity = ErrorSeverity.critical,
    super.timestamp,
    super.stackTrace,
    super.originalError,
    this.securityContext,
  });

  final String? securityContext;

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (securityContext != null) 'securityContext': securityContext,
      };
}

final class StorageError extends AppError {
  StorageError({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.severity = ErrorSeverity.error,
    super.timestamp,
    super.stackTrace,
    super.originalError,
    this.storageType,
    this.operation,
  });

  final String? storageType;
  final String? operation;

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (storageType != null) 'storageType': storageType,
        if (operation != null) 'operation': operation,
      };
}

final class NetworkError extends AppError {
  NetworkError({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.severity = ErrorSeverity.error,
    super.timestamp,
    super.stackTrace,
    super.originalError,
    this.statusCode,
    this.url,
  });

  final int? statusCode;
  final String? url;

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (statusCode != null) 'statusCode': statusCode,
        if (url != null) 'url': url,
      };
}

final class PlatformError extends AppError {
  PlatformError({
    required super.message,
    super.code = 'PLATFORM_ERROR',
    super.severity = ErrorSeverity.error,
    super.timestamp,
    super.stackTrace,
    super.originalError,
    this.platform,
    this.feature,
  });

  final String? platform;
  final String? feature;

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (platform != null) 'platform': platform,
        if (feature != null) 'feature': feature,
      };
}

final class ConfigurationError extends AppError {
  ConfigurationError({
    required super.message,
    super.code = 'CONFIGURATION_ERROR',
    super.severity = ErrorSeverity.critical,
    super.timestamp,
    super.stackTrace,
    super.originalError,
    this.configKey,
  });

  final String? configKey;

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (configKey != null) 'configKey': configKey,
      };
}
