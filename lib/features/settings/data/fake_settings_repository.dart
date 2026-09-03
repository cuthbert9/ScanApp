import '../../../core/errors/app_exception.dart';
import '../../../core/result/result.dart';
import '../domain/daily_scan_count.dart';
import '../domain/operator_profile.dart';
import '../domain/scanner_config.dart';
import '../domain/session_config.dart';
import '../domain/settings_repository.dart';
import '../domain/settings_snapshot.dart';
import '../domain/shift_stats.dart';
import '../domain/station.dart';

/// In-memory [SettingsRepository].
///
/// Times are fixed rather than taken from the clock, so the shift figures are
/// deterministic across runs and tests. `capturedAt` at 12:12 against a 06:00
/// start is what produces `6:12 ON SHIFT`.
class FakeSettingsRepository implements SettingsRepository {
  const FakeSettingsRepository({this.failNextLoad = false});

  final bool failNextLoad;

  static const Duration _latency = Duration(milliseconds: 200);

  static final DateTime _day = DateTime(2026, 9, 3);

  @override
  Future<Result<SettingsSnapshot>> load() async {
    await Future<void>.delayed(_latency);

    if (failNextLoad) {
      return const Failure<SettingsSnapshot>(
        NetworkException('Cannot reach the operator directory.'),
      );
    }

    return Success<SettingsSnapshot>(
      SettingsSnapshot(
        deviceSerial: 'TC58-DAR-014',
        appVersion: '3.8.2',
        capturedAt: _day.add(const Duration(hours: 12, minutes: 12)),
        profile: OperatorProfile(
          name: 'Neema Mwakalinga',
          staffId: 'MSD-OP-2214',
          role: 'Loading Officer II',
          shiftStart: _day.add(const Duration(hours: 6)),
          shiftEnd: _day.add(const Duration(hours: 15)),
        ),
        stats: const ShiftStats(
          unitsScanned: 148,
          coldChainHolds: 1,
          medianSecondsPerUnit: 11,
          loadsSealed: 3,
          week: <DailyScanCount>[
            DailyScanCount(label: 'T', dayName: 'Thursday', units: 152),
            DailyScanCount(label: 'F', dayName: 'Friday', units: 149),
            DailyScanCount(label: 'S', dayName: 'Saturday', units: 86),
            DailyScanCount(label: 'S', dayName: 'Sunday', units: 24),
            DailyScanCount(label: 'M', dayName: 'Monday', units: 141),
            DailyScanCount(label: 'T', dayName: 'Tuesday', units: 145),
            DailyScanCount(
              label: 'W',
              dayName: 'Wednesday',
              units: 148,
              isToday: true,
            ),
          ],
        ),
        station: Station(
          name: 'Dar es Salaam Central Vaccine Store',
          code: 'MSD-CVS-DAR',
          latitude: -6.8123,
          longitude: 39.2691,
          assignedBay: '04',
          bayPurpose: 'dispatch',
          isInsideGeofence: true,
          geofenceMetres: 40,
          gpsAccuracyMetres: 6,
          lastSyncedAt: _day.add(const Duration(hours: 7, minutes: 58)),
        ),
        scanner: const ScannerConfig(
          input: 'DataWedge intent',
          symbologies: <String>['EAN-13', 'GS1-128', 'DataMatrix'],
          passFeedback: 'Beep + 1 buzz',
          failFeedback: 'Double tone + 3 buzz',
        ),
        session: const SessionConfig(
          languages: <String>['Kiswahili', 'English'],
          idleLockSeconds: 90,
        ),
      ),
    );
  }
}
