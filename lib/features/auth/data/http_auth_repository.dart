import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/token_store.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

/// [AuthRepository] over the ERP's general auth endpoint.
///
/// `POST /v2/auth/login` returns `user.id`, not an `operatorId` field — but
/// that id is confirmed to be the same GUID the SCN endpoints call
/// `operatorId`, so [Session.operatorId] is read straight from it.
class HttpAuthRepository implements AuthRepository {
  const HttpAuthRepository(this._dio, this._tokenStore);

  final Dio _dio;
  final TokenStore _tokenStore;

  @override
  Future<Result<Session>> signIn({
    required String email,
    required String password,
  }) => Result.guard(() async {
    final Response<Map<String, Object?>> res;
    try {
      res = await _dio.post<Map<String, Object?>>(
        '/v2/auth/login',
        data: <String, String>{'email': email, 'password': password},
      );
    } on DioException catch (e) {
      // A 401/403 here means the credentials were rejected on a fresh
      // attempt, not that an existing session expired — `mapDioError`'s
      // generic wording is written for the latter and would mislead an
      // operator who just mistyped a password. Every other status still
      // goes through the shared mapper.
      final int? status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw const AuthException('Incorrect email or password.');
      }
      throw mapDioError(e);
    }

    final Map<String, Object?> body = res.data!;
    if (body['success'] != true) {
      throw const AuthException('Sign-in was rejected.');
    }
    final Map<String, Object?> user = body['user']! as Map<String, Object?>;
    final Session session = Session(
      token: body['token']! as String,
      refreshToken: body['refreshToken']! as String,
      expiresAt: DateTime.now().add(
        Duration(seconds: body['expiresIn']! as int),
      ),
      operatorId: user['id']! as String,
      name: user['name']! as String,
      email: user['email']! as String,
      role: user['role']! as String,
    );

    await _tokenStore.save(
      token: session.token,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
      operatorId: session.operatorId,
      name: session.name,
      email: session.email,
      role: session.role,
    );
    return session;
  });

  @override
  Future<Result<Session?>> restore() => Result.guard(() async {
    final Map<String, String>? raw = await _tokenStore.readAll();
    if (raw == null) return null;
    return Session(
      token: raw['token']!,
      refreshToken: raw['refreshToken']!,
      expiresAt: DateTime.parse(raw['expiresAt']!),
      operatorId: raw['operatorId']!,
      name: raw['name']!,
      email: raw['email']!,
      role: raw['role']!,
    );
  });

  @override
  Future<Result<void>> signOut() => Result.guard(() => _tokenStore.clear());
}
