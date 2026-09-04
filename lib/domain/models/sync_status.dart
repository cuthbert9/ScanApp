import 'package:freezed_annotation/freezed_annotation.dart';

import 'sync_record.dart';
import 'sync_mode.dart';

part 'sync_status.freezed.dart';

/// What the outbox is doing right now. Derived, never stored.
enum SyncState {
  live('Live'),
  accumulating('Accumulating'),
  archiving('Archiving'),
  pushing('Pushing'),
  retrying('Retrying'),

  /// Nothing waiting — the state after a successful flush.
  upToDate('Up to date');

  const SyncState(this.label);
  final String label;

  bool get needsAttention => this == SyncState.retrying;
}

/// The device's outbox in one read.
///
/// Counts, payload and the state word are all derived from [records], so the
/// summary strip, the local-queue card and the tab badge cannot disagree.
@freezed
abstract class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    required SyncMode mode,

    /// Oldest first, which is also push order.
    required List<SyncRecord> records,
    required String tripReference,
    required String hub,
    DateTime? lastPushAt,
    @Default(true) bool lastPushAccepted,
    @Default(false) bool isPushing,

    /// Debug switch: while true, a flush cannot reach anything and scans pile
    /// up, so the queueing behaviour can be watched.
    @Default(false) bool simulateOffline,
  }) = _SyncStatus;

  const SyncStatus._();

  List<SyncRecord> get pending =>
      records.where((SyncRecord r) => r.isPending).toList(growable: false);

  int get pendingCount => pending.length;

  int get failedCount => records.where((SyncRecord r) => r.isFailed).length;

  int get payloadBytes =>
      pending.fold(0, (int s, SyncRecord r) => s + r.payloadBytes);

  /// `4.1 kB`. Decimal kilobytes, which is what an operator comparing this
  /// against a data allowance expects.
  String get payloadLabel {
    if (payloadBytes < 1000) return '$payloadBytes B';
    final double kb = payloadBytes / 1000;
    if (kb < 1000) return '${kb.toStringAsFixed(1)} kB';
    return '${(kb / 1000).toStringAsFixed(1)} MB';
  }

  DateTime? get oldestCapturedAt {
    if (pending.isEmpty) return null;
    DateTime oldest = pending.first.createdAt;
    for (final SyncRecord r in pending) {
      if (r.createdAt.isBefore(oldest)) oldest = r.createdAt;
    }
    return oldest;
  }

  String get oldestRecordLabel => formatClock(oldestCapturedAt);
  String get lastPushLabel => formatClock(lastPushAt);

  String get lastPushOutcome {
    if (lastPushAt == null) return 'never';
    return lastPushAccepted ? 'accepted' : 'rejected';
  }

  SyncState get state {
    if (isPushing) return SyncState.pushing;
    if (failedCount > 0) return SyncState.retrying;
    if (pending.isEmpty) return SyncState.upToDate;
    return switch (mode) {
      SyncMode.onlineDirect => SyncState.live,
      SyncMode.storeAndForward => SyncState.accumulating,
      SyncMode.airGapped => SyncState.archiving,
    };
  }

  /// Whether a flush could usefully run: something to send, not already
  /// running, a mode that can reach the network, and a link.
  bool get canFlush =>
      pending.isNotEmpty &&
      !isPushing &&
      mode.canFlushOverNetwork &&
      !simulateOffline;

  /// `08:09`, or an em dash when there is no time.
  static String formatClock(DateTime? t) {
    if (t == null) return '—';
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }
}
