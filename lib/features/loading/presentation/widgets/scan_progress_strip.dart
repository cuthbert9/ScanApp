import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../shared/widgets/widgets.dart';

/// The load summary under the scan header: units loaded, verified, held.
///
/// Two forms. The full one carries a progress ring; [compact] is a single line
/// of text in one cell.
///
/// Compact is used when the keyboard is up. This screen keeps focus in the scan
/// field, so the keyboard is up almost all the time, and the full strip plus
/// the rest of the pinned chrome does not fit in the ~280 dp that leaves. This
/// is dropping optional chrome, not forking the layout (CLAUDE.md rule 1c).
class ScanProgressStrip extends StatelessWidget {
  const ScanProgressStrip({
    super.key,
    required this.loaded,
    required this.expected,
    required this.verified,
    required this.held,
    this.compact = false,
  });

  final int loaded;
  final int expected;
  final int verified;
  final int held;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return AppSummaryStrip(
        dense: true,
        cells: <Widget>[
          _CompactLine(
            loaded: loaded,
            expected: expected,
            verified: verified,
            held: held,
          ),
        ],
      );
    }

    return AppSummaryStrip(
      cells: <Widget>[
        AppStatRing(value: loaded, total: expected, label: 'Units loaded'),
        AppStatTile(
          value: '$verified',
          label: 'Verified',
          accent: StatAccent.success,
        ),
        AppStatTile(
          value: '$held',
          label: 'Held',
          accent: held > 0 ? StatAccent.warning : StatAccent.none,
        ),
      ],
    );
  }
}

class _CompactLine extends StatelessWidget {
  const _CompactLine({
    required this.loaded,
    required this.expected,
    required this.verified,
    required this.held,
  });

  final int loaded;
  final int expected;
  final int verified;
  final int held;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '$loaded/$expected loaded',
            style: context.type.labelMd.copyWith(color: colors.onHeader),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$verified ok',
          style: context.type.labelMd.copyWith(color: colors.success),
          maxLines: 1,
        ),
        SizedBox(width: context.spacing.sm),
        Text(
          '$held held',
          style: context.type.labelMd.copyWith(color: colors.statusActive),
          maxLines: 1,
        ),
      ],
    );
  }
}
