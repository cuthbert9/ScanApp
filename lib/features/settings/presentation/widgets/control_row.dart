import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// A settings line whose value is a control rather than text.
///
/// The label sits **above** the control rather than beside it. Side by side is
/// what the design shows, but a three-option segmented control plus its label
/// does not fit in 272 dp of card width — and at font scale 1.3 it overflowed
/// by 182 px. Stacking gives the control the full width, so its segments stay
/// full-size tap targets instead of being squeezed to `Nig…`.
///
/// The text-valued sibling is `AppDetailRow`.
class ControlRow extends StatelessWidget {
  const ControlRow({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: context.type.overline.copyWith(
              color: context.colors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: context.spacing.sm),
          child,
        ],
      ),
    );
  }
}
