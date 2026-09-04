import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle.freezed.dart';

/// The truck an order is loaded onto.
@freezed
abstract class Vehicle with _$Vehicle {
  const factory Vehicle({
    /// Plate as printed on the manifest, e.g. `T 421 DKV`.
    required String plate,
    required double maxWeightKg,
    required double maxVolumeM3,

    /// Current reefer reading. Null on a vehicle with no cold compartment.
    double? reeferTempC,
    @Default(true) bool reeferStable,
  }) = _Vehicle;

  const Vehicle._();

  /// The cold-chain band this fleet carries vaccines and biologicals in.
  static const double minSafeTempC = 2;
  static const double maxSafeTempC = 8;

  bool get hasReefer => reeferTempC != null;

  /// Whether the reading sits inside the safe band.
  bool get temperatureInBand =>
      reeferTempC != null &&
      reeferTempC! >= minSafeTempC &&
      reeferTempC! <= maxSafeTempC;

  /// Where the reading sits in the band, 0 to 1, for a meter. Clamped so an
  /// out-of-band reading pins to an end rather than drawing off the bar.
  double get temperaturePosition {
    if (reeferTempC == null) return 0;
    return ((reeferTempC! - minSafeTempC) / (maxSafeTempC - minSafeTempC))
        .clamp(0.0, 1.0);
  }
}
