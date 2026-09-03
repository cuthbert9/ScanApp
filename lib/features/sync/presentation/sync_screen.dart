import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/design.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/sync/application/sync_queue_controller.dart';
import '../../../core/sync/domain/sync_mode.dart';
import '../../../core/sync/domain/sync_queue.dart';
import '../../../shared/widgets/widgets.dart';
import 'widgets/sync_mode_card.dart';
import 'widgets/sync_state_banner.dart';

/// The device's outbox: how captured work reaches the backend, and what is
/// still waiting.
///
/// Presentation only. The queue itself lives in `core/sync/`, because the tab
/// badge and the scan header read it too and a feature must never import
/// another feature (CLAUDE.md rule 3). Flushing here empties the badge without
/// either side knowing about the other.
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SyncQueue> async = ref.watch(syncQueueControllerProvider);
    final SyncQueue? queue = async.value;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: <Widget>[
          AppScreenHeader(
            title: 'Offline Sync',
            tripReference: queue?.tripReference ?? '—',
            hub: queue?.hub ?? '—',
            hasPendingSync: (queue?.pendingCount ?? 0) > 0,
            onSync: () =>
                ref.read(syncQueueControllerProvider.notifier).refresh(),
          ),
          AppSummaryStrip(
            cells: <Widget>[
              AppStatTile(
                value: '${queue?.pendingCount ?? 0}',
                label: 'Pending',
                accent: (queue?.pendingCount ?? 0) > 0
                    ? StatAccent.warning
                    : StatAccent.none,
              ),
              AppStatTile(
                value: '${queue?.failedCount ?? 0}',
                label: 'Failed',
                accent: (queue?.failedCount ?? 0) > 0
                    ? StatAccent.warning
                    : StatAccent.none,
              ),
              AppStatTile(
                value: queue?.lastPushLabel ?? '—',
                label: 'Last push',
              ),
            ],
          ),
          // Pinned rather than scrolled with the body: this shows what the
          // current mode is doing, and an operator comparing the three options
          // needs it in view while they scroll past them. Dropped in a short
          // viewport, where the pinned chrome would not otherwise fit
          // (CLAUDE.md rule 1c).
          if (queue != null && !context.isCompactHeight)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.md,
                context.spacing.none,
                context.spacing.md,
                context.spacing.md,
              ),
              child: SyncStateBanner(
                modeTitle: queue.mode.title,
                state: queue.state,
              ),
            ),
          Expanded(
            child: switch (async) {
              AsyncData<SyncQueue>(:final SyncQueue value) => _SyncBody(
                queue: value,
              ),
              AsyncError<SyncQueue>(:final Object error) => _SyncError(
                error: error,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
      bottomNavigationBar: AppBottomActionBar(
        secondaryLabel: 'Back',
        onSecondary: () =>
            context.canPop() ? context.pop() : context.go(Routes.orders),
        primaryLabel: (queue?.isPushing ?? false)
            ? 'Pushing…'
            : 'Flush queue now',
        // Disabled when there is nothing to send, or a push is already running.
        onPrimary: (queue?.canFlush ?? false)
            ? () => ref.read(syncQueueControllerProvider.notifier).flush()
            : null,
      ),
    );
  }
}

class _SyncBody extends ConsumerWidget {
  const _SyncBody({required this.queue});

  final SyncQueue queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSpacing spacing = context.spacing;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.md,
        spacing.md,
        spacing.xl,
      ),
      children: <Widget>[
        AppSectionHeading(label: 'Sync mode', trailing: queue.tripReference),
        SizedBox(height: spacing.sm),
        for (final SyncMode mode in SyncMode.values) ...<Widget>[
          SyncModeCard(
            mode: mode,
            isSelected: queue.mode == mode,
            onSelect: () =>
                ref.read(syncQueueControllerProvider.notifier).selectMode(mode),
          ),
          SizedBox(height: spacing.sm),
        ],
        SizedBox(height: spacing.md),
        const AppSectionHeading(
          label: 'Local queue',
          trailing: 'AES-256 at rest',
        ),
        SizedBox(height: spacing.sm),
        Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.md),
            child: Column(
              children: <Widget>[
                AppDetailRow(
                  label: 'Pending upload',
                  value:
                      '${queue.pendingCount} '
                      '${queue.pendingCount == 1 ? 'scan' : 'scans'}',
                  accent: queue.pendingCount > 0
                      ? StatAccent.warning
                      : StatAccent.none,
                ),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'Oldest record',
                  value: queue.oldestRecordLabel,
                ),
                const Divider(height: 1),
                AppDetailRow(label: 'Payload', value: queue.payloadLabel),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'Last push',
                  value: '${queue.lastPushLabel}  ·  ${queue.lastPushOutcome}',
                  accent: queue.lastPushAccepted
                      ? StatAccent.success
                      : StatAccent.warning,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Failure state. Shows the operator-facing message, never the raw exception.
class _SyncError extends ConsumerWidget {
  const _SyncError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final String message = error is AppException
        ? (error as AppException).message
        : 'Could not read the local queue.';

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
                ref.read(syncQueueControllerProvider.notifier).refresh(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
