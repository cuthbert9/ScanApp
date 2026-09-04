import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import 'app_stat_tile.dart';

/// One figure in an [AppSummaryCompactLine] — the collapsed form of a
/// summary strip once it is pinned at the top.
class AppSummaryCompactItem {
  const AppSummaryCompactItem({
    required this.value,
    required this.label,
    this.accent = StatAccent.none,
  });

  final String value;
  final String label;
  final StatAccent accent;
}

/// `VALUE label  ·  VALUE label  ·  VALUE label` on a single line.
///
/// The pinned, minimised form of a summary strip: the same figures an
/// [AppSummaryStrip] shows as stacked two-line tiles, read left to right
/// instead, so the strip can shrink to one line once it sticks to the top of
/// the screen. Reuses [StatAccent] so a figure keeps the same tint collapsed
/// as it had expanded.
class AppSummaryCompactLine extends StatelessWidget {
  const AppSummaryCompactLine({super.key, required this.items});

  final List<AppSummaryCompactItem> items;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

    Color valueColor(StatAccent accent) => switch (accent) {
      StatAccent.coldChain => colors.coldChain,
      StatAccent.success => colors.success,
      StatAccent.warning => colors.statusActive,
      StatAccent.none => colors.onHeader,
    };

    return Row(
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) ...<Widget>[
            SizedBox(width: spacing.sm),
            Text(
              '·',
              style: context.type.overline.copyWith(
                color: colors.onHeaderMuted,
              ),
            ),
            SizedBox(width: spacing.sm),
          ],
          Flexible(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '${items[i].value} ',
                    style: context.type.labelMd.copyWith(
                      color: valueColor(items[i].accent),
                    ),
                  ),
                  TextSpan(
                    text: items[i].label.toUpperCase(),
                    style: context.type.overline.copyWith(
                      color: colors.onHeaderMuted,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
