import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import 'app_stat_tile.dart';

/// A progress dial with its figure inside and a label beneath.
///
/// ```
///    ╭────╮
///   │13/14│
///    ╰────╯
///  UNITS LOADED
/// ```
///
/// Use where a count only means something against a target — units loaded of
/// units expected. For a standalone figure use [AppStatTile]; a ring around a
/// number with no denominator is decoration.
class AppStatRing extends StatelessWidget {
  const AppStatRing({
    super.key,
    required this.value,
    required this.total,
    required this.label,
    this.tone = AppStatTileTone.onHeader,
  });

  final int value;
  final int total;
  final String label;
  final AppStatTileTone tone;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSizes sizes = context.sizes;

    final Color labelColor = switch (tone) {
      AppStatTileTone.onHeader => colors.onHeaderMuted,
      AppStatTileTone.onSurface => colors.textSecondary,
    };
    final Color figureColor = switch (tone) {
      AppStatTileTone.onHeader => colors.onHeader,
      AppStatTileTone.onSurface => colors.textPrimary,
    };

    // Guard against a zero manifest: 0/0 is complete, not a divide-by-zero.
    final double progress = total <= 0 ? 1 : (value / total).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: sizes.ringDiameter,
          height: sizes.ringDiameter,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: sizes.ringStroke,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.progressTrack,
                  color: colors.progressFill,
                  // Announced by the label below; the ring itself is decoration.
                  semanticsLabel: label,
                ),
              ),
              Text(
                '$value/$total',
                style: context.type.labelMd.copyWith(color: figureColor),
                maxLines: 1,
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.sm),
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
