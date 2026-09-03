import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/design.dart';
import '../../../core/sync/application/sync_queue_controller.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/scan_session_controller.dart';
import '../domain/load_reconciliation.dart';
import 'widgets/meter_row.dart';

/// What goes on the truck versus what the manifest asked for, before sealing.
///
/// Every figure is derived from the same session the Scan tab writes to, so
/// scanning one more unit moves all of them at once. There is no second copy of
/// the truth to drift.
class LoadReconciliationScreen extends ConsumerWidget {
  const LoadReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LoadReconciliation? report = ref.watch(loadReconciliationProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: <Widget>[
          AppScreenHeader(
            title: 'Load Reconciliation',
            tripReference: report?.bay.toUpperCase() ?? '—',
            hub: report?.orderReference ?? '—',
            hasPendingSync: ref.watch(pendingSyncCountProvider) > 0,
            onSync: () =>
                ref.read(scanSessionControllerProvider.notifier).refresh(),
          ),
          AppSummaryStrip(
            cells: <Widget>[
              AppStatTile(value: '${report?.ordered ?? 0}', label: 'Ordered'),
              AppStatTile(
                value: '${report?.verified ?? 0}',
                label: 'Verified',
                accent: StatAccent.success,
              ),
              AppStatTile(
                value: '${report?.short ?? 0}',
                label: 'Short',
                accent: (report?.short ?? 0) > 0
                    ? StatAccent.warning
                    : StatAccent.none,
              ),
            ],
          ),
          Expanded(
            child: report == null
                ? const Center(child: CircularProgressIndicator())
                : _ReconciliationBody(report: report),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomActionBar(
        secondaryLabel: 'Back',
        onSecondary: () =>
            context.canPop() ? context.pop() : context.go(Routes.orders),
        primaryLabel: 'Seal load',
        onPrimary: report == null ? null : () {},
      ),
    );
  }
}

class _ReconciliationBody extends StatelessWidget {
  const _ReconciliationBody({required this.report});

  final LoadReconciliation report;

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final String yield =
        '${(report.firstPassYield * 100).toStringAsFixed(1)} %';

    return ListView(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.md,
        spacing.md,
        spacing.xl,
      ),
      children: <Widget>[
        AppSectionHeading(
          label: 'Reconciliation',
          trailing: report.orderReference,
        ),
        SizedBox(height: spacing.sm),
        Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.md),
            child: Column(
              children: <Widget>[
                AppDetailRow(
                  label: 'Ordered',
                  value: '${report.ordered} units',
                ),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'Verified onto truck',
                  value: '${report.verified} units',
                  accent: StatAccent.success,
                ),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'Short',
                  value: report.shortReason == null
                      ? '${report.short}'
                      : '${report.short}  ·  ${report.shortReason}',
                  accent: report.short > 0
                      ? StatAccent.warning
                      : StatAccent.none,
                ),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'Over / unexpected',
                  value: '${report.over}',
                  accent: report.over > 0
                      ? StatAccent.warning
                      : StatAccent.none,
                ),
                const Divider(height: 1),
                AppDetailRow(
                  label: 'First-pass yield',
                  value: yield,
                  emphasised: true,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: spacing.sectionGap),
        AppSectionHeading(
          label: 'Vehicle utilisation',
          trailing: report.vehicle.registration,
        ),
        SizedBox(height: spacing.sm),
        Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.md),
            child: Column(
              children: <Widget>[
                MeterRow(
                  label: 'Weight',
                  value:
                      '${_thousands(report.loadedWeightKg)} / '
                      '${_thousands(report.vehicle.maxWeightKg)} kg',
                  fraction: report.weightFraction,
                ),
                const Divider(height: 1),
                MeterRow(
                  label: 'Volume',
                  value:
                      '${report.loadedVolumeM3.toStringAsFixed(1)} / '
                      '${report.vehicle.maxVolumeM3.toStringAsFixed(1)} m³',
                  fraction: report.volumeFraction,
                ),
                const Divider(height: 1),
                MeterRow(
                  label: 'Reefer compartment',
                  value: report.temperatureC == null
                      ? 'No reading'
                      : '${report.temperatureC!.toStringAsFixed(1)} °C  ·  '
                            '${report.isTemperatureStable ? 'stable' : 'out of band'}',
                  fraction: report.temperatureFraction,
                  accent: report.isTemperatureStable
                      ? MeterAccent.coldChain
                      : MeterAccent.alert,
                ),
              ],
            ),
          ),
        ),
        if (!report.isClean) ...<Widget>[
          SizedBox(height: spacing.sectionGap),
          AppInfoPanel(
            variant: AppNoticeVariant.warning,
            message:
                'Sealing sends the short line to the dispatcher as an '
                'amended manifest. The delivery note will print '
                '${report.verified} lines, not ${report.ordered}.',
          ),
        ],
      ],
    );
  }

  /// `2986` becomes `2 986` — a thin space every three digits, so an operator
  /// reads the magnitude at a glance rather than counting characters.
  static String _thousands(double value) {
    final String digits = value.round().toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(' ');
      out.write(digits[i]);
    }
    return out.toString();
  }
}
