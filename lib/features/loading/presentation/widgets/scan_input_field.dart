import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// Where scans enter the app.
///
/// This is not only a development stand-in. Zebra's DataWedge has a
/// **keyboard-wedge** mode that types the decoded barcode into the focused
/// field and sends Enter — so on a real MC9450 this field receives genuine
/// hardware scans with no native code at all. It also stays useful once the
/// intent-broadcast bridge exists, because warehouse labels get torn and
/// someone has to key the number in.
///
/// It therefore keeps focus aggressively: after every submission the text is
/// cleared and focus is taken back, so a rapid sequence of trigger pulls never
/// lands in a field that has quietly lost focus.
class ScanInputField extends StatefulWidget {
  const ScanInputField({
    super.key,
    required this.onSubmitted,
    this.label = 'GS1-128 · SSCC',
    this.hint = 'Scan or type a barcode',
    this.showLabel = true,
  });

  final ValueChanged<String> onSubmitted;
  final String label;
  final String hint;

  /// Dropped when there is almost no vertical room — the field's own hint
  /// already says what to do.
  final bool showLabel;

  @override
  State<ScanInputField> createState() => _ScanInputFieldState();
}

class _ScanInputFieldState extends State<ScanInputField> {
  // Controllers are why this is a StatefulWidget.
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String value) {
    if (value.trim().isEmpty) return;
    widget.onSubmitted(value);
    _controller.clear();
    // Take focus back so the next trigger pull has somewhere to land.
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.showLabel) ...<Widget>[
          Text(
            widget.label.toUpperCase(),
            style: context.type.overline.copyWith(color: colors.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing.xs),
        ],
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          // Enter submits, so the whole flow works from the physical keypad
          // without touching the screen.
          onSubmitted: _submit,
          style: context.type.dataMd.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(
              Icons.qr_code_2,
              size: context.sizes.iconLg,
              color: colors.textSecondary,
            ),
            suffixIcon: IconButton(
              onPressed: () => _submit(_controller.text),
              icon: const Icon(Icons.keyboard_return),
              tooltip: 'Submit scan',
            ),
          ),
        ),
      ],
    );
  }
}
