import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift_stats.freezed.dart';

/// One day's throughput, for the seven-day strip.
@freezed
abstract class DailyScanCount with _$DailyScanCount {
  const factory DailyScanCount({
    /// Single-letter axis label.
    required String label,

    /// Full day name, for the accessible description of the bar.
    required String dayName,
    required int units,
    @Default(false) bool isToday,

    /// The station was shut. Rendered as no bar at all, because a bar for
    /// "closed" reads as a very quiet day, which is a different thing.
    @Default(false) bool closed,
  }) = _DailyScanCount;

  const DailyScanCount._();
}

/// What the officer has done today.
@freezed
abstract class ShiftStats with _$ShiftStats {
  const factory ShiftStats({
    required int unitsScanned,

    /// Units stopped on cold-chain grounds — the failures in first-pass terms.
    required int coldChainHolds,
    required int medianSecondsPerUnit,
    required int loadsSealed,

    /// Oldest day first, so the chart reads left to right.
    required List<DailyScanCount> week,
  }) = _ShiftStats;

  const ShiftStats._();

  /// Share of units that passed without intervention, 0 to 1.
  ///
  /// Officer-level and distinct from an order's `firstPassYield`: this is the
  /// whole shift across every load, not one manifest.
  double get firstPassAccuracy {
    if (unitsScanned <= 0) return 1;
    return (unitsScanned - coldChainHolds) / unitsScanned;
  }

  /// `99.3` — without the unit, so `%` can be styled apart.
  String get firstPassLabel => (firstPassAccuracy * 100).toStringAsFixed(1);

  int get peakUnits => week.isEmpty
      ? 0
      : week
            .map((DailyScanCount d) => d.units)
            .reduce((int a, int b) => a > b ? a : b);

  int get todayUnits {
    for (final DailyScanCount d in week) {
      if (d.isToday) return d.units;
    }
    return unitsScanned;
  }
}
