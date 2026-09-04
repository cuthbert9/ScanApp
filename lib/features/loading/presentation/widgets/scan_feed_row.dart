import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../domain/models/gs1_barcode.dart';
import '../../../../domain/models/order_line.dart';
import '../../../../domain/models/scan_event.dart';
import '../../../../shared/widgets/widgets.dart';
import 'gs1_meta_line.dart';

/// One line of the scan feed.
///
/// Status is carried by a coloured left edge **and** a text badge. Colour alone
/// is not enough: the device is read in a dim aisle, through safety glasses, by
/// operators who may be colour-blind.
class ScanFeedRow extends StatelessWidget {
  const ScanFeedRow({super.key, required this.event});

  final ScanEvent event;

  AppBadgeVariant get _badgeVariant => switch (event.result) {
    ScanResult.ok => AppBadgeVariant.success,
    ScanResult.hold => AppBadgeVariant.blocked,
    ScanResult.duplicate => AppBadgeVariant.pending,
    ScanResult.wrongOrder => AppBadgeVariant.danger,
  };

  Color _edgeColor(AppColors colors) => switch (event.result) {
    ScanResult.ok => colors.success,
    ScanResult.hold => colors.statusActive,
    ScanResult.duplicate => colors.borderStrong,
    ScanResult.wrongOrder => colors.danger,
  };

  /// The monospaced detail line, assembled from the line this code resolved to.
  List<Gs1Segment> get _segments {
    final List<Gs1Segment> parts = <Gs1Segment>[];
    final OrderLine? line = event.line;

    if (line != null) {
      parts
        ..add(Gs1Segment(ai: '00', text: line.sscc))
        ..add(Gs1Segment(ai: '10', text: line.lot))
        ..add(Gs1Segment(text: 'EXP ${line.expiryLabel}'));
    } else if (event.rawCode.isNotEmpty) {
      parts.add(Gs1Segment(text: event.rawCode));
    }
    if (event.reason != null) parts.add(Gs1Segment(text: event.reason!));
    if (parts.isEmpty) parts.add(const Gs1Segment(text: '—'));
    return parts;
  }

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
              children: <Widget>[
                Text(
                  '${event.seq}',
                  style: context.type.dataMd.copyWith(color: colors.dataMuted),
                ),
                SizedBox(width: spacing.sm),
                // Expanded: product names run long and would otherwise overflow
                // the row at 320 dp.
                Expanded(child: _ProductLabel(event: event)),
                SizedBox(width: spacing.sm),
                AppBadge(label: event.result.label, variant: _badgeVariant),
              ],
            ),
            SizedBox(height: spacing.xs),
            Gs1MetaLine(segments: _segments),
          ],
        ),
      ),
    );
  }
}

/// `Zinc Sulfate 20 mg ×500` — name emphasised, quantity secondary.
class _ProductLabel extends StatelessWidget {
  const _ProductLabel({required this.event});

  final ScanEvent event;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: event.productName,
            style: context.type.headingSm.copyWith(color: colors.textPrimary),
          ),
          if (event.quantity > 0)
            TextSpan(
              text: '  × ${event.quantity}',
              style: context.type.bodyMd.copyWith(color: colors.textTertiary),
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
