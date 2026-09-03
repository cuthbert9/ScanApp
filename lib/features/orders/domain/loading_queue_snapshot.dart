import 'package:freezed_annotation/freezed_annotation.dart';

import 'loading_order.dart';

part 'loading_queue_snapshot.freezed.dart';

/// Everything the loading queue screen needs, in one consistent read.
///
/// One object rather than several providers so the header, the summary counts
/// and the list can never disagree — they are always derived from the same
/// fetch.
@freezed
abstract class LoadingQueueSnapshot with _$LoadingQueueSnapshot {
  const factory LoadingQueueSnapshot({
    /// Transport schedule reference, e.g. `TSP FR 9.1–9.3`.
    required String tripReference,

    /// Origin hub code, e.g. `DAR CVS`.
    required String hub,

    /// Dock the pallets are staged to, e.g. `Dock 04`.
    required String dock,

    /// Whether the bay is currently open for loading.
    required bool isBayOpen,

    required List<LoadingOrder> orders,
  }) = _LoadingQueueSnapshot;

  const LoadingQueueSnapshot._();

  /// Counts for the summary strip, derived rather than stored so they cannot
  /// drift from [orders].
  int get orderCount => orders.length;

  int get unitCount =>
      orders.fold(0, (int sum, LoadingOrder o) => sum + o.units);

  int get coldChainCount =>
      orders.where((LoadingOrder o) => o.isColdChain).length;

  /// The order the primary action should act on: whichever is being loaded, or
  /// else the first in the queue.
  LoadingOrder? get activeOrder {
    for (final LoadingOrder order in orders) {
      if (order.status.isActive) return order;
    }
    return orders.isEmpty ? null : orders.first;
  }

  bool get isEmpty => orders.isEmpty;
}
