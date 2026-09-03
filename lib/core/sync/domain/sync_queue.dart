import 'package:freezed_annotation/freezed_annotation.dart';

import 'queued_record.dart';
import 'sync_mode.dart';
import 'sync_state.dart';

part 'sync_queue.freezed.dart';

/// The device's outbox: everything captured but not yet accepted by the
/// backend.
///
/// Counts, payload size and the oldest record are all derived from [pending],
/// so the summary strip, the local-queue card and the tab badge cannot
/// disagree with each other.
@freezed
abstract class SyncQueue with _$SyncQueue {
  const factory SyncQueue({
    required SyncMode mode,

    /// Oldest first, which is also push order.
    required List<QueuedRecord> pending,

    /// Trip this device is working, e.g. `TSP FR 14.9`.
    required String tripReference,

    /// Origin hub code, e.g. `DAR CVS`.
    required String hub,

    /// Records rejected by the backend and awaiting retry.
    @Default(0) int failedCount,

    /// When the last push completed. Null before the first one.
    DateTime? lastPushAt,

    /// Whether that push was accepted.
    @Default(true) bool lastPushAccepted,

    /// True while a flush is in flight.
    @Default(false) bool isPushing,
  }) = _SyncQueue;

  const SyncQueue._();

  int get pendingCount => pending.length;

  /// Total bytes waiting to go.
  int get payloadBytes =>
      pending.fold(0, (int sum, QueuedRecord r) => sum + r.sizeBytes);

  /// `4.1 kB`. Decimal kilobytes, which is what an operator comparing this
  /// against a data allowance expects.
  String get payloadLabel {
    if (payloadBytes < 1000) return '$payloadBytes B';
    final double kb = payloadBytes / 1000;
    if (kb < 1000) return '${kb.toStringAsFixed(1)} kB';
    return '${(kb / 1000).toStringAsFixed(1)} MB';
  }

  /// When the oldest waiting record was captured — how far behind the device
  /// has fallen.
  DateTime? get oldestCapturedAt {
    if (pending.isEmpty) return null;
    DateTime oldest = pending.first.capturedAt;
    for (final QueuedRecord record in pending) {
      if (record.capturedAt.isBefore(oldest)) oldest = record.capturedAt;
    }
    return oldest;
  }

  String get oldestRecordLabel => formatClock(oldestCapturedAt);

  String get lastPushLabel => formatClock(lastPushAt);

  /// Outcome of the last push, for the local-queue card.
  String get lastPushOutcome {
    if (lastPushAt == null) return 'never';
    return lastPushAccepted ? 'accepted' : 'rejected';
  }

  /// What the outbox is doing, derived from mode and contents.
  SyncState get state {
    if (isPushing) return SyncState.pushing;
    if (failedCount > 0) return SyncState.retrying;
    return switch (mode) {
      SyncMode.onlineDirect => SyncState.live,
      SyncMode.storeAndForward =>
        pending.isEmpty ? SyncState.clear : SyncState.accumulating,
      SyncMode.airGapped => SyncState.archiving,
    };
  }

  /// Whether there is anything a flush could usefully do.
  bool get canFlush => pending.isNotEmpty && !isPushing;

  /// `08:09`, or an em dash when there is no time.
  ///
  /// Lives on the domain rather than in a widget because two screens render it
  /// and a second copy would eventually disagree.
  static String formatClock(DateTime? time) {
    if (time == null) return '—';
    final String h = time.hour.toString().padLeft(2, '0');
    final String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
