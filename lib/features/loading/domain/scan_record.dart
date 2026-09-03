import 'package:freezed_annotation/freezed_annotation.dart';

import 'gs1_barcode.dart';
import 'scan_issue.dart';
import 'scan_verdict.dart';

part 'scan_record.freezed.dart';

/// One line in the scan feed: what was scanned, what it is, and whether it
/// passed.
///
/// Every scan produces one of these, including a code that could not be
/// decoded. A scanner that appears to do nothing is worse than one that
/// reports a problem.
@freezed
abstract class ScanRecord with _$ScanRecord {
  const factory ScanRecord({
    /// Position in the session, starting at 1. Shown at the head of the row so
    /// an operator can call out "number 14" to a supervisor.
    required int sequence,

    /// Catalogue description, or a fallback when the code is unrecognised.
    required String productName,

    /// Units in this pack.
    required int quantity,

    required Gs1Barcode barcode,
    required ScanVerdict verdict,
    required DateTime scannedAt,

    /// Why this was held or rejected, in the operator's words — "FEFO: earlier
    /// lot in stock". Null when [verdict] is [ScanVerdict.ok].
    String? reason,

    @Default(false) bool isColdChain,

    /// Machine-readable cause, for reconciliation counts. See [ScanIssue].
    @Default(ScanIssue.none) ScanIssue issue,

    /// Gross mass of this unit, summed into the load's weight utilisation.
    @Default(0.0) double weightKg,

    /// Volume of this unit, for the same reason.
    @Default(0.0) double volumeM3,
  }) = _ScanRecord;

  const ScanRecord._();

  /// The monospaced detail line, assembled once here so every view of a record
  /// shows the same fields in the same order.
  ///
  /// Matches a printed label: identifiers first with their AI prefixes, then
  /// expiry, then any exception.
  List<Gs1Segment> get segments {
    final List<Gs1Segment> parts = <Gs1Segment>[];

    if (barcode.sscc != null) {
      parts.add(Gs1Segment(ai: '00', text: barcode.sscc!));
    }
    if (barcode.gtin != null && barcode.sscc == null) {
      parts.add(Gs1Segment(ai: '01', text: barcode.gtin!));
    }
    if (barcode.batch != null) {
      parts.add(Gs1Segment(ai: '10', text: barcode.batch!));
    }
    if (barcode.expiryLabel != null) {
      parts.add(Gs1Segment(text: 'EXP ${barcode.expiryLabel}'));
    }
    if (reason != null) {
      parts.add(Gs1Segment(text: reason!));
    }

    // Never render an empty line: fall back to whatever was actually scanned.
    if (parts.isEmpty) {
      parts.add(Gs1Segment(text: barcode.raw.isEmpty ? '—' : barcode.raw));
    }
    return parts;
  }

  /// Identity used for duplicate detection. See [Gs1Barcode.identity].
  String get identity => barcode.identity;
}
