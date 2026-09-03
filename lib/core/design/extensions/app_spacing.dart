import 'package:flutter/material.dart';

import '../tokens/primitive_tokens.dart';

/// Null-safe double interpolation, shared by the numeric token bundles.
double lerpToken(double a, double b, double t) => a + (b - a) * t;

/// SEMANTIC SPACING — Layer 2.
///
/// A t-shirt scale over the 4pt grid. Reach for these rather than typing a
/// number: `context.spacing.md`, not `12`.
///
/// On the MC9450's narrow canvas: [xs]/[sm] inside a control, [md] between
/// controls, [lg] between groups, [xl]/[xxl] between page sections.
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.none,
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.screenPadding,
    required this.listGap,
    required this.sectionGap,
  });

  final double none;
  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  /// Horizontal inset for page content. Deliberately 12, not 16 — on a 320 dp
  /// canvas, 16 dp gutters cost 10% of usable width.
  final double screenPadding;

  /// Vertical gap between sibling rows in a list.
  final double listGap;

  /// Vertical gap between titled sections.
  final double sectionGap;

  static const AppSpacing standard = AppSpacing(
    none: PrimitiveSpacing.space0,
    xxs: PrimitiveSpacing.space2,
    xs: PrimitiveSpacing.space4,
    sm: PrimitiveSpacing.space8,
    md: PrimitiveSpacing.space12,
    lg: PrimitiveSpacing.space16,
    xl: PrimitiveSpacing.space24,
    xxl: PrimitiveSpacing.space32,
    screenPadding: PrimitiveSpacing.space12,
    listGap: PrimitiveSpacing.space8,
    sectionGap: PrimitiveSpacing.space20,
  );

  /// Ready-made insets, so screens never construct one from a literal.
  EdgeInsets get screenH => EdgeInsets.symmetric(horizontal: screenPadding);
  EdgeInsets get screenAll => EdgeInsets.all(screenPadding);
  EdgeInsets get cardInsets => EdgeInsets.all(md);

  @override
  AppSpacing copyWith({
    double? none,
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? screenPadding,
    double? listGap,
    double? sectionGap,
  }) {
    return AppSpacing(
      none: none ?? this.none,
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      screenPadding: screenPadding ?? this.screenPadding,
      listGap: listGap ?? this.listGap,
      sectionGap: sectionGap ?? this.sectionGap,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      none: lerpToken(none, other.none, t),
      xxs: lerpToken(xxs, other.xxs, t),
      xs: lerpToken(xs, other.xs, t),
      sm: lerpToken(sm, other.sm, t),
      md: lerpToken(md, other.md, t),
      lg: lerpToken(lg, other.lg, t),
      xl: lerpToken(xl, other.xl, t),
      xxl: lerpToken(xxl, other.xxl, t),
      screenPadding: lerpToken(screenPadding, other.screenPadding, t),
      listGap: lerpToken(listGap, other.listGap, t),
      sectionGap: lerpToken(sectionGap, other.sectionGap, t),
    );
  }
}
