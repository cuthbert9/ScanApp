import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../domain/operator_profile.dart';

/// Who is signed in: initials, name, staff number and role.
class OperatorCard extends StatelessWidget {
  const OperatorCard({super.key, required this.profile});

  final OperatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Row(
          children: <Widget>[
            _Avatar(initials: profile.initials),
            SizedBox(width: spacing.md),
            // Expanded: a long name plus a long role will not fit one line at
            // 320 dp, so this yields before the shift status does.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    profile.name,
                    style: context.type.headingSm.copyWith(
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacing.xxs),
                  Text(
                    '${profile.staffId}  ·  ${profile.role}',
                    style: context.type.dataSm.copyWith(
                      color: colors.dataMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.sm),
            Text(
              profile.isOnShift ? 'ON SHIFT' : 'OFF SHIFT',
              style: context.type.overline.copyWith(
                color: profile.isOnShift
                    ? colors.textSecondary
                    : colors.textTertiary,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final AppSizes sizes = context.sizes;
    return Container(
      width: sizes.controlLg,
      height: sizes.controlLg,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.headerSurface,
        borderRadius: context.radii.cardBorder,
      ),
      child: Text(
        initials,
        style: context.type.labelLg.copyWith(color: context.colors.onHeader),
        maxLines: 1,
      ),
    );
  }
}
