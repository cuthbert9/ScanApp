import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/state/dock_controller.dart';
import '../../../app/state/sync_controller.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/result/result.dart';
import '../../../data/repository_providers.dart';
import '../../../domain/models/load_seal.dart';
import '../../../domain/models/order.dart';
import '../../../domain/repositories/load_repository.dart';

part 'load_controller.g.dart';

/// Seals a load.
///
/// Holds no figures of its own: everything the reconciliation screen shows is
/// derived from the open [Order]. This exists only to perform the seal and fan
/// the result out.
///
/// `keepAlive` because sealing outlives the screen that started it: the moment
/// the order leaves the staged queue, the Load screen swaps to its empty state
/// and would auto-dispose this mid-flight.
@Riverpod(keepAlive: true)
class LoadController extends _$LoadController {
  @override
  LoadSeal? build() => null;

  /// Seals the open order.
  ///
  /// Returns the [AppException] the backend refused with — a cold-chain
  /// excursion, an order already sealed — or null on success. The caller shows
  /// the message; this never formats one.
  Future<AppException?> seal() async {
    final Order? order = ref.read(selectedOrderProvider);
    if (order == null) return null;

    // Resolved BEFORE the await. Sealing removes the order from the queue,
    // which tears the Load screen down; reading `ref` afterwards would throw.
    final LoadRepository repo = ref.read(loadRepositoryProvider);
    final DockController dock = ref.read(dockControllerProvider.notifier);
    final SyncController sync = ref.read(syncControllerProvider.notifier);

    final Result<LoadSeal> result = await repo.seal(docNo: order.docNo);

    switch (result) {
      case Success<LoadSeal>(:final LoadSeal value):
        state = value;
        // The order leaves the staged queue and the seal enters the outbox.
        await dock.refresh();
        await sync.refresh();
        dock.clearSelection();
        return null;
      case Failure<LoadSeal>(:final AppException error):
        return error;
    }
  }
}
