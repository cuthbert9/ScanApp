import '../core/errors/app_exception.dart';
import '../core/result/result.dart';
import '../domain/models/station.dart';
import '../domain/repositories/station_repository.dart';
import 'mock_backend.dart';
import 'mock_latency.dart';

/// In-memory [StationRepository] over [MockBackend].
class MockStationRepository implements StationRepository {
  const MockStationRepository(this._backend);

  final MockBackend _backend;

  /// Switching station re-pulls bays and routes, which takes longer than a
  /// read.
  static const Duration _resyncDuration = Duration(milliseconds: 700);

  @override
  Future<Result<Station>> current() async {
    await mockLatency();
    return Success<Station>(_backend.station);
  }

  @override
  Future<Result<List<Station>>> available() async {
    await mockLatency();
    return Success<List<Station>>(_backend.stations);
  }

  @override
  Future<Result<Station>> select(String code) async {
    await Future<void>.delayed(_resyncDuration);
    try {
      return Success<Station>(_backend.selectStation(code));
    } on StateError catch (e) {
      return Failure<Station>(ValidationException(e.message, cause: e));
    }
  }
}
