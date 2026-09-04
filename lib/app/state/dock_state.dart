import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/order.dart';
import '../../domain/models/station.dart';

part 'dock_state.freezed.dart';

/// Everything the dock screens share.
///
/// The open order is **app-level**, not per-screen: Orders, Scan and Load all
/// read it, so `BAY 04 · DO-2026-04417` is a binding rather than a literal.
@freezed
abstract class DockState with _$DockState {
  const factory DockState({
    required Station station,

    /// Staged to this bay, sealed orders already excluded.
    required List<Order> staged,

    /// The order the operator has opened, by document number.
    String? selectedDocNo,

    /// `Seal load` stays disabled until the Load screen has actually been
    /// looked at — sealing is not something to do from the queue.
    @Default(false) bool hasViewedLoad,
  }) = _DockState;

  const DockState._();

  /// The open order, or null when none is selected or it has been sealed away.
  Order? get selected {
    if (selectedDocNo == null) return null;
    for (final Order o in staged) {
      if (o.docNo == selectedDocNo) return o;
    }
    return null;
  }

  bool get hasSelection => selected != null;

  // --- Queue summary, derived once here and read by the strip -------------

  int get orderCount => staged.length;

  int get totalUnits => staged.fold(0, (int s, Order o) => s + o.units);

  int get coldChainCount => staged.where((Order o) => o.coldChain).length;

  bool get isEmpty => staged.isEmpty;

  /// `BAY 04 · DO-2026-04417`, or the bay alone when nothing is open.
  String get contextLabel {
    final String bay = 'BAY ${station.assignedBay}';
    return selectedDocNo == null ? bay : '$bay  ·  $selectedDocNo';
  }
}
