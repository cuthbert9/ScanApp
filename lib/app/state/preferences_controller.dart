import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repository_providers.dart';
import '../../domain/models/display_choice.dart';
import '../../domain/repositories/settings_repository.dart';

part 'preferences_controller.g.dart';

/// The operator's theme choice.
///
/// `keepAlive` and read by `app.dart`, so it drives `MaterialApp.themeMode` and
/// must outlive the Settings screen being popped. Selection is applied
/// optimistically: the whole app repaints on the tap, not after a round trip.
@Riverpod(keepAlive: true)
class ThemePreference extends _$ThemePreference {
  @override
  Future<ThemeChoice> build() async {
    final SettingsRepository repo = ref.read(settingsRepositoryProvider);
    return (await repo.themeChoice()).valueOrNull ?? ThemeChoice.auto;
  }

  Future<void> select(ThemeChoice choice) async {
    state = AsyncData<ThemeChoice>(choice);
    await ref.read(settingsRepositoryProvider).setThemeChoice(choice);
  }
}

/// The operator's text-size choice, applied app-wide at the root.
@Riverpod(keepAlive: true)
class TextScalePreference extends _$TextScalePreference {
  @override
  Future<TextScaleChoice> build() async {
    final SettingsRepository repo = ref.read(settingsRepositoryProvider);
    return (await repo.textScale()).valueOrNull ?? TextScaleChoice.standard;
  }

  Future<void> select(TextScaleChoice choice) async {
    state = AsyncData<TextScaleChoice>(choice);
    await ref.read(settingsRepositoryProvider).setTextScale(choice);
  }
}

/// The resolved theme choice, defaulting while the stored one loads so the
/// first frame is not blank.
@riverpod
ThemeChoice resolvedThemeChoice(Ref ref) =>
    ref.watch(themePreferenceProvider).value ?? ThemeChoice.auto;

@riverpod
TextScaleChoice resolvedTextScale(Ref ref) =>
    ref.watch(textScalePreferenceProvider).value ?? TextScaleChoice.standard;
