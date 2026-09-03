/// What the outbox is doing right now.
///
/// Derived from the mode and the queue rather than stored, so it cannot
/// disagree with the figures beside it.
enum SyncState {
  /// Posting as work happens; nothing held locally.
  live('Live'),

  /// Holding work until a link returns.
  accumulating('Accumulating'),

  /// Building a signed batch for a cradle sync.
  archiving('Archiving'),

  /// A push is in flight.
  pushing('Pushing'),

  /// A push failed and will be retried.
  retrying('Retrying'),

  /// Queueing, with nothing waiting.
  clear('Clear');

  const SyncState(this.label);

  /// Rendered upper-case beside the mode name.
  final String label;

  /// Whether this should read as a problem rather than normal operation.
  bool get needsAttention => this == SyncState.retrying;
}
