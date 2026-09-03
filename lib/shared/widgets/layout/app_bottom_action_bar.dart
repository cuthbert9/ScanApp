import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// The pinned action bar at the bottom of a screen, above the tab bar.
///
/// Two shapes, because two screens need them:
///
/// * **One action** — full width, with an optional monospaced detail after the
///   label (`Open  DO-2026-04417`).
/// * **Two actions** — a secondary outlined button beside a primary filled one
///   (`Manifest` / `Reconcile`).
///
/// Buttons inherit their height from `AppTheme` (56 dp, sized for gloves), so
/// nothing here restates styling.
class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryDetail,
    this.secondaryLabel,
    this.onSecondary,
  }) : assert(
         (secondaryLabel == null) == (onSecondary == null),
         'A secondary action needs both a label and a callback.',
       );

  final String primaryLabel;
  final VoidCallback? onPrimary;

  /// Monospaced value shown after [primaryLabel] — an order number, a code.
  /// Ignored when a secondary action is present; there is no room for both.
  final String? primaryDetail;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final bool hasSecondary = secondaryLabel != null;

    return Container(
      color: context.colors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: hasSecondary
            ? Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSecondary,
                      child: Text(
                        secondaryLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: onPrimary,
                      child: Text(
                        primaryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              )
            : FilledButton(
                onPressed: onPrimary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(primaryLabel, style: context.type.labelLg),
                    if (primaryDetail != null) ...<Widget>[
                      SizedBox(width: context.spacing.sm),
                      // Flexible so a long code ellipsises rather than
                      // overflowing the button on a 320 dp screen.
                      Flexible(
                        child: Text(
                          primaryDetail!,
                          style: context.type.dataLg.copyWith(
                            color: context.colors.onPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
