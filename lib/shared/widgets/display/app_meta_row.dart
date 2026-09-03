import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// A single line of machine-readable metadata, rendered monospaced and
/// separated by a middot:
///
/// ```
/// DO-2026-04417 · T 421 DKV · TZ-C-07 · 14 u · 3.2 t
/// ```
///
/// The first segment is the identifying value and is emphasised; the rest are
/// supporting detail. Monospace is not decorative — operators compare these
/// strings by eye, and proportional digits let a transposition hide.
///
/// The whole line is one text run, so it ellipsises as a unit rather than
/// wrapping into a ragged second line on a 320 dp screen.
class AppMetaRow extends StatelessWidget {
  const AppMetaRow({super.key, required this.segments, this.maxLines = 1});

  /// Ordered segments. The first is treated as the identifier.
  final List<String> segments;

  final int maxLines;

  static const String _separator = '  ·  ';

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final AppColors colors = context.colors;
    final TextStyle strong = context.type.dataMd.copyWith(
      color: colors.dataStrong,
    );
    final TextStyle muted = context.type.dataSm.copyWith(
      color: colors.dataMuted,
    );

    final List<TextSpan> spans = <TextSpan>[
      TextSpan(text: segments.first, style: strong),
    ];
    for (final String segment in segments.skip(1)) {
      spans
        ..add(TextSpan(text: _separator, style: muted))
        ..add(TextSpan(text: segment, style: muted));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
