import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_line.freezed.dart';

/// Where one line of an order has got to.
enum LineState {
  /// Not yet scanned onto the truck.
  pending,

  /// Scanned and accepted. The only state that counts towards the load.
  verified,

  /// Scanned and stopped — FEFO, damage, a discrepancy. Recorded, not loaded.
  held,
}

/// One unit on an order.
///
/// Weight and volume live here rather than on a product catalogue, because
/// utilisation is summed across the *verified* lines — the load is what is
/// physically on the truck, not what was ordered.
@freezed
abstract class OrderLine with _$OrderLine {
  const factory OrderLine({
    /// Position on the manifest, from 1.
    required int seq,
    required String productName,

    /// Units in this pack — the `× 1000` on a feed row.
    required int quantity,

    /// Serial shipping container code, as scanned.
    required String sscc,

    required String lot,

    /// Expiry, to the month. FEFO compares these.
    required DateTime expiry,

    required double weightKg,
    required double volumeM3,

    @Default(LineState.pending) LineState state,

    /// Why this line is held, in two or three words — `FEFO hold`. Null unless
    /// [state] is [LineState.held]. Kept short: it sits beside a label on a
    /// 320 dp reconciliation card.
    String? holdReason,
  }) = _OrderLine;

  const OrderLine._();

  bool get isVerified => state == LineState.verified;
  bool get isHeld => state == LineState.held;
  bool get isPending => state == LineState.pending;

  /// `2027-06`, the form printed on a label.
  String get expiryLabel =>
      '${expiry.year.toString().padLeft(4, '0')}-'
      '${expiry.month.toString().padLeft(2, '0')}';
}
