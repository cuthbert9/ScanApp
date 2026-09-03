/// The truck a load is going onto.
///
/// Capacities are what reconciliation checks the load against; the reefer band
/// is the temperature range the consignment must stay inside.
class Vehicle {
  const Vehicle({
    required this.registration,
    required this.maxWeightKg,
    required this.maxVolumeM3,
    this.reeferMinC = 2,
    this.reeferMaxC = 8,
  });

  /// Plate as printed on the manifest, e.g. `T 421 DKV`.
  final String registration;

  final double maxWeightKg;
  final double maxVolumeM3;

  /// Cold-chain band. Defaults to +2 to +8 °C, the standard range for the
  /// vaccines and biologicals this fleet carries.
  final double reeferMinC;
  final double reeferMaxC;

  /// Whether [temperatureC] sits inside the allowed band.
  bool isTemperatureInBand(double? temperatureC) =>
      temperatureC != null &&
      temperatureC >= reeferMinC &&
      temperatureC <= reeferMaxC;

  /// Where [temperatureC] sits in the band, 0 to 1, for a meter.
  ///
  /// Clamped, so a reading outside the band pins the meter to an end rather
  /// than drawing off the edge of the bar.
  double temperaturePosition(double? temperatureC) {
    if (temperatureC == null || reeferMaxC <= reeferMinC) return 0;
    final double span = reeferMaxC - reeferMinC;
    return ((temperatureC - reeferMinC) / span).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is Vehicle &&
      other.registration == registration &&
      other.maxWeightKg == maxWeightKg &&
      other.maxVolumeM3 == maxVolumeM3 &&
      other.reeferMinC == reeferMinC &&
      other.reeferMaxC == reeferMaxC;

  @override
  int get hashCode => Object.hash(
    registration,
    maxWeightKg,
    maxVolumeM3,
    reeferMinC,
    reeferMaxC,
  );

  @override
  String toString() => 'Vehicle($registration)';
}
