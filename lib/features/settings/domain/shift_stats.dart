import 'package:freezed_annotation/freezed_annotation.dart';

import 'daily_scan_count.dart';

part 'shift_stats.freezed.dart';

/// What the operator has done today.
///
/// Accuracy and the chart's peak are derived, so the summary strip, the detail
/// rows and the bars cannot disagree.
@freezed
abstract class ShiftStats with _$ShiftStats {
  const factory ShiftStats({
    required int unitsScanned,

    /// Units stopped on cold-chain grounds — the failures in first-pass terms.
    required int coldChainHolds,

    /// Median seconds from trigger pull to accepted scan.
    required int medianSecondsPerUnit,

    required int loadsSealed,

    /// Oldest day first, so the chart reads left to right.
    required List<DailyScanCount> week,
  }) = _ShiftStats;

  const ShiftStats._();

  /// Share of units that passed without intervention, 0 to 1.
  double get firstPassAccuracy {
    if (unitsScanned <= 0) return 1;
    return (unitsScanned - coldChainHolds) / unitsScanned;
  }

  /// `99.3` — the figure without its unit, so the `%` can be styled apart.
  String get firstPassLabel => (firstPassAccuracy * 100).toStringAsFixed(1);

  /// The best day this week, which the chart scales against.
  int get peakUnits => week.isEmpty
      ? 0
      : week
            .map((DailyScanCount d) => d.units)
            .reduce((int a, int b) => a > b ? a : b);

  int get todayUnits {
    for (final DailyScanCount day in week) {
      if (day.isToday) return day.units;
    }
    return unitsScanned;
  }
}
