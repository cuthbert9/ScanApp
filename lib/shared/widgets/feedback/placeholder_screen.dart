import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// A tab that exists in the navigation but has no implementation yet.
///
/// One parameterised widget rather than four near-identical stub screens, and
/// no `lib/features/<name>/` folder until there is real code to put in it.
/// When a tab becomes real, it gets its own feature slice and stops using this.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    this.note,
  });

  final String title;
  final IconData icon;

  /// One line on what this tab will do, so the screen is informative rather
  /// than merely empty.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        // Scrollable even though the content is short: at font scale 1.3 in
        // landscape there is very little height to work with.
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: context.spacing.xxl),
              Icon(
                icon,
                size: context.sizes.iconXl,
                color: colors.textTertiary,
              ),
              SizedBox(height: context.spacing.md),
              Text(
                title,
                style: context.type.headingSm.copyWith(
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                note ?? 'Not built yet.',
                style: context.type.bodySm.copyWith(color: colors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
