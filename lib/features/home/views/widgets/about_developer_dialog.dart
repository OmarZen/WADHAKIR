import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

Future<void> showAboutDeveloperDialog(BuildContext context) async {
  final theme = Theme.of(context);
  final l10n = context.l10n;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                    const Spacer(),
                    Text(
                      l10n?.translate('home.about_developer') ?? 'عن المطور',
                      style: theme.textTheme.displaySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.25),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/profile/profile.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.08),
                          child: Icon(
                            Icons.account_circle_rounded,
                            color: theme.colorScheme.primary,
                            size: 76,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.translate('home.developer_name') ?? 'عمر وليد',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n?.translate('home.developer_job') ??
                      'مهندس برمجيات ومؤسس YouBe',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    l10n?.translate('home.developer_duha_ask') ??
                        'هذا العمل أقدمه صدقة جارية لوجه الله، فادعوا لي بالقبول والمغفرة؛ وإن رأيتم فائدة، فشاركوها، ف"الدال على الخير كفاعله".',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _circleIconButton(
                      context,
                      icon: FontAwesomeIcons.youtube,
                      tooltip: 'YouTube',
                      url: Uri.parse(
                          'https://www.youtube.com/channel/UCZm5Gb5AcrZsPRF5bIjXCJw'),
                    ),
                    const SizedBox(width: 12),
                    _circleIconButton(
                      context,
                      icon: FontAwesomeIcons.github,
                      tooltip: 'GitHub',
                      url: Uri.parse('https://github.com/OmarZen'),
                    ),
                    const SizedBox(width: 12),
                    _circleIconButton(
                      context,
                      icon: FontAwesomeIcons.linkedin,
                      tooltip: 'LinkedIn',
                      url: Uri.parse(
                          'https://www.linkedin.com/in/omarwaleedzenhom/'),
                    ),
                    const SizedBox(width: 12),
                    _circleIconButton(
                      context,
                      icon: FontAwesomeIcons.xTwitter,
                      tooltip: 'X (Twitter)',
                      url: Uri.parse('https://x.com/omarwaleedzen'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Share.share('شارك تطبيق واذكِّر لمنفعة الجميع بإذن الله');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n?.translate('home.share_app') ?? 'مشاركة التطبيق',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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

Widget _circleIconButton(
  BuildContext context, {
  required IconData icon,
  required String tooltip,
  required Uri url,
}) {
  final theme = Theme.of(context);
  return Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      shape: BoxShape.circle,
      border:
          Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: () async {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      icon: Icon(icon, color: theme.colorScheme.primary),
    ),
  );
}
