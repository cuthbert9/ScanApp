import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../domain/models/sync_status.dart';

/// The active mode and what it is currently doing.
///
/// ```
/// Store & forward                          ACCUMULATING
/// ```
///
/// Sits directly above the mode list so the consequence of the current choice
/// is visible while an operator considers changing it.
class SyncStateBanner extends StatelessWidget {
  const SyncStateBanner({
    super.key,
    required this.modeTitle,
    required this.state,
  });

  final String modeTitle;
  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    final Color stateColor = switch (state) {
      SyncState.live => colors.success,
      SyncState.accumulating => colors.onStatusBlockedSurface,
      SyncState.archiving => colors.info,
      SyncState.pushing => colors.primary,
      SyncState.retrying => colors.danger,
      SyncState.upToDate => colors.textSecondary,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: context.radii.cardBorder,
      ),
      child: Row(
        children: <Widget>[
          // Expanded so a long mode name yields to the state word, which is the
          // part that changes and therefore the part worth reading.
          Expanded(
            child: Text(
              modeTitle,
              style: context.type.headingSm.copyWith(color: colors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: context.spacing.sm),
          Text(
            state.label.toUpperCase(),
            style: context.type.overline.copyWith(color: stateColor),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
