import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// A row of mutually exclusive options — `Day | Night | Auto`.
///
/// Segments share the width equally and each is a full-height tap target, so
/// there is no small hit area to miss with a gloved thumb.
///
/// Feature-local until a second feature needs it (CLAUDE.md rule 2).
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelOf;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Container(
      padding: EdgeInsets.all(context.spacing.xxs),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: context.radii.controlBorder,
      ),
      child: Row(
        children: <Widget>[
          for (final T option in options)
            // Expanded, and the Row is full width: segments share the space
            // equally so every one is the same size target. Flexible inside a
            // min-width Row let them keep their natural width and overflow.
            Expanded(
              child: _Segment(
                label: labelOf(option),
                isSelected: option == selected,
                onTap: () => onSelect(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        // The unselected segment takes the track's own colour rather than a
        // transparent fill — same result, no extra token.
        color: isSelected ? colors.surface : colors.surfaceSunken,
        borderRadius: context.radii.controlBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: context.radii.controlBorder,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.sm,
              vertical: context.spacing.sm,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: context.type.labelMd.copyWith(
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
