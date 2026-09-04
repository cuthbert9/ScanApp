import '../core/errors/app_exception.dart';
import '../core/result/result.dart';
import '../domain/models/load_seal.dart';
import '../domain/repositories/load_repository.dart';
import 'mock_backend.dart';
import 'mock_latency.dart';

/// In-memory [LoadRepository] over [MockBackend].
class MockLoadRepository implements LoadRepository {
  const MockLoadRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<Result<LoadSeal>> seal({required String docNo}) async {
    await mockLatency();
    try {
      return Success<LoadSeal>(_backend.seal(docNo));
    } on StateError catch (e) {
      // The backend refuses a seal it cannot make — an excursion, or an order
      // already sealed. Its message is written for an operator.
      return Failure<LoadSeal>(ValidationException(e.message, cause: e));
    }
  }

  @override
  Future<Result<LoadSeal?>> sealFor(String docNo) async {
    await mockLatency();
    return Success<LoadSeal?>(_backend.sealFor(docNo));
  }
}
