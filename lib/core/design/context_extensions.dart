import 'package:flutter/material.dart';

import 'extensions/app_colors.dart';
import 'extensions/app_motion.dart';
import 'extensions/app_radii.dart';
import 'extensions/app_sizes.dart';
import 'extensions/app_spacing.dart';
import 'extensions/app_typography.dart';

/// The app's single entry point to design tokens.
///
/// ```dart
/// Container(
///   padding: EdgeInsets.all(context.spacing.md),
///   decoration: BoxDecoration(
///     color: context.colors.surface,
///     borderRadius: context.radii.cardBorder,
///   ),
///   child: Text('Ready', style: context.type.headingSm),
/// )
/// ```
///
/// Everything resolves from [Theme], so a token change re-themes every screen
/// at once and light/dark stays automatic.
extension AppThemeContext on BuildContext {
  ThemeData get _theme => Theme.of(this);

  /// Semantic colours. See [AppColors].
  AppColors get colors => _resolve<AppColors>(AppColors.light);

  /// Spacing scale. See [AppSpacing].
  AppSpacing get spacing => _resolve<AppSpacing>(AppSpacing.standard);

  /// Corner radii. See [AppRadii].
  AppRadii get radii => _resolve<AppRadii>(AppRadii.standard);

  /// Touch targets, icon and control sizes. See [AppSizes].
  AppSizes get sizes => _resolve<AppSizes>(AppSizes.standard);

  /// Text styles. See [AppTypography].
  AppTypography get type => _resolve<AppTypography>(AppTypography.standard);

  /// Durations and curves. See [AppMotion].
  AppMotion get motion => _resolve<AppMotion>(AppMotion.standard);

  /// Resolves a theme extension: asserts loudly in debug if the app was built
  /// without [AppTheme], but degrades to a sane default in release rather than
  /// crashing an operator mid-shift.
  T _resolve<T extends ThemeExtension<T>>(T fallback) {
    final T? value = _theme.extension<T>();
    assert(
      value != null,
      'Missing ThemeExtension<$T>. Build the app with AppTheme.light / '
      'AppTheme.dark — see lib/core/design/theme/app_theme.dart.',
    );
    return value ?? fallback;
  }

  // --- Layout helpers -------------------------------------------------------

  bool get isDarkMode => _theme.brightness == Brightness.dark;

  /// True on the MC9450's ~320 dp canvas and anything narrower.
  ///
  /// Use it to DROP optional chrome, never to fork a layout — two layouts
  /// behind a size check is two layouts to maintain, and one is always stale.
  bool get isCompactWidth => MediaQuery.sizeOf(this).width < 360;

  /// True when rotation or the keyboard has left little vertical room.
  bool get isCompactHeight => MediaQuery.sizeOf(this).height < 420;

  /// True while the on-screen keyboard is up.
  bool get isKeyboardVisible => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// Height genuinely available to content, once the keyboard has taken its
  /// share.
  double get usableHeight =>
      MediaQuery.sizeOf(this).height - MediaQuery.viewInsetsOf(this).bottom;

  /// True when there is barely room for anything beyond the essential control —
  /// landscape with the keyboard up leaves roughly 140 dp.
  ///
  /// Screens use this to shed the *last* of their optional chrome. It is still
  /// dropping chrome, not forking a layout: the same widget tree renders, with
  /// fewer optional parts in it.
  bool get isSeverelyConstrainedHeight => usableHeight < 260;
}
