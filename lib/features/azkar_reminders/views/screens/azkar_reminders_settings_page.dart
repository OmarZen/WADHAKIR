import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/branded_header.dart';
import 'package:wadhakir/features/azkar_reminders/cubit/azkar_reminders_cubit.dart';
import 'package:wadhakir/features/azkar_reminders/cubit/azkar_reminders_state.dart';
import 'package:wadhakir/features/azkar_reminders/views/widgets/after_prayer_reminder_tile.dart';
import 'package:wadhakir/features/azkar_reminders/views/widgets/azkar_reminder_toggle_card.dart';
import 'package:wadhakir/features/azkar_reminders/views/widgets/qiyam_reminder_tile.dart';

/// Dedicated page listing every daily-azkar reminder with its toggle and
/// (where relevant) time. Mirrors the fasting settings page layout.
class AzkarRemindersSettingsPage extends StatelessWidget {
  const AzkarRemindersSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Column(
        children: [
          BrandedHeader(
            title: l10n?.translate('azkar_reminders.title') ?? 'تذكيرات الأذكار',
            subtitle:
                l10n?.translate('azkar_reminders.subtitle') ??
                'الصباح والمساء، بعد الصلاة، قيام الليل وغيرها',
          ),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: AzkarRemindersSettingsBody(),
            ),
          ),
        ],
      ),
    );
  }
}

/// The reusable body — also embeddable elsewhere if needed.
class AzkarRemindersSettingsBody extends StatelessWidget {
  const AzkarRemindersSettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<AzkarRemindersCubit, AzkarRemindersState>(
      builder: (context, state) {
        final s = state.settings;
        final cubit = context.read<AzkarRemindersCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AzkarTestButton(),
            const SizedBox(height: 12),

            _SectionLabel(
              l10n?.translate('azkar_reminders.section_daily') ??
                  'الأذكار اليومية',
            ),
            const SizedBox(height: 8),
            AzkarReminderToggleCard(
              icon: Icons.wb_sunny_outlined,
              title:
                  l10n?.translate('azkar_reminders.morning') ?? 'أذكار الصباح',
              value: s.morningEnabled,
              timeLabel: _fmt(context, s.morningHour, s.morningMinute),
              onToggle: (v) => requestAzkarEnable(
                context,
                enable: v,
                onGranted: () => cubit.setMorningEnabled(true),
                onDisable: () => cubit.setMorningEnabled(false),
              ),
              onEditTime: () => pickAzkarTime(
                context,
                s.morningHour,
                s.morningMinute,
                cubit.setMorningTime,
              ),
            ),
            const SizedBox(height: 8),
            AzkarReminderToggleCard(
              icon: Icons.nights_stay_outlined,
              title:
                  l10n?.translate('azkar_reminders.evening') ?? 'أذكار المساء',
              value: s.eveningEnabled,
              timeLabel: _fmt(context, s.eveningHour, s.eveningMinute),
              onToggle: (v) => requestAzkarEnable(
                context,
                enable: v,
                onGranted: () => cubit.setEveningEnabled(true),
                onDisable: () => cubit.setEveningEnabled(false),
              ),
              onEditTime: () => pickAzkarTime(
                context,
                s.eveningHour,
                s.eveningMinute,
                cubit.setEveningTime,
              ),
            ),
            const SizedBox(height: 8),
            AzkarReminderToggleCard(
              icon: Icons.bedtime_outlined,
              title: l10n?.translate('azkar_reminders.sleep') ?? 'أذكار النوم',
              value: s.sleepEnabled,
              timeLabel: _fmt(context, s.sleepHour, s.sleepMinute),
              onToggle: (v) => requestAzkarEnable(
                context,
                enable: v,
                onGranted: () => cubit.setSleepEnabled(true),
                onDisable: () => cubit.setSleepEnabled(false),
              ),
              onEditTime: () => pickAzkarTime(
                context,
                s.sleepHour,
                s.sleepMinute,
                cubit.setSleepTime,
              ),
            ),

            const SizedBox(height: 16),
            _SectionLabel(
              l10n?.translate('azkar_reminders.section_prayer') ??
                  'متعلقة بالصلاة',
            ),
            const SizedBox(height: 8),
            const AfterPrayerReminderTile(),
            const SizedBox(height: 8),
            const QiyamReminderTile(),
            const SizedBox(height: 8),
            AzkarReminderToggleCard(
              icon: Icons.light_mode_outlined,
              title: l10n?.translate('azkar_reminders.duha') ?? 'صلاة الضحى',
              subtitle:
                  (l10n?.translate('azkar_reminders.duha_subtitle') ??
                          'بعد الشروق بـ {min} دقيقة')
                      .replaceAll('{min}', '${s.duhaOffsetMinutes}'),
              value: s.duhaEnabled,
              onToggle: (v) => requestAzkarEnable(
                context,
                enable: v,
                onGranted: () => cubit.setDuhaEnabled(true),
                onDisable: () => cubit.setDuhaEnabled(false),
              ),
            ),

            const SizedBox(height: 16),
            _SectionLabel(
              l10n?.translate('azkar_reminders.section_nawafil') ?? 'نوافل وسنن',
            ),
            const SizedBox(height: 8),
            AzkarReminderToggleCard(
              icon: Icons.menu_book_outlined,
              title:
                  l10n?.translate('azkar_reminders.kahf') ??
                  'سورة الكهف (الجمعة)',
              value: s.fridayKahfEnabled,
              timeLabel: _fmt(context, s.fridayKahfHour, s.fridayKahfMinute),
              onToggle: (v) => requestAzkarEnable(
                context,
                enable: v,
                onGranted: () => cubit.setFridayKahfEnabled(true),
                onDisable: () => cubit.setFridayKahfEnabled(false),
              ),
              onEditTime: () => pickAzkarTime(
                context,
                s.fridayKahfHour,
                s.fridayKahfMinute,
                cubit.setFridayKahfTime,
              ),
            ),
            const SizedBox(height: 8),
            AzkarReminderToggleCard(
              icon: Icons.bedtime,
              title: l10n?.translate('azkar_reminders.witr') ?? 'صلاة الوتر',
              value: s.witrEnabled,
              timeLabel: _fmt(context, s.witrHour, s.witrMinute),
              onToggle: (v) => requestAzkarEnable(
                context,
                enable: v,
                onGranted: () => cubit.setWitrEnabled(true),
                onDisable: () => cubit.setWitrEnabled(false),
              ),
              onEditTime: () => pickAzkarTime(
                context,
                s.witrHour,
                s.witrMinute,
                cubit.setWitrTime,
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  String _fmt(BuildContext context, int hour, int minute) =>
      TimeOfDay(hour: hour, minute: minute).format(context);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _AzkarTestButton extends StatelessWidget {
  const _AzkarTestButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final cubit = context.read<AzkarRemindersCubit>();
          final ok = await cubit.sendTest();
          if (!context.mounted) return;
          showFToast(
            context: context,
            title: Text(
              ok
                  ? (l10n?.translate('azkar_reminders.test_sent') ??
                        'تم إرسال تذكير تجريبي للأذكار')
                  : (l10n?.translate('azkar_reminders.test_failed') ??
                        'تعذّر الإرسال — تأكد من منح صلاحية الإشعارات'),
            ),
            variant: ok ? FToastVariant.primary : FToastVariant.destructive,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n?.translate('azkar_reminders.send_test') ??
                      'إرسال تذكير تجريبي',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
