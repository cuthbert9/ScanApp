import 'package:freezed_annotation/freezed_annotation.dart';

import 'order_line.dart';
import 'vehicle.dart';

part 'order.freezed.dart';

/// Where a delivery order has got to on the dock.
///
/// The order of the values is the order work flows in.
enum OrderStatus {
  /// Released and staged, waiting its turn.
  queued('Queued'),

  /// Currently being loaded.
  loading('Loading'),

  /// Staged, but no vehicle assigned yet.
  awaitingTruck('No truck'),

  /// Signed off. Leaves the staged queue and accepts no further scans.
  sealed('Sealed');

  const OrderStatus(this.label);

  /// Operator-facing label, rendered upper-case by the badge.
  ///
  /// `awaitingTruck` still prints `NO TRUCK`: the value was renamed for
  /// clarity, the copy on screen did not change.
  final String label;

  bool get isActive => this == OrderStatus.loading;
  bool get isSealed => this == OrderStatus.sealed;
  bool get acceptsScans => this != OrderStatus.sealed;
}

/// A delivery order and its lines.
///
/// **This is the single source of every figure the app shows about a load.**
/// Units, verified, held, short, yield, weight and volume are all computed
/// here, so changing one line's state moves every number on every screen at
/// once. Nothing downstream may recompute or cache them.
@freezed
abstract class Order with _$Order {
  const factory Order({
    /// Delivery-order number, e.g. `DO-2026-04417`.
    required String docNo,

    /// Receiving facility.
    required String consignee,

    /// Distribution route code, e.g. `TZ-C-07`.
    required String routeCode,

    /// Bay the pallets are staged to, e.g. `04`.
    required String bay,

    required Vehicle vehicle,
    required OrderStatus status,
    required List<OrderLine> lines,

    /// Expanded Programme on Immunisation consignment.
    @Default(false) bool isEPI,

    /// Requires temperature-controlled handling.
    @Default(false) bool coldChain,

    /// Estimated time of departure. Null until a truck is assigned.
    DateTime? etd,

    /// True once a temperature reading has left the safe band. Blocks sealing.
    @Default(false) bool hasColdChainExcursion,
  }) = _Order;

  const Order._();

  // --- Derived: the numbers every screen reads --------------------------

  int get units => lines.length;

  Iterable<OrderLine> get verifiedLines =>
      lines.where((OrderLine l) => l.isVerified);

  int get verifiedUnits => verifiedLines.length;

  int get heldUnits => lines.where((OrderLine l) => l.isHeld).length;

  int get pendingUnits => lines.where((OrderLine l) => l.isPending).length;

  /// 0 to 1. Drives both the queue card and the scan progress ring.
  double get progress => units == 0 ? 0 : verifiedUnits / units;

  /// Ordered but not on the truck — held or never presented.
  int get shortUnits {
    final int short = units - verifiedUnits;
    return short > 0 ? short : 0;
  }

  /// Presented but not on the manifest. Zero until over-scanning is possible.
  int get overUnits => 0;

  /// Share that went on without intervention, 0 to 1.
  double get firstPassYield => progress;

  /// `92.9` — the figure without its unit, so `%` can be styled apart.
  String get firstPassLabel => (firstPassYield * 100).toStringAsFixed(1);

  double get loadedWeightKg =>
      verifiedLines.fold(0, (double s, OrderLine l) => s + l.weightKg);

  double get loadedVolumeM3 =>
      verifiedLines.fold(0, (double s, OrderLine l) => s + l.volumeM3);

  double get weightPct => vehicle.maxWeightKg <= 0
      ? 0
      : (loadedWeightKg / vehicle.maxWeightKg).clamp(0.0, 1.0);

  double get volumePct => vehicle.maxVolumeM3 <= 0
      ? 0
      : (loadedVolumeM3 / vehicle.maxVolumeM3).clamp(0.0, 1.0);

  bool get isComplete => verifiedUnits >= units;

  /// Nothing short, nothing unexpected.
  bool get isClean => shortUnits == 0 && overUnits == 0;

  /// Sealing is refused while the cold chain has been broken.
  bool get canSeal => status.acceptsScans && !hasColdChainExcursion;

  /// Why the load is short, from the first held line. Null when it is not.
  String? get shortReason {
    for (final OrderLine l in lines) {
      if (l.isHeld && l.holdReason != null) return l.holdReason;
    }
    return null;
  }

  /// The next line a hardware trigger would present.
  OrderLine? get nextPendingLine {
    for (final OrderLine line in lines) {
      if (line.isPending) return line;
    }
    return null;
  }

  OrderLine? lineBySscc(String sscc) {
    for (final OrderLine line in lines) {
      if (line.sscc == sscc) return line;
    }
    return null;
  }

  /// `T 421 DKV`, or a dash when no truck is assigned.
  String get plateLabel => vehicle.plate.isEmpty ? '—' : vehicle.plate;

  /// The metadata line under the consignee on a queue card.
  List<String> get metaSegments => <String>[
    docNo,
    plateLabel,
    routeCode,
    '$units u',
    '${(loadedWeightKg / 1000).toStringAsFixed(1)} t',
  ];
}
