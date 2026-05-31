import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/radii.dart';
import 'package:wadhakir/core/utils/alarm_permission_helper.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/widgets/number_stepper_field.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/wird/wird_enums.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/features/wird/cubit/wird_cubit.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';
import 'package:wadhakir/features/wird/views/screens/wird_schedule_view.dart';
import 'package:wadhakir/features/wird/views/widgets/wird_unit_selector.dart';

/// Setup screen ("ابدأ ختمتك"). Holds a local draft plan and only commits to
/// the cubit when the user taps "بدء الخطة".
class WirdSetupView extends StatefulWidget {
  const WirdSetupView({super.key});

  @override
  State<WirdSetupView> createState() => _WirdSetupViewState();
}

class _WirdSetupViewState extends State<WirdSetupView> {
  static const _scheduleService = WirdScheduleService();

  WirdUnit _unit = WirdUnit.pages;
  int _amountPerDay = 4;
  int _startPage = 1;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  late final TextEditingController _amountController = TextEditingController(
    text: '$_amountPerDay',
  );
  late final TextEditingController _startPageController = TextEditingController(
    text: '$_startPage',
  );

  @override
  void dispose() {
    _amountController.dispose();
    _startPageController.dispose();
    super.dispose();
  }

  String get _reminderTimeHHmm =>
      '${_reminderTime.hour.toString().padLeft(2, '0')}:'
      '${_reminderTime.minute.toString().padLeft(2, '0')}';

  WirdPlanModel _draftPlan() {
    return WirdPlanModel(
      isActive: true,
      goalMode: WirdGoalMode.fixedDailyAmount,
      unit: _unit,
      amountPerDay: _amountPerDay < 1 ? 1 : _amountPerDay,
      startPage: _startPage.clamp(1, 604),
      reminderTime: _reminderTimeHHmm,
      reminderEnabled: true,
      completedDayIndices: const <int>{},
      planStartDate: DateTime.now(),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final draft = _draftPlan();
    final completion = _scheduleService.expectedCompletionDate(draft);
    final totalDays = _scheduleService.totalDays(draft);

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        // Goal
        _Section(
          title: l10n?.translate('wird.goal_label') ?? 'الهدف',
          child: Row(
            children: [
              Icon(
                Icons.radio_button_checked,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  l10n?.translate('wird.goal_fixed_daily') ??
                      'قراءة مقدار ثابت يومياً',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),

        // Unit
        _Section(
          title: l10n?.translate('wird.unit_label') ?? 'وحدة التتبع',
          subtitle:
              l10n?.translate('wird.unit_subtitle') ??
              'اختر وحدة التتبع المفضلة لديك',
          child: WirdUnitSelector(
            selected: _unit,
            onChanged: (u) => setState(() => _unit = u),
          ),
        ),

        // Amount per day
        _Section(
          title: _amountLabel(context),
          child: NumberStepperField(
            value: _amountPerDay,
            min: 1,
            max: 604,
            controller: _amountController,
            onChanged: (v) => setState(() => _amountPerDay = v),
          ),
        ),

        // Start page
        _Section(
          title: l10n?.translate('wird.start_page') ?? 'بداية صفحة',
          child: NumberStepperField(
            value: _startPage,
            min: 1,
            max: 604,
            controller: _startPageController,
            onChanged: (v) => setState(() => _startPage = v),
          ),
        ),

        // Reminder time
        _Section(
          title: l10n?.translate('wird.reminder_time') ?? 'وقت التذكير',
          child: Row(
            children: [
              Icon(Icons.alarm, color: theme.colorScheme.primary),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  _reminderTime.format(context),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              TextButton(
                onPressed: _pickTime,
                child: Text(l10n?.translate('common.change') ?? 'تغيير'),
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacing.sm),

        // Expected completion (live)
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.event_available, color: theme.colorScheme.primary),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  completion != null
                      ? '${l10n?.translate('wird.expected_completion') ?? 'موعد الختم المتوقع'}: '
                            '${WirdFormat.longDate(completion)}'
                      : (l10n?.translate('wird.expected_completion') ??
                            'موعد الختم المتوقع'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),

        FButton(
          onPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WirdSchedulePreviewScreen(plan: draft),
              ),
            );
          },
          variant: FButtonVariant.outline,
          prefix: const Icon(Icons.calendar_month_outlined),
          child: Text(
            '${l10n?.translate('wird.view_schedule') ?? 'عرض الجدول الكامل'} '
            '(${WirdFormat.toArabicDigits(totalDays)} ${l10n?.translate('wird.days') ?? 'يوم'})',
          ),
        ),
        const SizedBox(height: Spacing.lg),

        FButton(
          onPress: () async {
            final cubit = context.read<WirdCubit>();
            // Ensure notification + exact-alarm (+ one-time battery-opt)
            // permission so the daily wird reminder actually fires.
            await AlarmPermissionHelper.requestAllPermissions(context);
            await cubit.startPlan(
              unit: _unit,
              amountPerDay: _amountPerDay,
              startPage: _startPage,
              reminderTime: _reminderTimeHHmm,
            );
          },
          child: Text(l10n?.translate('wird.start_plan') ?? 'بدء الخطة'),
        ),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }

  String _amountLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (_unit) {
      case WirdUnit.pages:
        return l10n?.translate('wird.amount_pages') ?? 'صفحة يومياً';
      case WirdUnit.rub:
        return l10n?.translate('wird.amount_rub') ?? 'ربع يومياً';
      case WirdUnit.hizb:
        return l10n?.translate('wird.amount_hizb') ?? 'حزب يومياً';
      case WirdUnit.juz:
        return l10n?.translate('wird.amount_juz') ?? 'جزء يومياً';
    }
  }
}

/// Simple titled section card used across the setup screen.
class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Section({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: Spacing.xxs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              const SizedBox(height: Spacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
