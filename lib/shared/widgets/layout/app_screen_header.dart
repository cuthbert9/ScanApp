import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// The navy band at the top of a screen: title, a monospaced context line, and
/// the sync action.
///
/// Promoted here from the orders feature once the scan screen needed the same
/// header. Two features now use it and it carries no feature-specific logic,
/// which is exactly the bar for `lib/shared/` (CLAUDE.md rule 2).
class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    required this.tripReference,
    required this.hub,
    required this.hasPendingSync,
    required this.onSync,
    this.onBack,
  });

  final String title;

  /// Left half of the monospaced context line — a trip reference, a bay.
  final String tripReference;

  /// Right half — a hub code, an order number.
  final String hub;

  /// Draws the amber dot on the sync control.
  final bool hasPendingSync;

  final VoidCallback onSync;

  /// Null on a tab root, where there is nothing to go back to.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

    return ColoredBox(
      color: colors.headerSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            onBack == null ? spacing.lg : spacing.xs,
            spacing.sm,
            spacing.xs,
            spacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left),
                  color: colors.onHeader,
                  iconSize: context.sizes.iconLg,
                  tooltip: 'Back',
                ),
              // Expanded so a long title ellipsises instead of overflowing the
              // row on a 320 dp screen.
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: spacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        style: context.type.headingMd.copyWith(
                          color: colors.onHeader,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacing.xxs),
                      Text(
                        '$tripReference  ·  $hub',
                        style: context.type.overline.copyWith(
                          color: colors.onHeaderMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              _SyncAction(hasPending: hasPendingSync, onPressed: onSync),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sync control with an unsynced-work indicator.
///
/// A private widget class rather than a `_buildSync()` method: a method does
/// not get its own element, so it defeats `const` and rebuild isolation.
class _SyncAction extends StatelessWidget {
  const _SyncAction({required this.hasPending, required this.onPressed});

  final bool hasPending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSizes sizes = context.sizes;

    return IconButton(
      onPressed: onPressed,
      iconSize: sizes.iconLg,
      color: colors.onHeader,
      tooltip: hasPending ? 'Sync — changes pending' : 'Sync',
      icon: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Icon(Icons.sync),
          if (hasPending)
            Positioned(
              top: -context.spacing.xs,
              right: -context.spacing.xs,
              child: Container(
                width: context.spacing.sm,
                height: context.spacing.sm,
                decoration: BoxDecoration(
                  color: colors.badgeSurface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
