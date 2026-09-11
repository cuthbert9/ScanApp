import 'package:dio/dio.dart';

import 'api_config.dart';

/// The single configured Dio instance for every HTTP repository.
///
/// Reads its bearer token from [getToken] rather than from auth state
/// directly — `core/` must not depend on `features/auth` (rule 3). The
/// composition root in `lib/data/` wires the real token source in.
class ApiClient {
  ApiClient({this.getToken})
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final String? token = await getToken?.call();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
      ),
    );
  }

  final Dio dio;
  final Future<String?> Function()? getToken;
}
