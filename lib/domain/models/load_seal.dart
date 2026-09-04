import 'package:freezed_annotation/freezed_annotation.dart';

part 'load_seal.freezed.dart';

/// The record written when a load is sealed.
///
/// A snapshot, deliberately: it is what the delivery note printed at that
/// moment, and must not change afterwards even if the order is edited.
@freezed
abstract class LoadSeal with _$LoadSeal {
  const factory LoadSeal({
    required String docNo,
    required DateTime sealedAt,
    required int orderedUnits,
    required int verifiedUnits,
    required int shortUnits,
    required int overUnits,

    /// True when the load did not match the manifest, so dispatch receives an
    /// amended one.
    required bool amended,
  }) = _LoadSeal;

  const LoadSeal._();

  /// How many lines the delivery note prints — the verified ones only.
  int get printedLines => verifiedUnits;
}
