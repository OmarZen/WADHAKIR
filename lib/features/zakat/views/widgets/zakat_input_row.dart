import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';

/// A labelled decimal money/weight input used throughout the Zakat form.
///
/// Label sits above a bordered, primary-tinted field (matching
/// [NumberStepperField]'s visual language). The field itself is forced LTR so
/// digits read naturally even inside the RTL Arabic layout, with an optional
/// trailing [suffix] (a unit or currency glyph).
class ZakatInputRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? suffix;
  final IconData? icon;
  final String? hint;

  const ZakatInputRow({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.suffix,
    this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final primary = cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: primary.withValues(alpha: 0.8)),
                const SizedBox(width: Spacing.xs),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Container(
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.04),
              borderRadius: Radii.all(Radii.md),
              border: Border.all(color: primary.withValues(alpha: 0.25)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: hint ?? '0',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: Spacing.md,
                      ),
                    ),
                  ),
                ),
                if (suffix != null && suffix!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: Spacing.sm),
                    child: Text(
                      suffix!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
