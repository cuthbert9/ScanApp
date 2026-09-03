import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../errors/app_exception.dart';
import '../../result/result.dart';
import '../data/fake_sync_queue_repository.dart';
import '../domain/sync_mode.dart';
import '../domain/sync_queue.dart';
import '../domain/sync_queue_repository.dart';

part 'sync_queue_controller.g.dart';

/// Which [SyncQueueRepository] the app runs against.
///
/// `keepAlive` because the outbox is stateful: a fresh repository per read
/// would restore the seeded queue and undo every flush.
@Riverpod(keepAlive: true)
SyncQueueRepository syncQueueRepository(Ref ref) {
  return FakeSyncQueueRepository();
}

/// Owns the device's outbox.
///
/// Kept alive for the session, because the pending count is read by the tab
/// badge and the scan header — parts of the app that are not on screen when the
/// queue changes.
@Riverpod(keepAlive: true)
class SyncQueueController extends _$SyncQueueController {
  @override
  Future<SyncQueue> build() => _load();

  Future<SyncQueue> _load() async {
    final SyncQueueRepository repository = ref.watch(
      syncQueueRepositoryProvider,
    );
    return _unwrap(await repository.load());
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// Pushes everything waiting.
  ///
  /// Sets the pushing flag first so the state word changes immediately, rather
  /// than the screen sitting still for the length of the round trip.
  Future<void> flush() async {
    final SyncQueue? current = state.value;
    if (current == null || !current.canFlush) return;

    state = AsyncData<SyncQueue>(current.copyWith(isPushing: true));
    state = await AsyncValue.guard(() async {
      final SyncQueueRepository repository = ref.read(
        syncQueueRepositoryProvider,
      );
      return _unwrap(await repository.flush());
    });
  }

  /// Changes how captured work is sent.
  ///
  /// Applied optimistically so the radio moves under the operator's finger; the
  /// store's answer replaces it a moment later.
  Future<void> selectMode(SyncMode mode) async {
    final SyncQueue? current = state.value;
    if (current == null || current.mode == mode) return;

    state = AsyncData<SyncQueue>(current.copyWith(mode: mode));
    state = await AsyncValue.guard(() async {
      final SyncQueueRepository repository = ref.read(
        syncQueueRepositoryProvider,
      );
      return _unwrap(await repository.setMode(mode));
    });
  }

  SyncQueue _unwrap(Result<SyncQueue> result) => switch (result) {
    Success<SyncQueue>(:final SyncQueue value) => value,
    Failure<SyncQueue>(:final AppException error) => throw error,
  };
}

/// How many records are captured but not yet accepted by the backend.
///
/// Read by the tab badge and the scan header's indicator. It lives in `core/`
/// rather than a feature because those consumers are unrelated to each other,
/// and a feature must never import another feature (CLAUDE.md rule 3).
///
/// Derived from the queue, so flushing empties the badge without anything
/// having to remember to update it.
@riverpod
int pendingSyncCount(Ref ref) {
  return ref.watch(syncQueueControllerProvider).value?.pendingCount ?? 0;
}
