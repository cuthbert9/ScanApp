import '../../core/result/result.dart';
import '../models/order.dart';

/// Reads delivery orders staged at the dock.
///
/// SWAP POINT — replace [MockOrderRepository] with an HTTP implementation and
/// nothing above this interface changes.
abstract interface class OrderRepository {
  /// Orders staged to [bay], **excluding sealed ones** — a sealed order leaves
  /// the queue.
  Future<Result<List<Order>>> stagedOrders({required String bay});

  /// One order by document number, sealed or not.
  Future<Result<Order>> byDocNo(String docNo);
}
