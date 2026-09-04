import '../core/result/result.dart';
import '../domain/models/device_config.dart';
import '../domain/models/display_choice.dart';
import '../domain/repositories/settings_repository.dart';
import 'mock_backend.dart';
import 'mock_latency.dart';
import 'mock_seed.dart';

/// In-memory [SettingsRepository] over [MockBackend].
///
/// The one repository that is never replaced by HTTP — preferences are
/// device-local by definition. Swapping the backing map for
/// `shared_preferences` is the whole of the real implementation.
class MockSettingsRepository implements SettingsRepository {
  const MockSettingsRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<Result<ThemeChoice>> themeChoice() async {
    await mockLatency();
    return Success<ThemeChoice>(_backend.themeChoice);
  }

  @override
  Future<Result<void>> setThemeChoice(ThemeChoice choice) async {
    // No latency: a theme switch must repaint immediately, not after a beat.
    _backend.setThemeChoice(choice);
    return const Success<void>(null);
  }

  @override
  Future<Result<TextScaleChoice>> textScale() async {
    await mockLatency();
    return Success<TextScaleChoice>(_backend.textScale);
  }

  @override
  Future<Result<void>> setTextScale(TextScaleChoice choice) async {
    _backend.setTextScale(choice);
    return const Success<void>(null);
  }

  @override
  Future<Result<DeviceConfig>> deviceConfig() async {
    await mockLatency();
    return const Success<DeviceConfig>(
      DeviceConfig(
        serial: MockSeed.deviceSerial,
        appVersion: MockSeed.appVersion,
        scannerInput: MockSeed.scannerInput,
        symbologies: MockSeed.symbologies,
        passFeedback: MockSeed.passFeedback,
        failFeedback: MockSeed.failFeedback,
        languages: MockSeed.languages,
        idleLockSeconds: MockSeed.idleLockSeconds,
      ),
    );
  }
}
