/// PRIMITIVE TOKENS — Layer 1 of the design system.
///
/// Raw, context-free values. These are the ONLY literal colours, sizes and
/// durations in the codebase; everything else derives from them.
///
/// ⚠️ DO NOT import this file from `lib/features/**` or `lib/shared/**`.
/// UI reads *semantic* tokens instead — `context.colors.surface`,
/// `context.spacing.md`. `navy800` says nothing about *why* it is used, which
/// is exactly what makes it unsafe to spread through screens.
library;

import 'dart:ui';

/// Raw colour ramps, named by hue + lightness step, never by usage.
///
/// Tuned for the Zebra MC9450: a 4.3" transflective display used in bright
/// sun, in dim aisles, and behind safety glasses. Mid-steps carry enough
/// chroma to survive glare, and the neutral ramp is cool so gold and tan
/// status colours separate from it cleanly.
abstract final class PrimitiveColors {
  // --- Neutral (cool grey) --------------------------------------------------
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF7F7F8);
  static const Color neutral100 = Color(0xFFF0F0F1);
  static const Color neutral150 = Color(0xFFE9ECEF);
  static const Color neutral200 = Color(0xFFE2E4E7);
  static const Color neutral300 = Color(0xFFC9CDD3);
  static const Color neutral400 = Color(0xFFA3A9B2);
  static const Color neutral500 = Color(0xFF8C9199);
  static const Color neutral600 = Color(0xFF59626E);
  static const Color neutral700 = Color(0xFF3D444E);
  static const Color neutral800 = Color(0xFF262B33);
  static const Color neutral900 = Color(0xFF1A1D22);
  static const Color neutral950 = Color(0xFF0E1014);

  // --- Navy (brand: header, primary action) ---------------------------------
  static const Color navy50 = Color(0xFFEDF1F8);
  static const Color navy100 = Color(0xFFD4DEEE);
  static const Color navy200 = Color(0xFFA9BCDB);
  static const Color navy300 = Color(0xFF6E88B8);
  static const Color navy400 = Color(0xFF3E5A8C);
  static const Color navy500 = Color(0xFF2B4570);
  static const Color navy600 = Color(0xFF23375C);
  static const Color navy700 = Color(0xFF1B2C49);
  static const Color navy800 = Color(0xFF16243D);
  static const Color navy900 = Color(0xFF101A2C);

  // --- Gold (in-progress, active selection) ---------------------------------
  static const Color gold50 = Color(0xFFFDF8EC);
  static const Color gold100 = Color(0xFFF7E9C6);
  static const Color gold200 = Color(0xFFEDD79B);
  static const Color gold300 = Color(0xFFDCBB5C);
  static const Color gold400 = Color(0xFFC8A227);
  static const Color gold500 = Color(0xFFA8861C);
  static const Color gold600 = Color(0xFF876A16);
  static const Color gold700 = Color(0xFF6E5420);
  static const Color gold800 = Color(0xFF4B3915);
  static const Color gold900 = Color(0xFF2E230D);

  // --- Teal (cold chain) ----------------------------------------------------
  static const Color teal50 = Color(0xFFE9F6F6);
  static const Color teal100 = Color(0xFFC5E8E8);
  static const Color teal200 = Color(0xFF92D3D3);
  static const Color teal300 = Color(0xFF5BB5B5);
  static const Color teal400 = Color(0xFF3E9A9A);
  static const Color teal500 = Color(0xFF2E7D7D);
  static const Color teal600 = Color(0xFF246363);
  static const Color teal700 = Color(0xFF1B4B4B);
  static const Color teal800 = Color(0xFF123333);
  static const Color teal900 = Color(0xFF0B2020);

  // --- Tan / orange (blocked, attention, sync backlog) ----------------------
  static const Color tan50 = Color(0xFFFDF3E9);
  static const Color tan100 = Color(0xFFF6E2C9);
  static const Color tan200 = Color(0xFFEFC79A);
  static const Color tan300 = Color(0xFFE3A362);
  static const Color tan400 = Color(0xFFD9782D);
  static const Color tan500 = Color(0xFFB55F1F);
  static const Color tan600 = Color(0xFF934B18);
  static const Color tan700 = Color(0xFF7C4E22);
  static const Color tan800 = Color(0xFF52300F);
  static const Color tan900 = Color(0xFF321D09);

  // --- Red (destructive, hard failure) --------------------------------------
  static const Color red50 = Color(0xFFFDECEC);
  static const Color red100 = Color(0xFFFAD1D1);
  static const Color red300 = Color(0xFFEC7070);
  static const Color red400 = Color(0xFFE04343);
  static const Color red500 = Color(0xFFC42626);
  static const Color red700 = Color(0xFF781414);
  static const Color red900 = Color(0xFF370909);

  // --- Green (accepted, complete) -------------------------------------------
  static const Color green50 = Color(0xFFE8F8EE);
  static const Color green100 = Color(0xFFC6EDD6);
  static const Color green300 = Color(0xFF4FC684);
  static const Color green400 = Color(0xFF23AC63);
  static const Color green500 = Color(0xFF128A4C);
  static const Color green700 = Color(0xFF09522E);
  static const Color green900 = Color(0xFF042616);

  // --- Overlays (alpha-composited over whatever is beneath) -----------------
  static const Color scrimLight = Color(0x99101A2C);
  static const Color scrimDark = Color(0xB30E1014);
  static const Color overlayHoverLight = Color(0x0A16243D);
  static const Color overlayPressedLight = Color(0x1A16243D);
  static const Color overlayHoverDark = Color(0x14FFFFFF);
  static const Color overlayPressedDark = Color(0x29FFFFFF);

  // --- Absolutes ------------------------------------------------------------
  static const Color transparent = Color(0x00000000);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
}

/// The 4pt spacing grid.
///
/// The MC9450's usable canvas is ~320×533 dp. Chrome has to be lean so content
/// survives, so this scale is tighter than a phone's — touch comfort is bought
/// back with generous *target* sizes (see [PrimitiveSizes]), not padding.
abstract final class PrimitiveSpacing {
  static const double space0 = 0;
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
}

/// Corner radii.
abstract final class PrimitiveRadii {
  static const double radius0 = 0;
  static const double radius4 = 4;
  static const double radius6 = 6;
  static const double radius8 = 8;
  static const double radius10 = 10;
  static const double radius12 = 12;
  static const double radius16 = 16;
  static const double radiusFull = 999;
}

/// Font sizes, weights, line heights and tracking.
///
/// Sizes do NOT shrink to fit the small screen — warehouse legibility beats
/// density. The narrow canvas is paid for out of padding, not type.
abstract final class PrimitiveTypography {
  static const double size10 = 10;
  static const double size11 = 11;
  static const double size12 = 12;
  static const double size13 = 13;
  static const double size14 = 14;
  static const double size16 = 16;
  static const double size18 = 18;
  static const double size20 = 20;
  static const double size24 = 24;
  static const double size30 = 30;

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  static const double leadingTight = 1.1;
  static const double leadingSnug = 1.25;
  static const double leadingNormal = 1.4;

  static const double trackingTight = -0.2;
  static const double trackingNormal = 0;
  static const double trackingWide = 0.5;
  static const double trackingWidest = 1.4;

  /// Android resolves `monospace` to Roboto Mono. Barcode-adjacent values are
  /// compared by eye, and proportional digits hide transpositions.
  static const List<String> monoFallback = <String>['monospace', 'Roboto Mono'];
}

/// Touch targets, icon sizes, control heights, border widths.
///
/// [tapTargetGloved] is the important one: operators wear gloves, so Material's
/// 48 dp minimum is a floor, not a goal.
abstract final class PrimitiveSizes {
  static const double tapTargetMin = 48;
  static const double tapTargetGloved = 56;

  static const double icon14 = 14;
  static const double icon16 = 16;
  static const double icon20 = 20;
  static const double icon24 = 24;
  static const double icon32 = 32;
  static const double icon40 = 40;

  static const double controlSm = 32;
  static const double controlMd = 44;
  static const double controlLg = 56;

  static const double borderHairline = 1;
  static const double borderThin = 1.5;
  static const double borderThick = 2;
  static const double borderFocus = 3;
}

/// Motion. Brisk — an operator scanning hundreds of items a shift experiences
/// every animation as latency.
abstract final class PrimitiveMotion {
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
}

/// Elevation steps. Used sparingly — flat reads better in bright light.
abstract final class PrimitiveElevation {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
}
