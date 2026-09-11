import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result/result.dart';
import '../../../data/network_providers.dart';
import '../domain/session.dart';

part 'auth_controller.g.dart';

/// The signed-in operator's session, or null when signed out.
///
/// `keepAlive` because a session must not depend on something happening to
/// watch it — the router listens, which means a refactor there could
/// otherwise sign the operator out mid-shift.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<Session?> build() async {
    final Result<Session?> result = await ref
        .read(authRepositoryProvider)
        .restore();
    return result.valueOrNull;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading<Session?>();
    final Result<Session> result = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    state = switch (result) {
      Success<Session>(:final Session value) => AsyncData<Session?>(value),
      Failure<Session>(:final error) => AsyncError<Session?>(
        error,
        StackTrace.current,
      ),
    };
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData<Session?>(null);
  }
}
