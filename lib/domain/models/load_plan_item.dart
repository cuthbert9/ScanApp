import 'package:freezed_annotation/freezed_annotation.dart';

part 'load_plan_item.freezed.dart';
part 'load_plan_item.g.dart';

/// One item on a load plan — a single scannable unit (a box, carrying its own
/// unique GS1 serial number), not a quantity to be partly fulfilled.
///
/// There is deliberately no expected/scanned/remaining quantity here: an item
/// is either `pending` or scanned. How much of the load is done lives on
/// [LoadPlan] (`expectedItemsCount`/`completedItemsCount`/`remainingItemsCount`),
/// which is the only place that mutation should ever be read from.
@freezed
abstract class LoadPlanItem with _$LoadPlanItem {
  const factory LoadPlanItem({
    required String id,
    required String sku,
    String? description,
    @Default(<String>[]) List<String> barcodes,
    String? status,
  }) = _LoadPlanItem;

  factory LoadPlanItem.fromJson(Map<String, Object?> json) =>
      _$LoadPlanItemFromJson(json);
}
