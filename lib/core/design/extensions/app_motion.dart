import 'package:flutter/material.dart';

import '../tokens/primitive_tokens.dart';

/// SEMANTIC MOTION — Layer 2.
///
/// Durations and curves, named by the transition they describe.
///
/// Deliberately restrained: an operator scanning several hundred items a shift
/// experiences every animation as latency, so feedback is quick and nothing
/// blocks the next scan.
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    required this.instant,
    required this.feedback,
    required this.transition,
    required this.emphasis,
    required this.standardCurve,
    required this.enterCurve,
    required this.exitCurve,
  });

  final Duration instant;

  /// Press states, ripples, colour changes.
  final Duration feedback;

  /// Route and container transitions.
  final Duration transition;

  /// Deliberate, attention-drawing motion. Rare.
  final Duration emphasis;

  final Curve standardCurve;
  final Curve enterCurve;
  final Curve exitCurve;

  static const AppMotion standard = AppMotion(
    instant: PrimitiveMotion.instant,
    feedback: PrimitiveMotion.fast,
    transition: PrimitiveMotion.normal,
    emphasis: PrimitiveMotion.slow,
    standardCurve: Curves.easeInOutCubic,
    enterCurve: Curves.easeOutCubic,
    exitCurve: Curves.easeInCubic,
  );

  @override
  AppMotion copyWith({
    Duration? instant,
    Duration? feedback,
    Duration? transition,
    Duration? emphasis,
    Curve? standardCurve,
    Curve? enterCurve,
    Curve? exitCurve,
  }) {
    return AppMotion(
      instant: instant ?? this.instant,
      feedback: feedback ?? this.feedback,
      transition: transition ?? this.transition,
      emphasis: emphasis ?? this.emphasis,
      standardCurve: standardCurve ?? this.standardCurve,
      enterCurve: enterCurve ?? this.enterCurve,
      exitCurve: exitCurve ?? this.exitCurve,
    );
  }

  /// Durations and curves are discrete choices — there is no meaningful
  /// midpoint between `easeIn` and `easeOut` — so we snap at the halfway mark
  /// rather than inventing an in-between.
  @override
  AppMotion lerp(ThemeExtension<AppMotion>? other, double t) {
    if (other is! AppMotion) return this;
    return t < 0.5 ? this : other;
  }
}
