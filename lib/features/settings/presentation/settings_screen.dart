import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/design.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/sync/application/sync_queue_controller.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/display_preferences.dart';
import '../application/preferences_controller.dart';
import '../application/settings_controller.dart';
import '../domain/settings_snapshot.dart';
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

    // The dialog awaited, so the screen may be gone by now.
    if (!context.mounted) return;
    ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SettingsSnapshot> async = ref.watch(
      settingsControllerProvider,
    );
    final SettingsSnapshot? data = async.value;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: <Widget>[
          AppScreenHeader(
            title: 'Settings',
            tripReference: data?.deviceSerial ?? '—',
            hub: data == null ? '—' : 'APP ${data.appVersion}',
            hasPendingSync: ref.watch(pendingSyncCountProvider) > 0,
            onSync: () =>
                ref.read(settingsControllerProvider.notifier).refresh(),
          ),
          AppSummaryStrip(
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
              AppStatTile(value: data?.onShiftLabel ?? '—', label: 'On shift'),
            ],
          ),
          Expanded(
            child: switch (async) {
              AsyncData<SettingsSnapshot>(:final SettingsSnapshot value) =>
                _SettingsBody(data: value),
              AsyncError<SettingsSnapshot>(:final Object error) =>
                _SettingsError(error: error),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
      bottomNavigationBar: AppBottomActionBar(
        secondaryLabel: 'Sign out',
        onSecondary: () => _signOut(context, ref),
        primaryLabel: 'Done',
        onPrimary: () =>
            context.canPop() ? context.pop() : context.go(Routes.orders),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.data});

  final SettingsSnapshot data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSpacing spacing = context.spacing;
    final AppThemeChoice theme = ref.watch(themePreferenceProvider);
    final AppTextScaleChoice textScale = ref.watch(textScalePreferenceProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.md,
        spacing.md,
        spacing.xl,
      ),
      children: <Widget>[
        OperatorCard(profile: data.profile),
        SizedBox(height: spacing.sectionGap),

        const AppSectionHeading(label: 'Shift performance', trailing: 'Today'),
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
          trailing: data.station.hasFix
              ? 'GPS locked  ·  ±${data.station.gpsAccuracyMetres} m'
              : 'No fix',
        ),
        SizedBox(height: spacing.sm),
        StationCard(station: data.station),
        SizedBox(height: spacing.sm),
        NavRow(
          title: 'Change station',
          subtitle: 'Re-syncs bays and routes from the dispatch map',
          onTap: () {},
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
                  child: SegmentedControl<AppThemeChoice>(
                    options: AppThemeChoice.values,
                    selected: theme,
                    labelOf: (AppThemeChoice c) => c.label,
                    onSelect: (AppThemeChoice c) =>
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
                  child: SegmentedControl<AppTextScaleChoice>(
                    options: AppTextScaleChoice.values,
                    selected: textScale,
                    labelOf: (AppTextScaleChoice c) => c.label,
                    onSelect: (AppTextScaleChoice c) => ref
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
                AppDetailRow(label: 'Input', value: data.scanner.input),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'Symbologies',
                  value: data.scanner.symbologiesLabel,
                ),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'Pass feedback',
                  value: data.scanner.passFeedback,
                ),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'Fail feedback',
                  value: data.scanner.failFeedback,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: spacing.sectionGap),

        AppSectionHeading(label: 'Session', trailing: data.shiftWindowLabel),
        SizedBox(height: spacing.sm),
        Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.md),
            child: Column(
              children: <Widget>[
                AppDetailRow(
                  label: 'Language',
                  value: data.session.languagesLabel,
                ),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'Idle lock',
                  value: data.session.idleLockLabel,
                ),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'Shift auto-close',
                  value: data.shiftAutoCloseLabel,
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
class _SettingsError extends ConsumerWidget {
  const _SettingsError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final String message = error is AppException
        ? (error as AppException).message
        : 'Could not load settings.';

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
                ref.read(settingsControllerProvider.notifier).refresh(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
