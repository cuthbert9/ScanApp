import '../../../core/errors/app_exception.dart';
import '../../../core/result/result.dart';
import '../domain/loading_order.dart';
import '../domain/loading_queue_repository.dart';
import '../domain/loading_queue_snapshot.dart';
import '../domain/order_status.dart';

/// In-memory [LoadingQueueRepository], so the UI can be built and demonstrated
/// before the backend exists.
///
/// The real implementation will call the MSSQL-backed service in the separate
/// backend repo. Nothing outside `data/` changes when it lands — only which
/// implementation `loadingQueueRepositoryProvider` returns.
///
/// [failNextFetch] exists so the error state gets built and looked at rather
/// than assumed. A UI that has only ever been seen in its happy path is a UI
/// with an untested half.
class FakeLoadingQueueRepository implements LoadingQueueRepository {
  const FakeLoadingQueueRepository({this.failNextFetch = false});

  final bool failNextFetch;

  /// Stand-in for network latency, so loading states are visible in
  /// development instead of flashing past.
  static const Duration _latency = Duration(milliseconds: 350);

  @override
  Future<Result<LoadingQueueSnapshot>> fetchQueue() async {
    await Future<void>.delayed(_latency);

    if (failNextFetch) {
      return const Failure<LoadingQueueSnapshot>(
        NetworkException('Cannot reach the dispatch service. Working offline.'),
      );
    }

    return const Success<LoadingQueueSnapshot>(
      LoadingQueueSnapshot(
        tripReference: 'TSP FR 9.1–9.3',
        hub: 'DAR CVS',
        dock: 'Dock 04',
        isBayOpen: true,
        orders: <LoadingOrder>[
          LoadingOrder(
            id: 'DO-2026-04417',
            facility: 'Dodoma Zonal Store',
            truck: 'T 421 DKV',
            route: 'TZ-C-07',
            units: 14,
            tonnes: 3.2,
            status: OrderStatus.loading,
            isColdChain: true,
            loadProgress: 0.92,
          ),
          LoadingOrder(
            id: 'DO-2026-04418',
            facility: 'Morogoro Regional Medical Store',
            truck: 'T 118 CQA',
            route: 'TZ-E-02',
            units: 19,
            tonnes: 4.7,
            status: OrderStatus.queued,
          ),
          LoadingOrder(
            id: 'DO-2026-04421',
            facility: 'Ifakara District Hospital',
            truck: 'T 906 BLE',
            route: 'TZ-S-11',
            units: 8,
            tonnes: 0.9,
            status: OrderStatus.noTruck,
            isColdChain: true,
            programme: 'EPI',
          ),
        ],
      ),
    );
  }
}
