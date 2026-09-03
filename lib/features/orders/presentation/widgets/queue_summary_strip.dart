import 'package:flutter/material.dart';

import '../../../../shared/widgets/widgets.dart';

/// The `3 ORDERS · 41 UNITS · 2 COLD CHAIN` panel under the queue header.
///
/// Counts arrive already derived from the snapshot, so this widget holds no
/// logic and cannot disagree with the list below it.
class QueueSummaryStrip extends StatelessWidget {
  const QueueSummaryStrip({
    super.key,
    required this.orderCount,
    required this.unitCount,
    required this.coldChainCount,
  });

  final int orderCount;
  final int unitCount;
  final int coldChainCount;

  @override
  Widget build(BuildContext context) {
    return AppSummaryStrip(
      cells: <Widget>[
        AppStatTile(value: '$orderCount', label: 'Orders'),
        AppStatTile(value: '$unitCount', label: 'Units'),
        AppStatTile(
          value: '$coldChainCount',
          label: 'Cold chain',
          // The one figure that changes how the load is handled.
          accent: coldChainCount > 0 ? StatAccent.coldChain : StatAccent.none,
        ),
      ],
    );
  }
}
