import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'display_preferences.dart';

part 'preferences_controller.g.dart';

/// The operator's theme choice.
///
/// `keepAlive` and read by `app.dart`: this drives `MaterialApp.themeMode`, so
/// it must outlive the settings screen being popped.
///
/// Nothing is persisted yet — the choice resets on restart. A local store is
/// the next step, and only this controller changes when it lands.
@Riverpod(keepAlive: true)
class ThemePreference extends _$ThemePreference {
  @override
  AppThemeChoice build() => AppThemeChoice.auto;

  void select(AppThemeChoice choice) => state = choice;
}

/// The operator's text-size choice, applied app-wide at the root.
@Riverpod(keepAlive: true)
class TextScalePreference extends _$TextScalePreference {
  @override
  AppTextScaleChoice build() => AppTextScaleChoice.standard;

  void select(AppTextScaleChoice choice) => state = choice;
}
