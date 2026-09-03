import 'scan_issue.dart';
import 'scan_record.dart';
import 'scan_session.dart';
import 'vehicle.dart';

/// What reconciliation reports before a load is sealed.
///
/// A pure read model: every figure is computed from the session and the
/// vehicle, and nothing is stored. Scanning one more unit therefore moves all
/// of it at once, and there is no second copy of the truth to drift.
class LoadReconciliation {
  const LoadReconciliation({
    required this.orderReference,
    required this.bay,
    required this.vehicle,
    required this.ordered,
    required this.verified,
    required this.short,
    required this.over,
    required this.shortReason,
    required this.loadedWeightKg,
    required this.loadedVolumeM3,
    required this.temperatureC,
  });

  /// Derives the report from the live session.
  factory LoadReconciliation.from(ScanSession session) {
    final int verified = session.verifiedCount;
    final int ordered = session.expectedUnits;

    // Anything the manifest expected that is not on the truck is short —
    // whether it was held, damaged, or simply never presented.
    final int short = ordered - verified > 0 ? ordered - verified : 0;

    // Surplus is the opposite problem and is counted separately: units
    // presented that the manifest did not ask for.
    final int over = session.records
        .where((ScanRecord r) => r.issue.isUnexpected)
        .length;

    return LoadReconciliation(
      orderReference: session.orderReference,
      bay: session.bay,
      vehicle: session.vehicle,
      ordered: ordered,
      verified: verified,
      short: short,
      over: over,
      shortReason: _shortReason(session),
      loadedWeightKg: session.loadedWeightKg,
      loadedVolumeM3: session.loadedVolumeM3,
      temperatureC: session.temperatureC,
    );
  }

  final String orderReference;
  final String bay;
  final Vehicle vehicle;

  /// Units the manifest asked for.
  final int ordered;

  /// Units verified onto the truck.
  final int verified;

  /// Units the manifest expected that are not on the truck.
  final int short;

  /// Units presented that the manifest did not expect.
  final int over;

  /// Why the load is short, in the operator's words. Null when it is not.
  final String? shortReason;

  final double loadedWeightKg;
  final double loadedVolumeM3;
  final double? temperatureC;

  /// Proportion of the order that went on the truck without intervention,
  /// 0 to 1. Rendered as `92.9 %`.
  double get firstPassYield => ordered <= 0 ? 1 : verified / ordered;

  /// Nothing short, nothing unexpected — the load matches the manifest exactly.
  bool get isClean => short == 0 && over == 0;

  double get weightFraction => vehicle.maxWeightKg <= 0
      ? 0
      : (loadedWeightKg / vehicle.maxWeightKg).clamp(0.0, 1.0);

  double get volumeFraction => vehicle.maxVolumeM3 <= 0
      ? 0
      : (loadedVolumeM3 / vehicle.maxVolumeM3).clamp(0.0, 1.0);

  /// Where the reefer reading sits in its allowed band, for the meter.
  double get temperatureFraction => vehicle.temperaturePosition(temperatureC);

  /// Whether the cold chain is holding.
  bool get isTemperatureStable => vehicle.isTemperatureInBand(temperatureC);

  /// Why the load is short, in two or three words.
  ///
  /// Uses [ScanIssue.shortLabel] rather than the record's full sentence: this
  /// sits on one line beside a label on a 320 dp card, where "FEFO: earlier lot
  /// in stock" would not fit. The long form stays in the scan feed.
  ///
  /// Read from the held records rather than stored, so it cannot disagree with
  /// the feed.
  static String? _shortReason(ScanSession session) {
    for (final ScanRecord record in session.records) {
      if (record.verdict.isAccepted) continue;
      if (record.issue.isUnexpected) continue;
      if (record.issue != ScanIssue.none) return record.issue.shortLabel;
    }
    return null;
  }
}
