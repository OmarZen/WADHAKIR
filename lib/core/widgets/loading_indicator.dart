import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: CircularProgressIndicator(
        color: theme.colorScheme.primary,
        backgroundColor: Colors.transparent,
        strokeWidth: 4,
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        semanticsLabel: context.l10n?.translate('loading') ?? 'Loading...',
        semanticsValue: context.l10n?.translate('loading') ?? 'Loading...',
        strokeCap: StrokeCap.round,
      ),
    );
  }
}
