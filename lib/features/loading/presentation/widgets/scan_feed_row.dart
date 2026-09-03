import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/scan_record.dart';
import '../../domain/scan_verdict.dart';
import 'gs1_meta_line.dart';

/// One line of the scan feed.
///
/// Status is carried by a coloured left edge **and** a text badge. Colour alone
/// is not enough: the device is read in a dim aisle, through safety glasses, by
/// operators who may be colour-blind.
class ScanFeedRow extends StatelessWidget {
  const ScanFeedRow({super.key, required this.record});

  final ScanRecord record;

  AppBadgeVariant get _badgeVariant => switch (record.verdict) {
    ScanVerdict.ok => AppBadgeVariant.success,
    ScanVerdict.hold => AppBadgeVariant.blocked,
    ScanVerdict.unknown => AppBadgeVariant.danger,
  };

  Color _edgeColor(AppColors colors) => switch (record.verdict) {
    ScanVerdict.ok => colors.success,
    ScanVerdict.hold => colors.statusActive,
    ScanVerdict.unknown => colors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

    // The coloured edge is the outer container showing through on the left,
    // rather than a stretched sibling. That avoids IntrinsicHeight, which would
    // cost an extra layout pass on every row of a long feed.
    return Container(
      decoration: BoxDecoration(
        color: _edgeColor(colors),
        borderRadius: context.radii.cardBorder,
      ),
      padding: EdgeInsets.only(left: context.sizes.accentEdge),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(context.radii.card),
          ),
          border: Border.all(
            color: colors.border,
            width: context.sizes.borderHairline,
          ),
        ),
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              // Centre rather than baseline: the product label can wrap to two
              // lines, and baseline alignment against a wrapping child aligns
              // to the first line and leaves the badge floating.
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${record.sequence}',
                  style: context.type.dataMd.copyWith(color: colors.dataMuted),
                ),
                SizedBox(width: spacing.sm),
                // Expanded: product names run long and would otherwise
                // overflow the row at 320 dp.
                Expanded(child: _ProductLabel(record: record)),
                SizedBox(width: spacing.sm),
                AppBadge(label: record.verdict.label, variant: _badgeVariant),
              ],
            ),
            SizedBox(height: spacing.xs),
            Gs1MetaLine(segments: record.segments),
          ],
        ),
      ),
    );
  }
}

/// `Zinc Sulfate 20 mg × 500` — name emphasised, quantity secondary.
class _ProductLabel extends StatelessWidget {
  const _ProductLabel({required this.record});

  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: record.productName,
            style: context.type.headingSm.copyWith(color: colors.textPrimary),
          ),
          if (record.quantity > 0)
            TextSpan(
              text: '  × ${record.quantity}',
              style: context.type.bodyMd.copyWith(color: colors.textTertiary),
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
