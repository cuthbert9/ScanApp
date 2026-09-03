import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../extensions/app_colors.dart';
import '../extensions/app_motion.dart';
import '../extensions/app_radii.dart';
import '../extensions/app_sizes.dart';
import '../extensions/app_spacing.dart';
import '../extensions/app_typography.dart';
import '../tokens/primitive_tokens.dart';

/// COMPONENT THEME — Layer 3.
///
/// Wires the semantic tokens into Flutter's [ThemeData] so that *unstyled*
/// Material widgets already look correct. Anything not explicitly styled still
/// lands on-brand, which is what keeps a growing app consistent — and it is why
/// screens should never restate styling at the call site (CLAUDE.md rule 1b).
///
/// Nothing here invents a value: every number and colour comes from Layer 1/2.
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  /// System status/navigation bar styling.
  ///
  /// The app's header is dark in both themes, so the status bar always carries
  /// light icons.
  static SystemUiOverlayStyle overlayStyle(AppColors c, Brightness brightness) {
    return SystemUiOverlayStyle(
      statusBarColor: PrimitiveColors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: c.surface,
      systemNavigationBarIconBrightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  static ThemeData _build(AppColors c, Brightness brightness) {
    const AppSpacing spacing = AppSpacing.standard;
    const AppRadii radii = AppRadii.standard;
    const AppSizes sizes = AppSizes.standard;
    const AppTypography type = AppTypography.standard;
    const AppMotion motion = AppMotion.standard;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySubtle,
      onPrimaryContainer: c.onPrimarySubtle,
      secondary: c.coldChain,
      onSecondary: c.onColdChainSurface,
      secondaryContainer: c.coldChainSurface,
      onSecondaryContainer: c.onColdChainSurface,
      tertiary: c.statusActive,
      onTertiary: c.onStatusActiveSurface,
      tertiaryContainer: c.statusActiveSurface,
      onTertiaryContainer: c.onStatusActiveSurface,
      error: c.danger,
      onError: c.onDanger,
      errorContainer: c.dangerSurface,
      onErrorContainer: c.onDangerSurface,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.surfaceSunken,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.border,
      inverseSurface: c.surfaceInverse,
      onInverseSurface: c.textInverse,
      scrim: c.scrim,
      shadow: PrimitiveColors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      splashFactory: InkSparkle.splashFactory,

      // Every token bundle is attached here — this is what `context.colors`
      // and friends read.
      extensions: <ThemeExtension<dynamic>>[
        c,
        spacing,
        radii,
        sizes,
        type,
        motion,
      ],

      textTheme: _textTheme(type, c),

      appBarTheme: AppBarTheme(
        backgroundColor: c.headerSurface,
        foregroundColor: c.onHeader,
        surfaceTintColor: PrimitiveColors.transparent,
        elevation: PrimitiveElevation.level0,
        scrolledUnderElevation: PrimitiveElevation.level0,
        centerTitle: false,
        titleTextStyle: type.headingMd.copyWith(color: c.onHeader),
        systemOverlayStyle: overlayStyle(c, brightness),
      ),

      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: sizes.borderHairline,
        space: sizes.borderHairline,
      ),

      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: PrimitiveColors.transparent,
        elevation: PrimitiveElevation.level0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radii.cardBorder,
          side: BorderSide(color: c.border, width: sizes.borderHairline),
        ),
      ),

      // 56 dp minimum height: primary actions are tapped with gloves.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.disabledSurface,
          disabledForegroundColor: c.disabledContent,
          minimumSize: Size.fromHeight(sizes.tapTargetComfortable),
          padding: EdgeInsets.symmetric(horizontal: spacing.lg),
          textStyle: type.labelLg,
          shape: RoundedRectangleBorder(borderRadius: radii.controlBorder),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          disabledForegroundColor: c.disabledContent,
          minimumSize: Size.fromHeight(sizes.tapTargetComfortable),
          padding: EdgeInsets.symmetric(horizontal: spacing.lg),
          textStyle: type.labelLg,
          side: BorderSide(color: c.border, width: sizes.borderThin),
          shape: RoundedRectangleBorder(borderRadius: radii.controlBorder),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          disabledForegroundColor: c.disabledContent,
          minimumSize: Size(0, sizes.tapTargetMin),
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
          textStyle: type.labelMd,
          shape: RoundedRectangleBorder(borderRadius: radii.controlBorder),
        ),
      ),

      iconTheme: IconThemeData(color: c.textSecondary, size: sizes.iconLg),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textSecondary,
          minimumSize: Size.square(sizes.tapTargetMin),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceSunken,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.md,
        ),
        hintStyle: type.bodyMd.copyWith(color: c.textTertiary),
        labelStyle: type.labelMd.copyWith(color: c.textSecondary),
        errorStyle: type.caption.copyWith(color: c.danger),
        border: OutlineInputBorder(
          borderRadius: radii.controlBorder,
          borderSide: BorderSide(color: c.border, width: sizes.borderHairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radii.controlBorder,
          borderSide: BorderSide(color: c.border, width: sizes.borderHairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radii.controlBorder,
          borderSide: BorderSide(
            color: c.borderFocus,
            width: sizes.borderFocus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radii.controlBorder,
          borderSide: BorderSide(color: c.danger, width: sizes.borderThin),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radii.controlBorder,
          borderSide: BorderSide(color: c.danger, width: sizes.borderFocus),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radii.controlBorder,
          borderSide: BorderSide(color: c.border, width: sizes.borderHairline),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceInverse,
        contentTextStyle: type.bodyMd.copyWith(color: c.textInverse),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radii.controlBorder),
        insetPadding: EdgeInsets.all(spacing.md),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: PrimitiveColors.transparent,
        elevation: PrimitiveElevation.level3,
        shape: RoundedRectangleBorder(borderRadius: radii.sheetBorder),
        titleTextStyle: type.headingSm.copyWith(color: c.textPrimary),
        contentTextStyle: type.bodyMd.copyWith(color: c.textSecondary),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: PrimitiveColors.transparent,
        elevation: PrimitiveElevation.level3,
        shape: RoundedRectangleBorder(borderRadius: radii.sheetBorder),
        showDragHandle: true,
        dragHandleColor: c.border,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.progressFill,
        linearTrackColor: c.progressTrack,
        circularTrackColor: c.progressTrack,
        linearMinHeight: sizes.progressBarHeight,
      ),

      listTileTheme: ListTileThemeData(
        minVerticalPadding: spacing.sm,
        contentPadding: EdgeInsets.symmetric(horizontal: spacing.md),
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        titleTextStyle: type.bodyMd.copyWith(color: c.textPrimary),
        subtitleTextStyle: type.bodySm.copyWith(color: c.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: radii.cardBorder),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.surfaceInverse,
          borderRadius: radii.controlBorder,
        ),
        textStyle: type.caption.copyWith(color: c.textInverse),
      ),

      // One transition everywhere. The app ships on Android handhelds; matching
      // that on desktop keeps UI development honest about how it will feel.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  /// Maps our semantic styles onto Material's slots, so third-party and
  /// unstyled widgets inherit the same type system.
  static TextTheme _textTheme(AppTypography t, AppColors c) {
    TextStyle p(TextStyle s) => s.copyWith(color: c.textPrimary);
    TextStyle q(TextStyle s) => s.copyWith(color: c.textSecondary);
    return TextTheme(
      displayLarge: p(t.displayLg),
      displayMedium: p(t.headingLg),
      displaySmall: p(t.headingMd),
      headlineLarge: p(t.headingLg),
      headlineMedium: p(t.headingMd),
      headlineSmall: p(t.headingSm),
      titleLarge: p(t.headingMd),
      titleMedium: p(t.headingSm),
      titleSmall: p(t.labelLg),
      bodyLarge: p(t.bodyLg),
      bodyMedium: p(t.bodyMd),
      bodySmall: q(t.bodySm),
      labelLarge: p(t.labelLg),
      labelMedium: q(t.labelMd),
      labelSmall: q(t.labelSm),
    );
  }
}
