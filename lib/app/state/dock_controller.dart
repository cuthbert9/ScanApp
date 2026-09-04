import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/result/result.dart';
import '../../data/repository_providers.dart';
import '../../domain/models/order.dart';
import '../../domain/models/station.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/station_repository.dart';
import 'dock_state.dart';

part 'dock_controller.g.dart';

/// The app's single store of dock state.
///
/// Every screen watches this, and every mutation goes through a repository and
/// then [refresh]. That is the whole mechanism behind "change one line's state
/// and every number on every screen moves together": there is one list of
/// [Order] objects, and all the figures are derived from it.
///
/// `keepAlive` so the open order and the loaded queue survive a tab switch.
@Riverpod(keepAlive: true)
class DockController extends _$DockController {
  @override
  Future<DockState> build() => _load();

  Future<DockState> _load({
    String? selectedDocNo,
    bool hasViewedLoad = false,
  }) async {
    final StationRepository stations = ref.read(stationRepositoryProvider);
    final Station station = _unwrap(await stations.current());

    final OrderRepository orders = ref.read(orderRepositoryProvider);
    final List<Order> staged = _unwrap(
      await orders.stagedOrders(bay: station.assignedBay),
    );

    return DockState(
      station: station,
      staged: staged,
      selectedDocNo: selectedDocNo,
      hasViewedLoad: hasViewedLoad,
    );
  }

  /// Re-reads the queue, keeping the selection and the viewed flag.
  ///
  /// Called after every mutation — a scan, a seal — so the figures on screens
  /// the operator is not looking at are already correct when they get there.
  Future<void> refresh() async {
    final DockState? current = state.value;
    state = await AsyncValue.guard(
      () => _load(
        selectedDocNo: current?.selectedDocNo,
        hasViewedLoad: current?.hasViewedLoad ?? false,
      ),
    );
  }

  /// Selects an order without navigating. Resets the viewed flag, because a
  /// different order has not had its load screen looked at.
  void select(String docNo) {
    final DockState? current = state.value;
    if (current == null) return;
    state = AsyncData<DockState>(
      current.copyWith(selectedDocNo: docNo, hasViewedLoad: false),
    );
  }

  void clearSelection() {
    final DockState? current = state.value;
    if (current == null) return;
    state = AsyncData<DockState>(
      current.copyWith(selectedDocNo: null, hasViewedLoad: false),
    );
  }

  /// Records that the Load screen has been opened, which is what enables
  /// sealing.
  void markLoadViewed() {
    final DockState? current = state.value;
    if (current == null || current.hasViewedLoad) return;
    state = AsyncData<DockState>(current.copyWith(hasViewedLoad: true));
  }

  /// Changes station, then reloads the queue for its bay.
  Future<void> selectStation(String code) async {
    state = await AsyncValue.guard(() async {
      final StationRepository stations = ref.read(stationRepositoryProvider);
      _unwrap(await stations.select(code));
      // A different station means a different bay, so the open order no longer
      // applies.
      return _load();
    });
  }

  T _unwrap<T>(Result<T> result) => switch (result) {
    Success<T>(:final T value) => value,
    Failure<T>(:final AppException error) => throw error,
  };
}

/// The order currently open, or null.
///
/// Scan and Load both read this rather than taking a document number as a
/// route parameter, so their titles and figures cannot disagree with the queue.
@riverpod
Order? selectedOrder(Ref ref) =>
    ref.watch(dockControllerProvider).value?.selected;

/// `BAY 04 · DO-2026-04417` for the screen headers.
@riverpod
String dockContextLabel(Ref ref) =>
    ref.watch(dockControllerProvider).value?.contextLabel ?? '—';
