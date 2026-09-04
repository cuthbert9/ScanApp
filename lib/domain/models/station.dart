import 'package:freezed_annotation/freezed_annotation.dart';

part 'station.freezed.dart';

/// A warehouse base the handheld can be assigned to.
@freezed
abstract class Station with _$Station {
  const factory Station({
    required String code,
    required String name,
    required double lat,
    required double lng,

    /// Bay the operator is working, e.g. `04`.
    required String assignedBay,

    /// What that bay is for, e.g. `dispatch`.
    @Default('dispatch') String bayPurpose,

    /// Every bay at this station, e.g. `01`..`06`.
    required List<String> bays,

    required int geofenceMetres,
    required bool insideGeofence,

    /// Reported GPS accuracy, in metres.
    @Default(6) int gpsAccuracyMetres,

    /// When bays and routes were last pulled from the dispatch map.
    required DateTime mapSyncedAt,
  }) = _Station;

  const Station._();

  /// `-6.8123, 39.2691` — four places, finer than the device's own fix.
  String get coordinatesLabel =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  /// `04  ·  dispatch`
  String get bayLabel => '$assignedBay  ·  $bayPurpose';

  String get geofenceLabel =>
      '${insideGeofence ? 'Inside' : 'Outside'}  ·  $geofenceMetres m';

  String get mapSyncedLabel =>
      '${mapSyncedAt.hour.toString().padLeft(2, '0')}:'
      '${mapSyncedAt.minute.toString().padLeft(2, '0')}';
}
