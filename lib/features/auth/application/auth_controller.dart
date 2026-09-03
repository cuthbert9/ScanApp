import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

/// Whether an operator is signed in.
///
/// Deliberately a bare bool for now: sign-in is a stub until the backend auth
/// endpoint exists. When it lands, this becomes an `AsyncNotifier` holding a
/// session, and the only other change is that [signIn] awaits a repository.
/// The router guard and the login screen stay as they are.
///
/// `keepAlive` because a session must not depend on something happening to
/// watch it. Auto-disposed, it survives today only because the router listens —
/// which means a refactor of the router could silently sign the operator out
/// mid-shift.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  bool build() => false;

  /// Stub sign-in. Accepts anything — no credentials are checked yet.
  void signIn() => state = true;

  void signOut() => state = false;
}
