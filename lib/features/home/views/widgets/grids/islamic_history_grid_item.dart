import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/islamic_history/views/screens/islamic_history_screen.dart';

class IslamicHistoryGridItem extends StatelessWidget {
  const IslamicHistoryGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const IslamicHistoryScreen(),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.history_edu_rounded,
                  color: isDark
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n?.translate('home.islamic_history') ?? 'السيرة النبوية',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
