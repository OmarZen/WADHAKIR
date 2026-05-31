import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';

/// A polished numeric input that combines a directly-typeable centered field
/// with `−` / `+` stepper buttons. Designed to replace bare [TextField]s for
/// small integer settings (page counts, start page) so they match the app's
/// rounded, primary-tinted design language.
///
/// Pass an external [controller] to keep the field in sync with parent state;
/// the stepper rewrites its text on `−`/`+` taps and clamps to [min]..[max].
class NumberStepperField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  /// Optional trailing label (e.g. a unit). Rendered muted after the `+` button.
  final String? suffix;

  /// Optional external controller. When provided it is kept in sync with the
  /// current value; otherwise an internal controller is created.
  final TextEditingController? controller;

  const NumberStepperField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 9999,
    this.step = 1,
    this.suffix,
    this.controller,
  });

  @override
  State<NumberStepperField> createState() => _NumberStepperFieldState();
}

class _NumberStepperFieldState extends State<NumberStepperField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController(text: '${widget.value}');
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant NumberStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reflect external value changes when the field isn't being edited.
    if (!_focused && widget.value != _readText()) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    // Only dispose the controller we created ourselves.
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  int? _readText() => int.tryParse(_controller.text.trim());

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
    // Normalise (clamp + canonical text) when the user leaves the field.
    if (!_focusNode.hasFocus) {
      final normalised = (_readText() ?? widget.value).clamp(
        widget.min,
        widget.max,
      );
      _controller.text = '$normalised';
      if (normalised != widget.value) widget.onChanged(normalised);
    }
  }

  void _apply(int next) {
    final clamped = next.clamp(widget.min, widget.max);
    _controller.text = '$clamped';
    widget.onChanged(clamped);
  }

  void _onTyped(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) return; // wait for a valid number (or focus loss)
    final clamped = parsed.clamp(widget.min, widget.max);
    // Don't rewrite the text mid-edit (avoids caret jumps); just report value.
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final current = _readText() ?? widget.value;

    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.04),
        borderRadius: Radii.all(Radii.md),
        border: Border.all(
          color: _focused ? primary : primary.withValues(alpha: 0.25),
          width: _focused ? 1.6 : 1.0,
        ),
      ),
      child: Row(
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            color: primary,
            enabled: current > widget.min,
            onTap: () => _apply(current - widget.step),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: Spacing.md),
              ),
              onChanged: _onTyped,
            ),
          ),
          if (widget.suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: Text(
                widget.suffix!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          _StepperButton(
            icon: Icons.add_rounded,
            color: primary,
            enabled: current < widget.max,
            onTap: () => _apply(current + widget.step),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? color : color.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
