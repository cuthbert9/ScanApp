import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// A summary strip that scrolls away with the header above it, then sticks
/// to the top of the screen and shrinks to its one-line form once it gets
/// there.
///
/// Drop-in replacement for placing a summary strip directly in a `Column`:
/// this returns a sliver, so it belongs inside a screen's `CustomScrollView`,
/// straight after the (now plain, scrolling) `AppScreenHeader` sliver.
///
/// [expanded] and [collapsed] are two renderings of the same figures — a
/// full `AppSummaryStrip`/`ScanProgressStrip` and a one-line
/// `AppSummaryCompactLine` — not two different states, so nothing here reads
/// the underlying data. That stays with the screen, which already has it.
///
/// [startCollapsed] skips the expanded form entirely, from the very first
/// frame — not just once scrolled. Scroll position starts at zero, so
/// without this a short viewport (landscape; the keyboard up) would still
/// spend the full expanded extent on first paint, before the operator has
/// scrolled anything. Screens pass their own "not enough room" condition —
/// `context.isCompactHeight`, or Scan's own `tight` — the same one they
/// already use to shed other optional chrome (CLAUDE.md rule 1c).
///
/// [expandedExtent] overrides `AppSizes.summaryStripExpandedHeight` for a
/// screen whose full form is a different height — Scan's progress ring is
/// taller than a plain stat tile.
class AppPinnedSummary extends StatelessWidget {
  const AppPinnedSummary({
    super.key,
    required this.expanded,
    required this.collapsed,
    this.startCollapsed = false,
    this.expandedExtent,
  });

  final Widget expanded;
  final Widget collapsed;
  final bool startCollapsed;
  final double? expandedExtent;

  @override
  Widget build(BuildContext context) {
    final AppSizes sizes = context.sizes;
    // Both extents are the strip's real, unstretched content height at text
    // scale 1.0 — not padded upfront — scaled here by the live text scale so
    // there is still room to grow without inflating the common case. Mirrors
    // the same `textScaler.scale(100)/100` technique `_TextScale` already
    // uses in `app/app.dart`.
    final double scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    final double collapsedExtent = sizes.summaryStripCollapsedHeight * scale;
    final double naturalExpandedExtent =
        (expandedExtent ?? sizes.summaryStripExpandedHeight) * scale;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedSummaryDelegate(
        expanded: startCollapsed ? collapsed : expanded,
        collapsed: collapsed,
        expandedExtent: startCollapsed
            ? collapsedExtent
            : naturalExpandedExtent,
        collapsedExtent: collapsedExtent,
        dividerColor: context.colors.headerDivider,
        hairline: sizes.borderHairline,
      ),
    );
  }
}

class _PinnedSummaryDelegate extends SliverPersistentHeaderDelegate {
  _PinnedSummaryDelegate({
    required this.expanded,
    required this.collapsed,
    required this.expandedExtent,
    required this.collapsedExtent,
    required this.dividerColor,
    required this.hairline,
  });

  final Widget expanded;
  final Widget collapsed;
  final double expandedExtent;
  final double collapsedExtent;
  final Color dividerColor;
  final double hairline;

  @override
  double get maxExtent => expandedExtent;

  @override
  double get minExtent => collapsedExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double range = expandedExtent - collapsedExtent;
    final double t = range <= 0 ? 1 : (shrinkOffset / range).clamp(0.0, 1.0);

    // Mid-crossfade the reserved box is briefly somewhere between the two
    // extents — shorter than the still-fading-out expanded form's natural
    // height. `OverflowBox` lets each form lay out at its own real size
    // regardless, rather than being squeezed into whatever height the
    // transition is passing through; the outer `ClipRect` trims the part of
    // that natural size that pokes out, so this never throws instead of
    // painting.
    return ClipRect(
      child: SizedBox(
        height: expandedExtent - shrinkOffset.clamp(0.0, range),
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            _NaturalHeight(opacity: 1 - t, child: expanded),
            _NaturalHeight(opacity: t, child: collapsed),
            // A hairline only once the strip has something to be separated
            // from — the same visual language `AppSummaryStrip` already uses
            // between its own cells.
            if (t > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(height: hairline, color: dividerColor),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedSummaryDelegate oldDelegate) {
    return oldDelegate.expanded != expanded ||
        oldDelegate.collapsed != collapsed ||
        oldDelegate.expandedExtent != expandedExtent ||
        oldDelegate.collapsedExtent != collapsedExtent;
  }
}

/// Lays [child] out at its own natural height, ignoring whatever (possibly
/// smaller, mid-transition) height the surrounding `Stack` is currently
/// passing down — the overflow this sidesteps is expected, not a bug: the
/// fading-out form briefly wants more room than the box has mid-crossfade.
class _NaturalHeight extends StatelessWidget {
  const _NaturalHeight({required this.opacity, required this.child});

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // A bare (non-`Positioned`) `Stack` child, so the enclosing `Stack`'s own
    // `alignment: topCenter` places it — `Positioned` here would opt this
    // out of that and needs explicit edges instead, which isn't the point.
    return OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: 0,
      maxHeight: double.infinity,
      child: Opacity(opacity: opacity, child: child),
    );
  }
}
