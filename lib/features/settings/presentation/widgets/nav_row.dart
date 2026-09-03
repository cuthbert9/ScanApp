import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// A tappable row that leads somewhere else, with a line explaining what will
/// happen when it does.
///
/// The subtitle is not decoration: `Change station` re-syncs bays and routes,
/// which an operator mid-shift needs to know before tapping it.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radii.cardBorder,
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: context.type.headingSm.copyWith(
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacing.xxs),
                    Text(
                      subtitle,
                      style: context.type.dataSm.copyWith(
                        color: colors.dataMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              Icon(
                Icons.chevron_right,
                size: context.sizes.iconLg,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
