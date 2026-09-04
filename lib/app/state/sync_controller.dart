import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/result/result.dart';
import '../../data/repository_providers.dart';
import '../../domain/models/sync_mode.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/sync_repository.dart';

part 'sync_controller.g.dart';

/// The device's outbox, app-level.
///
/// `keepAlive` and read from three unrelated places — the tab badge, the amber
/// dot on every screen header, and the Sync screen. One provider, so a flush
/// clears all three at once and none can go stale.
@Riverpod(keepAlive: true)
class SyncController extends _$SyncController {
  @override
  Future<SyncStatus> build() => _load();

  Future<SyncStatus> _load() async {
    final SyncRepository repo = ref.read(syncRepositoryProvider);
    return _unwrap(await repo.status());
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> setMode(SyncMode mode) async {
    final SyncStatus? current = state.value;
    if (current == null || current.mode == mode) return;

    // Optimistic, so the mode chip changes under the operator's finger.
    state = AsyncData<SyncStatus>(current.copyWith(mode: mode));
    state = await AsyncValue.guard(() async {
      final SyncRepository repo = ref.read(syncRepositoryProvider);
      return _unwrap(await repo.setMode(mode));
    });
  }

  /// Pushes everything pending.
  ///
  /// Sets the pushing flag first so the state word changes immediately rather
  /// than the screen sitting still for the length of the round trip.
  Future<void> flush() async {
    final SyncStatus? current = state.value;
    if (current == null || !current.canFlush) return;

    state = AsyncData<SyncStatus>(current.copyWith(isPushing: true));
    state = await AsyncValue.guard(() async {
      final SyncRepository repo = ref.read(syncRepositoryProvider);
      return _unwrap(await repo.flush());
    });
  }

  /// Debug switch: queue work up instead of sending it.
  Future<void> setSimulatedOffline(bool value) async {
    state = await AsyncValue.guard(() async {
      final SyncRepository repo = ref.read(syncRepositoryProvider);
      return _unwrap(await repo.setSimulatedOffline(value));
    });
  }

  T _unwrap<T>(Result<T> result) => switch (result) {
    Success<T>(:final T value) => value,
    Failure<T>(:final AppException error) => throw error,
  };
}

/// Records captured but not yet accepted by the backend.
///
/// Drives **both** the amber dot on every screen header and the Sync tab badge,
/// so they can never disagree.
@riverpod
int pendingSyncCount(Ref ref) =>
    ref.watch(syncControllerProvider).value?.pendingCount ?? 0;
