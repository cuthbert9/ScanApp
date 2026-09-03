import 'package:freezed_annotation/freezed_annotation.dart';

part 'station.freezed.dart';

/// The warehouse base this handheld is working from.
///
/// A dispatch map will eventually render around this; for now the screen shows
/// the details on their own.
@freezed
abstract class Station with _$Station {
  const factory Station({
    required String name,
    required String code,
    required double latitude,
    required double longitude,

    /// Bay number the operator is assigned to, e.g. `04`.
    required String assignedBay,

    /// What that bay is for, e.g. `dispatch`.
    required String bayPurpose,

    /// Whether the device is inside the station's geofence.
    required bool isInsideGeofence,

    /// Distance to the geofence edge, in metres.
    required int geofenceMetres,

    /// Reported GPS accuracy, in metres.
    required int gpsAccuracyMetres,

    /// When bays and routes were last pulled from dispatch.
    required DateTime lastSyncedAt,
  }) = _Station;

  const Station._();

  /// `-6.8123, 39.2691` — four decimal places, roughly 11 m, which is finer
  /// than the device's own fix.
  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  String get bayLabel => '$assignedBay  ·  $bayPurpose';

  String get geofenceLabel =>
      '${isInsideGeofence ? 'Inside' : 'Outside'}  ·  $geofenceMetres m';

  bool get hasFix => gpsAccuracyMetres > 0;
}
