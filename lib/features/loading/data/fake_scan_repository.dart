import '../../../core/errors/app_exception.dart';
import '../../../core/result/result.dart';
import '../domain/gs1_barcode.dart';
import '../domain/scan_record.dart';
import '../domain/scan_issue.dart';
import '../domain/scan_repository.dart';
import '../domain/scan_session.dart';
import '../domain/scan_verdict.dart';
import '../domain/vehicle.dart';
import 'product_catalogue.dart';

/// In-memory [ScanRepository], so the screen can be built and demonstrated
/// before the backend exists.
///
/// The session is seeded as though the operator is **resuming** a partly loaded
/// order: 14 scans recorded, 13 verified and one held. Every figure in the
/// summary strip derives from those records, so the numbers on screen are real
/// rather than hardcoded.
///
/// `DO-2026-04417` expects 14 units — the same count the loading queue shows
/// for that order — leaving exactly one slot free. The next valid scan
/// completes the load; the one after is an over-count, which is the manifest
/// rule demonstrating itself rather than a bug.
class FakeScanRepository implements ScanRepository {
  const FakeScanRepository({this.failNextLoad = false});

  final bool failNextLoad;

  static const Duration _latency = Duration(milliseconds: 250);

  /// Fixed base time so the seeded feed is deterministic across runs and tests.
  static final DateTime _sessionStart = DateTime(2026, 9, 3, 8, 40);

  /// The truck on Bay 04, matching `T 421 DKV` on the loading queue.
  static const Vehicle _truck = Vehicle(
    registration: 'T 421 DKV',
    maxWeightKg: 8000,
    maxVolumeM3: 26,
  );

  @override
  Future<Result<ScanSession>> loadSession() async {
    await Future<void>.delayed(_latency);

    if (failNextLoad) {
      return const Failure<ScanSession>(
        NetworkException('Cannot reach the dispatch service. Working offline.'),
      );
    }

    return Success<ScanSession>(
      ScanSession(
        orderReference: 'DO-2026-04417',
        bay: 'Bay 04',
        expectedUnits: 14,
        vehicle: _truck,
        temperatureC: 4.6,
        doorOpenSeconds: 42,
        records: _seededRecords(),
      ),
    );
  }

  /// Fourteen records, newest first.
  static List<ScanRecord> _seededRecords() {
    final List<ScanRecord> records = <ScanRecord>[
      _record(
        sequence: 14,
        item: ProductCatalogue.zincSulfate,
        sscc: null,
        batch: 'ZNC26B118',
        expiry: '290228',
        verdict: ScanVerdict.hold,
        issue: ScanIssue.fefoHold,
        reason: 'FEFO: earlier lot in stock',
      ),
      _record(
        sequence: 13,
        item: ProductCatalogue.malariaTest,
        sscc: '3600980000004404',
        batch: 'MRD24L221',
        expiry: '270930',
      ),
      _record(
        sequence: 12,
        item: ProductCatalogue.paracetamol,
        sscc: '3600980000004403',
        batch: 'PCM25A006',
        expiry: '280430',
      ),
      _record(
        sequence: 11,
        item: ProductCatalogue.ors,
        sscc: '3600980000004402',
        batch: 'ORS24H902',
        expiry: '280131',
      ),
      _record(
        sequence: 10,
        item: ProductCatalogue.amoxicillin,
        sscc: '3600980000004401',
        batch: 'AMX25C441',
        expiry: '270630',
      ),
    ];

    // Nine earlier scans, so the feed genuinely scrolls and the counts add up
    // to the 13 verified the strip reports.
    const List<CatalogueItem> rotation = <CatalogueItem>[
      ProductCatalogue.rutf,
      ProductCatalogue.oxytocin,
      ProductCatalogue.amoxicillin,
    ];
    for (int sequence = 9; sequence >= 1; sequence--) {
      final CatalogueItem item = rotation[sequence % rotation.length];
      records.add(
        _record(
          sequence: sequence,
          item: item,
          // A distinct SSCC range: the visible rows already use ...44xx, and
          // reusing them would make two records share an identity.
          sscc: '36009800000045${sequence.toString().padLeft(2, '0')}',
          batch: 'LOT25X${sequence.toString().padLeft(3, '0')}',
          expiry: '2712${sequence.toString().padLeft(2, '0')}',
        ),
      );
    }
    return records;
  }

  static ScanRecord _record({
    required int sequence,
    required CatalogueItem item,
    required String? sscc,
    required String batch,
    required String expiry,
    ScanVerdict verdict = ScanVerdict.ok,
    ScanIssue issue = ScanIssue.none,
    String? reason,
  }) {
    final StringBuffer raw = StringBuffer();
    if (sscc != null) raw.write('(00)$sscc');
    raw.write('(10)$batch(17)$expiry');

    return ScanRecord(
      sequence: sequence,
      productName: item.name,
      quantity: item.packSize,
      barcode: Gs1Barcode.parse(raw.toString()),
      verdict: verdict,
      issue: issue,
      reason: reason,
      isColdChain: item.isColdChain,
      weightKg: item.weightKg,
      volumeM3: item.volumeM3,
      scannedAt: _sessionStart.add(Duration(minutes: sequence * 2)),
    );
  }
}
