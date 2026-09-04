import '../core/errors/app_exception.dart';
import '../core/result/result.dart';
import '../domain/models/order.dart';
import '../domain/repositories/order_repository.dart';
import 'mock_backend.dart';
import 'mock_latency.dart';

/// In-memory [OrderRepository] over [MockBackend].
class MockOrderRepository implements OrderRepository {
  const MockOrderRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<Result<List<Order>>> stagedOrders({required String bay}) async {
    await mockLatency();
    return Success<List<Order>>(_backend.stagedOrders(bay));
  }

  @override
  Future<Result<Order>> byDocNo(String docNo) async {
    await mockLatency();
    final Order? order = _backend.orderByDocNo(docNo);
    if (order == null) {
      return Failure<Order>(
        ValidationException('Order $docNo is not staged here.'),
      );
    }
    return Success<Order>(order);
  }
}
