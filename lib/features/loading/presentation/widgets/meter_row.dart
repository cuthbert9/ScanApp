import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// What a [MeterRow] is measuring, which decides its colour.
enum MeterAccent {
  /// Capacity against a limit — weight, volume.
  capacity,

  /// A temperature holding inside its band.
  coldChain,

  /// Out of range and needing attention.
  alert,
}

/// A labelled measurement with a bar beneath it.
///
/// ```
/// Weight                          2 986 / 8 000 kg
/// ████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
/// ```
///
/// [fraction] is 0 to 1 and is what the bar draws; [value] is the text, which
/// the caller formats. The two are separate because the reefer meter's bar
/// shows position within a temperature band while its text shows the reading.
class MeterRow extends StatelessWidget {
  const MeterRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    this.accent = MeterAccent.capacity,
  });

  final String label;
  final String value;
  final double fraction;
  final MeterAccent accent;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    final Color barColor = switch (accent) {
      MeterAccent.capacity => colors.primary,
      MeterAccent.coldChain => colors.coldChain,
      MeterAccent.alert => colors.danger,
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: context.type.headingSm.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: context.spacing.sm),
              // Flexible so a long reading ellipsises rather than overflowing
              // the row at font scale 1.3.
              Flexible(
                child: Text(
                  value,
                  style: context.type.dataMd.copyWith(color: colors.dataMuted),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          ClipRRect(
            borderRadius: context.radii.pillBorder,
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: context.sizes.progressBarHeight,
              backgroundColor: colors.progressTrack,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}
