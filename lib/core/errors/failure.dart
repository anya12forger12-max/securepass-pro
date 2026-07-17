sealed class Failure {
  const Failure({
    required this.message,
    required this.code,
  });

  final String message;
  final String code;

  @override
  String toString() => 'Failure($code): $message';
}

final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_FAILURE',
    this.field,
    this.details,
  });

  final String? field;
  final Map<String, dynamic>? details;
}

final class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code = 'STORAGE_FAILURE',
    this.operation,
    this.storageType,
  });

  final String? operation;
  final String? storageType;
}

final class SecurityFailure extends Failure {
  const SecurityFailure({
    required super.message,
    super.code = 'SECURITY_FAILURE',
    this.securityContext,
  });

  final String? securityContext;
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code = 'NOT_FOUND_FAILURE',
    this.resourceType,
    this.resourceId,
  });

  final String? resourceType;
  final String? resourceId;
}

final class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code = 'UNKNOWN_FAILURE',
    this.originalError,
  });

  final Object? originalError;
}
