import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../domain/repositories/app_config_repository.dart';
import '../domain/repositories/load_plan_repository.dart';
import '../domain/repositories/operator_repository.dart';
import '../features/auth/data/http_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import 'http_app_config_repository.dart';
import 'http_load_plan_repository.dart';
import 'http_operator_repository.dart';

part 'network_providers.g.dart';

/// The composition root for networking + the real SCN backend.
///
/// This is the one file allowed to import both `core/` and `features/` for
/// wiring purposes — `core/network` itself stays feature-agnostic (rule 3).

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => TokenStore();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final TokenStore store = ref.watch(tokenStoreProvider);
  return ApiClient(getToken: store.readToken);
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) => ref.watch(apiClientProvider).dio;

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    HttpAuthRepository(ref.watch(dioProvider), ref.watch(tokenStoreProvider));

@Riverpod(keepAlive: true)
AppConfigRepository appConfigRepository(Ref ref) =>
    HttpAppConfigRepository(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
OperatorRepository operatorRepository(Ref ref) =>
    HttpOperatorRepository(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
LoadPlanRepository loadPlanRepository(Ref ref) =>
    HttpLoadPlanRepository(ref.watch(dioProvider));
