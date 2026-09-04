import 'package:freezed_annotation/freezed_annotation.dart';

part 'officer.freezed.dart';

/// The person signed in and working a shift.
@freezed
abstract class Officer with _$Officer {
  const factory Officer({
    required String id,
    required String name,

    /// Staff number as printed on the badge, e.g. `MSD-OP-2214`.
    required String staffNo,

    /// Job grade, e.g. `Loading Officer II`.
    required String grade,

    required DateTime shiftStart,
    required DateTime shiftEnd,

    @Default(true) bool onShift,
  }) = _Officer;

  const Officer._();

  /// Up to two letters for the avatar, derived so it cannot disagree with
  /// [name] after a correction.
  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    String first(String w) => String.fromCharCode(w.runes.first);
    if (parts.length == 1) return first(parts.first).toUpperCase();
    return (first(parts.first) + first(parts.last)).toUpperCase();
  }

  String get shiftWindowLabel => '${_clock(shiftStart)} – ${_clock(shiftEnd)}';

  static String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
