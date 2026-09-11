import 'package:freezed_annotation/freezed_annotation.dart';

part 'truck.freezed.dart';
part 'truck.g.dart';

/// The vehicle assigned to a load plan.
@freezed
abstract class Truck with _$Truck {
  const factory Truck({
    required String id,
    @JsonKey(name: 'registration_number') required String registrationNumber,
  }) = _Truck;

  factory Truck.fromJson(Map<String, Object?> json) => _$TruckFromJson(json);
}
