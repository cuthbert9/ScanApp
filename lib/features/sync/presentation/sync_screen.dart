import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/errors/app_exception.dart';
import '../../../app/state/sync_controller.dart';
import '../../../domain/models/sync_mode.dart';
import '../../../domain/models/sync_status.dart';
import '../../../shared/widgets/widgets.dart';
import 'widgets/sync_mode_card.dart';
import 'widgets/sync_state_banner.dart';

/// The device's outbox: how captured work reaches the backend, and what is
/// still waiting.
///
/// Presentation only. The queue lives behind `SyncRepository` and is held by
/// `SyncController` in `app/state/`, because the tab badge and every screen
/// header read it too. Flushing here empties all of them at once, because they
/// are one provider rather than three copies.
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SyncStatus> async = ref.watch(syncControllerProvider);
    final SyncStatus? queue = async.value;

    return Scaffold(
      backgroundColor: context.colors.background,
      // The outer SafeArea keeps the pinned strip clear of the status bar
      // once it reaches the top — AppScreenHeader no longer carries that
      // padding itself (see its doc comment).
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: AppScreenHeader(
                title: 'Offline Sync',
                tripReference: queue?.tripReference ?? '—',
                hub: queue?.hub ?? '—',
                hasPendingSync: (queue?.pendingCount ?? 0) > 0,
                onBack: () => StatefulNavigationShell.of(context).goBranch(0),
                onSync: () =>
                    ref.read(syncControllerProvider.notifier).refresh(),
              ),
            ),
            AppPinnedSummary(
              startCollapsed: context.isCompactHeight,
              expanded: AppSummaryStrip(
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
              collapsed: AppSummaryStrip(
                dense: true,
                cells: <Widget>[
                  AppSummaryCompactLine(
                    items: <AppSummaryCompactItem>[
                      AppSummaryCompactItem(
                        value: '${queue?.pendingCount ?? 0}',
                        label: 'Pending',
                        accent: (queue?.pendingCount ?? 0) > 0
                            ? StatAccent.warning
                            : StatAccent.none,
                      ),
                      AppSummaryCompactItem(
                        value: '${queue?.failedCount ?? 0}',
                        label: 'Failed',
                        accent: (queue?.failedCount ?? 0) > 0
                            ? StatAccent.warning
                            : StatAccent.none,
                      ),
                      AppSummaryCompactItem(
                        value: queue?.lastPushLabel ?? '—',
                        label: 'Last push',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Scrolls with the body now rather than staying pinned above it —
            // still ahead of the mode cards, so the "what is it doing right
            // now" line is read before the three options that set it.
            if (queue != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.spacing.md,
                    context.spacing.md,
                    context.spacing.md,
                    context.spacing.none,
                  ),
                  child: SyncStateBanner(
                    modeTitle: queue.mode.title,
                    state: queue.state,
                  ),
                ),
              ),
            switch (async) {
              AsyncData<SyncStatus>(:final SyncStatus value) => _SyncBody(
                queue: value,
              ),
              AsyncError<SyncStatus>(:final Object error) => _SyncError(
                error: error,
              ),
              _ => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            SliverToBoxAdapter(
              child: AppBottomActionBar(
                secondaryLabel: 'Back',
                // Back returns to Orders, per the navigation graph.
                onSecondary: () =>
                    StatefulNavigationShell.of(context).goBranch(0),
                primaryLabel: (queue?.isPushing ?? false)
                    ? 'Pushing…'
                    : 'Flush queue now',
                // Disabled when nothing to send, or a push is already running.
                onPrimary: (queue?.canFlush ?? false)
                    ? () => ref.read(syncControllerProvider.notifier).flush()
                    : (queue == null || queue.pending.isEmpty)
                    ? null
                    // Disabled for a reason the operator can act on —
                    // air-gapped mode, or the debug offline switch — so say
                    // which.
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            queue.simulateOffline
                                ? 'Simulated offline is on. Turn it off to '
                                      'flush.'
                                : queue.mode.flushBlockedReason,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBody extends ConsumerWidget {
  const _SyncBody({required this.queue});

  final SyncStatus queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSpacing spacing = context.spacing;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.md,
        spacing.md,
        spacing.xl,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate(<Widget>[
          AppSectionHeading(label: 'Sync mode', trailing: queue.tripReference),
          SizedBox(height: spacing.sm),
          for (final SyncMode mode in SyncMode.values) ...<Widget>[
            SyncModeCard(
              mode: mode,
              isSelected: queue.mode == mode,
              onSelect: () =>
                  ref.read(syncControllerProvider.notifier).setMode(mode),
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
                    value:
                        '${queue.lastPushLabel}  ·  ${queue.lastPushOutcome}',
                    accent: queue.lastPushAccepted
                        ? StatAccent.success
                        : StatAccent.warning,
                  ),
                  if (kDebugMode) ...<Widget>[
                    const Divider(height: 1),
                    // Debug only: watch scans pile up instead of being sent.
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'SIMULATE OFFLINE',
                        style: context.type.overline.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      value: queue.simulateOffline,
                      onChanged: (bool v) => ref
                          .read(syncControllerProvider.notifier)
                          .setSimulatedOffline(v),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),
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
                  ref.read(syncControllerProvider.notifier).refresh(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
