import 'package:freezed_annotation/freezed_annotation.dart';

import 'truck.dart';

part 'load_plan.freezed.dart';
part 'load_plan.g.dart';

/// A load plan assigned to an operator — the loading queue's real-backend
/// counterpart. The ERP owns it; this app only reads it.
///
/// `completedItemsCount`/`remainingItemsCount` are only present on the
/// single-load-plan detail read, not the assigned-list read — both come back
/// null there rather than a fabricated zero.
@freezed
abstract class LoadPlan with _$LoadPlan {
  const factory LoadPlan({
    required String id,
    required String reference,
    required String status,
    Truck? truck,
    String? destination,
    @JsonKey(name: 'assigned_at') DateTime? assignedAt,
    @JsonKey(name: 'expected_items_count') required int expectedItemsCount,
    @JsonKey(name: 'completed_items_count') int? completedItemsCount,
    @JsonKey(name: 'remaining_items_count') int? remainingItemsCount,
  }) = _LoadPlan;

  const LoadPlan._();

  factory LoadPlan.fromJson(Map<String, Object?> json) =>
      _$LoadPlanFromJson(json);

  /// 0 to 1, or null when this read didn't carry progress counts.
  double? get progress {
    final int? completed = completedItemsCount;
    if (completed == null) return null;
    if (expectedItemsCount == 0) return 0;
    return completed / expectedItemsCount;
  }
}
