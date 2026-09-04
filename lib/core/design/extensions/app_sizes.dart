import 'package:flutter/material.dart';

import '../tokens/primitive_tokens.dart';
import 'app_spacing.dart' show lerpToken;

/// SEMANTIC SIZES — Layer 2.
///
/// Touch targets, icon sizes, control heights and border widths.
///
/// [tapTargetComfortable] (56) is the default for anything an operator taps in
/// a hurry: the MC9450 is used with gloves, often one-handed. [tapTargetMin]
/// (48) is the absolute floor, for secondary controls only.
@immutable
class AppSizes extends ThemeExtension<AppSizes> {
  const AppSizes({
    required this.tapTargetMin,
    required this.tapTargetComfortable,
    required this.iconXs,
    required this.iconSm,
    required this.iconMd,
    required this.iconLg,
    required this.iconXl,
    required this.controlSm,
    required this.controlMd,
    required this.controlLg,
    required this.borderHairline,
    required this.borderThin,
    required this.borderThick,
    required this.borderFocus,
    required this.tabBarHeight,
    required this.progressBarHeight,
    required this.badgeMin,
    required this.ringDiameter,
    required this.ringStroke,
    required this.accentEdge,
    required this.chartPlotHeight,
    required this.summaryStripExpandedHeight,
    required this.summaryStripCollapsedHeight,
    required this.scanProgressStripExpandedHeight,
  });

  final double tapTargetMin;
  final double tapTargetComfortable;

  final double iconXs;
  final double iconSm;
  final double iconMd;
  final double iconLg;
  final double iconXl;

  final double controlSm;
  final double controlMd;
  final double controlLg;

  final double borderHairline;
  final double borderThin;
  final double borderThick;

  /// Focus ring width — thicker than a normal border, because hardware-key
  /// navigation depends on focus being obvious at a glance.
  final double borderFocus;

  /// Bottom navigation height. Kept tight: it is permanent chrome on a
  /// 533 dp-tall screen.
  final double tabBarHeight;

  /// Height of the thin load-progress bar on an order card.
  final double progressBarHeight;

  /// Minimum diameter of a count badge.
  final double badgeMin;

  /// Outer diameter of a progress dial in a summary strip.
  final double ringDiameter;

  /// Stroke width of that dial. Thick enough to read at arm's length in a
  /// warehouse aisle.
  final double ringStroke;

  /// Width of the coloured status edge down the side of a list row.
  /// Carries status alongside the badge, so meaning never rests on colour
  /// alone.
  final double accentEdge;

  /// Height of a small in-card chart's plot area, excluding its axis
  /// labels. Tall enough that a quiet day still reads as a bar.
  final double chartPlotHeight;

  /// Height of a pinned summary strip's sliver header at full size — the
  /// three stat tiles, before it has scrolled under anything. Matches the
  /// strip's actual, unstretched content height at text scale 1.0 exactly —
  /// `AppPinnedSummary` scales this by the live text scale itself, so the
  /// token stays the true baseline rather than a padded guess.
  ///
  /// A `SliverPersistentHeader` needs a concrete pixel extent, which is
  /// normally exactly what rule 1c forbids for a box holding text; scaling it
  /// live rather than padding it flat is what keeps that promise here too.
  final double summaryStripExpandedHeight;

  /// Height once the strip is pinned at the top and has shrunk to its
  /// one-line form. Same baseline rationale as [summaryStripExpandedHeight].
  final double summaryStripCollapsedHeight;

  /// [summaryStripExpandedHeight]'s counterpart for the Scan screen, whose
  /// full form carries a progress ring instead of a plain stat tile and so
  /// needs more room.
  final double scanProgressStripExpandedHeight;

  static const AppSizes standard = AppSizes(
    tapTargetMin: PrimitiveSizes.tapTargetMin,
    tapTargetComfortable: PrimitiveSizes.tapTargetGloved,
    iconXs: PrimitiveSizes.icon14,
    iconSm: PrimitiveSizes.icon16,
    iconMd: PrimitiveSizes.icon20,
    iconLg: PrimitiveSizes.icon24,
    iconXl: PrimitiveSizes.icon32,
    controlSm: PrimitiveSizes.controlSm,
    controlMd: PrimitiveSizes.controlMd,
    controlLg: PrimitiveSizes.controlLg,
    borderHairline: PrimitiveSizes.borderHairline,
    borderThin: PrimitiveSizes.borderThin,
    borderThick: PrimitiveSizes.borderThick,
    borderFocus: PrimitiveSizes.borderFocus,
    tabBarHeight: 56,
    progressBarHeight: 3,
    badgeMin: 18,
    ringDiameter: 56,
    ringStroke: 4,
    accentEdge: 4,
    chartPlotHeight: 72,
    summaryStripExpandedHeight: 78,
    summaryStripCollapsedHeight: 46,
    scanProgressStripExpandedHeight: 114,
  );

  @override
  AppSizes copyWith({
    double? tapTargetMin,
    double? tapTargetComfortable,
    double? iconXs,
    double? iconSm,
    double? iconMd,
    double? iconLg,
    double? iconXl,
    double? controlSm,
    double? controlMd,
    double? controlLg,
    double? borderHairline,
    double? borderThin,
    double? borderThick,
    double? borderFocus,
    double? tabBarHeight,
    double? progressBarHeight,
    double? badgeMin,
    double? ringDiameter,
    double? ringStroke,
    double? accentEdge,
    double? chartPlotHeight,
    double? summaryStripExpandedHeight,
    double? summaryStripCollapsedHeight,
    double? scanProgressStripExpandedHeight,
  }) {
    return AppSizes(
      tapTargetMin: tapTargetMin ?? this.tapTargetMin,
      tapTargetComfortable: tapTargetComfortable ?? this.tapTargetComfortable,
      iconXs: iconXs ?? this.iconXs,
      iconSm: iconSm ?? this.iconSm,
      iconMd: iconMd ?? this.iconMd,
      iconLg: iconLg ?? this.iconLg,
      iconXl: iconXl ?? this.iconXl,
      controlSm: controlSm ?? this.controlSm,
      controlMd: controlMd ?? this.controlMd,
      controlLg: controlLg ?? this.controlLg,
      borderHairline: borderHairline ?? this.borderHairline,
      borderThin: borderThin ?? this.borderThin,
      borderThick: borderThick ?? this.borderThick,
      borderFocus: borderFocus ?? this.borderFocus,
      tabBarHeight: tabBarHeight ?? this.tabBarHeight,
      progressBarHeight: progressBarHeight ?? this.progressBarHeight,
      badgeMin: badgeMin ?? this.badgeMin,
      ringDiameter: ringDiameter ?? this.ringDiameter,
      ringStroke: ringStroke ?? this.ringStroke,
      accentEdge: accentEdge ?? this.accentEdge,
      chartPlotHeight: chartPlotHeight ?? this.chartPlotHeight,
      summaryStripExpandedHeight:
          summaryStripExpandedHeight ?? this.summaryStripExpandedHeight,
      summaryStripCollapsedHeight:
          summaryStripCollapsedHeight ?? this.summaryStripCollapsedHeight,
      scanProgressStripExpandedHeight:
          scanProgressStripExpandedHeight ??
          this.scanProgressStripExpandedHeight,
    );
  }

  @override
  AppSizes lerp(ThemeExtension<AppSizes>? other, double t) {
    if (other is! AppSizes) return this;
    return AppSizes(
      tapTargetMin: lerpToken(tapTargetMin, other.tapTargetMin, t),
      tapTargetComfortable: lerpToken(
        tapTargetComfortable,
        other.tapTargetComfortable,
        t,
      ),
      iconXs: lerpToken(iconXs, other.iconXs, t),
      iconSm: lerpToken(iconSm, other.iconSm, t),
      iconMd: lerpToken(iconMd, other.iconMd, t),
      iconLg: lerpToken(iconLg, other.iconLg, t),
      iconXl: lerpToken(iconXl, other.iconXl, t),
      controlSm: lerpToken(controlSm, other.controlSm, t),
      controlMd: lerpToken(controlMd, other.controlMd, t),
      controlLg: lerpToken(controlLg, other.controlLg, t),
      borderHairline: lerpToken(borderHairline, other.borderHairline, t),
      borderThin: lerpToken(borderThin, other.borderThin, t),
      borderThick: lerpToken(borderThick, other.borderThick, t),
      borderFocus: lerpToken(borderFocus, other.borderFocus, t),
      tabBarHeight: lerpToken(tabBarHeight, other.tabBarHeight, t),
      progressBarHeight: lerpToken(
        progressBarHeight,
        other.progressBarHeight,
        t,
      ),
      badgeMin: lerpToken(badgeMin, other.badgeMin, t),
      ringDiameter: lerpToken(ringDiameter, other.ringDiameter, t),
      ringStroke: lerpToken(ringStroke, other.ringStroke, t),
      accentEdge: lerpToken(accentEdge, other.accentEdge, t),
      chartPlotHeight: lerpToken(chartPlotHeight, other.chartPlotHeight, t),
      summaryStripExpandedHeight: lerpToken(
        summaryStripExpandedHeight,
        other.summaryStripExpandedHeight,
        t,
      ),
      summaryStripCollapsedHeight: lerpToken(
        summaryStripCollapsedHeight,
        other.summaryStripCollapsedHeight,
        t,
      ),
      scanProgressStripExpandedHeight: lerpToken(
        scanProgressStripExpandedHeight,
        other.scanProgressStripExpandedHeight,
        t,
      ),
    );
  }
}
