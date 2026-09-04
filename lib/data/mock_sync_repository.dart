import '../core/errors/app_exception.dart';
import '../core/result/result.dart';
import '../domain/models/sync_mode.dart';
import '../domain/models/sync_status.dart';
import '../domain/repositories/sync_repository.dart';
import 'mock_backend.dart';
import 'mock_latency.dart';

/// In-memory [SyncRepository] over [MockBackend].
class MockSyncRepository implements SyncRepository {
  const MockSyncRepository(this._backend);

  final MockBackend _backend;

  /// A push takes noticeably longer than a read, so the pushing state is
  /// visible rather than a flicker.
  static const Duration _pushDuration = Duration(milliseconds: 900);

  @override
  Future<Result<SyncStatus>> status() async {
    await mockLatency();
    return Success<SyncStatus>(_backend.syncStatus);
  }

  @override
  Future<Result<SyncStatus>> setMode(SyncMode mode) async {
    await mockLatency();
    return Success<SyncStatus>(_backend.setSyncMode(mode));
  }

  @override
  Future<Result<SyncStatus>> flush() async {
    final SyncStatus before = _backend.syncStatus;

    if (!before.mode.canFlushOverNetwork) {
      return Failure<SyncStatus>(
        ValidationException(before.mode.flushBlockedReason),
      );
    }
    if (before.simulateOffline) {
      return Failure<SyncStatus>(
        const NetworkException(
          'No link. Work stays queued until the network returns.',
        ),
      );
    }

    await Future<void>.delayed(_pushDuration);
    return Success<SyncStatus>(_backend.flush());
  }

  @override
  Future<Result<SyncStatus>> setSimulatedOffline(bool value) async {
    await mockLatency();
    return Success<SyncStatus>(_backend.setSimulatedOffline(value));
  }
}
