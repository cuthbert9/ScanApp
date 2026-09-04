import '../core/result/result.dart';
import '../domain/models/officer.dart';
import '../domain/models/shift_stats.dart';
import '../domain/repositories/officer_repository.dart';
import 'mock_backend.dart';
import 'mock_latency.dart';

/// In-memory [OfficerRepository] over [MockBackend].
class MockOfficerRepository implements OfficerRepository {
  const MockOfficerRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<Result<Officer>> current() async {
    await mockLatency();
    return Success<Officer>(_backend.officer);
  }

  @override
  Future<Result<ShiftStats>> statsToday() async {
    await mockLatency();
    return Success<ShiftStats>(_backend.shiftStats);
  }
}
