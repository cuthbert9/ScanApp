import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_record.freezed.dart';

/// Where one queued record has got to.
enum SyncRecordState { pending, sent, failed }

/// One unit of captured work waiting to be pushed.
///
/// Deliberately opaque about its contents: the outbox does not care whether a
/// record is a scan or a seal, which is what lets any part of the app enqueue
/// into it without the outbox depending on any of them.
@freezed
abstract class SyncRecord with _$SyncRecord {
  const factory SyncRecord({
    required String id,

    /// What kind of work this is — `scan`, `seal`.
    required String type,

    /// When the work happened on the device, not when it was queued.
    required DateTime createdAt,

    required int payloadBytes,

    @Default(SyncRecordState.pending) SyncRecordState state,
  }) = _SyncRecord;

  const SyncRecord._();

  bool get isPending => state == SyncRecordState.pending;
  bool get isFailed => state == SyncRecordState.failed;
}
