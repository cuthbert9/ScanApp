import '../../result/result.dart';
import '../domain/queued_record.dart';
import '../domain/sync_mode.dart';
import '../domain/sync_queue.dart';
import '../domain/sync_queue_repository.dart';

/// In-memory [SyncQueueRepository], standing in for the encrypted local store.
///
/// Unlike the other fakes this one is **stateful**, because a local outbox is
/// stateful: flushing has to actually empty it, and a mode change has to stick.
/// That is also why its provider is kept alive — a fresh instance per read
/// would silently undo every flush.
///
/// Nothing here is encrypted. `AES-256 at rest` is a label on the screen until
/// a real store exists.
class FakeSyncQueueRepository implements SyncQueueRepository {
  FakeSyncQueueRepository() : _queue = _seed();

  SyncQueue _queue;

  static const Duration _latency = Duration(milliseconds: 200);

  /// Round-trip time for a push, long enough that the pushing state is visible.
  static const Duration _pushDuration = Duration(milliseconds: 600);

  /// Fixed times so the seeded queue is deterministic across runs and tests.
  static SyncQueue _seed() {
    final DateTime day = DateTime(2026, 9, 3);
    return SyncQueue(
      mode: SyncMode.storeAndForward,
      tripReference: 'TSP FR 14.9',
      hub: 'DAR CVS',
      lastPushAt: day.add(const Duration(hours: 8, minutes: 9)),
      pending: <QueuedRecord>[
        QueuedRecord(
          id: 'Q-0001',
          capturedAt: day.add(const Duration(hours: 8, minutes: 7)),
          sizeBytes: 2050,
        ),
        QueuedRecord(
          id: 'Q-0002',
          capturedAt: day.add(const Duration(hours: 8, minutes: 8)),
          sizeBytes: 2050,
        ),
      ],
    );
  }

  @override
  Future<Result<SyncQueue>> load() async {
    await Future<void>.delayed(_latency);
    return Success<SyncQueue>(_queue);
  }

  @override
  Future<Result<SyncQueue>> flush() async {
    await Future<void>.delayed(_pushDuration);

    // Everything pending is accepted. A real implementation would push in
    // batches and keep whatever the server rejected, incrementing failedCount.
    _queue = _queue.copyWith(
      pending: const <QueuedRecord>[],
      lastPushAt: DateTime.now(),
      lastPushAccepted: true,
      failedCount: 0,
      isPushing: false,
    );
    return Success<SyncQueue>(_queue);
  }

  @override
  Future<Result<SyncQueue>> setMode(SyncMode mode) async {
    await Future<void>.delayed(_latency);
    _queue = _queue.copyWith(mode: mode);
    return Success<SyncQueue>(_queue);
  }
}
