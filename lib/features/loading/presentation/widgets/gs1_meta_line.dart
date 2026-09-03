import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../domain/gs1_barcode.dart';

/// The monospaced detail line under a scan, with GS1 Application Identifiers
/// emphasised:
///
/// ```
/// (00)3600980000004404 · (10)MRD24L221 · EXP 2027-09
/// ```
///
/// Deliberately not `AppMetaRow`: that widget emphasises the *first* segment,
/// whereas this emphasises **every AI prefix** wherever it appears. Different
/// rule, so a different widget rather than a boolean bolted onto the shared one
/// (CLAUDE.md rule 2). It stays feature-local until a second feature needs it.
class Gs1MetaLine extends StatelessWidget {
  const Gs1MetaLine({super.key, required this.segments, this.maxLines = 1});

  final List<Gs1Segment> segments;
  final int maxLines;

  static const String _separator = '  ·  ';

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final AppColors colors = context.colors;
    final TextStyle aiStyle = context.type.dataSm.copyWith(
      color: colors.dataStrong,
    );
    final TextStyle valueStyle = context.type.dataSm.copyWith(
      color: colors.dataMuted,
    );

    final List<TextSpan> spans = <TextSpan>[];
    for (int i = 0; i < segments.length; i++) {
      if (i > 0) {
        spans.add(TextSpan(text: _separator, style: valueStyle));
      }
      final Gs1Segment segment = segments[i];
      if (segment.ai != null) {
        spans.add(TextSpan(text: '(${segment.ai})', style: aiStyle));
      }
      spans.add(TextSpan(text: segment.text, style: valueStyle));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
