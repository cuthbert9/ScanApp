import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// A section divider with a label, a rule, and an optional status on the right:
///
/// ```
/// SCAN FEED ─────────────────────── NEWEST FIRST
/// ```
///
/// Promoted from the orders feature when the scan feed needed the same shape.
class AppSectionHeading extends StatelessWidget {
  const AppSectionHeading({super.key, required this.label, this.trailing});

  final String label;

  /// Right-aligned status, e.g. `BAY OPEN`, `NEWEST FIRST`.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Row(
      children: <Widget>[
        // Flexible, not Expanded: the label takes only what it needs so the
        // rule fills the gap, but still ellipsises rather than overflowing.
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: context.type.overline.copyWith(color: colors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
            child: Divider(color: colors.border),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!.toUpperCase(),
            style: context.type.overline.copyWith(color: colors.textTertiary),
            maxLines: 1,
          ),
      ],
    );
  }
}
