import '../../../core/result/result.dart';
import 'settings_snapshot.dart';

/// Reads the operator, their shift figures, the station and device
/// configuration.
///
/// The backend seam. Today an in-memory fake satisfies it; the real
/// implementation will read the operator from the session and the rest from the
/// device's managed configuration.
abstract interface class SettingsRepository {
  Future<Result<SettingsSnapshot>> load();
}
