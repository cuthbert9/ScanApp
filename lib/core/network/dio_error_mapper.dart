import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Translates a [DioException] into the app's own error vocabulary, so
/// nothing above the repository layer ever sees a transport-specific type.
AppException mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return NetworkException('No link to the dispatch server.', cause: e);
    case DioExceptionType.badCertificate:
      return NetworkException(
        'The server certificate could not be verified.',
        cause: e,
      );
    case DioExceptionType.badResponse:
      final int? status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return AuthException('Session expired — sign in again.', cause: e);
      }
      if (status == 400 || status == 404 || status == 409) {
        return ValidationException(
          _extractMessage(e.response?.data) ?? 'Rejected by the server.',
          cause: e,
        );
      }
      return ServerException(
        'The server could not complete this request.',
        statusCode: status,
        cause: e,
      );
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return UnknownException('Unexpected network error.', cause: e);
  }
}

String? _extractMessage(Object? data) => data is Map<String, Object?>
    ? (data['message'] ?? data['error'] ?? data['detail']) as String?
    : null;
