import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';

/// One-time, in-app prompt asking existing users — who installed before the
/// onboarding name page existed and therefore never saw it — for their name.
/// Shown once from the home screen and gated so it never nags.
class NamePromptSheet {
  const NamePromptSheet._();

  /// Show the sheet exactly once, only if onboarding is done, no name is set,
  /// and the prompt hasn't been shown before. No-op otherwise. The "seen" flag
  /// is set BEFORE showing so dismissing without entering a name still never
  /// repeats it.
  static Future<void> maybeShow(BuildContext context) async {
    final settingsState = context.read<SettingsCubit>().state;
    if (settingsState is! SettingsLoaded) return;
    final settings = settingsState.settings;
    if (!settings.onboardingCompleted) return;
    if (settings.userName.trim().isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConstants.namePromptSeenKey) ?? false) return;
    await prefs.setBool(AppConstants.namePromptSeenKey, true);

    if (!context.mounted) return;
    final cubit = context.read<SettingsCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const _NamePromptBody()),
    );
  }
}

class _NamePromptBody extends StatefulWidget {
  const _NamePromptBody();

  @override
  State<_NamePromptBody> createState() => _NamePromptBodyState();
}

class _NamePromptBodyState extends State<_NamePromptBody> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      context.read<SettingsCubit>().setUserName(name);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Lift the sheet content above the on-screen keyboard.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.waving_hand_rounded,
            color: theme.colorScheme.primary,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.translate('name_prompt.title') ?? 'بماذا نناديك؟',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.translate('name_prompt.subtitle') ??
                'أضف اسمك لنحيّيك به في كل مرة',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          FTextField(
            control: FTextFieldControl.managed(controller: _controller),
            hint: l10n?.translate('name_prompt.hint') ?? 'اسمك الأول',
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            maxLines: 1,
            autofocus: true,
            onSubmit: (_) => _save(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => Navigator.of(context).pop(),
                  child: Text(l10n?.translate('name_prompt.skip') ?? 'لاحقًا'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FButton(
                  onPress: _save,
                  child: Text(l10n?.translate('name_prompt.save') ?? 'حفظ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
