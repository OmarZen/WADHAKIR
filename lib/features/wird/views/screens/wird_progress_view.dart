import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/spacing.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/wird/cubit/wird_state.dart';
import 'package:wadhakir/features/wird/views/screens/wird_schedule_view.dart';
import 'package:wadhakir/features/wird/views/widgets/wird_progress_header.dart';
import 'package:wadhakir/features/wird/views/widgets/wird_today_card.dart';
import 'package:wadhakir/features/wird/views/widgets/wird_settings_section.dart';

/// Progress screen shown when a plan is active.
class WirdProgressView extends StatelessWidget {
  final WirdLoaded state;

  const WirdProgressView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        WirdProgressHeader(state: state),
        const SizedBox(height: Spacing.lg),
        WirdTodayCard(state: state),
        const SizedBox(height: Spacing.lg),
        // Full schedule link
        FItem(
          prefix: Icon(
            Icons.calendar_month_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            l10n?.translate('wird.view_schedule') ?? 'عرض الجدول الكامل',
          ),
          subtitle: state.expectedCompletionDate != null
              ? Text(
                  l10n?.translate('wird.full_schedule_subtitle') ??
                      'جميع أيام الختمة',
                )
              : null,
          suffix: const Icon(Icons.chevron_left),
          onPress: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WirdScheduleScreen()),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        WirdSettingsSection(plan: state.plan),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }
}
