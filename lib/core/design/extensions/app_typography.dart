import 'package:flutter/material.dart';

import '../tokens/primitive_tokens.dart';

/// SEMANTIC TYPOGRAPHY — Layer 2.
///
/// The complete set of text styles the app may use. Screens compose these
/// (`context.type.bodyMd`) and never build a [TextStyle] from scratch.
///
/// Colour is applied separately with `.copyWith(color: context.colors.x)`, so
/// one style works on both light and dark surfaces.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.displayLg,
    required this.headingLg,
    required this.headingMd,
    required this.headingSm,
    required this.bodyLg,
    required this.bodyMd,
    required this.bodySm,
    required this.labelLg,
    required this.labelMd,
    required this.labelSm,
    required this.caption,
    required this.dataLg,
    required this.dataMd,
    required this.dataSm,
    required this.overline,
    required this.tabLabel,
  });

  /// A hero numeral — a scanned count, a total. At most one per screen.
  final TextStyle displayLg;

  final TextStyle headingLg;
  final TextStyle headingMd;
  final TextStyle headingSm;

  final TextStyle bodyLg;
  final TextStyle bodyMd;
  final TextStyle bodySm;

  /// Text inside controls — buttons, tabs, chips.
  final TextStyle labelLg;
  final TextStyle labelMd;
  final TextStyle labelSm;

  final TextStyle caption;

  /// Monospaced, for machine-readable values: order numbers, barcodes, SKUs,
  /// serials, LPNs, route codes.
  ///
  /// Fixed width matters here — operators visually diff long alphanumeric
  /// strings, and proportional digits let a transposition hide.
  final TextStyle dataLg;
  final TextStyle dataMd;
  final TextStyle dataSm;

  /// All-caps section eyebrow.
  final TextStyle overline;

  /// Bottom-navigation label: small, all-caps, widely tracked.
  final TextStyle tabLabel;

  static const AppTypography standard = AppTypography(
    displayLg: TextStyle(
      fontSize: PrimitiveTypography.size30,
      fontWeight: PrimitiveTypography.weightBold,
      height: PrimitiveTypography.leadingTight,
      letterSpacing: PrimitiveTypography.trackingTight,
    ),
    headingLg: TextStyle(
      fontSize: PrimitiveTypography.size24,
      fontWeight: PrimitiveTypography.weightBold,
      height: PrimitiveTypography.leadingTight,
      letterSpacing: PrimitiveTypography.trackingTight,
    ),
    headingMd: TextStyle(
      fontSize: PrimitiveTypography.size20,
      fontWeight: PrimitiveTypography.weightBold,
      height: PrimitiveTypography.leadingSnug,
    ),
    headingSm: TextStyle(
      fontSize: PrimitiveTypography.size16,
      fontWeight: PrimitiveTypography.weightBold,
      height: PrimitiveTypography.leadingSnug,
    ),
    bodyLg: TextStyle(
      fontSize: PrimitiveTypography.size16,
      fontWeight: PrimitiveTypography.weightRegular,
      height: PrimitiveTypography.leadingNormal,
    ),
    bodyMd: TextStyle(
      fontSize: PrimitiveTypography.size14,
      fontWeight: PrimitiveTypography.weightRegular,
      height: PrimitiveTypography.leadingNormal,
    ),
    bodySm: TextStyle(
      fontSize: PrimitiveTypography.size13,
      fontWeight: PrimitiveTypography.weightRegular,
      height: PrimitiveTypography.leadingNormal,
    ),
    labelLg: TextStyle(
      fontSize: PrimitiveTypography.size16,
      fontWeight: PrimitiveTypography.weightBold,
      height: PrimitiveTypography.leadingSnug,
    ),
    labelMd: TextStyle(
      fontSize: PrimitiveTypography.size14,
      fontWeight: PrimitiveTypography.weightSemibold,
      height: PrimitiveTypography.leadingSnug,
    ),
    labelSm: TextStyle(
      fontSize: PrimitiveTypography.size12,
      fontWeight: PrimitiveTypography.weightSemibold,
      height: PrimitiveTypography.leadingSnug,
    ),
    caption: TextStyle(
      fontSize: PrimitiveTypography.size12,
      fontWeight: PrimitiveTypography.weightRegular,
      height: PrimitiveTypography.leadingNormal,
    ),
    dataLg: TextStyle(
      fontSize: PrimitiveTypography.size16,
      fontWeight: PrimitiveTypography.weightSemibold,
      height: PrimitiveTypography.leadingSnug,
      letterSpacing: PrimitiveTypography.trackingWide,
      fontFamilyFallback: PrimitiveTypography.monoFallback,
    ),
    dataMd: TextStyle(
      fontSize: PrimitiveTypography.size13,
      fontWeight: PrimitiveTypography.weightSemibold,
      height: PrimitiveTypography.leadingSnug,
      letterSpacing: PrimitiveTypography.trackingWide,
      fontFamilyFallback: PrimitiveTypography.monoFallback,
    ),
    dataSm: TextStyle(
      fontSize: PrimitiveTypography.size12,
      fontWeight: PrimitiveTypography.weightRegular,
      height: PrimitiveTypography.leadingSnug,
      letterSpacing: PrimitiveTypography.trackingWide,
      fontFamilyFallback: PrimitiveTypography.monoFallback,
    ),
    overline: TextStyle(
      fontSize: PrimitiveTypography.size11,
      fontWeight: PrimitiveTypography.weightBold,
      height: PrimitiveTypography.leadingSnug,
      letterSpacing: PrimitiveTypography.trackingWidest,
    ),
    tabLabel: TextStyle(
      fontSize: PrimitiveTypography.size10,
      fontWeight: PrimitiveTypography.weightSemibold,
      height: PrimitiveTypography.leadingSnug,
      letterSpacing: PrimitiveTypography.trackingWide,
    ),
  );

  @override
  AppTypography copyWith({
    TextStyle? displayLg,
    TextStyle? headingLg,
    TextStyle? headingMd,
    TextStyle? headingSm,
    TextStyle? bodyLg,
    TextStyle? bodyMd,
    TextStyle? bodySm,
    TextStyle? labelLg,
    TextStyle? labelMd,
    TextStyle? labelSm,
    TextStyle? caption,
    TextStyle? dataLg,
    TextStyle? dataMd,
    TextStyle? dataSm,
    TextStyle? overline,
    TextStyle? tabLabel,
  }) {
    return AppTypography(
      displayLg: displayLg ?? this.displayLg,
      headingLg: headingLg ?? this.headingLg,
      headingMd: headingMd ?? this.headingMd,
      headingSm: headingSm ?? this.headingSm,
      bodyLg: bodyLg ?? this.bodyLg,
      bodyMd: bodyMd ?? this.bodyMd,
      bodySm: bodySm ?? this.bodySm,
      labelLg: labelLg ?? this.labelLg,
      labelMd: labelMd ?? this.labelMd,
      labelSm: labelSm ?? this.labelSm,
      caption: caption ?? this.caption,
      dataLg: dataLg ?? this.dataLg,
      dataMd: dataMd ?? this.dataMd,
      dataSm: dataSm ?? this.dataSm,
      overline: overline ?? this.overline,
      tabLabel: tabLabel ?? this.tabLabel,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    TextStyle s(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTypography(
      displayLg: s(displayLg, other.displayLg),
      headingLg: s(headingLg, other.headingLg),
      headingMd: s(headingMd, other.headingMd),
      headingSm: s(headingSm, other.headingSm),
      bodyLg: s(bodyLg, other.bodyLg),
      bodyMd: s(bodyMd, other.bodyMd),
      bodySm: s(bodySm, other.bodySm),
      labelLg: s(labelLg, other.labelLg),
      labelMd: s(labelMd, other.labelMd),
      labelSm: s(labelSm, other.labelSm),
      caption: s(caption, other.caption),
      dataLg: s(dataLg, other.dataLg),
      dataMd: s(dataMd, other.dataMd),
      dataSm: s(dataSm, other.dataSm),
      overline: s(overline, other.overline),
      tabLabel: s(tabLabel, other.tabLabel),
    );
  }
}
