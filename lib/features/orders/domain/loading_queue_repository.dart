import '../../../core/result/result.dart';
import 'loading_queue_snapshot.dart';

/// Reads the loading queue for the current dock.
///
/// This interface is the seam the backend plugs into. Today it is satisfied by
/// an in-memory fake; when the MSSQL-backed HTTP service exists, a second
/// implementation lands in `data/` and the only change elsewhere is which one
/// the provider returns.
///
/// Returns [Result] rather than throwing, so callers cannot forget the failure
/// path — which on warehouse Wi-Fi is not an edge case.
abstract interface class LoadingQueueRepository {
  /// Fetches the current queue.
  Future<Result<LoadingQueueSnapshot>> fetchQueue();
}
