import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/result/result.dart';
import '../data/fake_loading_queue_repository.dart';
import '../domain/loading_order.dart';
import '../domain/loading_queue_repository.dart';
import '../domain/loading_queue_snapshot.dart';

part 'loading_queue_controller.g.dart';

/// Which [LoadingQueueRepository] the app runs against.
///
/// This single line is the fake-to-real backend switch. When the HTTP client
/// exists, return it here — no screen, controller or model changes. Tests
/// override this provider to inject their own fixture.
@riverpod
LoadingQueueRepository loadingQueueRepository(Ref ref) {
  return const FakeLoadingQueueRepository();
}

/// Loads and holds the dock's queue.
///
/// Unwraps [Result] here so widgets deal in `AsyncValue` and never handle a
/// `Result` themselves: throwing the [AppException] lets Riverpod route it to
/// `AsyncError`, where the screen renders it once, in one place.
@riverpod
class LoadingQueueController extends _$LoadingQueueController {
  @override
  Future<LoadingQueueSnapshot> build() => _load();

  Future<LoadingQueueSnapshot> _load() async {
    final LoadingQueueRepository repository = ref.watch(
      loadingQueueRepositoryProvider,
    );
    final Result<LoadingQueueSnapshot> result = await repository.fetchQueue();
    return switch (result) {
      Success<LoadingQueueSnapshot>(:final LoadingQueueSnapshot value) => value,
      Failure<LoadingQueueSnapshot>(:final AppException error) => throw error,
    };
  }

  /// Re-reads the queue, keeping the current list on screen while it runs so
  /// the operator does not lose their place on a manual refresh.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}

/// The order the operator has tapped, if any.
///
/// Kept separate from the queue itself: a refresh replaces the snapshot, and
/// selection should survive that.
@riverpod
class SelectedOrder extends _$SelectedOrder {
  @override
  String? build() => null;

  void select(String orderId) => state = orderId;
}

/// The order the primary action applies to.
///
/// The explicit selection when there is one, otherwise whichever order is being
/// loaded — so the CTA is useful the moment the screen opens, with no tap.
/// That matters on a device where the operator's hands are full.
@riverpod
LoadingOrder? focusedOrder(Ref ref) {
  final LoadingQueueSnapshot? snapshot = ref
      .watch(loadingQueueControllerProvider)
      .value;
  if (snapshot == null || snapshot.isEmpty) return null;

  final String? selectedId = ref.watch(selectedOrderProvider);
  if (selectedId != null) {
    for (final LoadingOrder order in snapshot.orders) {
      if (order.id == selectedId) return order;
    }
  }
  return snapshot.activeOrder;
}
