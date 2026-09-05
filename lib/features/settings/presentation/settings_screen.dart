import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/dock_controller.dart';
import '../../../app/state/preferences_controller.dart';
import '../../../app/state/sync_controller.dart';
import '../../../core/design/design.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/display_choice.dart';
import '../../../domain/models/station.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/settings_controller.dart';
import 'widgets/control_row.dart';
import 'widgets/nav_row.dart';
import 'widgets/operator_card.dart';
import 'widgets/segmented_control.dart';
import 'widgets/station_card.dart';
import 'widgets/weekly_scan_chart.dart';

/// Operator, shift figures, station, device configuration — and the three
/// preferences that actually do something.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _toOrders(BuildContext context) =>
      StatefulNavigationShell.of(context).goBranch(0);

  /// Ends the shift.
  ///
  /// Signing out with work still in the outbox would strand it, so when the
  /// queue is non-empty this asks first. The count comes from the same provider
  /// the tab badge reads.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final int pending = ref.read(pendingSyncCountProvider);

    if (pending > 0) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Sign out with work pending?'),
          content: Text(
            '$pending ${pending == 1 ? 'record has' : 'records have'} not been '
            'pushed. They stay on this device until someone signs in and '
            'flushes the queue.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay signed in'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!context.mounted) return;
    ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SettingsView> async = ref.watch(
      settingsControllerProvider,
    );
    final SettingsView? data = async.value;

    final String onShiftLabel = ref.watch(onShiftLabelProvider);

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
                title: 'Settings',
                tripReference: data?.device.serial ?? '—',
                hub: data == null ? '—' : 'APP ${data.device.appVersion}',
                hasPendingSync: ref.watch(pendingSyncCountProvider) > 0,
                onBack: () => _toOrders(context),
                onSync: () =>
                    ref.read(settingsControllerProvider.notifier).refresh(),
              ),
            ),
            AppPinnedSummary(
              startCollapsed: context.isCompactHeight,
              expanded: AppSummaryStrip(
                cells: <Widget>[
                  AppStatTile(
                    value: '${data?.stats.unitsScanned ?? 0}',
                    label: 'Scans today',
                  ),
                  AppStatTile(
                    value: data?.stats.firstPassLabel ?? '—',
                    unit: '%',
                    label: 'First pass',
                    accent: StatAccent.success,
                  ),
                  AppStatTile(value: onShiftLabel, label: 'On shift'),
                ],
              ),
              collapsed: AppSummaryStrip(
                dense: true,
                cells: <Widget>[
                  AppSummaryCompactLine(
                    items: <AppSummaryCompactItem>[
                      AppSummaryCompactItem(
                        value: '${data?.stats.unitsScanned ?? 0}',
                        label: 'Scans today',
                      ),
                      AppSummaryCompactItem(
                        value: '${data?.stats.firstPassLabel ?? '—'}%',
                        label: 'First pass',
                        accent: StatAccent.success,
                      ),
                      AppSummaryCompactItem(
                        value: onShiftLabel,
                        label: 'On shift',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            switch (async) {
              AsyncData<SettingsView>(:final SettingsView value) =>
                _SettingsBody(data: value),
              AsyncError<SettingsView>(:final Object error) => _SettingsError(
                error: error,
              ),
              _ => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            SliverToBoxAdapter(
              child: AppBottomActionBar(
                secondaryLabel: 'Sign out',
                onSecondary: () => _signOut(context, ref),
                primaryLabel: 'Done',
                onPrimary: () => _toOrders(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.data});

  final SettingsView data;

  /// Offers the three mock stations. A sheet, not a screen — the brief adds no
  /// screens.
  Future<void> _changeStation(BuildContext context, WidgetRef ref) async {
    final List<Station> stations = await ref.read(
      availableStationsProvider.future,
    );
    if (!context.mounted) return;

    final String? code = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(context.spacing.md),
              child: const AppSectionHeading(
                label: 'Change station',
                trailing: 'Re-syncs bays',
              ),
            ),
            for (final Station s in stations)
              ListTile(
                title: Text(s.name),
                subtitle: Text(s.code),
                trailing: s.code == data.station.code
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(s.code),
              ),
          ],
        ),
      ),
    );

    if (code == null || code == data.station.code) return;

    // Switching re-syncs bays and routes and reloads the queue for the new
    // bay, so the dock store moves too — not just this screen.
    await ref.read(dockControllerProvider.notifier).selectStation(code);
    await ref.read(settingsControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSpacing spacing = context.spacing;
    final ThemeChoice theme = ref.watch(resolvedThemeChoiceProvider);
    final TextScaleChoice textScale = ref.watch(resolvedTextScaleProvider);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.md,
        spacing.md,
        spacing.xl,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate(<Widget>[
          OperatorCard(profile: data.officer),
          SizedBox(height: spacing.sectionGap),

          const AppSectionHeading(
            label: 'Shift performance',
            trailing: 'Today',
          ),
          SizedBox(height: spacing.sm),
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: Column(
                children: <Widget>[
                  AppDetailRow(
                    label: 'Units scanned',
                    value: '${data.stats.unitsScanned}',
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'First-pass accuracy',
                    value: '${data.stats.firstPassLabel} %',
                    accent: StatAccent.success,
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Cold-chain holds',
                    value: '${data.stats.coldChainHolds}',
                    accent: data.stats.coldChainHolds > 0
                        ? StatAccent.warning
                        : StatAccent.none,
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Median per unit',
                    value: '${data.stats.medianSecondsPerUnit} s',
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Loads sealed',
                    value: '${data.stats.loadsSealed}',
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: spacing.md),
                    child: WeeklyScanChart(
                      week: data.stats.week,
                      todayUnits: data.stats.todayUnits,
                      peakUnits: data.stats.peakUnits,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.sectionGap),

          AppSectionHeading(
            label: 'Station',
            trailing: 'GPS locked  ·  ±${data.station.gpsAccuracyMetres} m',
          ),
          SizedBox(height: spacing.sm),
          StationCard(station: data.station),
          SizedBox(height: spacing.sm),
          NavRow(
            title: 'Change station',
            subtitle: 'Re-syncs bays and routes from the dispatch map',
            onTap: () => _changeStation(context, ref),
          ),
          SizedBox(height: spacing.sectionGap),

          const AppSectionHeading(label: 'Display', trailing: 'NFR 4.3'),
          SizedBox(height: spacing.sm),
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: Column(
                children: <Widget>[
                  ControlRow(
                    label: 'Theme',
                    child: SegmentedControl<ThemeChoice>(
                      options: ThemeChoice.values,
                      selected: theme,
                      labelOf: (ThemeChoice c) => c.label,
                      onSelect: (ThemeChoice c) =>
                          ref.read(themePreferenceProvider.notifier).select(c),
                    ),
                  ),
                  const Divider(height: 1),
                  const AppDetailRow(
                    label: 'Auto switch',
                    value: 'Sunset  ·  ambient sensor',
                  ),
                  const Divider(height: 1),
                  ControlRow(
                    label: 'Text size',
                    child: SegmentedControl<TextScaleChoice>(
                      options: TextScaleChoice.values,
                      selected: textScale,
                      labelOf: (TextScaleChoice c) => c.label,
                      onSelect: (TextScaleChoice c) => ref
                          .read(textScalePreferenceProvider.notifier)
                          .select(c),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.sectionGap),

          const AppSectionHeading(label: 'Scanning', trailing: 'NFR 4.4'),
          SizedBox(height: spacing.sm),
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: Column(
                children: <Widget>[
                  AppDetailRow(label: 'Input', value: data.device.scannerInput),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Symbologies',
                    value: data.device.symbologiesLabel,
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Pass feedback',
                    value: data.device.passFeedback,
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Fail feedback',
                    value: data.device.failFeedback,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.sectionGap),

          AppSectionHeading(
            label: 'Session',
            trailing: data.officer.shiftWindowLabel,
          ),
          SizedBox(height: spacing.sm),
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: Column(
                children: <Widget>[
                  AppDetailRow(
                    label: 'Language',
                    value: data.device.languagesLabel,
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Idle lock',
                    value: data.device.idleLockLabel,
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Shift auto-close',
                    value: data.officer.shiftWindowLabel.split(' – ').last,
                  ),
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
class _SettingsError extends ConsumerWidget {
  const _SettingsError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final String message = error is AppException
        ? (error as AppException).message
        : 'Could not load settings.';

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
                  ref.read(settingsControllerProvider.notifier).refresh(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
