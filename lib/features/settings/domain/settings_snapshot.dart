import 'package:freezed_annotation/freezed_annotation.dart';

import 'operator_profile.dart';
import 'scanner_config.dart';
import 'session_config.dart';
import 'shift_stats.dart';
import 'station.dart';

part 'settings_snapshot.freezed.dart';

/// Everything the settings screen shows, in one consistent read.
@freezed
abstract class SettingsSnapshot with _$SettingsSnapshot {
  const factory SettingsSnapshot({
    required OperatorProfile profile,
    required ShiftStats stats,
    required Station station,
    required ScannerConfig scanner,
    required SessionConfig session,

    /// Device asset tag, e.g. `TC58-DAR-014`.
    required String deviceSerial,

    /// Installed build, e.g. `3.8.2`.
    required String appVersion,

    /// When this snapshot was taken.
    ///
    /// Elapsed shift time is measured against this rather than `DateTime.now()`
    /// so the figure is stable within a read — and deterministic in tests.
    required DateTime capturedAt,
  }) = _SettingsSnapshot;

  const SettingsSnapshot._();

  /// How long the operator has been on shift.
  Duration get onShiftFor {
    final Duration elapsed = capturedAt.difference(profile.shiftStart);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// `6:12` — hours and minutes, not zero-padded on the hour, because it reads
  /// as a duration rather than a clock time.
  String get onShiftLabel {
    final Duration d = onShiftFor;
    final String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours}:$minutes';
  }

  /// `06:00 – 15:00`
  String get shiftWindowLabel {
    String clock(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${clock(profile.shiftStart)} – ${clock(profile.shiftEnd)}';
  }

  /// `15:00` — when the shift closes itself if nobody does.
  String get shiftAutoCloseLabel {
    final DateTime t = profile.shiftEnd;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// `TC58-DAR-014 · APP 3.8.2`
  String get deviceLabel => '$deviceSerial  ·  APP $appVersion';
}
