import '../../../core/result/result.dart';
import 'scan_session.dart';

/// Loads the scanning session for the order currently being worked.
///
/// The seam the backend plugs into. Today an in-memory fake satisfies it; when
/// the MSSQL-backed service exists, a second implementation lands in `data/`
/// and the only change elsewhere is which one the provider returns.
abstract interface class ScanRepository {
  /// Fetches the active session, including any scans already recorded against
  /// it — an operator may be resuming a partly loaded order.
  Future<Result<ScanSession>> loadSession();
}
