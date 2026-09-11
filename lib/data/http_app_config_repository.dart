import 'package:dio/dio.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/result/result.dart';
import '../domain/models/app_remote_config.dart';
import '../domain/repositories/app_config_repository.dart';

class HttpAppConfigRepository implements AppConfigRepository {
  const HttpAppConfigRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<AppRemoteConfig>> current() => Result.guard(() async {
    try {
      final Response<Map<String, Object?>> res = await _dio
          .get<Map<String, Object?>>('/v2/scn/app/config');
      return AppRemoteConfig.fromJson(res.data ?? const <String, Object?>{});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  });
}
