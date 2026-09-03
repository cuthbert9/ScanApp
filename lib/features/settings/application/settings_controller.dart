import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/result/result.dart';
import '../data/fake_settings_repository.dart';
import '../domain/settings_repository.dart';
import '../domain/settings_snapshot.dart';

part 'settings_controller.g.dart';

/// Which [SettingsRepository] the app runs against.
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  return const FakeSettingsRepository();
}

/// Loads the operator, their shift figures, the station and device config.
@riverpod
class SettingsController extends _$SettingsController {
  @override
  Future<SettingsSnapshot> build() => _load();

  Future<SettingsSnapshot> _load() async {
    final SettingsRepository repository = ref.watch(settingsRepositoryProvider);
    final Result<SettingsSnapshot> result = await repository.load();
    return switch (result) {
      Success<SettingsSnapshot>(:final SettingsSnapshot value) => value,
      Failure<SettingsSnapshot>(:final AppException error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}
