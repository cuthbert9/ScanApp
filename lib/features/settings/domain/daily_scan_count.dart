import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_scan_count.freezed.dart';

/// One day's throughput, for the weekly chart.
@freezed
abstract class DailyScanCount with _$DailyScanCount {
  const factory DailyScanCount({
    /// Single-letter axis label — `M`, `T`, `W`.
    required String label,

    /// Full day name, for the accessible description of the bar.
    required String dayName,

    required int units,

    /// Whether this is the day currently being worked.
    @Default(false) bool isToday,
  }) = _DailyScanCount;

  const DailyScanCount._();
}
