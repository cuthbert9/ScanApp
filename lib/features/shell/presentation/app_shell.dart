import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/sync/application/sync_queue_controller.dart';
import '../../../shared/widgets/widgets.dart';

/// One entry in the bottom navigation.
///
/// A plain data class rather than five hand-written tab widgets — the tabs
/// differ only in label, icon and destination.
@immutable
class _TabSpec {
  const _TabSpec({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Persistent chrome around the five tabs.
///
/// Wraps go_router's [StatefulNavigationShell], which keeps a separate
/// navigation stack per branch. That is why switching ORDERS → SCAN → ORDERS
/// returns you to the same scroll position: on a device where an operator works
/// a forty-item queue, losing your place mid-shift is a real cost.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Index order must match the branch order in the router.
  static const List<_TabSpec> _tabs = <_TabSpec>[
    _TabSpec(label: 'Orders', icon: Icons.list),
    _TabSpec(label: 'Scan', icon: Icons.qr_code_scanner),
    _TabSpec(label: 'Load', icon: Icons.local_shipping_outlined),
    _TabSpec(label: 'Sync', icon: Icons.sync),
    _TabSpec(label: 'Settings', icon: Icons.settings_outlined),
  ];

  /// The Sync tab carries the outstanding-work count.
  static const int _syncTabIndex = 3;

  void _onTap(int index) {
    // `initialLocation: true` when re-tapping the current tab pops that
    // branch back to its root — the standard "tap again to go home" gesture.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final int pending = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.border,
              width: context.sizes.borderHairline,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: context.sizes.tabBarHeight,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      spec: _tabs[i],
                      isSelected: navigationShell.currentIndex == i,
                      badgeCount: i == _syncTabIndex ? pending : 0,
                      onTap: () => _onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.spec,
    required this.isSelected,
    required this.badgeCount,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color tint = isSelected ? colors.primary : colors.textTertiary;

    return Semantics(
      selected: isSelected,
      button: true,
      label: spec.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(spec.icon, size: context.sizes.iconMd, color: tint),
                if (badgeCount > 0)
                  Positioned(
                    top: -context.spacing.sm,
                    right: -context.spacing.md,
                    child: AppCountBadge(count: badgeCount),
                  ),
              ],
            ),
            SizedBox(height: context.spacing.xxs),
            Text(
              spec.label.toUpperCase(),
              style: context.type.tabLabel.copyWith(color: tint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
