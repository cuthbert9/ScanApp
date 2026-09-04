import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// Cold-chain confirmation for the consignment currently being loaded.
///
/// Shown only when the session actually contains a temperature-controlled unit.
/// A permanent banner that says nothing most of the time is chrome an operator
/// learns to ignore, which is exactly what you do not want from a temperature
/// warning.
class ColdChainBanner extends StatelessWidget {
  const ColdChainBanner({
    super.key,
    required this.temperatureC,
    required this.doorOpenSeconds,
    this.needsAttention = false,
    this.statusLabel = 'stable',
  });

  final double? temperatureC;
  final int? doorOpenSeconds;

  /// Derived on [ColdChainLog], not decided here — the door has been open too
  /// long, or a reading has left the band.
  final bool needsAttention;

  /// `stable`, `door open`, `excursion`.
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

    final List<String> readings = <String>[
      if (temperatureC != null) '${temperatureC!.toStringAsFixed(1)} °C',
      if (doorOpenSeconds != null) 'DOOR ${doorOpenSeconds}s',
      statusLabel.toUpperCase(),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),
      decoration: BoxDecoration(
        color: needsAttention
            ? colors.statusBlockedSurface
            : colors.coldChainSurface,
        borderRadius: context.radii.cardBorder,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.ac_unit,
            size: context.sizes.iconMd,
            color: needsAttention ? colors.warning : colors.coldChain,
            semanticLabel: 'Cold chain',
          ),
          SizedBox(width: spacing.sm),
          // Expanded so the label yields to the readings rather than pushing
          // them off a 320 dp row.
          Expanded(
            child: Text(
              needsAttention
                  ? 'Cold chain needs attention'
                  : 'Cold unit verified',
              style: context.type.labelMd.copyWith(
                color: colors.onColdChainSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Flexible, not a bare Text: at font scale 1.3 on a 320 dp row the
          // readings alone can exceed what is left and overflow the banner.
          if (readings.isNotEmpty)
            Flexible(
              child: Text(
                readings.join('  ·  '),
                style: context.type.dataSm.copyWith(color: colors.dataMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}
