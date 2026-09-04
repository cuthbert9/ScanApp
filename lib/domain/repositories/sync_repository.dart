import '../../core/result/result.dart';
import '../models/sync_mode.dart';
import '../models/sync_status.dart';

/// The device's outbox.
///
/// Every method returns the whole [SyncStatus] so callers refresh from one read
/// and the pending count can never disagree between the badge, the header dot
/// and the Sync screen.
///
/// SWAP POINT — the real implementation persists to an encrypted local store
/// and pushes batches to the ERP.
abstract interface class SyncRepository {
  Future<Result<SyncStatus>> status();

  Future<Result<SyncStatus>> setMode(SyncMode mode);

  /// Pushes everything pending. Refused in air-gapped mode, and while the debug
  /// offline switch is on.
  Future<Result<SyncStatus>> flush();

  /// Debug switch, so scans can be watched piling up.
  Future<Result<SyncStatus>> setSimulatedOffline(bool value);
}
