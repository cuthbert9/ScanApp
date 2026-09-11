import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the signed-in session's raw fields in the device's secure
/// storage.
///
/// Deliberately untyped (flat string keys) rather than storing a `Session`
/// object directly — `core/` must not depend on `features/auth` (rule 3), so
/// the conversion to/from `Session` happens in `HttpAuthRepository`.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _kToken = 'auth.token';
  static const String _kRefreshToken = 'auth.refreshToken';
  static const String _kExpiresAt = 'auth.expiresAt';
  static const String _kOperatorId = 'auth.operatorId';
  static const String _kName = 'auth.name';
  static const String _kEmail = 'auth.email';
  static const String _kRole = 'auth.role';

  /// Just the bearer token, for the request interceptor — cheaper than
  /// [readAll] on every outgoing call.
  Future<String?> readToken() => _storage.read(key: _kToken);

  /// The full persisted session, or null when any field is missing (a clean
  /// install, a partial write that was interrupted, or nothing saved yet).
  Future<Map<String, String>?> readAll() async {
    final Map<String, String?> raw = <String, String?>{
      'token': await _storage.read(key: _kToken),
      'refreshToken': await _storage.read(key: _kRefreshToken),
      'expiresAt': await _storage.read(key: _kExpiresAt),
      'operatorId': await _storage.read(key: _kOperatorId),
      'name': await _storage.read(key: _kName),
      'email': await _storage.read(key: _kEmail),
      'role': await _storage.read(key: _kRole),
    };
    if (raw.values.any((String? v) => v == null)) return null;
    return raw.cast<String, String>();
  }

  Future<void> save({
    required String token,
    required String refreshToken,
    required DateTime expiresAt,
    required String operatorId,
    required String name,
    required String email,
    required String role,
  }) => Future.wait(<Future<void>>[
    _storage.write(key: _kToken, value: token),
    _storage.write(key: _kRefreshToken, value: refreshToken),
    _storage.write(key: _kExpiresAt, value: expiresAt.toIso8601String()),
    _storage.write(key: _kOperatorId, value: operatorId),
    _storage.write(key: _kName, value: name),
    _storage.write(key: _kEmail, value: email),
    _storage.write(key: _kRole, value: role),
  ]);

  Future<void> clear() => _storage.deleteAll();
}
