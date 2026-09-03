import 'package:flutter/material.dart';

/// The operator's theme preference.
///
/// Lives in `application/` rather than `domain/` because it maps directly onto
/// Flutter's [ThemeMode]; domain stays free of Flutter.
enum AppThemeChoice {
  /// Force the daylight palette — the right call under a bright dock roof even
  /// after sunset.
  day('Day', ThemeMode.light),

  /// Force the dim-aisle palette.
  night('Night', ThemeMode.dark),

  /// Follow the device, which follows sunset and the ambient sensor.
  auto('Auto', ThemeMode.system);

  const AppThemeChoice(this.label, this.themeMode);

  final String label;
  final ThemeMode themeMode;
}

/// How large interface text should be.
///
/// `Gloved` is not an accessibility afterthought here: it is the setting an
/// operator picks when they are wearing cold-store gloves and safety glasses,
/// and it is expected to be the common choice on the floor.
enum AppTextScaleChoice {
  standard('Standard', 1.0),
  gloved('Gloved', 1.15);

  const AppTextScaleChoice(this.label, this.scale);

  final String label;
  final double scale;
}
