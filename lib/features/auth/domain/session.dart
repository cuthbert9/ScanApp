import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';

/// The signed-in operator's authenticated session.
///
/// `operatorId` is the ERP's `user.id` from the login response — confirmed to
/// be the same identity the SCN endpoints call `operatorId`, so no separate
/// lookup is needed.
@freezed
abstract class Session with _$Session {
  const factory Session({
    required String token,
    required String refreshToken,
    required DateTime expiresAt,
    required String operatorId,
    required String name,
    required String email,
    required String role,
  }) = _Session;

  const Session._();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
