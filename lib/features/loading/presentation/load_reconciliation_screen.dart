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
import '../application/load_controller.dart';
import 'widgets/meter_row.dart';

/// What goes on the truck versus what the manifest asked for, before sealing.
///
/// Reads the same open [Order] the Scan screen writes to, so every figure moves
/// the moment a line changes state. Nothing here is stored or recomputed.
class LoadReconciliationScreen extends ConsumerStatefulWidget {
  const LoadReconciliationScreen({super.key});

  @override
  ConsumerState<LoadReconciliationScreen> createState() =>
      _LoadReconciliationScreenState();
}

class _LoadReconciliationScreenState
    extends ConsumerState<LoadReconciliationScreen> {
  @override
  void initState() {
    super.initState();
    // Sealing is refused until the ledger has actually been looked at, so this
    // is where "viewed" is recorded — not when Reconcile was tapped.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dockControllerProvider.notifier).markLoadViewed();
    });
  }

  void _toScan() => StatefulNavigationShell.of(context).goBranch(1);
  void _toOrders() => StatefulNavigationShell.of(context).goBranch(0);

  Future<void> _seal(Order order) async {
    final AppException? error = await ref
        .read(loadControllerProvider.notifier)
        .seal();

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    // Confirm in place, then return to the queue where the order is gone.
    final int printed = order.verifiedUnits;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          order.shortUnits > 0
              ? 'Sealed as amended. The delivery note will print $printed '
                    'lines, not ${order.units}.'
              : 'Sealed. ${order.units} lines confirmed.',
        ),
      ),
    );
    _toOrders();
  }

  @override
  Widget build(BuildContext context) {
    final DockState? dock = ref.watch(dockControllerProvider).value;
    final Order? order = ref.watch(selectedOrderProvider);

    if (order == null) {
      return _NothingToReconcile(onChoose: _toOrders);
    }

    final bool canSeal = (dock?.hasViewedLoad ?? false) && order.canSeal;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: AppScreenHeader(
              title: 'Load Reconciliation',
              tripReference: 'BAY ${dock?.station.assignedBay ?? '—'}',
              hub: order.docNo,
              hasPendingSync: ref.watch(pendingSyncCountProvider) > 0,
              onBack: _toScan,
              onSync: () => ref.read(dockControllerProvider.notifier).refresh(),
            ),
          ),
          AppPinnedSummary(
            startCollapsed: context.isCompactHeight,
            expanded: AppSummaryStrip(
              cells: <Widget>[
                AppStatTile(value: '${order.units}', label: 'Ordered'),
                AppStatTile(
                  value: '${order.verifiedUnits}',
                  label: 'Verified',
                  accent: StatAccent.success,
                ),
                AppStatTile(
                  value: '${order.shortUnits}',
                  label: 'Short',
                  accent: order.shortUnits > 0
                      ? StatAccent.warning
                      : StatAccent.none,
                ),
              ],
            ),
            collapsed: AppSummaryStrip(
              dense: true,
              cells: <Widget>[
                AppSummaryCompactLine(
                  items: <AppSummaryCompactItem>[
                    AppSummaryCompactItem(
                      value: '${order.units}',
                      label: 'Ordered',
                    ),
                    AppSummaryCompactItem(
                      value: '${order.verifiedUnits}',
                      label: 'Verified',
                      accent: StatAccent.success,
                    ),
                    AppSummaryCompactItem(
                      value: '${order.shortUnits}',
                      label: 'Short',
                      accent: order.shortUnits > 0
                          ? StatAccent.warning
                          : StatAccent.none,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Ledger(order: order),
          SliverToBoxAdapter(
            child: AppBottomActionBar(
              secondaryLabel: 'Back',
              onSecondary: _toScan,
              primaryLabel: 'Seal load',
              onPrimary: canSeal ? () => _seal(order) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Ledger extends StatelessWidget {
  const _Ledger({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
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
          AppSectionHeading(label: 'Reconciliation', trailing: order.docNo),
          SizedBox(height: spacing.sm),
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: Column(
                children: <Widget>[
                  AppDetailRow(label: 'Ordered', value: '${order.units} units'),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Verified onto truck',
                    value: '${order.verifiedUnits} units',
                    accent: StatAccent.success,
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Short',
                    value: order.shortReason == null
                        ? '${order.shortUnits}'
                        : '${order.shortUnits}  ·  ${order.shortReason}',
                    accent: order.shortUnits > 0
                        ? StatAccent.warning
                        : StatAccent.none,
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'Over / unexpected',
                    value: '${order.overUnits}',
                    accent: order.overUnits > 0
                        ? StatAccent.warning
                        : StatAccent.none,
                  ),
                  const Divider(height: 1),
                  AppDetailRow(
                    label: 'First-pass yield',
                    value: '${order.firstPassLabel} %',
                    emphasised: true,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          AppSectionHeading(
            label: 'Vehicle utilisation',
            trailing: order.vehicle.plate,
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
                        '${_thousands(order.loadedWeightKg)} / '
                        '${_thousands(order.vehicle.maxWeightKg)} kg',
                    fraction: order.weightPct,
                  ),
                  const Divider(height: 1),
                  MeterRow(
                    label: 'Volume',
                    value:
                        '${order.loadedVolumeM3.toStringAsFixed(1)} / '
                        '${order.vehicle.maxVolumeM3.toStringAsFixed(1)} m³',
                    fraction: order.volumePct,
                  ),
                  if (order.vehicle.hasReefer) ...<Widget>[
                    const Divider(height: 1),
                    MeterRow(
                      label: 'Reefer compartment',
                      value:
                          '${order.vehicle.reeferTempC!.toStringAsFixed(1)} °C  ·  '
                          '${order.vehicle.temperatureInBand ? 'stable' : 'out of band'}',
                      fraction: order.vehicle.temperaturePosition,
                      accent: order.vehicle.temperatureInBand
                          ? MeterAccent.coldChain
                          : MeterAccent.alert,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (order.hasColdChainExcursion) ...<Widget>[
            SizedBox(height: spacing.sectionGap),
            const AppInfoPanel(
              variant: AppNoticeVariant.danger,
              message:
                  'A cold-chain excursion was recorded on this load. It '
                  'cannot be sealed until a supervisor clears it.',
            ),
          ] else if (!order.isClean) ...<Widget>[
            SizedBox(height: spacing.sectionGap),
            AppInfoPanel(
              variant: AppNoticeVariant.warning,
              message:
                  'Sealing sends the short line to the dispatcher as an '
                  'amended manifest. The delivery note will print '
                  '${order.verifiedUnits} lines, not ${order.units}.',
            ),
          ],
        ]),
      ),
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

/// Shown when the Load tab is opened with nothing selected.
class _NothingToReconcile extends StatelessWidget {
  const _NothingToReconcile({required this.onChoose});

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
                Icons.local_shipping_outlined,
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
