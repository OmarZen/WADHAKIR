import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/daily_inspiration_item.dart';
import 'package:wadhakir/features/daily_inspiration/cubit/daily_inspiration_cubit.dart';
import 'package:wadhakir/features/daily_inspiration/cubit/daily_inspiration_state.dart';

/// Settings for the "Verse/Dua of the Day": enable the daily notification, pick
/// its time, and choose which content type rotates.
class DailyInspirationSettingsPage extends StatelessWidget {
  const DailyInspirationSettingsPage({super.key});

  TimeOfDay _time(DailyInspirationState s) =>
      TimeOfDay(hour: s.settings.hour, minute: s.settings.minute);

  Future<void> _pickTime(BuildContext context, DailyInspirationState s) async {
    final cubit = context.read<DailyInspirationCubit>();
    final picked = await showTimePicker(
      context: context,
      initialTime: _time(s),
    );
    if (picked != null) {
      await cubit.updateTime(picked.hour, picked.minute);
    }
  }

  Future<void> _sendTest(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<DailyInspirationCubit>().sendTest();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (l10n?.translate('daily_inspiration.test_sent') ??
                    'تم إرسال تنبيه تجريبي')
              : (l10n?.translate('daily_inspiration.test_failed') ??
                    'تعذّر الإرسال — تحقّق من إذن الإشعارات'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.translate('daily_inspiration.settings_title') ??
              'آية وذِكر اليوم',
        ),
      ),
      body: BlocBuilder<DailyInspirationCubit, DailyInspirationState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n?.translate('daily_inspiration.settings_subtitle') ??
                      'تذكير يومي بآية أو دعاء أو حديث.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                FCard.raw(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.xs,
                    ),
                    child: Column(
                      children: [
                        FItem(
                          prefix: const Icon(Icons.notifications_active_outlined),
                          title: Text(
                            l10n?.translate('daily_inspiration.enable') ??
                                'تفعيل التذكير اليومي',
                          ),
                          suffix: FSwitch(
                            value: state.settings.enabled,
                            onChange: (v) =>
                                context.read<DailyInspirationCubit>().setEnabled(
                                  v,
                                ),
                          ),
                        ),
                        const Divider(height: 1),
                        FItem(
                          prefix: const Icon(Icons.alarm),
                          title: Text(
                            l10n?.translate('daily_inspiration.time') ??
                                'وقت التذكير',
                          ),
                          subtitle: Text(_time(state).format(context)),
                          onPress: () => _pickTime(context, state),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  l10n?.translate('daily_inspiration.content_type') ??
                      'نوع المحتوى',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                _ContentTypeSelector(
                  selected: state.settings.contentType,
                  onChanged: (t) =>
                      context.read<DailyInspirationCubit>().setContentType(t),
                ),
                const SizedBox(height: Spacing.xl),
                FButton(
                  onPress: () => _sendTest(context),
                  variant: FButtonVariant.outline,
                  prefix: const Icon(Icons.send_rounded, size: 18),
                  child: Text(
                    l10n?.translate('daily_inspiration.send_test') ??
                        'إرسال تنبيه تجريبي',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContentTypeSelector extends StatelessWidget {
  final DailyContentType selected;
  final ValueChanged<DailyContentType> onChanged;

  const _ContentTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    String label(DailyContentType t) {
      switch (t) {
        case DailyContentType.mixed:
          return l10n?.translate('daily_inspiration.type_mixed') ?? 'متنوّع';
        case DailyContentType.ayah:
          return l10n?.translate('daily_inspiration.type_ayah') ?? 'آية';
        case DailyContentType.dua:
          return l10n?.translate('daily_inspiration.type_dua') ?? 'دعاء';
        case DailyContentType.hadith:
          return l10n?.translate('daily_inspiration.type_hadith') ?? 'حديث';
      }
    }

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: DailyContentType.values.map((t) {
        final isSelected = t == selected;
        return InkWell(
          borderRadius: Radii.all(Radii.md),
          onTap: () => onChanged(t),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withValues(alpha: 0.14)
                  : primary.withValues(alpha: 0.03),
              borderRadius: Radii.all(Radii.md),
              border: Border.all(
                color: isSelected ? primary : primary.withValues(alpha: 0.2),
                width: isSelected ? 1.6 : 1.0,
              ),
            ),
            child: Text(
              label(t),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primary : theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
