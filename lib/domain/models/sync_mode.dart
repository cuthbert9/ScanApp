/// How captured work reaches the backend.
///
/// The operator-facing copy lives on the enum rather than in a widget, so a
/// description cannot drift from the behaviour it describes.
enum SyncMode {
  onlineDirect(
    code: '01',
    title: 'Online direct',
    description:
        'Every scan posts to the MSD ERP ledger as it happens. '
        'Needs dock Wi-Fi; sub-second round trip.',
  ),
  storeAndForward(
    code: '02',
    title: 'Store & forward',
    description:
        'Scans queue to an encrypted local store and flush the moment '
        'Wi-Fi or cellular returns. Default at all dispatch bays.',
  ),
  airGapped(
    code: '03',
    title: 'Air-gapped depot',
    description:
        'Signed batch archive for zonal stores with no link at all. '
        'Syncs when the handheld is docked in its cradle.',
  );

  const SyncMode({
    required this.code,
    required this.title,
    required this.description,
  });

  final String code;
  final String title;
  final String description;

  /// Whether work accumulates on the device before being sent.
  bool get queuesLocally => this != SyncMode.onlineDirect;

  /// Air-gapped depots have no link to flush over; the cradle does it.
  bool get canFlushOverNetwork => this != SyncMode.airGapped;

  /// Shown when flushing is refused.
  String get flushBlockedReason =>
      'Air-gapped mode has no link to push over. The queue clears when the '
      'handheld is docked in its cradle.';
}
