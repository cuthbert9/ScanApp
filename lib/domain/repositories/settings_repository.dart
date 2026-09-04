import '../../core/result/result.dart';
import '../models/device_config.dart';
import '../models/display_choice.dart';

/// Device preferences that survive a restart.
///
/// SWAP POINT — the only repository that is *not* replaced by HTTP. These are
/// device-local by definition; the real implementation swaps the in-memory map
/// for `shared_preferences` and nothing else changes.
abstract interface class SettingsRepository {
  Future<Result<ThemeChoice>> themeChoice();
  Future<Result<void>> setThemeChoice(ThemeChoice choice);

  Future<Result<TextScaleChoice>> textScale();
  Future<Result<void>> setTextScale(TextScaleChoice choice);

  /// The device's own configuration — serial, build, scanner profile, session
  /// policy. Read-only, and managed rather than chosen.
  Future<Result<DeviceConfig>> deviceConfig();
}
