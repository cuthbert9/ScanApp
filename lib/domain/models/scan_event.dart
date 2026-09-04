import 'package:freezed_annotation/freezed_annotation.dart';

import 'order_line.dart';

part 'scan_event.freezed.dart';

/// What the rules made of a scan.
///
/// Evaluated in this order: a duplicate is more useful to report than a wrong
/// order, and a wrong order more useful than a FEFO hold.
enum ScanResult {
  /// On the manifest, not seen before, no earlier lot in stock.
  ok('OK'),

  /// Recorded, but must not be loaded until someone resolves it.
  hold('Hold'),

  /// This exact code has already been scanned this session.
  duplicate('Duplicate'),

  /// The code belongs to a different order.
  wrongOrder('Wrong order');

  const ScanResult(this.label);

  /// Rendered upper-case by the badge.
  final String label;

  /// Whether this scan put a unit on the truck.
  bool get isAccepted => this == ScanResult.ok;

  /// Whether the device should give the failure signal — a double tone and
  /// three buzzes, distinguishable through ear defenders.
  bool get isFailure => this != ScanResult.ok;
}

/// One row of the scan feed.
///
/// Every scan produces one, including a rejected or unrecognised code. A
/// scanner that appears to do nothing is worse than one that reports a problem.
@freezed
abstract class ScanEvent with _$ScanEvent {
  const factory ScanEvent({
    /// Position in the session, from 1.
    required int seq,
    required DateTime at,

    /// The line this code resolved to, when it resolved to one.
    required OrderLine? line,

    required ScanResult result,

    /// Why, in the operator's words — `FEFO: earlier lot in stock`. Null on
    /// an accepted scan.
    String? reason,

    /// Exactly what was scanned, kept for diagnostics.
    @Default('') String rawCode,
  }) = _ScanEvent;

  const ScanEvent._();

  /// Falls back to the raw code when nothing on the manifest matched.
  String get productName => line?.productName ?? 'Unrecognised code';

  int get quantity => line?.quantity ?? 0;
}
