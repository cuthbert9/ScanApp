import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/result/result.dart';
import '../../../data/repository_providers.dart';
import '../../../domain/models/device_config.dart';
import '../../../domain/models/officer.dart';
import '../../../domain/models/shift_stats.dart';
import '../../../domain/models/station.dart';

part 'settings_controller.g.dart';

/// Everything the Settings screen shows, gathered in one read.
///
/// A record rather than a model: it is a view aggregation with no behaviour, so
/// it does not earn a domain type.
typedef SettingsView = ({
  Officer officer,
  ShiftStats stats,
  Station station,
  DeviceConfig device,
});

/// Reads the officer, their shift figures, the station and device config from
/// the four repositories that own them.
@riverpod
class SettingsController extends _$SettingsController {
  @override
  Future<SettingsView> build() => _load();

  Future<SettingsView> _load() async {
    final Officer officer = _unwrap(
      await ref.read(officerRepositoryProvider).current(),
    );
    final ShiftStats stats = _unwrap(
      await ref.read(officerRepositoryProvider).statsToday(),
    );
    final Station station = _unwrap(
      await ref.read(stationRepositoryProvider).current(),
    );
    final DeviceConfig device = _unwrap(
      await ref.read(settingsRepositoryProvider).deviceConfig(),
    );

    return (officer: officer, stats: stats, station: station, device: device);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  T _unwrap<T>(Result<T> result) => switch (result) {
    Success<T>(:final T value) => value,
    Failure<T>(:final AppException error) => throw error,
  };
}

/// Stations the handheld may be reassigned to, for the `Change station` picker.
@riverpod
Future<List<Station>> availableStations(Ref ref) async {
  final Result<List<Station>> result = await ref
      .read(stationRepositoryProvider)
      .available();
  return result.valueOrNull ?? const <Station>[];
}

/// Elapsed shift time, derived against a fixed capture rather than the wall
/// clock so the figure is stable within a read.
@riverpod
String onShiftLabel(Ref ref) {
  final Officer? officer = ref.watch(settingsControllerProvider).value?.officer;
  if (officer == null) return '—';
  final DateTime now = DateTime.now();
  Duration elapsed = now.difference(officer.shiftStart);
  if (elapsed.isNegative) elapsed = Duration.zero;
  final int hours = elapsed.inHours;
  final String minutes = elapsed.inMinutes
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  return '$hours:$minutes';
}
