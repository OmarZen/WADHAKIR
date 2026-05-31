import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/features/wird/cubit/wird_cubit.dart';

/// Settings block on the progress screen: reminder time + enable toggle +
/// reset plan.
class WirdSettingsSection extends StatelessWidget {
  final WirdPlanModel plan;

  const WirdSettingsSection({super.key, required this.plan});

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 20,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final cubit = context.read<WirdCubit>();
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(plan.reminderTime),
    );
    if (picked != null) {
      final hhmm =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
      await cubit.updateReminderTime(hhmm);
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<WirdCubit>();
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        title: Text(l10n?.translate('wird.reset_plan') ?? 'إعادة ضبط الختمة؟'),
        body: Text(
          l10n?.translate('wird.reset_confirm') ??
              'سيؤدي هذا إلى حذف الخطة الحالية والتقدّم.',
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(ctx, true),
            child: Text(l10n?.translate('common.confirm') ?? 'تأكيد'),
          ),
          FButton(
            onPress: () => Navigator.pop(ctx, false),
            variant: FButtonVariant.outline,
            child: Text(l10n?.translate('common.cancel') ?? 'إلغاء'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.resetPlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: Spacing.sm,
                bottom: Spacing.xs,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n?.translate('settings.title') ?? 'الإعدادات',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            FItem(
              prefix: const Icon(Icons.alarm),
              title: Text(
                l10n?.translate('wird.reminder_time') ?? 'وقت التذكير',
              ),
              subtitle: Text(_parseTime(plan.reminderTime).format(context)),
              suffix: FSwitch(
                value: plan.reminderEnabled,
                onChange: (v) =>
                    context.read<WirdCubit>().setReminderEnabled(v),
              ),
              onPress: () => _pickTime(context),
            ),
            const Divider(height: 1),
            FItem(
              prefix: Icon(Icons.refresh, color: theme.colorScheme.error),
              title: Text(
                l10n?.translate('wird.reset_plan') ?? 'إعادة ضبط الختمة؟',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle: Text(
                l10n?.translate('wird.reset_confirm') ??
                    'سيؤدي هذا إلى حذف الخطة الحالية والتقدّم.',
              ),
              onPress: () => _confirmReset(context),
            ),
          ],
        ),
      ),
    );
  }
}
