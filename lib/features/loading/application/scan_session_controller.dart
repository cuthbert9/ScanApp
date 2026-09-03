import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/result/result.dart';
import '../data/fake_scan_repository.dart';
import '../data/product_catalogue.dart';
import '../domain/gs1_barcode.dart';
import '../domain/load_reconciliation.dart';
import '../domain/scan_issue.dart';
import '../domain/scan_record.dart';
import '../domain/scan_repository.dart';
import '../domain/scan_session.dart';
import '../domain/scan_verdict.dart';

part 'scan_session_controller.g.dart';

/// Which [ScanRepository] the app runs against.
///
/// The fake-to-real backend switch, and the override point for tests.
@riverpod
ScanRepository scanRepository(Ref ref) {
  return const FakeScanRepository();
}

/// Owns the scanning session and judges every incoming scan.
///
/// [submitScan] is the **single entry point** for scanned input. The on-screen
/// field calls it today; when the DataWedge bridge lands, its intent stream
/// calls exactly the same method and nothing downstream changes. That is the
/// whole reason the field and the hardware scanner are not separate code paths.
@riverpod
class ScanSessionController extends _$ScanSessionController {
  @override
  Future<ScanSession> build() => _load();

  Future<ScanSession> _load() async {
    final ScanRepository repository = ref.watch(scanRepositoryProvider);
    final Result<ScanSession> result = await repository.loadSession();
    return switch (result) {
      Success<ScanSession>(:final ScanSession value) => value,
      Failure<ScanSession>(:final AppException error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// Records one scan, whatever it turns out to be.
  ///
  /// Every non-empty input produces a feed row — including a code that cannot
  /// be decoded. A scanner that appears to do nothing is worse than one that
  /// reports a problem.
  void submitScan(String raw) {
    if (raw.trim().isEmpty) return;

    final ScanSession? session = state.value;
    // Nothing to judge against until the session has loaded.
    if (session == null) return;

    final ScanRecord record = _judge(raw, session);
    state = AsyncData<ScanSession>(
      // Newest first: the operator watches the top of the feed.
      session.copyWith(records: <ScanRecord>[record, ...session.records]),
    );
  }

  /// Applies the manifest rules, most specific first.
  ///
  /// Order matters. "You already scanned this" is more useful than "the load is
  /// full", so duplicates are reported before over-counts.
  ScanRecord _judge(String raw, ScanSession session) {
    final Gs1Barcode barcode = Gs1Barcode.parse(raw);
    final CatalogueItem? item = ProductCatalogue.lookup(barcode.primaryKey);
    final DateTime now = DateTime.now();

    if (item == null) {
      return ScanRecord(
        sequence: session.nextSequence,
        productName: 'Unrecognised code',
        quantity: 0,
        barcode: barcode,
        verdict: ScanVerdict.unknown,
        issue: ScanIssue.notOnManifest,
        reason: 'Not on this manifest',
        scannedAt: now,
      );
    }

    ScanRecord base(ScanVerdict verdict, ScanIssue issue, String? reason) =>
        ScanRecord(
          sequence: session.nextSequence,
          productName: item.name,
          quantity: item.packSize,
          barcode: barcode,
          verdict: verdict,
          issue: issue,
          reason: reason,
          isColdChain: item.isColdChain,
          weightKg: item.weightKg,
          volumeM3: item.volumeM3,
          scannedAt: now,
        );

    if (session.contains(barcode.identity)) {
      return base(
        ScanVerdict.hold,
        ScanIssue.duplicate,
        'Duplicate — already on this load',
      );
    }

    if (session.loadedCount >= session.expectedUnits) {
      return base(
        ScanVerdict.hold,
        ScanIssue.overCount,
        'Over-count — manifest expects ${session.expectedUnits}',
      );
    }

    return base(ScanVerdict.ok, ScanIssue.none, null);
  }
}

/// The reconciliation report for the live session.
///
/// Derived, not stored: scanning one more unit on the Scan tab moves every
/// figure on the Load tab at once, because both read the same session.
@riverpod
LoadReconciliation? loadReconciliation(Ref ref) {
  final ScanSession? session = ref.watch(scanSessionControllerProvider).value;
  if (session == null) return null;
  return LoadReconciliation.from(session);
}
