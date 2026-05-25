import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/utils/alarm_permission_helper.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_cubit.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_state.dart';
import 'package:wadhakir/features/fasting_reminders/views/screens/fasting_calendar_screen.dart';
import 'package:wadhakir/features/fasting_reminders/services/fasting_notification_service.dart';

/// Settings widget for fasting reminders configuration
/// To be integrated into the settings screen
class FastingReminderSettingsWidget extends StatelessWidget {
  const FastingReminderSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;

    return BlocBuilder<FastingRemindersCubit, FastingRemindersState>(
      builder: (context, state) {
        // Previously this returned SizedBox.shrink() for any non-Loaded
        // state, which hid the entire fasting section while the cubit's
        // async loadSettings() was running. If loadSettings ever errored
        // (downstream dependencies on the hijri service / notification
        // service / repository), the section stayed invisible forever and
        // the user couldn't access fasting settings at all. Show a small
        // visible placeholder for Initial/Loading/Error so the section is
        // always discoverable.
        if (state is FastingRemindersInitial ||
            state is FastingRemindersLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        if (state is FastingRemindersError) {
          final cubit = context.read<FastingRemindersCubit>();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.translate('fasting.load_failed') ??
                            'تعذّر تحميل إعدادات الصيام',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: () => cubit.loadSettings(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      l10n?.translate('common.retry') ?? 'إعادة المحاولة',
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        // Defensive: any unexpected state — still render nothing here, but
        // the Loaded branch below covers the normal path.
        if (state is! FastingRemindersLoaded) {
          return const SizedBox.shrink();
        }

        final settings = state.settings;
        final cubit = context.read<FastingRemindersCubit>();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header with master toggle
              _buildHeaderWithToggle(
                context,
                theme,
                isDark,
                languageCode,
                l10n,
                settings.monthlyFastingRemindersEnabled,
                cubit,
              ),

              if (settings.monthlyFastingRemindersEnabled) ...[
                const SizedBox(height: 8),

                // Test button — fires a single sample fasting reminder so
                // the user can verify the notification channel + sound +
                // permission flow without waiting for a real fast day.
                _FastingTestButton(theme: theme, l10n: l10n),
                const SizedBox(height: 12),

                // Weekly Fasting Section (Monday/Thursday)
                _buildWeeklyFastingSection(
                  context,
                  theme,
                  isDark,
                  languageCode,
                  l10n,
                  settings,
                  cubit,
                ),

                const SizedBox(height: 12),

                // Hijri Calendar Fasting types grid
                _buildFastingTypesGrid(
                  context,
                  theme,
                  isDark,
                  languageCode,
                  l10n,
                  settings,
                  cubit,
                ),

                const SizedBox(height: 12),

                // Notification preferences grid
                _buildNotificationPreferencesGrid(
                  context,
                  theme,
                  isDark,
                  languageCode,
                  l10n,
                  settings,
                  cubit,
                ),

                const SizedBox(height: 12),

                // Days before and calendar button in single row
                _buildBottomActions(
                  context,
                  theme,
                  languageCode,
                  l10n,
                  settings.daysBeforeNotification,
                  cubit,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderWithToggle(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String languageCode,
    AppLocalizations? l10n,
    bool isEnabled,
    FastingRemindersCubit cubit,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.primary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.translate('fasting.settings_title') ??
                      (languageCode == 'ar'
                          ? 'تذكيرات الصيام'
                          : 'Fasting Reminders'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.translate('fasting.enable_reminders_subtitle') ??
                      (languageCode == 'ar'
                          ? 'أيام الصيام المستحبة'
                          : 'Recommended fasting days'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: isEnabled,
              onChanged: (value) async {
                if (value) {
                  // Request permissions before enabling
                  final permissions =
                      await AlarmPermissionHelper.requestAllPermissions(
                          context);

                  // Only enable if we got notification permission at minimum
                  if (permissions['notifications'] == true) {
                    cubit.toggleMonthlyReminders(value);

                    // Show warning if exact alarm permission was denied
                    if (permissions['exactAlarms'] != true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n?.translate(
                                  'settings.exact_alarm_permission_warning',
                                ) ??
                                'لن تصل التنبيهات في الوقت المحدد بدون إذن "التنبيهات والتذكيرات"',
                          ),
                          action: SnackBarAction(
                            label: l10n?.translate('settings.settings') ??
                                'الإعدادات',
                            onPressed: () => AlarmPermissionHelper
                                .showPermissionDeniedDialog(
                              context,
                            ),
                          ),
                        ),
                      );
                    }
                  }
                } else {
                  // Disable fasting reminders
                  cubit.toggleMonthlyReminders(value);
                }
              },
              activeThumbColor: theme.colorScheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyFastingSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String languageCode,
    AppLocalizations? l10n,
    settings,
    FastingRemindersCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 16),
            HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar01,
              color: theme.colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.translate('fasting.weekly_fasting') ??
                  (languageCode == 'ar' ? 'الصيام الأسبوعي' : 'Weekly Fasting'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            _buildCompactToggleCard(
              context,
              theme,
              isDark,
              icon: Icons.calendar_today,
              title: l10n?.translate('settings.fasting_monday') ??
                  (languageCode == 'ar' ? 'الإثنين' : 'Monday'),
              subtitle: l10n?.translate('settings.fasting_monday_subtitle') ??
                  (languageCode == 'ar' ? 'صيام الإثنين' : 'Monday fasting'),
              value: settings.mondayFastingEnabled,
              onChanged: (value) => cubit.toggleMondayFasting(value),
            ),
            const SizedBox(height: 8),
            _buildCompactToggleCard(
              context,
              theme,
              isDark,
              icon: Icons.calendar_today,
              title: l10n?.translate('settings.fasting_thursday') ??
                  (languageCode == 'ar' ? 'الخميس' : 'Thursday'),
              subtitle: l10n?.translate('settings.fasting_thursday_subtitle') ??
                  (languageCode == 'ar' ? 'صيام الخميس' : 'Thursday fasting'),
              value: settings.thursdayFastingEnabled,
              onChanged: (value) => cubit.toggleThursdayFasting(value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFastingTypesGrid(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String languageCode,
    AppLocalizations? l10n,
    settings,
    FastingRemindersCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 16),
            HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar01,
              color: theme.colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.translate('fasting.hijri_fasting_types') ??
                  (languageCode == 'ar'
                      ? 'الصيام الهجري الشهري'
                      : 'Hijri Monthly Fasting'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCompactToggleCard(
          context,
          theme,
          isDark,
          icon: Icons.wb_twilight,
          title: l10n?.translate('fasting.ayyam_al_bid') ??
              (languageCode == 'ar' ? 'الأيام البيض' : 'White Days'),
          subtitle: '13-15',
          value: settings.ayyamAlBidEnabled,
          onChanged: (value) => cubit.toggleAyyamAlBid(value),
        ),
        const SizedBox(height: 8),
        _buildCompactToggleCard(
          context,
          theme,
          isDark,
          icon: Icons.calendar_today,
          title: l10n?.translate('fasting.ninth_tenth') ??
              (languageCode == 'ar' ? 'التاسع والعاشر' : '9th & 10th'),
          subtitle: l10n?.translate('fasting.ninth_tenth_days') ?? '9-10',
          value: settings.ninthTenthEnabled,
          onChanged: (value) => cubit.toggleNinthTenth(value),
        ),
        const SizedBox(height: 8),
        _buildCompactToggleCard(
          context,
          theme,
          isDark,
          icon: Icons.star,
          title: l10n?.translate('fasting.special_days') ??
              (languageCode == 'ar' ? 'الأيام المميزة' : 'Special Days'),
          subtitle: l10n?.translate('fasting.special_days_subtitle') ??
              (languageCode == 'ar'
                  ? 'عاشوراء، عرفة وأخرى'
                  : 'Ashura, Arafah & more'),
          value: settings.specialDaysEmphasis,
          onChanged: (value) => cubit.toggleSpecialDays(value),
        ),
      ],
    );
  }

  Widget _buildNotificationPreferencesGrid(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String languageCode,
    AppLocalizations? l10n,
    settings,
    FastingRemindersCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 16),
            HugeIcon(
              icon: HugeIcons.strokeRoundedNotification01,
              color: theme.colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.translate('fasting.notification_timing') ??
                  (languageCode == 'ar'
                      ? 'توقيت الإشعارات'
                      : 'Notification Timing'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCompactToggleCard(
          context,
          theme,
          isDark,
          icon: Icons.nightlight_round,
          title: l10n?.translate('fasting.eve_reminder') ??
              (languageCode == 'ar' ? 'تذكير المساء' : 'Evening'),
          subtitle: l10n?.translate('fasting.eve_maghrib_time') ??
              (languageCode == 'ar' ? 'عند أذان المغرب' : 'At Maghrib Adhan'),
          value: settings.eveReminder,
          onChanged: (value) => cubit.toggleEveReminder(value),
        ),
        const SizedBox(height: 8),
        _buildCompactToggleCard(
          context,
          theme,
          isDark,
          icon: Icons.wb_sunny,
          title: l10n?.translate('fasting.morning_reminder') ??
              (languageCode == 'ar' ? 'تذكير الصباح' : 'Morning'),
          subtitle: l10n?.translate('fasting.morning_fajr_time') ??
              (languageCode == 'ar'
                  ? 'قبل الفجر بـ 5 دقائق'
                  : '5 min before Fajr'),
          value: settings.morningReminder,
          onChanged: (value) => cubit.toggleMorningReminder(value),
        ),
        const SizedBox(height: 8),
        _buildCompactToggleCard(
          context,
          theme,
          isDark,
          icon: Icons.schedule,
          title: l10n?.translate('fasting.advance_reminder') ??
              (languageCode == 'ar' ? 'التذكير المسبق' : 'Advance'),
          subtitle: _buildAdvanceReminderSubtitle(
            settings.daysBeforeNotification,
            settings.advanceReminderTime,
            languageCode,
          ),
          value: settings.advanceReminder,
          onChanged: (value) {
            if (value) {
              // Show dialog to configure days and time
              _showAdvanceReminderDialog(
                context,
                theme,
                languageCode,
                l10n,
                settings.daysBeforeNotification,
                settings.advanceReminderTime,
                cubit,
              );
            } else {
              cubit.toggleAdvanceReminder(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCompactToggleCard(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : (isDark ? theme.colorScheme.surface : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.colorScheme.onSurface.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value
                    ? (isDark
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.primary.withValues(alpha: 0.05))
                    : (isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: value
                    ? (isDark
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                        : theme.colorScheme.primary)
                    : (isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: value
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Switch
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: theme.colorScheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build advance reminder subtitle with separated logic
  String _buildAdvanceReminderSubtitle(
    int days,
    String time,
    String languageCode,
  ) {
    // Build day text
    final String dayText;
    if (languageCode == 'ar') {
      dayText = days == 1 ? 'يوم قبل' : 'أيام قبل';
    } else {
      dayText = days == 1 ? 'day before' : 'days before';
    }

    // Concatenate: "X day(s) before - HH:MM"
    return '$days $dayText - $time';
  }

  // Show dialog to configure advance reminder
  void _showAdvanceReminderDialog(
    BuildContext context,
    ThemeData theme,
    String languageCode,
    AppLocalizations? l10n,
    int currentDays,
    String currentTime,
    FastingRemindersCubit cubit,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AdvanceReminderDialog(
        theme: theme,
        languageCode: languageCode,
        l10n: l10n,
        currentDays: currentDays,
        currentTime: currentTime,
        cubit: cubit,
      ),
    );
  }

  // Calendar button - full width
  Widget _buildBottomActions(
    BuildContext context,
    ThemeData theme,
    String languageCode,
    AppLocalizations? l10n,
    int daysBeforeNotification,
    FastingRemindersCubit cubit,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const FastingCalendarScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 24),
            const SizedBox(width: 10),
            Text(
              l10n?.translate('fasting.view_calendar') ??
                  (languageCode == 'ar' ? 'عرض التقويم' : 'View Calendar'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stateful dialog widget for advance reminder configuration
class _AdvanceReminderDialog extends StatefulWidget {
  final ThemeData theme;
  final String languageCode;
  final AppLocalizations? l10n;
  final int currentDays;
  final String currentTime;
  final FastingRemindersCubit cubit;

  const _AdvanceReminderDialog({
    required this.theme,
    required this.languageCode,
    required this.l10n,
    required this.currentDays,
    required this.currentTime,
    required this.cubit,
  });

  @override
  State<_AdvanceReminderDialog> createState() => _AdvanceReminderDialogState();
}

class _AdvanceReminderDialogState extends State<_AdvanceReminderDialog> {
  late int tempDays;
  late TimeOfDay tempTime;

  @override
  void initState() {
    super.initState();
    tempDays = widget.currentDays;
    tempTime = TimeOfDay(
      hour: int.parse(widget.currentTime.split(':')[0]),
      minute: int.parse(widget.currentTime.split(':')[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.schedule,
            color: widget.theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.l10n?.translate('fasting.configure_advance_reminder') ??
                  (widget.languageCode == 'ar'
                      ? 'إعدادات التذكير المسبق'
                      : 'Configure Advance Reminder'),
              style: widget.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Days before section
            Text(
              widget.l10n?.translate('fasting.days_before_fasting') ??
                  (widget.languageCode == 'ar'
                      ? 'عدد الأيام قبل الصيام'
                      : 'Days before fasting'),
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      widget.theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: widget.theme.colorScheme.primary,
                    onPressed: tempDays > 1
                        ? () {
                            setState(() {
                              tempDays--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    '$tempDays ${widget.languageCode == 'ar' ? (tempDays == 1 ? 'يوم' : 'أيام') : (tempDays == 1 ? 'day' : 'days')}',
                    style: widget.theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: widget.theme.colorScheme.primary,
                    onPressed: tempDays < 7
                        ? () {
                            setState(() {
                              tempDays++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Time selection section
            Text(
              widget.l10n?.translate('fasting.reminder_time') ??
                  (widget.languageCode == 'ar'
                      ? 'وقت التذكير'
                      : 'Reminder Time'),
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final selectedTime = await showTimePicker(
                  context: context,
                  initialTime: tempTime,
                );
                if (selectedTime != null) {
                  setState(() {
                    tempTime = selectedTime;
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      widget.theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        widget.theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: widget.theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      tempTime.format(context),
                      style: widget.theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            widget.l10n?.translate('common.cancel') ??
                (widget.languageCode == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Save all settings at once to avoid multiple reschedules
            final timeString =
                '${tempTime.hour.toString().padLeft(2, '0')}:${tempTime.minute.toString().padLeft(2, '0')}';

            widget.cubit.updateAdvanceReminderSettings(
              days: tempDays,
              time: timeString,
              enabled: true,
            );

            Navigator.of(context).pop();
          },
          child: Text(
            widget.l10n?.translate('common.save') ??
                (widget.languageCode == 'ar' ? 'حفظ' : 'Save'),
          ),
        ),
      ],
    );
  }
}

/// Fires a single test fasting notification so the user can confirm the
/// notification channel + sound + permission flow are working.
class _FastingTestButton extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations? l10n;

  const _FastingTestButton({required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final ok =
                await FastingNotificationService().sendTestNotification();
            if (!context.mounted) return;
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? (l10n?.translate('fasting.test_sent') ??
                          'تم إرسال تذكير تجريبي للصيام')
                      : (l10n?.translate('fasting.test_failed') ??
                          'تعذّر الإرسال — تأكد من منح صلاحية الإشعارات'),
                ),
                behavior: SnackBarBehavior.floating,
              ),
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
                    l10n?.translate('fasting.send_test_notification') ??
                        'إرسال تذكير تجريبي للصيام',
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
      ),
    );
  }
}
