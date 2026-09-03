import 'package:freezed_annotation/freezed_annotation.dart';

import 'scan_record.dart';
import 'vehicle.dart';

part 'scan_session.freezed.dart';

/// A loading session: one delivery order being scanned onto one truck.
///
/// Every figure in the summary strip is derived from [records], so the counts
/// can never disagree with the feed the operator is looking at.
@freezed
abstract class ScanSession with _$ScanSession {
  const factory ScanSession({
    /// The order being loaded, e.g. `DO-2026-04417`.
    required String orderReference,

    /// Loading bay, e.g. `Bay 04`.
    required String bay,

    /// Units the manifest says should be loaded. Scanning past this is an
    /// over-count, not a success.
    required int expectedUnits,

    /// The truck this order is being loaded onto.
    required Vehicle vehicle,

    /// Newest first — the order the feed is displayed in.
    required List<ScanRecord> records,

    /// Last temperature reading for the cold-chain unit, in Celsius.
    double? temperatureC,

    /// How long the reefer door has been open, in seconds.
    int? doorOpenSeconds,
  }) = _ScanSession;

  const ScanSession._();

  /// Scans that passed and count towards the load.
  int get verifiedCount =>
      records.where((ScanRecord r) => r.verdict.isAccepted).length;

  /// Scans needing someone's attention before the truck leaves.
  int get heldCount =>
      records.where((ScanRecord r) => !r.verdict.isAccepted).length;

  /// Units actually on the truck. Only verified scans count.
  int get loadedCount => verifiedCount;

  /// The next sequence number to hand out.
  int get nextSequence => records.length + 1;

  bool get hasColdChain => records.any((ScanRecord r) => r.isColdChain);

  bool get isComplete => loadedCount >= expectedUnits;

  /// True once every expected unit is verified and nothing is held.
  bool get isClean => isComplete && heldCount == 0;

  /// Whether [identity] has already been recorded, for duplicate detection.
  bool contains(String identity) =>
      records.any((ScanRecord r) => r.identity == identity);

  /// Records that made it onto the truck.
  Iterable<ScanRecord> get accepted =>
      records.where((ScanRecord r) => r.verdict.isAccepted);

  /// Mass actually loaded, summed from the accepted records.
  double get loadedWeightKg =>
      accepted.fold(0, (double sum, ScanRecord r) => sum + r.weightKg);

  /// Volume actually loaded.
  double get loadedVolumeM3 =>
      accepted.fold(0, (double sum, ScanRecord r) => sum + r.volumeM3);
}
