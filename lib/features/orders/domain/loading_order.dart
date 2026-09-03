import 'package:freezed_annotation/freezed_annotation.dart';

import 'order_status.dart';

part 'loading_order.freezed.dart';

/// One delivery order staged at the dock, as shown in the loading queue.
///
/// Pure Dart — no Flutter import — so it can be unit-tested without a widget
/// binding and reused by whatever presents it.
@freezed
abstract class LoadingOrder with _$LoadingOrder {
  const factory LoadingOrder({
    /// Delivery-order number, e.g. `DO-2026-04417`. The operator's primary
    /// handle on this record and the value they scan against.
    required String id,

    /// Receiving facility, e.g. `Dodoma Zonal Store`.
    required String facility,

    /// Assigned vehicle, e.g. `T 421 DKV`. Null until a truck is allocated.
    required String? truck,

    /// Distribution route code, e.g. `TZ-C-07`.
    required String route,

    /// Number of units on the order.
    required int units,

    /// Gross weight in tonnes.
    required double tonnes,

    required OrderStatus status,

    /// True when any line requires temperature-controlled handling. Drives the
    /// cold-chain marker and the summary count.
    @Default(false) bool isColdChain,

    /// Health programme the consignment belongs to, e.g. `EPI`. Null for
    /// general stock.
    String? programme,

    /// Load completion from 0 to 1. Only meaningful while
    /// [OrderStatus.loading]; null otherwise.
    double? loadProgress,
  }) = _LoadingOrder;

  const LoadingOrder._();

  /// The metadata line under the facility name, already ordered for display.
  ///
  /// Built here rather than in the widget so every screen showing this order
  /// presents the same fields in the same order.
  List<String> get metaSegments => <String>[
    id,
    truck ?? 'No truck',
    route,
    '$units u',
    '${tonnes.toStringAsFixed(1)} t',
  ];

  /// True when a progress bar should be drawn for this order.
  bool get hasProgress =>
      status.isActive && loadProgress != null && loadProgress! > 0;
}
