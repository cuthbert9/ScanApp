/// The app's error vocabulary.
///
/// Every failure that crosses a layer boundary is one of these. Data sources
/// translate their own errors — HTTP, socket, platform channel, SQL — into an
/// [AppException] at the repository edge, so controllers and UI never have to
/// know which transport failed.
///
/// Being `sealed` means the analyzer flags a `switch` that misses a case, so a
/// new failure kind cannot silently fall through to a generic "something went
/// wrong" screen.
library;

sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  /// Operator-facing summary. Short and actionable — it may be read at arm's
  /// length on a 4.3" screen in a warehouse aisle.
  final String message;

  /// The underlying error, kept for logs. Never shown to an operator.
  final Object? cause;

  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// The device could not reach the backend at all — the usual case in a
/// warehouse Wi-Fi dead zone.
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

/// The server answered with an error status.
final class ServerException extends AppException {
  const ServerException(
    super.message, {
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;
}

/// Credentials missing, expired, or rejected.
final class AuthException extends AppException {
  const AuthException(super.message, {super.cause, super.stackTrace});
}

/// Well-formed request, rejected input — a bad SKU, a quantity over the limit,
/// a closed order.
final class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.fieldErrors = const <String, String>{},
    super.cause,
    super.stackTrace,
  });

  /// Field name → message, for inline form errors.
  final Map<String, String> fieldErrors;
}

/// Local persistence failed — database, secure storage, file system.
final class StorageException extends AppException {
  const StorageException(super.message, {super.cause, super.stackTrace});
}

/// The barcode scanner is unavailable, disabled, or returned an error.
final class ScannerException extends AppException {
  const ScannerException(super.message, {super.cause, super.stackTrace});
}

/// A response could not be parsed into the expected shape.
final class ParseException extends AppException {
  const ParseException(super.message, {super.cause, super.stackTrace});
}

/// Anything not covered above. Prefer adding a specific case over reaching for
/// this one.
final class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause, super.stackTrace});
}
