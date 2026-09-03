import '../../result/result.dart';
import 'sync_mode.dart';
import 'sync_queue.dart';

/// The device's local outbox.
///
/// This is infrastructure rather than a feature: the tab badge, the scan
/// header's indicator and the sync screen all read it, and every feature's
/// writes will eventually land in it. It therefore lives in `core/` and depends
/// on nothing above it.
///
/// The implementation owns the stored state — it *is* the local store — so
/// callers do not pass the current queue back in.
abstract interface class SyncQueueRepository {
  /// Reads the outbox as it stands.
  Future<Result<SyncQueue>> load();

  /// Pushes everything pending and returns the queue afterwards.
  Future<Result<SyncQueue>> flush();

  /// Changes how captured work is sent.
  Future<Result<SyncQueue>> setMode(SyncMode mode);
}
