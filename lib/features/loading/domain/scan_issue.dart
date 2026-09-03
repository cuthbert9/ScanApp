/// Why a scan was not accepted, as a value rather than a string.
///
/// [ScanRecord.reason] carries the operator-facing sentence; this carries the
/// machine-readable cause. Reconciliation needs to count over-scans separately
/// from short lines, and matching on English prose to do it would break the
/// first time someone reworded a message.
enum ScanIssue {
  /// The scan was accepted.
  none,

  /// This exact unit has already been recorded on this load.
  duplicate,

  /// The manifest is already satisfied; this unit is surplus.
  overCount,

  /// Nothing on the manifest matches the code.
  notOnManifest,

  /// Held on first-expiry-first-out grounds — an earlier lot is still in stock.
  fefoHold;

  /// Two or three words, for a reconciliation line where the full sentence
  /// would not fit.
  ///
  /// [ScanRecord.reason] stays the long form, shown in the scan feed where
  /// there is room for it.
  String get shortLabel => switch (this) {
    ScanIssue.none => '',
    ScanIssue.duplicate => 'Duplicate',
    ScanIssue.overCount => 'Over-count',
    ScanIssue.notOnManifest => 'Not on manifest',
    ScanIssue.fefoHold => 'FEFO hold',
  };

  /// Whether this issue means an unexpected unit was presented, as opposed to
  /// an expected one being rejected.
  ///
  /// Drives the reconciliation card's OVER / UNEXPECTED figure.
  bool get isUnexpected =>
      this == ScanIssue.overCount || this == ScanIssue.notOnManifest;
}
