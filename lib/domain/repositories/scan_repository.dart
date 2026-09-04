import '../../core/result/result.dart';
import '../models/cold_chain_log.dart';
import '../models/scan_event.dart';

/// Records scans against an open order and applies the manifest rules.
///
/// SWAP POINT — the real implementation receives decoded barcodes from the
/// DataWedge intent bridge instead of the debug triggers, and posts them to the
/// ERP. The rule ladder stays here, not in the UI.
abstract interface class ScanRepository {
  /// Debug trigger standing in for a hardware trigger pull: takes the next
  /// pending line of [docNo] and applies the rules to it.
  Future<Result<ScanEvent>> simulateScan({required String docNo});

  /// Scans a specific code, so duplicate, wrong-order and FEFO outcomes can be
  /// reproduced deliberately.
  Future<Result<ScanEvent>> scanCode({
    required String docNo,
    required String rawCode,
  });

  /// The session's feed, newest first.
  Future<Result<List<ScanEvent>>> feed({required String docNo});

  Future<Result<ColdChainLog>> coldChain({required String docNo});

  /// Advances door-open seconds and drifts the temperature.
  ///
  /// Called on a ticker while the Scan screen is mounted. The drift lives here
  /// so no widget owns business logic.
  Future<Result<ColdChainLog>> tickColdChain({
    required String docNo,
    required int elapsedSeconds,
  });
}
