import 'package:flutter/material.dart';

import '../tokens/primitive_tokens.dart';
import 'app_spacing.dart' show lerpToken;

/// SEMANTIC CORNER RADII — Layer 2.
///
/// Named by the component they shape, so a rounding change stays consistent
/// across every surface of that kind.
@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({
    required this.none,
    required this.sm,
    required this.md,
    required this.lg,
    required this.pill,
    required this.card,
    required this.control,
    required this.badge,
    required this.sheet,
  });

  final double none;
  final double sm;
  final double md;
  final double lg;
  final double pill;

  /// Cards, tiles, list rows.
  final double card;

  /// Buttons and inputs.
  final double control;

  /// Status pills.
  final double badge;

  /// Bottom sheets and dialogs.
  final double sheet;

  static const AppRadii standard = AppRadii(
    none: PrimitiveRadii.radius0,
    sm: PrimitiveRadii.radius4,
    md: PrimitiveRadii.radius8,
    lg: PrimitiveRadii.radius12,
    pill: PrimitiveRadii.radiusFull,
    card: PrimitiveRadii.radius10,
    control: PrimitiveRadii.radius8,
    badge: PrimitiveRadii.radius6,
    sheet: PrimitiveRadii.radius16,
  );

  BorderRadius get cardBorder => BorderRadius.circular(card);
  BorderRadius get controlBorder => BorderRadius.circular(control);
  BorderRadius get badgeBorder => BorderRadius.circular(badge);
  BorderRadius get pillBorder => BorderRadius.circular(pill);
  BorderRadius get sheetBorder =>
      BorderRadius.vertical(top: Radius.circular(sheet));

  @override
  AppRadii copyWith({
    double? none,
    double? sm,
    double? md,
    double? lg,
    double? pill,
    double? card,
    double? control,
    double? badge,
    double? sheet,
  }) {
    return AppRadii(
      none: none ?? this.none,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      pill: pill ?? this.pill,
      card: card ?? this.card,
      control: control ?? this.control,
      badge: badge ?? this.badge,
      sheet: sheet ?? this.sheet,
    );
  }

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) return this;
    return AppRadii(
      none: lerpToken(none, other.none, t),
      sm: lerpToken(sm, other.sm, t),
      md: lerpToken(md, other.md, t),
      lg: lerpToken(lg, other.lg, t),
      pill: lerpToken(pill, other.pill, t),
      card: lerpToken(card, other.card, t),
      control: lerpToken(control, other.control, t),
      badge: lerpToken(badge, other.badge, t),
      sheet: lerpToken(sheet, other.sheet, t),
    );
  }
}
