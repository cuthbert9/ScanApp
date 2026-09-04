import '../core/errors/app_exception.dart';
import '../core/result/result.dart';
import '../domain/models/cold_chain_log.dart';
import '../domain/models/scan_event.dart';
import '../domain/repositories/scan_repository.dart';
import 'mock_backend.dart';
import 'mock_latency.dart';

/// In-memory [ScanRepository] over [MockBackend].
///
/// The rule ladder lives in the backend, not here: this only adds latency and
/// wraps the result.
class MockScanRepository implements ScanRepository {
  const MockScanRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<Result<ScanEvent>> simulateScan({required String docNo}) async {
    await mockLatency();
    return Success<ScanEvent>(_backend.simulateScan(docNo));
  }

  @override
  Future<Result<ScanEvent>> scanCode({
    required String docNo,
    required String rawCode,
  }) async {
    await mockLatency();
    return Success<ScanEvent>(_backend.scanCode(docNo, rawCode));
  }

  @override
  Future<Result<List<ScanEvent>>> feed({required String docNo}) async {
    await mockLatency();
    return Success<List<ScanEvent>>(_backend.feed(docNo));
  }

  @override
  Future<Result<ColdChainLog>> coldChain({required String docNo}) async {
    await mockLatency();
    final ColdChainLog? log = _backend.coldChain(docNo);
    if (log == null) {
      // Not an error: a non-cold-chain order simply has no logger riding with
      // it, and the banner is hidden rather than shown broken.
      return Failure<ColdChainLog>(
        ValidationException('No cold-chain logger on $docNo.'),
      );
    }
    return Success<ColdChainLog>(log);
  }

  @override
  Future<Result<ColdChainLog>> tickColdChain({
    required String docNo,
    required int elapsedSeconds,
  }) async {
    // No latency: this runs on a one-second ticker and must not queue up.
    return Success<ColdChainLog>(_backend.tickColdChain(docNo, elapsedSeconds));
  }
}
