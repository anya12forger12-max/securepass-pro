import '../errors/failure.dart';

sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccessful => this is Success<T>;
  bool get isError => this is FailureResult<T>;

  T? get data => switch (this) {
        Success<T>(:final data) => data,
        FailureResult<T>() => null,
      };

  Failure? get failure => switch (this) {
        Success<T>() => null,
        FailureResult<T>(:final failure) => failure,
      };

  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => Result.success(transform(data)),
      FailureResult<T>(:final failure) => Result.failure(failure),
    };
  }

  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => transform(data),
      FailureResult<T>(:final failure) => Result.failure(failure),
    };
  }

  T fold(T Function() onEmpty, T Function(T data) onSuccess) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      FailureResult<T>() => onEmpty(),
    };
  }

  T orElse(T Function(Failure failure) onFailure) {
    return switch (this) {
      Success<T>(:final data) => data,
      FailureResult<T>(:final failure) => onFailure(failure),
    };
  }

  T? get orNull => switch (this) {
        Success<T>(:final data) => data,
        FailureResult<T>() => null,
      };

  Result<T> tap({
    void Function(T data)? onSuccess,
    void Function(Failure failure)? onError,
  }) {
    if (this is Success<T> && onSuccess != null) {
      onSuccess((this as Success<T>).data);
    } else if (this is FailureResult<T> && onError != null) {
      onError((this as FailureResult<T>).failure);
    }
    return this;
  }

  Result<T> onSuccess(void Function(T data) callback) {
    if (this is Success<T>) {
      callback((this as Success<T>).data);
    }
    return this;
  }

  Result<T> onError(void Function(Failure failure) callback) {
    if (this is FailureResult<T>) {
      callback((this as FailureResult<T>).failure);
    }
    return this;
  }

  @override
  String toString() => switch (this) {
        Success<T>(:final data) => 'Result.success($data)',
        FailureResult<T>(:final failure) => 'Result.failure($failure)',
      };
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  @override
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  @override
  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailureResult<T> && failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}
