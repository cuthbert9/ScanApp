import '../errors/app_exception.dart';

/// A success-or-failure value, used at repository boundaries.
///
/// Repositories return `Result<T>` instead of throwing, which puts the failure
/// path in the type and makes it impossible to forget. Callers unwrap with a
/// `switch`; because [Result] is `sealed`, the analyzer enforces that both
/// branches are handled.
///
/// ```dart
/// final Result<LoadingQueueSnapshot> result = await repository.fetch();
/// switch (result) {
///   case Success<LoadingQueueSnapshot>(:final value):
///     return value;
///   case Failure<LoadingQueueSnapshot>(:final error):
///     throw error;
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Runs [body], converting a thrown [AppException] into a [Failure].
  ///
  /// Other throws are deliberately NOT swallowed: they indicate a programming
  /// error and should crash loudly in development rather than reach an
  /// operator as a generic failure message.
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Success<T>(await body());
    } on AppException catch (e) {
      return Failure<T>(e);
    }
  }

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// The value, or null when this is a [Failure].
  T? get valueOrNull => switch (this) {
    Success<T>(:final T value) => value,
    Failure<T>() => null,
  };

  /// The error, or null when this is a [Success].
  AppException? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final AppException error) => error,
  };

  /// Transforms a success value, leaving a failure untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final T value) => Success<R>(transform(value)),
    Failure<T>(:final AppException error) => Failure<R>(error),
  };

  /// Collapses both branches into a single value.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppException error) onFailure,
  }) => switch (this) {
    Success<T>(:final T value) => onSuccess(value),
    Failure<T>(:final AppException error) => onFailure(error),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;

  @override
  String toString() => 'Success($value)';
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppException error;

  @override
  String toString() => 'Failure($error)';
}
