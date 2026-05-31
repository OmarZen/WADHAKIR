import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/fasting_reminders/views/widgets/fasting_reminder_settings_widget.dart';

/// Dedicated page for fasting reminder settings, moved out of the main
/// settings screen to reduce its density.
class FastingSettingsPage extends StatelessWidget {
  const FastingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.translate('fasting.fasting_reminders') ?? 'تذكيرات الصيام',
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: FastingReminderSettingsWidget(),
      ),
    );
  }
}
