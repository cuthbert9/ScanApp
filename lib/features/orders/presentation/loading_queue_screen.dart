import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/sync/application/sync_queue_controller.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/loading_queue_controller.dart';
import '../domain/loading_order.dart';
import '../domain/loading_queue_snapshot.dart';
import 'widgets/order_card.dart';
import 'widgets/queue_summary_strip.dart';

/// The app's home screen: what is staged at this dock and what to load next.
///
/// Layout is deliberately split into a pinned head and a scrolling body. The
/// header, summary and primary action stay put; only the queue scrolls. At
/// three orders that matches the design exactly, and at forty — or in landscape
/// with 320 dp of height — it still works (CLAUDE.md rule 1c).
class LoadingQueueScreen extends ConsumerWidget {
  const LoadingQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LoadingQueueSnapshot> queue = ref.watch(
      loadingQueueControllerProvider,
    );
    final LoadingQueueSnapshot? snapshot = queue.value;
    final LoadingOrder? focused = ref.watch(focusedOrderProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: <Widget>[
          AppScreenHeader(
            title: 'Loading Queue',
            // Em dashes while the first fetch is in flight, so the header does
            // not jump as text appears.
            tripReference: snapshot?.tripReference ?? '—',
            hub: snapshot?.hub ?? '—',
            hasPendingSync: ref.watch(pendingSyncCountProvider) > 0,
            onSync: () =>
                ref.read(loadingQueueControllerProvider.notifier).refresh(),
          ),
          QueueSummaryStrip(
            orderCount: snapshot?.orderCount ?? 0,
            unitCount: snapshot?.unitCount ?? 0,
            coldChainCount: snapshot?.coldChainCount ?? 0,
          ),
          Expanded(
            child: switch (queue) {
              AsyncData<LoadingQueueSnapshot>(
                :final LoadingQueueSnapshot value,
              ) =>
                _QueueBody(snapshot: value),
              AsyncError<LoadingQueueSnapshot>(:final Object error) =>
                _QueueError(error: error),
              _ => const _QueueLoading(),
            },
          ),
        ],
      ),
      // Populated without a tap — it defaults to whichever order is being
      // loaded — because the operator's hands are usually full.
      bottomNavigationBar: focused == null
          ? null
          : AppBottomActionBar(
              primaryLabel: 'Open',
              primaryDetail: focused.id,
              onPrimary: () {},
            ),
    );
  }
}

/// The scrolling part: section header, the queue, and the explanatory panel.
class _QueueBody extends ConsumerWidget {
  const _QueueBody({required this.snapshot});

  final LoadingQueueSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSpacing spacing = context.spacing;
    final String? selectedId = ref.watch(focusedOrderProvider)?.id;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(loadingQueueControllerProvider.notifier).refresh(),
      child: CustomScrollView(
        // Always scrollable so pull-to-refresh works even when the queue is
        // short enough to fit.
        physics: const AlwaysScrollableScrollPhysics(),
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
                label: 'Staged to ${snapshot.dock}',
                trailing: snapshot.isBayOpen ? 'Bay open' : 'Bay closed',
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: spacing.md),
            sliver: SliverList.builder(
              itemCount: snapshot.orders.length,
              itemBuilder: (BuildContext context, int index) {
                final LoadingOrder order = snapshot.orders[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing.sm),
                  child: OrderCard(
                    order: order,
                    isSelected: order.id == selectedId,
                    onTap: () => ref
                        .read(selectedOrderProvider.notifier)
                        .select(order.id),
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
      ),
    );
  }
}

class _QueueLoading extends StatelessWidget {
  const _QueueLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Failure state.
///
/// Shows [AppException.message] — written for an operator — and never the raw
/// exception. Retry is a 56 dp target because it is tapped with gloves.
class _QueueError extends ConsumerWidget {
  const _QueueError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final String message = error is AppException
        ? (error as AppException).message
        : 'Could not load the queue.';

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing.xl),
      child: Column(
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
                ref.read(loadingQueueControllerProvider.notifier).refresh(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
