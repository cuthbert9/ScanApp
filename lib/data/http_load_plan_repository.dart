import 'package:dio/dio.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/result/result.dart';
import '../domain/models/item_lookup_result.dart';
import '../domain/models/load_plan.dart';
import '../domain/models/load_plan_item.dart';
import '../domain/repositories/load_plan_repository.dart';

/// [LoadPlanRepository] over the ERP's SCN module.
class HttpLoadPlanRepository implements LoadPlanRepository {
  const HttpLoadPlanRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<LoadPlan>>> assignedTo(String operatorId) =>
      Result.guard(() async {
        try {
          final Response<Map<String, Object?>> res = await _dio
              .get<Map<String, Object?>>(
                '/v2/scn/operators/$operatorId/load-plans',
              );
          final List<Object?> raw =
              (res.data!['loadplans'] as List<Object?>?) ?? const <Object?>[];
          return raw
              .map((Object? e) => LoadPlan.fromJson(e! as Map<String, Object?>))
              .toList();
        } on DioException catch (e) {
          throw mapDioError(e);
        }
      });

  @override
  Future<Result<LoadPlan>> byId(String loadPlanId) => Result.guard(() async {
    try {
      final Response<Map<String, Object?>> res = await _dio
          .get<Map<String, Object?>>('/v2/scn/load-plans/$loadPlanId');
      return LoadPlan.fromJson(res.data!['loadplan']! as Map<String, Object?>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  });

  @override
  Future<Result<List<LoadPlanItem>>> items(
    String loadPlanId,
  ) => Result.guard(() async {
    try {
      final Response<Map<String, Object?>> res = await _dio
          .get<Map<String, Object?>>('/v2/scn/load-plans/$loadPlanId/items');
      final List<Object?> raw =
          (res.data!['items'] as List<Object?>?) ?? const <Object?>[];
      return raw
          .map((Object? e) => LoadPlanItem.fromJson(e! as Map<String, Object?>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  });

  @override
  Future<Result<ItemLookupResult>> lookupBarcode(String barcode) =>
      Result.guard(() async {
        try {
          final Response<Map<String, Object?>> res = await _dio
              .get<Map<String, Object?>>('/v2/scn/items/by-barcode/$barcode');
          return ItemLookupResult.fromJson(
            res.data!['item']! as Map<String, Object?>,
          );
        } on DioException catch (e) {
          throw mapDioError(e);
        }
      });
}
