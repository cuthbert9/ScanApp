import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/dock_controller.dart';
import '../../../app/state/sync_controller.dart';
import '../../../core/design/design.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/cold_chain_log.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/scan_event.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/scan_controller.dart';
import 'widgets/cold_chain_banner.dart';
import 'widgets/scan_feed_row.dart';
import 'widgets/scan_input_field.dart';
import 'widgets/scan_progress_strip.dart';

/// Scan units onto a truck and verify them against the manifest.
///
/// Every figure comes from the open [Order] in the dock store, so a scan here
/// moves the queue card behind it and the reconciliation ledger ahead of it at
/// the same moment.
///
/// The scan field holds focus, so the keyboard is up almost all the time on
/// device. That is the layout's governing constraint — chrome is shed in two
/// stages as vertical room disappears (CLAUDE.md rule 1c).
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  /// Advances the reefer door timer. Lives and dies with this screen: the door
  /// is only open while someone is loading through it.
  Timer? _doorTimer;

  @override
  void initState() {
    super.initState();
    _doorTimer = Timer.periodic(ColdChainLog.tickInterval, (_) {
      ref
          .read(coldChainMonitorProvider.notifier)
          .tick(ColdChainLog.tickInterval.inSeconds);
    });
  }

  @override
  void dispose() {
    _doorTimer?.cancel();
    super.dispose();
  }

  void _toOrders() => StatefulNavigationShell.of(context).goBranch(0);

  void _toReconcile() {
    // Sealing is only enabled once this has happened.
    ref.read(dockControllerProvider.notifier).markLoadViewed();
    StatefulNavigationShell.of(context).goBranch(2);
  }

  @override
  Widget build(BuildContext context) {
    final Order? order = ref.watch(selectedOrderProvider);

    if (order == null) {
      return _NoOrderOpen(onChoose: _toOrders);
    }

    final AsyncValue<List<ScanEvent>> feed = ref.watch(scanFeedProvider);
    final AppSpacing spacing = context.spacing;

    final bool tight = context.isKeyboardVisible || context.isCompactHeight;
    final bool minimal = context.isSeverelyConstrainedHeight;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: <Widget>[
          if (!minimal) ...<Widget>[
            SliverToBoxAdapter(
              child: AppScreenHeader(
                title: 'Scan & Verify',
                tripReference:
                    'BAY ${ref.watch(dockControllerProvider).value?.station.assignedBay ?? '—'}',
                hub: order.docNo,
                hasPendingSync: ref.watch(pendingSyncCountProvider) > 0,
                onBack: _toOrders,
                onSync: () =>
                    ref.read(syncControllerProvider.notifier).refresh(),
              ),
            ),
            // The keyboard-driven compact mode (not enough room) and the new
            // scroll-driven one (scrolled past) both want the same one-line
            // form, so `tight` simply forces it on the expanded slot too.
            AppPinnedSummary(
              startCollapsed: tight,
              expandedExtent: context.sizes.scanProgressStripExpandedHeight,
              expanded: ScanProgressStrip(
                loaded: order.verifiedUnits,
                expected: order.units,
                verified: order.verifiedUnits,
                held: order.heldUnits,
                compact: tight,
              ),
              collapsed: ScanProgressStrip(
                loaded: order.verifiedUnits,
                expected: order.units,
                verified: order.verifiedUnits,
                held: order.heldUnits,
                compact: true,
              ),
            ),
          ],
          // The scan field is the primary hardware-trigger/DataWedge target,
          // so — unlike the header above it — it stays put right after the
          // pinned strip rather than scrolling away.
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.md,
                spacing.md,
                spacing.md,
                spacing.sm,
              ),
              // Long-press is the debug trigger standing in for a hardware
              // trigger pull; typing a code is the other debug path.
              child: GestureDetector(
                onLongPress: kDebugMode
                    ? () => ref.read(scanFeedProvider.notifier).simulate()
                    : null,
                child: ScanInputField(
                  showLabel: !minimal,
                  onSubmitted: (String raw) =>
                      ref.read(scanFeedProvider.notifier).scanCode(raw),
                ),
              ),
            ),
          ),
          // The banner watches the log itself, so the once-a-second tick
          // rebuilds a 40 dp strip rather than the whole screen and its feed.
          if (!tight) const SliverToBoxAdapter(child: _ColdChainStrip()),
          switch (feed) {
            AsyncData<List<ScanEvent>>(:final List<ScanEvent> value) =>
              _ScanFeedList(events: value),
            AsyncError<List<ScanEvent>>(:final Object error) => _ScanError(
              error: error,
            ),
            _ => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          },
          if (!minimal)
            SliverToBoxAdapter(
              child: AppBottomActionBar(
                secondaryLabel: 'Manifest',
                onSecondary: _toOrders,
                primaryLabel: 'Reconcile',
                onPrimary: _toReconcile,
              ),
            ),
        ],
      ),
      floatingActionButton: kDebugMode && !minimal
          ? FloatingActionButton.small(
              onPressed: () => ref.read(scanFeedProvider.notifier).simulate(),
              tooltip: 'Debug: simulate a trigger pull',
              child: const Icon(Icons.bolt),
            )
          : null,
    );
  }
}

/// The cold-chain banner, isolated so the door timer's tick does not rebuild
/// the feed beneath it.
class _ColdChainStrip extends ConsumerWidget {
  const _ColdChainStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColdChainLog? log = ref.watch(coldChainMonitorProvider).value;
    if (log == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.md,
        context.spacing.none,
        context.spacing.md,
        context.spacing.sm,
      ),
      child: ColdChainBanner(
        temperatureC: log.tempC,
        doorOpenSeconds: log.doorOpenSeconds,
        needsAttention: log.needsAttention,
        statusLabel: log.statusLabel,
      ),
    );
  }
}

/// Shown when the Scan tab is opened with nothing selected.
class _NoOrderOpen extends StatelessWidget {
  const _NoOrderOpen({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: context.spacing.xxl),
              Icon(
                Icons.qr_code_scanner,
                size: context.sizes.iconXl,
                color: colors.textTertiary,
              ),
              SizedBox(height: context.spacing.md),
              Text(
                'No order open',
                style: context.type.headingSm.copyWith(
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                'Choose one from the loading queue.',
                style: context.type.bodySm.copyWith(color: colors.textTertiary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.lg),
              FilledButton(
                onPressed: onChoose,
                child: const Text('Go to loading queue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanFeedList extends StatelessWidget {
  const _ScanFeedList({required this.events});

  final List<ScanEvent> events;

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = context.spacing;

    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: const AppInfoPanel(
            message:
                'Nothing scanned yet. Pull the trigger, or type a barcode '
                'above, to record the first unit.',
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.md,
              spacing.none,
              spacing.md,
              spacing.sm,
            ),
            child: const AppSectionHeading(
              label: 'Scan feed',
              trailing: 'Newest first',
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            spacing.md,
            spacing.none,
            spacing.md,
            spacing.md,
          ),
          sliver: SliverList.builder(
            itemCount: events.length,
            itemBuilder: (BuildContext context, int index) => Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: ScanFeedRow(event: events[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanError extends ConsumerWidget {
  const _ScanError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final String message = error is AppException
        ? (error as AppException).message
        : 'Could not load the scan feed.';

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
              onPressed: () => ref.invalidate(scanFeedProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
