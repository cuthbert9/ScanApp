import 'package:freezed_annotation/freezed_annotation.dart';

part 'operator_profile.freezed.dart';

/// Who is signed in and working this shift.
@freezed
abstract class OperatorProfile with _$OperatorProfile {
  const factory OperatorProfile({
    required String name,

    /// Staff number as printed on the badge, e.g. `MSD-OP-2214`.
    required String staffId,

    /// Job title, e.g. `Loading Officer II`.
    required String role,

    /// When this shift opened and when it is due to close.
    required DateTime shiftStart,
    required DateTime shiftEnd,

    @Default(true) bool isOnShift,
  }) = _OperatorProfile;

  const OperatorProfile._();

  /// Up to two letters for the avatar. Derived so it cannot disagree with
  /// [name] after a correction.
  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';

    // `runes` rather than `substring(0, 1)`: it takes a whole code point, so a
    // name outside the basic plane does not get cut in half.
    String firstLetter(String word) => String.fromCharCode(word.runes.first);

    if (parts.length == 1) return firstLetter(parts.first).toUpperCase();
    return (firstLetter(parts.first) + firstLetter(parts.last)).toUpperCase();
  }
}
