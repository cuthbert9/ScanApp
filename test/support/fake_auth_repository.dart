import 'package:scanapp/core/result/result.dart';
import 'package:scanapp/features/auth/domain/auth_repository.dart';
import 'package:scanapp/features/auth/domain/session.dart';

/// A pre-signed-in [AuthRepository] for widget tests that exercise the
/// mock-backed screens (Orders/Scan/Load/Sync/Settings) — those tests are
/// about the five tabs, not auth, so they start signed in already rather than
/// calling the real login endpoint.
class FakeAuthRepository implements AuthRepository {
  const FakeAuthRepository();

  static final Session session = Session(
    token: 'test-token',
    refreshToken: 'test-refresh-token',
    expiresAt: DateTime(2100),
    operatorId: 'test-operator',
    name: 'Test Operator',
    email: 'test.operator@example.com',
    role: 'operator',
  );

  @override
  Future<Result<Session>> signIn({
    required String email,
    required String password,
  }) async => Success<Session>(session);

  @override
  Future<Result<Session?>> restore() async => Success<Session?>(session);

  @override
  Future<Result<void>> signOut() async => const Success<void>(null);
}
