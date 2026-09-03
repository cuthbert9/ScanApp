import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// How loudly an [AppInfoPanel] speaks.
enum AppNoticeVariant {
  /// Neutral context — why a list is short, what will populate it.
  info,

  /// A consequence the operator should read before acting.
  warning,

  /// Something is wrong and needs resolving.
  danger,
}

/// An explanatory panel — why a list is short, what an action will do, what the
/// operator is waiting on.
///
/// Use for context that *persists* on screen. For transient confirmation of an
/// action, use a snackbar: a panel that appears and vanishes on every scan is
/// noise at three hundred scans a shift.
class AppInfoPanel extends StatelessWidget {
  const AppInfoPanel({
    super.key,
    required this.message,
    this.variant = AppNoticeVariant.info,
    this.icon,
  });

  final String message;
  final AppNoticeVariant variant;

  /// Overrides the icon the variant would pick.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    final (
      Color background,
      Color foreground,
      Color iconColor,
      IconData glyph,
    ) = switch (variant) {
      AppNoticeVariant.info => (
        colors.surfaceSunken,
        colors.textSecondary,
        colors.textTertiary,
        Icons.info_outline,
      ),
      AppNoticeVariant.warning => (
        colors.statusBlockedSurface,
        colors.onStatusBlockedSurface,
        colors.onStatusBlockedSurface,
        Icons.warning_amber_rounded,
      ),
      AppNoticeVariant.danger => (
        colors.dangerSurface,
        colors.onDangerSurface,
        colors.onDangerSurface,
        Icons.error_outline,
      ),
    };

    return Container(
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: context.radii.cardBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon ?? glyph, size: context.sizes.iconMd, color: iconColor),
          SizedBox(width: context.spacing.sm),
          // Expanded, not a bare Text: a Text directly inside a Row is the most
          // common overflow in Flutter (CLAUDE.md rule 1c).
          Expanded(
            child: Text(
              message,
              style: context.type.bodySm.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
