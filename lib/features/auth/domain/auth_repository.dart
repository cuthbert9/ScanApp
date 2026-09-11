import '../../../core/result/result.dart';
import 'session.dart';

/// Signs an operator in and persists the resulting session.
abstract interface class AuthRepository {
  Future<Result<Session>> signIn({
    required String email,
    required String password,
  });

  /// The persisted session, if the device was left signed in.
  Future<Result<Session?>> restore();

  Future<Result<void>> signOut();
}
