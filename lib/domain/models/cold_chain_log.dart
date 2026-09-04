import 'package:freezed_annotation/freezed_annotation.dart';

import 'vehicle.dart';

part 'cold_chain_log.freezed.dart';

/// The temperature logger riding with a cold-chain consignment.
@freezed
abstract class ColdChainLog with _$ColdChainLog {
  const factory ColdChainLog({
    /// Logger asset tag, e.g. `MSD-LG-2291`.
    required String loggerId,
    required double tempC,

    /// How long the reefer door has been open. Rises while loading.
    required int doorOpenSeconds,

    required bool stable,

    /// Set once a reading has left the safe band, and never cleared — a
    /// consignment that went out of band stays suspect even if it comes back.
    @Default(false) bool hadExcursion,
  }) = _ColdChainLog;

  const ColdChainLog._();

  /// Beyond this the door has been open too long and the banner warns.
  static const int doorWarningSeconds = 120;

  /// How often the door timer advances while the Scan screen is open.
  ///
  /// Behaviour, not motion: this is how fast the reefer log is sampled, and it
  /// has nothing to do with animation, so it belongs here rather than in the
  /// design tokens.
  static const Duration tickInterval = Duration(seconds: 1);

  bool get doorOpenTooLong => doorOpenSeconds > doorWarningSeconds;

  bool get inBand =>
      tempC >= Vehicle.minSafeTempC && tempC <= Vehicle.maxSafeTempC;

  /// Whether the banner should read as a problem rather than a confirmation.
  bool get needsAttention => hadExcursion || !inBand || doorOpenTooLong;

  String get statusLabel {
    if (hadExcursion || !inBand) return 'excursion';
    if (doorOpenTooLong) return 'door open';
    return 'stable';
  }
}
