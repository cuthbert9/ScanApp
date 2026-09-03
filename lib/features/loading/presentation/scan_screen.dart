import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/sync/application/sync_queue_controller.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/scan_session_controller.dart';
import '../domain/scan_record.dart';
import '../domain/scan_session.dart';
import 'widgets/cold_chain_banner.dart';
import 'widgets/scan_feed_row.dart';
import 'widgets/scan_input_field.dart';
import 'widgets/scan_progress_strip.dart';

/// Scan units onto a truck and verify them against the manifest.
///
/// The scan field holds focus, so the keyboard is up almost all the time on
/// device. That is the layout's governing constraint: with ~280 dp of viewport
/// left, the full summary strip and the cold-chain banner do not fit alongside
/// the input, the feed and the actions. Both collapse while the keyboard is
/// visible — dropping optional chrome, never forking the layout
/// (CLAUDE.md rule 1c).
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ScanSession> async = ref.watch(
      scanSessionControllerProvider,
    );
    final ScanSession? session = async.value;
    final AppSpacing spacing = context.spacing;

    // Chrome is shed in two stages as vertical room disappears.
    //
    // `tight`: the keyboard is up — which on this screen is most of the time,
    // because the scan field holds focus. Collapses the summary strip and drops
    // the cold-chain banner, reclaiming roughly 110 dp.
    //
    // `minimal`: landscape with the keyboard up leaves about 140 dp, less than
    // the header, input and action bar need together. Everything except the
    // input and the feed goes — those are the two things an operator is
    // actually using mid-scan. It all returns when the keyboard closes.
    final bool tight = context.isKeyboardVisible || context.isCompactHeight;
    final bool minimal = context.isSeverelyConstrainedHeight;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: <Widget>[
          if (!minimal) ...<Widget>[
            AppScreenHeader(
              title: 'Scan & Verify',
              tripReference: session?.bay.toUpperCase() ?? '—',
              hub: session?.orderReference ?? '—',
              hasPendingSync: ref.watch(pendingSyncCountProvider) > 0,
              onSync: () =>
                  ref.read(scanSessionControllerProvider.notifier).refresh(),
            ),
            ScanProgressStrip(
              loaded: session?.loadedCount ?? 0,
              expected: session?.expectedUnits ?? 0,
              verified: session?.verifiedCount ?? 0,
              held: session?.heldCount ?? 0,
              compact: tight,
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.md,
              spacing.md,
              spacing.md,
              spacing.sm,
            ),
            child: ScanInputField(
              showLabel: !minimal,
              // The single entry point for scanned input. The DataWedge bridge
              // will call the same method.
              onSubmitted: (String raw) => ref
                  .read(scanSessionControllerProvider.notifier)
                  .submitScan(raw),
            ),
          ),
          if (!tight && (session?.hasColdChain ?? false))
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.md,
                spacing.none,
                spacing.md,
                spacing.sm,
              ),
              child: ColdChainBanner(
                temperatureC: session!.temperatureC,
                doorOpenSeconds: session.doorOpenSeconds,
              ),
            ),
          Expanded(
            child: switch (async) {
              AsyncData<ScanSession>(:final ScanSession value) => _ScanFeed(
                session: value,
              ),
              AsyncError<ScanSession>(:final Object error) => _ScanError(
                error: error,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
      // Hidden when there is no room: reconciling is not something you do
      // mid-scan, and it returns as soon as the keyboard closes.
      bottomNavigationBar: minimal
          ? null
          : AppBottomActionBar(
              secondaryLabel: 'Manifest',
              onSecondary: () {},
              primaryLabel: 'Reconcile',
              onPrimary: () {},
            ),
    );
  }
}

/// The feed itself: newest scan at the top.
class _ScanFeed extends StatelessWidget {
  const _ScanFeed({required this.session});

  final ScanSession session;

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = context.spacing;

    if (session.records.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(spacing.md),
        child: const AppInfoPanel(
          message:
              'Nothing scanned yet. Pull the trigger, or type a barcode '
              'above, to record the first unit.',
        ),
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
          child: const AppSectionHeading(
            label: 'Scan feed',
            trailing: 'Newest first',
          ),
        ),
        SizedBox(height: spacing.sm),
        Expanded(
          // builder, not a children list: the feed grows with every scan and
          // only the visible rows should be built.
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              spacing.md,
              spacing.none,
              spacing.md,
              spacing.md,
            ),
            itemCount: session.records.length,
            itemBuilder: (BuildContext context, int index) {
              final ScanRecord record = session.records[index];
              return Padding(
                padding: EdgeInsets.only(bottom: spacing.sm),
                child: ScanFeedRow(record: record),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Failure state. Shows the operator-facing message, never the raw exception.
class _ScanError extends ConsumerWidget {
  const _ScanError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final String message = error is AppException
        ? (error as AppException).message
        : 'Could not load the scanning session.';

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
                ref.read(scanSessionControllerProvider.notifier).refresh(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
