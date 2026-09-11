import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_lookup_result.freezed.dart';
part 'item_lookup_result.g.dart';

/// An item resolved from a scanned barcode, independent of any load plan.
@freezed
abstract class ItemLookupResult with _$ItemLookupResult {
  const factory ItemLookupResult({
    required String id,
    required String sku,
    String? description,
    @Default(<String>[]) List<String> barcodes,
  }) = _ItemLookupResult;

  factory ItemLookupResult.fromJson(Map<String, Object?> json) =>
      _$ItemLookupResultFromJson(json);
}
