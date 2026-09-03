import 'package:flutter/material.dart';

import '../tokens/primitive_tokens.dart';

/// SEMANTIC COLOUR TOKENS — Layer 2.
///
/// Every colour the UI may use, named by *role* rather than by hue. Read them
/// via `context.colors.<role>`; never reach for [PrimitiveColors] or Flutter's
/// `Colors.*` from a screen or widget.
///
/// Because the names describe intent, re-theming the app — or adding a
/// high-contrast sunlight mode for outdoor picking — is a change to this file
/// alone, and no screen has to be touched.
///
/// This class is generated in shape but hand-authored in content: constructor,
/// [light], [dark], [copyWith] and [lerp] all list the same fields, and adding
/// one means touching all five.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceInverse,
    required this.headerSurface,
    required this.headerSurfaceRaised,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.headerDivider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.textDisabled,
    required this.dataStrong,
    required this.dataMuted,
    required this.border,
    required this.borderStrong,
    required this.borderFocus,
    required this.borderSelected,
    required this.primary,
    required this.onPrimary,
    required this.primaryPressed,
    required this.primarySubtle,
    required this.onPrimarySubtle,
    required this.statusActive,
    required this.statusActiveSurface,
    required this.onStatusActiveSurface,
    required this.statusPendingSurface,
    required this.onStatusPendingSurface,
    required this.statusBlockedSurface,
    required this.onStatusBlockedSurface,
    required this.coldChain,
    required this.coldChainSurface,
    required this.onColdChainSurface,
    required this.success,
    required this.onSuccess,
    required this.successSurface,
    required this.onSuccessSurface,
    required this.danger,
    required this.onDanger,
    required this.dangerSurface,
    required this.onDangerSurface,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.badgeSurface,
    required this.onBadgeSurface,
    required this.progressTrack,
    required this.progressFill,
    required this.chartBar,
    required this.chartBarEmphasis,
    required this.disabledSurface,
    required this.disabledContent,
    required this.scrim,
    required this.hoverOverlay,
    required this.pressedOverlay,
  });

  // --- SURFACES ------------------------------------------------------------
  /// The page behind everything.
  final Color background;

  /// Default container sitting on [background] — cards, sheets.
  final Color surface;

  /// Reads as *above* [surface] — menus, dialogs.
  final Color surfaceRaised;

  /// A recessed well — input fills, list backgrounds.
  final Color surfaceSunken;

  /// Inverted container, for tooltips and snackbars.
  final Color surfaceInverse;

  // --- HEADER --------------------------------------------------------------
  /// The navy band at the top of a screen.
  final Color headerSurface;

  /// A panel resting on [headerSurface] — the summary strip.
  final Color headerSurfaceRaised;

  /// Primary content on [headerSurface].
  final Color onHeader;

  /// Secondary content on [headerSurface] — the trip reference line.
  final Color onHeaderMuted;

  /// Hairline separating cells inside a panel on [headerSurface].
  final Color headerDivider;

  // --- CONTENT -------------------------------------------------------------
  /// Body copy and headings. Meets AA on [surface].
  final Color textPrimary;

  /// Supporting copy, labels, metadata.
  final Color textSecondary;

  /// De-emphasised hints. First thing to vanish in direct sun — use sparingly.
  final Color textTertiary;

  /// Content on [surfaceInverse].
  final Color textInverse;

  /// Content in a disabled control.
  final Color textDisabled;

  // --- MACHINE-READABLE DATA -----------------------------------------------
  /// The identifying value in a monospace run — the DO number.
  final Color dataStrong;

  /// Supporting values in a monospace run — truck, route, units, tonnage.
  final Color dataMuted;

  // --- LINES ---------------------------------------------------------------
  /// Hairline dividers and default control outlines.
  final Color border;

  /// Emphasised outline — hovered inputs.
  final Color borderStrong;

  /// The focus ring. Must stay distinct from [primary]: hardware-key
  /// navigation on the MC9450 depends on it being obvious at a glance.
  final Color borderFocus;

  /// Outline of the currently selected row.
  final Color borderSelected;

  // --- BRAND ---------------------------------------------------------------
  /// Primary action — the navy CTA.
  final Color primary;

  /// Content on [primary].
  final Color onPrimary;

  /// [primary] while held.
  final Color primaryPressed;

  /// Tinted background for primary-flavoured chips.
  final Color primarySubtle;

  /// Content on [primarySubtle].
  final Color onPrimarySubtle;

  // --- ORDER STATUS --------------------------------------------------------
  /// Work in progress — the gold accent on a loading order.
  final Color statusActive;

  /// Badge background for an in-progress order.
  final Color statusActiveSurface;

  /// Badge text on [statusActiveSurface].
  final Color onStatusActiveSurface;

  /// Badge background for a queued order.
  final Color statusPendingSurface;

  /// Badge text on [statusPendingSurface].
  final Color onStatusPendingSurface;

  /// Badge background for an order that cannot proceed.
  final Color statusBlockedSurface;

  /// Badge text on [statusBlockedSurface].
  final Color onStatusBlockedSurface;

  // --- COLD CHAIN ----------------------------------------------------------
  /// Temperature-controlled consignment marker.
  final Color coldChain;

  /// Tinted background for cold-chain emphasis.
  final Color coldChainSurface;

  /// Content on [coldChainSurface].
  final Color onColdChainSurface;

  // --- SEMANTIC STATE ------------------------------------------------------
  /// Accepted scan, saved record, completed task.
  final Color success;

  /// Content on [success].
  final Color onSuccess;

  /// Tinted success background.
  final Color successSurface;

  /// Content on [successSurface].
  final Color onSuccessSurface;

  /// Rejected scan, failed sync, destructive action.
  final Color danger;

  /// Content on [danger].
  final Color onDanger;

  /// Tinted danger background.
  final Color dangerSurface;

  /// Content on [dangerSurface].
  final Color onDangerSurface;

  /// Needs attention but is not fatal.
  final Color warning;

  /// Content on [warning].
  final Color onWarning;

  /// Neutral emphasis — hints, counts, offline notices.
  final Color info;

  // --- NOTIFICATION --------------------------------------------------------
  /// Count badge — pending sync items, unread work.
  final Color badgeSurface;

  /// The numeral on [badgeSurface].
  final Color onBadgeSurface;

  // --- PROGRESS ------------------------------------------------------------
  /// Unfilled portion of a progress indicator.
  final Color progressTrack;

  /// Filled portion of a progress indicator.
  final Color progressFill;

  /// Default bar in a chart.
  ///
  /// Validated with the dataviz palette checker as a one-hue ordinal ramp
  /// against each theme's card surface. The dark steps are chosen, not
  /// flipped: on a dark card the *lighter* step is the prominent one.
  final Color chartBar;

  /// The emphasised bar — today, or the selected period.
  final Color chartBarEmphasis;

  // --- INTERACTION ---------------------------------------------------------
  /// Background of a disabled control.
  final Color disabledSurface;

  /// Foreground of a disabled control.
  final Color disabledContent;

  /// Behind modals and bottom sheets.
  final Color scrim;

  /// Applied over a surface on hover.
  final Color hoverOverlay;

  /// Applied over a surface while pressed.
  final Color pressedOverlay;

  /// Daylight-first palette. The default: the device is used outdoors, where a
  /// light UI stays readable against a bright ambient background.
  static const AppColors light = AppColors(
    background: PrimitiveColors.neutral100,
    surface: PrimitiveColors.neutral0,
    surfaceRaised: PrimitiveColors.neutral0,
    surfaceSunken: PrimitiveColors.neutral50,
    surfaceInverse: PrimitiveColors.neutral800,
    headerSurface: PrimitiveColors.navy800,
    headerSurfaceRaised: PrimitiveColors.navy600,
    onHeader: PrimitiveColors.neutral0,
    onHeaderMuted: PrimitiveColors.navy200,
    headerDivider: PrimitiveColors.navy500,
    textPrimary: PrimitiveColors.neutral900,
    textSecondary: PrimitiveColors.neutral600,
    textTertiary: PrimitiveColors.neutral500,
    textInverse: PrimitiveColors.neutral0,
    textDisabled: PrimitiveColors.neutral400,
    dataStrong: PrimitiveColors.neutral900,
    dataMuted: PrimitiveColors.neutral500,
    border: PrimitiveColors.neutral200,
    borderStrong: PrimitiveColors.neutral300,
    borderFocus: PrimitiveColors.navy400,
    borderSelected: PrimitiveColors.gold400,
    primary: PrimitiveColors.navy800,
    onPrimary: PrimitiveColors.neutral0,
    primaryPressed: PrimitiveColors.navy900,
    primarySubtle: PrimitiveColors.navy50,
    onPrimarySubtle: PrimitiveColors.navy700,
    statusActive: PrimitiveColors.gold400,
    statusActiveSurface: PrimitiveColors.gold100,
    onStatusActiveSurface: PrimitiveColors.gold700,
    statusPendingSurface: PrimitiveColors.neutral150,
    onStatusPendingSurface: PrimitiveColors.neutral600,
    statusBlockedSurface: PrimitiveColors.tan100,
    onStatusBlockedSurface: PrimitiveColors.tan700,
    coldChain: PrimitiveColors.teal400,
    coldChainSurface: PrimitiveColors.teal50,
    onColdChainSurface: PrimitiveColors.teal700,
    success: PrimitiveColors.green500,
    onSuccess: PrimitiveColors.neutral0,
    successSurface: PrimitiveColors.green50,
    onSuccessSurface: PrimitiveColors.green700,
    danger: PrimitiveColors.red500,
    onDanger: PrimitiveColors.neutral0,
    dangerSurface: PrimitiveColors.red50,
    onDangerSurface: PrimitiveColors.red700,
    warning: PrimitiveColors.tan400,
    onWarning: PrimitiveColors.neutral900,
    info: PrimitiveColors.teal500,
    badgeSurface: PrimitiveColors.tan400,
    onBadgeSurface: PrimitiveColors.neutral0,
    progressTrack: PrimitiveColors.neutral150,
    progressFill: PrimitiveColors.gold400,
    chartBar: PrimitiveColors.gold400,
    chartBarEmphasis: PrimitiveColors.gold600,
    disabledSurface: PrimitiveColors.neutral100,
    disabledContent: PrimitiveColors.neutral400,
    scrim: PrimitiveColors.scrimLight,
    hoverOverlay: PrimitiveColors.overlayHoverLight,
    pressedOverlay: PrimitiveColors.overlayPressedLight,
  );

  /// Night / dim-aisle palette. Surfaces sit near black to cut glare on a night
  /// shift without losing status legibility.
  static const AppColors dark = AppColors(
    background: PrimitiveColors.neutral950,
    surface: PrimitiveColors.neutral900,
    surfaceRaised: PrimitiveColors.neutral800,
    surfaceSunken: PrimitiveColors.neutral950,
    surfaceInverse: PrimitiveColors.neutral100,
    headerSurface: PrimitiveColors.navy900,
    headerSurfaceRaised: PrimitiveColors.navy800,
    onHeader: PrimitiveColors.neutral0,
    onHeaderMuted: PrimitiveColors.navy200,
    headerDivider: PrimitiveColors.navy700,
    textPrimary: PrimitiveColors.neutral50,
    textSecondary: PrimitiveColors.neutral300,
    textTertiary: PrimitiveColors.neutral400,
    textInverse: PrimitiveColors.neutral900,
    textDisabled: PrimitiveColors.neutral600,
    dataStrong: PrimitiveColors.neutral50,
    dataMuted: PrimitiveColors.neutral400,
    border: PrimitiveColors.neutral700,
    borderStrong: PrimitiveColors.neutral600,
    borderFocus: PrimitiveColors.navy300,
    borderSelected: PrimitiveColors.gold300,
    primary: PrimitiveColors.navy300,
    onPrimary: PrimitiveColors.navy900,
    primaryPressed: PrimitiveColors.navy200,
    primarySubtle: PrimitiveColors.navy800,
    onPrimarySubtle: PrimitiveColors.navy100,
    statusActive: PrimitiveColors.gold300,
    statusActiveSurface: PrimitiveColors.gold800,
    onStatusActiveSurface: PrimitiveColors.gold100,
    statusPendingSurface: PrimitiveColors.neutral800,
    onStatusPendingSurface: PrimitiveColors.neutral300,
    statusBlockedSurface: PrimitiveColors.tan800,
    onStatusBlockedSurface: PrimitiveColors.tan100,
    coldChain: PrimitiveColors.teal300,
    coldChainSurface: PrimitiveColors.teal800,
    onColdChainSurface: PrimitiveColors.teal100,
    success: PrimitiveColors.green300,
    onSuccess: PrimitiveColors.neutral950,
    successSurface: PrimitiveColors.green900,
    onSuccessSurface: PrimitiveColors.green100,
    danger: PrimitiveColors.red300,
    onDanger: PrimitiveColors.neutral950,
    dangerSurface: PrimitiveColors.red900,
    onDangerSurface: PrimitiveColors.red100,
    warning: PrimitiveColors.tan300,
    onWarning: PrimitiveColors.neutral950,
    info: PrimitiveColors.teal300,
    badgeSurface: PrimitiveColors.tan300,
    onBadgeSurface: PrimitiveColors.neutral950,
    progressTrack: PrimitiveColors.neutral800,
    progressFill: PrimitiveColors.gold300,
    chartBar: PrimitiveColors.gold500,
    chartBarEmphasis: PrimitiveColors.gold300,
    disabledSurface: PrimitiveColors.neutral800,
    disabledContent: PrimitiveColors.neutral600,
    scrim: PrimitiveColors.scrimDark,
    hoverOverlay: PrimitiveColors.overlayHoverDark,
    pressedOverlay: PrimitiveColors.overlayPressedDark,
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? surfaceInverse,
    Color? headerSurface,
    Color? headerSurfaceRaised,
    Color? onHeader,
    Color? onHeaderMuted,
    Color? headerDivider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? textDisabled,
    Color? dataStrong,
    Color? dataMuted,
    Color? border,
    Color? borderStrong,
    Color? borderFocus,
    Color? borderSelected,
    Color? primary,
    Color? onPrimary,
    Color? primaryPressed,
    Color? primarySubtle,
    Color? onPrimarySubtle,
    Color? statusActive,
    Color? statusActiveSurface,
    Color? onStatusActiveSurface,
    Color? statusPendingSurface,
    Color? onStatusPendingSurface,
    Color? statusBlockedSurface,
    Color? onStatusBlockedSurface,
    Color? coldChain,
    Color? coldChainSurface,
    Color? onColdChainSurface,
    Color? success,
    Color? onSuccess,
    Color? successSurface,
    Color? onSuccessSurface,
    Color? danger,
    Color? onDanger,
    Color? dangerSurface,
    Color? onDangerSurface,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? badgeSurface,
    Color? onBadgeSurface,
    Color? progressTrack,
    Color? progressFill,
    Color? chartBar,
    Color? chartBarEmphasis,
    Color? disabledSurface,
    Color? disabledContent,
    Color? scrim,
    Color? hoverOverlay,
    Color? pressedOverlay,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      headerSurface: headerSurface ?? this.headerSurface,
      headerSurfaceRaised: headerSurfaceRaised ?? this.headerSurfaceRaised,
      onHeader: onHeader ?? this.onHeader,
      onHeaderMuted: onHeaderMuted ?? this.onHeaderMuted,
      headerDivider: headerDivider ?? this.headerDivider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      textDisabled: textDisabled ?? this.textDisabled,
      dataStrong: dataStrong ?? this.dataStrong,
      dataMuted: dataMuted ?? this.dataMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      borderSelected: borderSelected ?? this.borderSelected,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primarySubtle: primarySubtle ?? this.primarySubtle,
      onPrimarySubtle: onPrimarySubtle ?? this.onPrimarySubtle,
      statusActive: statusActive ?? this.statusActive,
      statusActiveSurface: statusActiveSurface ?? this.statusActiveSurface,
      onStatusActiveSurface:
          onStatusActiveSurface ?? this.onStatusActiveSurface,
      statusPendingSurface: statusPendingSurface ?? this.statusPendingSurface,
      onStatusPendingSurface:
          onStatusPendingSurface ?? this.onStatusPendingSurface,
      statusBlockedSurface: statusBlockedSurface ?? this.statusBlockedSurface,
      onStatusBlockedSurface:
          onStatusBlockedSurface ?? this.onStatusBlockedSurface,
      coldChain: coldChain ?? this.coldChain,
      coldChainSurface: coldChainSurface ?? this.coldChainSurface,
      onColdChainSurface: onColdChainSurface ?? this.onColdChainSurface,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successSurface: successSurface ?? this.successSurface,
      onSuccessSurface: onSuccessSurface ?? this.onSuccessSurface,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      onDangerSurface: onDangerSurface ?? this.onDangerSurface,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      badgeSurface: badgeSurface ?? this.badgeSurface,
      onBadgeSurface: onBadgeSurface ?? this.onBadgeSurface,
      progressTrack: progressTrack ?? this.progressTrack,
      progressFill: progressFill ?? this.progressFill,
      chartBar: chartBar ?? this.chartBar,
      chartBarEmphasis: chartBarEmphasis ?? this.chartBarEmphasis,
      disabledSurface: disabledSurface ?? this.disabledSurface,
      disabledContent: disabledContent ?? this.disabledContent,
      scrim: scrim ?? this.scrim,
      hoverOverlay: hoverOverlay ?? this.hoverOverlay,
      pressedOverlay: pressedOverlay ?? this.pressedOverlay,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      surfaceInverse: c(surfaceInverse, other.surfaceInverse),
      headerSurface: c(headerSurface, other.headerSurface),
      headerSurfaceRaised: c(headerSurfaceRaised, other.headerSurfaceRaised),
      onHeader: c(onHeader, other.onHeader),
      onHeaderMuted: c(onHeaderMuted, other.onHeaderMuted),
      headerDivider: c(headerDivider, other.headerDivider),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      textInverse: c(textInverse, other.textInverse),
      textDisabled: c(textDisabled, other.textDisabled),
      dataStrong: c(dataStrong, other.dataStrong),
      dataMuted: c(dataMuted, other.dataMuted),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      borderFocus: c(borderFocus, other.borderFocus),
      borderSelected: c(borderSelected, other.borderSelected),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryPressed: c(primaryPressed, other.primaryPressed),
      primarySubtle: c(primarySubtle, other.primarySubtle),
      onPrimarySubtle: c(onPrimarySubtle, other.onPrimarySubtle),
      statusActive: c(statusActive, other.statusActive),
      statusActiveSurface: c(statusActiveSurface, other.statusActiveSurface),
      onStatusActiveSurface: c(
        onStatusActiveSurface,
        other.onStatusActiveSurface,
      ),
      statusPendingSurface: c(statusPendingSurface, other.statusPendingSurface),
      onStatusPendingSurface: c(
        onStatusPendingSurface,
        other.onStatusPendingSurface,
      ),
      statusBlockedSurface: c(statusBlockedSurface, other.statusBlockedSurface),
      onStatusBlockedSurface: c(
        onStatusBlockedSurface,
        other.onStatusBlockedSurface,
      ),
      coldChain: c(coldChain, other.coldChain),
      coldChainSurface: c(coldChainSurface, other.coldChainSurface),
      onColdChainSurface: c(onColdChainSurface, other.onColdChainSurface),
      success: c(success, other.success),
      onSuccess: c(onSuccess, other.onSuccess),
      successSurface: c(successSurface, other.successSurface),
      onSuccessSurface: c(onSuccessSurface, other.onSuccessSurface),
      danger: c(danger, other.danger),
      onDanger: c(onDanger, other.onDanger),
      dangerSurface: c(dangerSurface, other.dangerSurface),
      onDangerSurface: c(onDangerSurface, other.onDangerSurface),
      warning: c(warning, other.warning),
      onWarning: c(onWarning, other.onWarning),
      info: c(info, other.info),
      badgeSurface: c(badgeSurface, other.badgeSurface),
      onBadgeSurface: c(onBadgeSurface, other.onBadgeSurface),
      progressTrack: c(progressTrack, other.progressTrack),
      progressFill: c(progressFill, other.progressFill),
      chartBar: c(chartBar, other.chartBar),
      chartBarEmphasis: c(chartBarEmphasis, other.chartBarEmphasis),
      disabledSurface: c(disabledSurface, other.disabledSurface),
      disabledContent: c(disabledContent, other.disabledContent),
      scrim: c(scrim, other.scrim),
      hoverOverlay: c(hoverOverlay, other.hoverOverlay),
      pressedOverlay: c(pressedOverlay, other.pressedOverlay),
    );
  }
}
