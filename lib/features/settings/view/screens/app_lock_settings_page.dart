import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/features/settings/view/widgets/app_lock_settings_widget.dart';

/// Dedicated page for the prayer-time app-lock settings.
class AppLockSettingsPage extends StatelessWidget {
  const AppLockSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.translate('settings.app_lock') ?? 'قفل التطبيقات وقت الصلاة',
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is! SettingsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: AppLockSettingsWidget(
              settings: state.settings,
              cubit: context.read<SettingsCubit>(),
            ),
          );
        },
      ),
    );
  }
}
