import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';

class PalestineSupportCardWidget extends StatelessWidget {
  const PalestineSupportCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDesktop = PlatformUtils.isDesktop;
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection:
          languageCode == 'en' ? TextDirection.ltr : TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: isDesktop ? 6.0 : 8.0,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _showPalestineDuaDialog(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 14.0 : 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.15,
                          ),
                        ]
                      : [
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                          theme.colorScheme.primary.withValues(alpha: 0.04),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  _buildFlagIcon(theme, isDesktop),
                  SizedBox(width: isDesktop ? 14 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                languageCode == 'en'
                                    ? 'Pray for Palestine\n'
                                    : (l10n?.translate('home.free_palestine') ??
                                        '\u0641\u0644\u0633\u0637\u064a\u0646 \u062d\u0631\u0629'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isDesktop ? 16 : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            FaIcon(
                              FontAwesomeIcons.personPraying,
                              size: isDesktop ? 24 : 20,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 4 : 3),
                        Text(
                          languageCode == 'en'
                              ? 'Keep them in your prayers'
                              : (l10n?.translate('home.palestine_duah') ??
                                  'دعاء لفلسطين'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: isDesktop ? 14 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlagIcon(ThemeData theme, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 10.0 : 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: CountryFlag.fromCountryCode(
        'PS',
        theme: ImageTheme(
          width: isDesktop ? 24 : 20,
          height: isDesktop ? 18 : 15,
        ),
      ),
    );
  }

  void _showPalestineDuaDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection:
            languageCode == 'en' ? TextDirection.ltr : TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.personPraying,
                        size: 24,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageCode == 'en'
                                ? 'Prayer for Palestine'
                                : (l10n?.translate('home.free_palestine') ??
                                    'فلسطين حرية'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            languageCode == 'en'
                                ? 'Keep them in your prayers'
                                : (l10n?.translate('home.palestine_duah') ??
                                    'لا تنسوهم من دعائكم'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    languageCode == 'en'
                        ? 'O Allah, grant victory to our brothers and sisters in Palestine, protect them from harm, relieve their hardships, make their difficulties easy, and grant them patience and steadfastness. Feed the hungry, secure the fearful, and grant them a clear victory.'
                        : (l10n?.translate('home.palestine_support') ??
                            'دعم فلسطين'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                      fontSize: languageCode == 'en' ? 15 : 16,
                      fontFamily:
                          languageCode == 'en' ? null : 'ScheherazadeNew',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      languageCode == 'en' ? 'Ameen' : 'آمين',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
