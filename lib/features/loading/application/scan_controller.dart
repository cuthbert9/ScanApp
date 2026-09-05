import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/state/dock_controller.dart';
import '../../../app/state/sync_controller.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/result/result.dart';
import '../../../data/repository_providers.dart';
import '../../../domain/models/cold_chain_log.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/scan_event.dart';
import '../../../domain/repositories/scan_repository.dart';

part 'scan_controller.g.dart';

/// The scan feed for whichever order is open, newest first.
///
/// Watches [selectedOrder], so opening a different order reloads the feed
/// without the screen having to ask.
@riverpod
class ScanFeed extends _$ScanFeed {
  @override
  Future<List<ScanEvent>> build() async {
    final Order? order = ref.watch(selectedOrderProvider);
    if (order == null) return const <ScanEvent>[];

    final ScanRepository repo = ref.read(scanRepositoryProvider);
    return _unwrap(await repo.feed(docNo: order.docNo));
  }

  /// Debug trigger, standing in for a hardware trigger pull.
  Future<ScanEvent?> simulate() =>
      _record((ScanRepository r, String docNo) => r.simulateScan(docNo: docNo));

  /// Debug: scan a specific code, so duplicate, wrong-order and FEFO can be
  /// reproduced deliberately.
  Future<ScanEvent?> scanCode(String rawCode) {
    if (rawCode.trim().isEmpty) return Future<ScanEvent?>.value();
    return _record(
      (ScanRepository r, String docNo) =>
          r.scanCode(docNo: docNo, rawCode: rawCode),
    );
  }

  /// Runs a scan and then fans the change out.
  ///
  /// One mutation, three refreshes: the feed, the dock (which moves every
  /// figure on Orders, Scan and Load at once), and the outbox (which moves the
  /// tab badge and the amber dot on every header).
  Future<ScanEvent?> _record(
    Future<Result<ScanEvent>> Function(ScanRepository, String docNo) run,
  ) async {
    final Order? order = ref.read(selectedOrderProvider);
    if (order == null) return null;

    final ScanRepository repo = ref.read(scanRepositoryProvider);
    final Result<ScanEvent> result = await run(repo, order.docNo);

    await ref.read(dockControllerProvider.notifier).refresh();
    await ref.read(syncControllerProvider.notifier).refresh();
    ref.invalidateSelf();

    return result.valueOrNull;
  }

  T _unwrap<T>(Result<T> result) => switch (result) {
    Success<T>(:final T value) => value,
    Failure<T>(:final AppException error) => throw error,
  };
}

/// The temperature logger riding with a cold-chain consignment.
///
/// Null when the open order has no reefer, which is how the banner knows to
/// stay hidden rather than render empty.
@riverpod
class ColdChainMonitor extends _$ColdChainMonitor {
  @override
  Future<ColdChainLog?> build() async {
    final Order? order = ref.watch(selectedOrderProvider);
    if (order == null || !order.coldChain) return null;

    final ScanRepository repo = ref.read(scanRepositoryProvider);
    return (await repo.coldChain(docNo: order.docNo)).valueOrNull;
  }

  /// Advances the door timer and drifts the temperature.
  ///
  /// Driven by a one-second ticker that lives and dies with the Scan screen —
  /// the door is only open while someone is loading through it.
  Future<void> tick(int elapsedSeconds) async {
    final Order? order = ref.read(selectedOrderProvider);
    if (order == null || !order.coldChain) return;

    final ScanRepository repo = ref.read(scanRepositoryProvider);
    final Result<ColdChainLog> result = await repo.tickColdChain(
      docNo: order.docNo,
      elapsedSeconds: elapsedSeconds,
    );

    // The door timer lives with the Scan screen, but this await can still be
    // in flight the moment that screen (and this provider with it) is torn
    // down — leaving the app, in particular. Touching `state` after that
    // throws.
    if (!ref.mounted) return;

    final ColdChainLog? log = result.valueOrNull;
    if (log == null) return;
    state = AsyncData<ColdChainLog?>(log);

    // An excursion changes whether the load can be sealed, which is dock
    // state, so the Load screen must hear about it.
    if (log.hadExcursion && !order.hasColdChainExcursion) {
      await ref.read(dockControllerProvider.notifier).refresh();
    }
  }
}
