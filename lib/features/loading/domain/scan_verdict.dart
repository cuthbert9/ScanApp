/// The outcome of checking one scan against the manifest.
enum ScanVerdict {
  /// On the manifest, not seen before, within the expected count.
  ok('OK'),

  /// Recorded, but it must not be loaded until someone resolves it.
  hold('Hold'),

  /// Decoded, but nothing on this manifest matches it.
  unknown('Unknown');

  const ScanVerdict(this.label);

  /// Rendered upper-case by the badge.
  final String label;

  /// Whether this scan counts towards units loaded.
  ///
  /// Only [ok] does. A held or unknown unit is recorded — never silently
  /// dropped — but it does not advance the load.
  bool get isAccepted => this == ScanVerdict.ok;
}
