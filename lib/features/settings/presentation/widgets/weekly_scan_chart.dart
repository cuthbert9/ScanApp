import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../domain/models/shift_stats.dart';

/// Units scanned per day over the last seven days.
///
/// Built against the project's dataviz rules:
///
/// * **One series**, so there is no legend — the title names it. Today is an
///   emphasised mark within that series, not a second series.
/// * **Colours are validated, not chosen by eye.** `chartBar` and
///   `chartBarEmphasis` were run through the palette checker as a one-hue
///   ordinal ramp against each theme's card surface. The mockup's paler tan
///   failed at 1.38:1 contrast, which on a device used in direct sunlight is a
///   real legibility problem rather than a nitpick.
/// * The validator's sub-3:1 contrast warning **obligates relief**, so the
///   values are always readable as text: a caption line, a per-bar semantic
///   label, and tap-to-inspect.
/// * Bars are anchored to the baseline with rounded tops and a gap between, and
///   the axis labels stay recessive.
///
/// Tap-to-inspect replaces hover, which does not exist on a gloved handheld.
class WeeklyScanChart extends StatefulWidget {
  const WeeklyScanChart({
    super.key,
    required this.week,
    required this.todayUnits,
    required this.peakUnits,
  });

  final List<DailyScanCount> week;
  final int todayUnits;
  final int peakUnits;

  @override
  State<WeeklyScanChart> createState() => _WeeklyScanChartState();
}

class _WeeklyScanChartState extends State<WeeklyScanChart> {
  /// The bar the operator has tapped, if any.
  int? _selected;

  void _toggle(int index) {
    setState(() => _selected = _selected == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

    if (widget.week.isEmpty) return const SizedBox.shrink();

    // Scale against the best day, so the tallest bar fills the plot and the
    // rest read as a share of it.
    final int scaleMax = widget.peakUnits > 0 ? widget.peakUnits : 1;

    final DailyScanCount? picked = _selected == null
        ? null
        : widget.week[_selected!];
    final String caption = picked == null
        ? '${widget.todayUnits} today  ·  ${widget.peakUnits} peak'
        : '${picked.dayName}  ·  ${picked.units} units';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // The title names the series, which is why no legend is needed.
            Expanded(
              child: Text(
                'Units scanned',
                style: context.type.headingSm.copyWith(
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: spacing.sm),
            Flexible(
              child: Text(
                caption,
                style: context.type.dataSm.copyWith(color: colors.dataMuted),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.md),
        SizedBox(
          height: context.sizes.chartPlotHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int i = 0; i < widget.week.length; i++) ...<Widget>[
                if (i > 0) SizedBox(width: spacing.xs),
                Expanded(
                  child: _Bar(
                    day: widget.week[i],
                    fraction: widget.week[i].units / scaleMax,
                    isPicked: _selected == i,
                    onTap: () => _toggle(i),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: spacing.xs),
        Row(
          children: <Widget>[
            for (int i = 0; i < widget.week.length; i++) ...<Widget>[
              if (i > 0) SizedBox(width: spacing.xs),
              Expanded(
                child: Text(
                  widget.week[i].label,
                  textAlign: TextAlign.center,
                  style: context.type.dataSm.copyWith(
                    color: colors.textTertiary,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.fraction,
    required this.isPicked,
    required this.onTap,
  });

  final DailyScanCount day;
  final double fraction;
  final bool isPicked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final double plot = context.sizes.chartPlotHeight;

    // A floor so a very quiet day is still a visible mark rather than nothing.
    final double height = (fraction.clamp(0.0, 1.0) * plot).clamp(
      context.spacing.xs,
      plot,
    );

    final Color fill = day.isToday || isPicked
        ? colors.chartBarEmphasis
        : colors.chartBar;

    return Semantics(
      button: true,
      selected: isPicked,
      // The accessible equivalent of a data table: every value is reachable as
      // text, which is also what discharges the palette checker's contrast
      // warning.
      label:
          '${day.dayName}, ${day.units} units'
          '${day.isToday ? ', today' : ''}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: fill,
              // Rounded data-end on top only: the bar stays anchored to the
              // baseline, which is what makes the heights comparable.
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.radii.sm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
