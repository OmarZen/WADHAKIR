import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/wird/wird_enums.dart';

/// Segmented chip selector for the tracking unit (صفحات / ربع / حزب / جزء).
class WirdUnitSelector extends StatelessWidget {
  final WirdUnit selected;
  final ValueChanged<WirdUnit> onChanged;

  const WirdUnitSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  String _label(BuildContext context, WirdUnit unit) {
    final l10n = context.l10n;
    switch (unit) {
      case WirdUnit.pages:
        return l10n?.translate('wird.unit_pages') ?? 'صفحات';
      case WirdUnit.rub:
        return l10n?.translate('wird.unit_rub') ?? 'ربع (ربع جزء)';
      case WirdUnit.hizb:
        return l10n?.translate('wird.unit_hizb') ?? 'حزب (نصف جزء)';
      case WirdUnit.juz:
        return l10n?.translate('wird.unit_juz') ?? 'جزء';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: WirdUnit.values.map((unit) {
        final isSelected = unit == selected;
        return ChoiceChip(
          label: Text(_label(context, unit)),
          selected: isSelected,
          onSelected: (_) => onChanged(unit),
          showCheckmark: true,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
          selectedColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        );
      }).toList(),
    );
  }
}
