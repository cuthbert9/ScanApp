import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// Emphasis applied to a stat's value.
///
/// Replaces an earlier `emphasised: bool`: the scan summary needs a green
/// "verified" figure and a gold "held" figure in the same strip, which a
/// boolean cannot express. Extending the enum beats adding a second widget
/// (CLAUDE.md rule 2).
enum StatAccent {
  /// Inherit the tone's default content colour.
  none,

  /// Temperature-controlled — teal.
  coldChain,

  /// Confirmed, accepted — green.
  success,

  /// Needs attention — gold.
  warning,
}

/// Which surface an [AppStatTile] is sitting on.
///
/// The tile picks its own colours from this rather than taking them as
/// parameters, so the call site never restates styling (CLAUDE.md rule 1b).
enum AppStatTileTone {
  /// On the dark navy header strip.
  onHeader,

  /// On a normal light surface.
  onSurface,
}

/// One cell of a summary strip: a large value over a small upper-case label.
///
/// ```
///      41
///    UNITS
/// ```
///
/// [accent] tints the value for a figure that carries extra meaning — a
/// cold-chain count, a verified total, a held total.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.value,
    required this.label,
    this.tone = AppStatTileTone.onHeader,
    this.accent = StatAccent.none,
    this.unit,
  });

  final String value;

  /// Rendered after [value] at label weight — the `%` in `99.3 %`. Smaller and
  /// quieter, so the figure reads first.
  final String? unit;

  final String label;
  final AppStatTileTone tone;
  final StatAccent accent;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    final Color labelColor = switch (tone) {
      AppStatTileTone.onHeader => colors.onHeaderMuted,
      AppStatTileTone.onSurface => colors.textSecondary,
    };
    final Color valueColor = switch (accent) {
      StatAccent.coldChain => colors.coldChain,
      StatAccent.success => colors.success,
      StatAccent.warning => colors.statusActive,
      StatAccent.none => switch (tone) {
        AppStatTileTone.onHeader => colors.onHeader,
        AppStatTileTone.onSurface => colors.textPrimary,
      },
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Flexible(
              child: Text(
                value,
                style: context.type.headingLg.copyWith(color: valueColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unit != null) ...<Widget>[
              SizedBox(width: context.spacing.xxs),
              Text(
                unit!,
                style: context.type.labelMd.copyWith(color: valueColor),
                maxLines: 1,
              ),
            ],
          ],
        ),
        SizedBox(height: context.spacing.xxs),
        Text(
          label.toUpperCase(),
          style: context.type.overline.copyWith(color: labelColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
