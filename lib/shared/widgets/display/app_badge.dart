import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// The visual weight of an [AppBadge], named by meaning rather than colour.
///
/// One enum rather than one widget per colour: `LoadingBadge`, `QueuedBadge`
/// and `NoTruckBadge` would differ only in which token they read, and would
/// have to be edited together forever (CLAUDE.md rule 2).
enum AppBadgeVariant {
  /// Work in progress — the gold accent.
  active,

  /// Waiting its turn. Deliberately quiet.
  pending,

  /// Cannot proceed until something changes.
  blocked,

  /// Finished successfully.
  success,

  /// Failed, or requires intervention.
  danger,
}

/// A short status pill: `LOADING`, `QUEUED`, `NO TRUCK`.
///
/// Use for the state of a *record*. For a count, use `AppCountBadge`; for a
/// message the operator must read, use `AppInfoPanel`.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.pending,
  });

  /// Rendered upper-case; pass it in natural case.
  final String label;

  final AppBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final (Color background, Color foreground) = switch (variant) {
      AppBadgeVariant.active => (
        colors.statusActiveSurface,
        colors.onStatusActiveSurface,
      ),
      AppBadgeVariant.pending => (
        colors.statusPendingSurface,
        colors.onStatusPendingSurface,
      ),
      AppBadgeVariant.blocked => (
        colors.statusBlockedSurface,
        colors.onStatusBlockedSurface,
      ),
      AppBadgeVariant.success => (
        colors.successSurface,
        colors.onSuccessSurface,
      ),
      AppBadgeVariant.danger => (colors.dangerSurface, colors.onDangerSurface),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: context.radii.badgeBorder,
      ),
      child: Text(
        label.toUpperCase(),
        style: context.type.labelSm.copyWith(color: foreground),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// A small numeric badge, for counts that sit on an icon — pending syncs,
/// unread work.
class AppCountBadge extends StatelessWidget {
  const AppCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final AppSizes sizes = context.sizes;
    return Container(
      constraints: BoxConstraints(
        minWidth: sizes.badgeMin,
        minHeight: sizes.badgeMin,
      ),
      padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
      decoration: BoxDecoration(
        color: context.colors.badgeSurface,
        shape: BoxShape.rectangle,
        borderRadius: context.radii.pillBorder,
      ),
      alignment: Alignment.center,
      child: Text(
        // A three-digit backlog is a problem to fix, not a number to render.
        count > 99 ? '99+' : '$count',
        style: context.type.labelSm.copyWith(
          color: context.colors.onBadgeSurface,
        ),
        maxLines: 1,
      ),
    );
  }
}
