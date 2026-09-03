import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// The panel of summary figures that sits under a screen header.
///
/// ```
/// ┌──────────────────────────────────────┐
/// │   14      │      13     │      1     │
/// │ ORDERED   │   VERIFIED  │   SHORT    │
/// └──────────────────────────────────────┘
/// ```
///
/// Cells are laid out evenly with a hairline between each. Pass whatever
/// belongs in them — [AppStatTile], [AppStatRing], or a single row of text when
/// [dense] — since the strip owns the panel, not the content.
///
/// Promoted to `shared/` once orders, scan and load all needed it. Before that
/// it existed twice, which is exactly the duplication rule 2 exists to catch.
class AppSummaryStrip extends StatelessWidget {
  const AppSummaryStrip({super.key, required this.cells, this.dense = false});

  /// One widget per column. A single cell renders with no dividers.
  final List<Widget> cells;

  /// Tighter vertical padding, for a one-line summary in a cramped viewport.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

    return ColoredBox(
      color: colors.headerSurface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.md,
          spacing.none,
          spacing.md,
          spacing.md,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: dense ? spacing.sm : spacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.headerSurfaceRaised,
            borderRadius: context.radii.cardBorder,
          ),
          // IntrinsicHeight so the dividers match whatever the tallest cell
          // turns out to be — a ring is taller than a stat tile. It costs an
          // extra layout pass, which is fine for one strip per screen; it would
          // not be inside a list.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < cells.length; i++) ...<Widget>[
                  if (i > 0)
                    Container(
                      width: context.sizes.borderHairline,
                      color: colors.headerDivider,
                    ),
                  Expanded(child: Center(child: cells[i])),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
