import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../domain/models/sync_mode.dart';

/// One selectable sync mode: number, title, and what choosing it means.
///
/// The description matters more than it looks. These three modes have very
/// different failure characteristics — one needs live Wi-Fi, one tolerates a
/// dead zone, one assumes no link at all — and an operator picking the wrong
/// one at the wrong bay loses work. So the copy is part of the control, not
/// decoration, and it comes from [SyncMode] rather than the widget.
class SyncModeCard extends StatelessWidget {
  const SyncModeCard({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.onSelect,
  });

  final SyncMode mode;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;
    final AppSizes sizes = context.sizes;

    return Semantics(
      selected: isSelected,
      button: true,
      label: '${mode.title}. ${mode.description}',
      child: Material(
        color: colors.surface,
        borderRadius: context.radii.cardBorder,
        child: InkWell(
          onTap: onSelect,
          borderRadius: context.radii.cardBorder,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: context.radii.cardBorder,
              border: Border.all(
                color: isSelected ? colors.borderSelected : colors.border,
                width: isSelected ? sizes.borderThick : sizes.borderHairline,
              ),
            ),
            padding: EdgeInsets.all(spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _RadioDot(isSelected: isSelected),
                SizedBox(width: spacing.md),
                // Expanded: titles and descriptions both wrap at 320 dp.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          Text(
                            mode.code,
                            style: context.type.dataMd.copyWith(
                              color: colors.dataMuted,
                            ),
                          ),
                          SizedBox(width: spacing.sm),
                          Expanded(
                            child: Text(
                              mode.title,
                              style: context.type.headingSm.copyWith(
                                color: colors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        mode.description,
                        style: context.type.bodySm.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The selection indicator.
///
/// Drawn rather than using Material's [Radio] so it takes its colours from the
/// app's tokens and matches the card's gold selected state exactly.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSizes sizes = context.sizes;

    return SizedBox(
      width: sizes.iconLg,
      height: sizes.iconLg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colors.statusActive : colors.borderStrong,
            width: isSelected ? sizes.borderThick : sizes.borderThin,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: context.spacing.md,
                  height: context.spacing.md,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.statusActive,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
