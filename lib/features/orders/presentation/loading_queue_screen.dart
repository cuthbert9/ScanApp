import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/dock_controller.dart';
import '../../../app/state/dock_state.dart';
import '../../../app/state/sync_controller.dart';
import '../../../core/design/design.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/order.dart';
import '../../../shared/widgets/widgets.dart';
import 'widgets/order_card.dart';
import 'widgets/queue_summary_strip.dart';

/// The home screen: what is staged at this bay and what to load next.
///
/// Holds no figures of its own. The counts, the selection and the open order
/// all live in [DockController], which is why they agree with Scan and Load.
class LoadingQueueScreen extends ConsumerWidget {
  const LoadingQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DockState> dock = ref.watch(dockControllerProvider);
    final DockState? state = dock.value;
    final Order? selected = state?.selected;

    final int orderCount = state?.orderCount ?? 0;
    final int unitCount = state?.totalUnits ?? 0;
    final int coldChainCount = state?.coldChainCount ?? 0;

    return Scaffold(
      backgroundColor: context.colors.background,
      // The header and dashboard scroll with the page; only the dashboard
      // sticks — and shrinks to one line — once it reaches the top
      // (CLAUDE.md rule 1c: this is what buys back vertical room on a
      // 320x533 canvas).
      body: RefreshIndicator(
        onRefresh: () => ref.read(dockControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: AppScreenHeader(
                title: 'Loading Queue',
                tripReference:
                    ref.watch(syncControllerProvider).value?.tripReference ??
                    '—',
                hub: ref.watch(syncControllerProvider).value?.hub ?? '—',
                hasPendingSync: ref.watch(pendingSyncCountProvider) > 0,
                onSync: () =>
                    ref.read(dockControllerProvider.notifier).refresh(),
              ),
            ),
            AppPinnedSummary(
              startCollapsed: context.isCompactHeight,
              expanded: QueueSummaryStrip(
                orderCount: orderCount,
                unitCount: unitCount,
                coldChainCount: coldChainCount,
              ),
              collapsed: AppSummaryStrip(
                dense: true,
                cells: <Widget>[
                  AppSummaryCompactLine(
                    items: <AppSummaryCompactItem>[
                      AppSummaryCompactItem(
                        value: '$orderCount',
                        label: 'Orders',
                      ),
                      AppSummaryCompactItem(
                        value: '$unitCount',
                        label: 'Units',
                      ),
                      AppSummaryCompactItem(
                        value: '$coldChainCount',
                        label: 'Cold chain',
                        accent: coldChainCount > 0
                            ? StatAccent.coldChain
                            : StatAccent.none,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            switch (dock) {
              AsyncData<DockState>(:final DockState value) => _QueueBody(
                state: value,
              ),
              AsyncError<DockState>(:final Object error) => _QueueError(
                error: error,
              ),
              _ => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            // Populated without a tap — it defaults to whichever order is being
            // loaded — because the operator's hands are usually full. Scrolls
            // with the content rather than staying pinned, per the same rule.
            if (selected != null)
              SliverToBoxAdapter(
                child: AppBottomActionBar(
                  primaryLabel: 'Open',
                  primaryDetail: selected.docNo,
                  // Opening sets the Scan tab active; Scan reads the same
                  // selection, so it needs no route parameter. It deliberately
                  // does NOT mark the load viewed — sealing requires actually
                  // opening the reconciliation screen.
                  onPrimary: () => navigateToScan(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Switches to the Scan branch. Kept separate so the intent is legible.
  static void navigateToScan(BuildContext context) =>
      StatefulNavigationShell.of(context).goBranch(1);
}

class _QueueBody extends ConsumerWidget {
  const _QueueBody({required this.state});

  final DockState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSpacing spacing = context.spacing;

    if (state.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: const AppInfoPanel(
            message:
                'Nothing staged to this bay. Orders appear here once '
                'Warehouse Management releases the pick and stages the '
                'pallets.',
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            spacing.md,
            spacing.md,
            spacing.md,
            spacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: AppSectionHeading(
              label: 'Staged to Dock ${state.station.assignedBay}',
              trailing: state.station.insideGeofence
                  ? 'Bay open'
                  : 'Bay closed',
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
          sliver: SliverList.builder(
            itemCount: state.staged.length,
            itemBuilder: (BuildContext context, int index) {
              final Order order = state.staged[index];
              return Padding(
                padding: EdgeInsets.only(bottom: spacing.sm),
                child: OrderCard(
                  order: order,
                  isSelected: order.docNo == state.selectedDocNo,
                  // Tapping selects; it does not navigate.
                  onTap: () => ref
                      .read(dockControllerProvider.notifier)
                      .select(order.docNo),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            spacing.md,
            spacing.xs,
            spacing.md,
            spacing.xl,
          ),
          sliver: const SliverToBoxAdapter(
            child: AppInfoPanel(
              message:
                  'Orders appear here once Warehouse Management '
                  'releases the pick and stages the pallets to this bay.',
            ),
          ),
        ),
      ],
    );
  }
}

/// Failure state. Shows the operator-facing message, never the raw exception.
class _QueueError extends ConsumerWidget {
  const _QueueError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final String message = error is AppException
        ? (error as AppException).message
        : 'Could not load the queue.';

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.cloud_off_outlined,
              size: context.sizes.iconXl,
              color: colors.textTertiary,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              message,
              style: context.type.bodyMd.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.lg),
            OutlinedButton(
              onPressed: () =>
                  ref.read(dockControllerProvider.notifier).refresh(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
