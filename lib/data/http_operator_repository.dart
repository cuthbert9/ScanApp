import 'package:dio/dio.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/result/result.dart';
import '../domain/models/operator_profile.dart';
import '../domain/repositories/operator_repository.dart';

class HttpOperatorRepository implements OperatorRepository {
  const HttpOperatorRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<OperatorProfile>> byId(String operatorId) =>
      Result.guard(() async {
        try {
          final Response<Map<String, Object?>> res = await _dio
              .get<Map<String, Object?>>('/v2/scn/operators/$operatorId');
          return OperatorProfile.fromJson(
            res.data!['operator']! as Map<String, Object?>,
          );
        } on DioException catch (e) {
          throw mapDioError(e);
        }
      });
}
