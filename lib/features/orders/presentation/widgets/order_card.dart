import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/loading_order.dart';
import '../../domain/order_status.dart';

/// One row of the loading queue.
///
/// Selection is shown with a gold outline and a load-progress bar rather than a
/// fill, so the card's own status colours stay readable — an operator scanning
/// down the list is looking for the badge, not the selection.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.isSelected,
    required this.onTap,
  });

  final LoadingOrder order;
  final bool isSelected;
  final VoidCallback onTap;

  /// Status → badge weight. Lives in presentation because [OrderStatus] is pure
  /// domain and must not know about widgets.
  AppBadgeVariant get _badgeVariant => switch (order.status) {
    OrderStatus.loading => AppBadgeVariant.active,
    OrderStatus.queued => AppBadgeVariant.pending,
    OrderStatus.loaded => AppBadgeVariant.success,
    OrderStatus.noTruck => AppBadgeVariant.blocked,
    OrderStatus.held => AppBadgeVariant.danger,
  };

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;
    final AppSizes sizes = context.sizes;

    return Material(
      color: colors.surface,
      borderRadius: context.radii.cardBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radii.cardBorder,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: context.radii.cardBorder,
            border: Border.all(
              color: isSelected ? colors.borderSelected : colors.border,
              width: isSelected ? sizes.borderThick : sizes.borderHairline,
            ),
          ),
          child: ClipRRect(
            borderRadius: context.radii.cardBorder,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          // Expanded: facility names run long
                          // ("Morogoro Regional Medical Store") and would
                          // otherwise overflow at 320 dp.
                          Expanded(child: _FacilityLabel(order: order)),
                          if (order.isColdChain) ...<Widget>[
                            SizedBox(width: spacing.xs),
                            Icon(
                              Icons.ac_unit,
                              size: sizes.iconSm,
                              color: colors.coldChain,
                              semanticLabel: 'Cold chain',
                            ),
                          ],
                          SizedBox(width: spacing.sm),
                          AppBadge(
                            label: order.status.label,
                            variant: _badgeVariant,
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.sm),
                      AppMetaRow(segments: order.metaSegments),
                    ],
                  ),
                ),
                if (order.hasProgress)
                  LinearProgressIndicator(
                    value: order.loadProgress,
                    minHeight: sizes.progressBarHeight,
                    backgroundColor: colors.progressTrack,
                    color: colors.progressFill,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Facility name with its optional programme tag, as one wrapping text run.
class _FacilityLabel extends StatelessWidget {
  const _FacilityLabel({required this.order});

  final LoadingOrder order;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextStyle nameStyle = context.type.headingSm.copyWith(
      color: colors.textPrimary,
    );

    if (order.programme == null) {
      return Text(
        order.facility,
        style: nameStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(text: order.facility, style: nameStyle),
          TextSpan(
            text: '  ·  ${order.programme}',
            style: context.type.labelMd.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
