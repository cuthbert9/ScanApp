import '../../core/result/result.dart';
import '../models/station.dart';

/// The warehouse base the handheld is assigned to.
///
/// SWAP POINT — the real implementation reads the station from the device's
/// managed configuration and its bays and routes from dispatch.
abstract interface class StationRepository {
  Future<Result<Station>> current();

  /// Stations this handheld may be reassigned to.
  Future<Result<List<Station>>> available();

  /// Switches station, re-syncs bays and routes, and stamps a new
  /// `mapSyncedAt`.
  Future<Result<Station>> select(String code);
}
