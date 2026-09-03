import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import 'app_stat_tile.dart';

/// One label/value line inside a reconciliation card.
///
/// ```
/// VERIFIED ONTO TRUCK                        13 units
/// ```
///
/// The label may wrap; the **value never truncates**. Shortening a label is
/// survivable, but an operator is about to seal a truck on these numbers, so a
/// clipped figure is not.
///
/// Promoted here from the loading feature once the sync screen's local-queue
/// card needed the same four label/value lines — the second consumer, which is
/// the bar for `shared/` (CLAUDE.md rule 2).
class AppDetailRow extends StatelessWidget {
  const AppDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.accent = StatAccent.none,
    this.emphasised = false,
  });

  final String label;
  final String value;

  /// Tints the value where it carries meaning — verified green, short amber.
  final StatAccent accent;

  /// Renders the value in the heavier data style, for a headline figure.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    final Color valueColor = switch (accent) {
      StatAccent.success => colors.success,
      StatAccent.warning => colors.onStatusBlockedSurface,
      StatAccent.coldChain => colors.coldChain,
      StatAccent.none => colors.textPrimary,
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // BOTH sides are flex, and both are tight.
          //
          // An Expanded label beside a bare Text was the earlier shape, and it
          // overflowed: the value kept its intrinsic width whatever was left,
          // so a long one (`Sunset · ambient sensor`) blew the row by 182 px at
          // font scale 1.3. Giving the value a share of its own lets it
          // ellipsise instead, and a tight fit keeps it right-aligned when short.
          //
          // The 4:6 split favours the value, because the value is what is being
          // read; the label is context the operator already has.
          Expanded(
            flex: 4,
            child: Text(
              label.toUpperCase(),
              style: context.type.overline.copyWith(
                color: colors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: (emphasised ? context.type.dataLg : context.type.dataMd)
                  .copyWith(color: valueColor),
              textAlign: TextAlign.end,
              maxLines: 1,
              // Reverses an earlier call that values never truncate. That held
              // for figures, but a value can be a *list* — the scanner's
              // symbologies, say — and ellipsis beats a RenderFlex overflow.
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
