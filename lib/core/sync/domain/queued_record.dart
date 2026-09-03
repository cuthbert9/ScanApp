import 'package:freezed_annotation/freezed_annotation.dart';

part 'queued_record.freezed.dart';

/// One unit of captured work waiting to be pushed.
///
/// Deliberately opaque: the outbox does not care whether a record is a scan, a
/// seal, or a stock adjustment. That is what lets any feature write into it
/// without the outbox depending on any of them.
@freezed
abstract class QueuedRecord with _$QueuedRecord {
  const factory QueuedRecord({
    required String id,

    /// When the work happened on the device — not when it was queued.
    required DateTime capturedAt,

    /// Serialised size, summed into the queue's payload figure.
    required int sizeBytes,

    /// What kind of work this is, for diagnostics.
    @Default('scan') String kind,
  }) = _QueuedRecord;

  const QueuedRecord._();
}
