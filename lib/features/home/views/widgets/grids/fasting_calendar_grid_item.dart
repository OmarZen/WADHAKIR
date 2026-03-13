import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_cubit.dart';
import 'package:wadhakir/features/fasting_reminders/views/screens/fasting_calendar_screen.dart';

class FastingCalendarGridItem extends StatelessWidget {
  const FastingCalendarGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = PlatformUtils.isDesktop;

    final padding = isDesktop ? 16.0 : 12.0;
    final verticalPadding = isDesktop ? 12.0 : 10.0;
    final iconPadding = isDesktop ? 10.0 : 8.0;
    final iconSize = isDesktop ? 22.0 : 20.0;
    final spacing = isDesktop ? 12.0 : 10.0;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _showFastingCalendar(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: iconSize,
                  color: isDark
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                      : theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  l10n?.translate('fasting.calendar_title') ?? 'تقويم الصيام',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: isDesktop ? 16 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFastingCalendar(BuildContext context) async {
    final cubit = context.read<FastingRemindersCubit>();

    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const FastingCalendarScreen(),
      ),
    );
  }
}
