import 'package:freezed_annotation/freezed_annotation.dart';

part 'operator_profile.freezed.dart';
part 'operator_profile.g.dart';

/// Basic operator profile as the scanning app sees it.
///
/// Deliberately lean — unlike `Officer` (staff number, grade, shift window,
/// all still mock-only), this maps exactly to what
/// `GET /v2/scn/operators/{operatorId}` actually returns.
@freezed
abstract class OperatorProfile with _$OperatorProfile {
  const factory OperatorProfile({
    required String id,
    required String username,
    required String name,
    required String role,
  }) = _OperatorProfile;

  factory OperatorProfile.fromJson(Map<String, Object?> json) =>
      _$OperatorProfileFromJson(json);
}
