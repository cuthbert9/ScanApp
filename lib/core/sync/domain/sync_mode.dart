/// How captured work reaches the backend.
///
/// The operator-facing copy lives on the enum rather than in the widget, so a
/// description can never drift from the behaviour it describes.
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

  /// Two-digit ordinal shown beside the title.
  final String code;

  final String title;
  final String description;

  /// Whether work accumulates on the device before being sent.
  ///
  /// Only [onlineDirect] posts as it happens; the others build a queue, which
  /// is what the pending count and the flush action act on.
  bool get queuesLocally => this != SyncMode.onlineDirect;
}
