import '../../core/result/result.dart';
import '../models/item_lookup_result.dart';
import '../models/load_plan.dart';
import '../models/load_plan_item.dart';

/// Reads load plans (the real backend's loading queue) and their items.
///
/// Read-only everywhere: load plans, trucks and items are created and
/// maintained by the ERP. This app only reads them and submits scans.
abstract interface class LoadPlanRepository {
  /// Load plans assigned to [operatorId] — the operator's loading queue.
  Future<Result<List<LoadPlan>>> assignedTo(String operatorId);

  /// One load plan's summary, including overall scan progress.
  Future<Result<LoadPlan>> byId(String loadPlanId);

  /// All items on [loadPlanId], each with its own scan progress.
  Future<Result<List<LoadPlanItem>>> items(String loadPlanId);

  /// Resolves a scanned barcode to an item, independent of any load plan.
  Future<Result<ItemLookupResult>> lookupBarcode(String barcode);
}
