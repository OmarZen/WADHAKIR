import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class AboutSectionWidgets extends StatelessWidget {
  const AboutSectionWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    // This is a container widget, children use static methods
    return const SizedBox.shrink();
  }

  static Widget buildAboutTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return FItem(
      prefix: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.info_outline,
          color: theme.colorScheme.onPrimary,
          size: 18,
        ),
      ),
      title: Text(
        l10n?.translate('settings.about_app') ?? 'حول التطبيق',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        l10n?.translate('settings.app_description') ??
            'تطبيق وذكّر لمساعدتك في شعائر الإسلام',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      suffix: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onPress: () => _showAboutDialog(context),
    );
  }

  static void _showAboutDialog(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: Curves.easeOut.transform(animation.value),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.translate('settings.about_app') ?? 'حول التطبيق',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 36,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      l10n?.translate('settings.app_name') ?? 'وذكّر',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: _VersionText(
                      label: l10n?.translate('settings.version') ?? 'الإصدار',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.translate('settings.app_description') ??
                        'تطبيق وذكّر لمساعدتك في شعائر الإسلام',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.translate('settings.copyright') ??
                        '© 2025 جميع الحقوق محفوظة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    l10n?.translate('settings.close') ?? 'إغلاق',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget buildFeedbackTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return FItem(
      prefix: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.feedback_outlined,
          color: theme.colorScheme.onPrimary,
          size: 18,
        ),
      ),
      title: Text(
        l10n?.translate('settings.feedback') ?? 'إرسال تعليق',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        l10n?.translate('settings.feedback_description') ??
            'شاركنا رأيك لتحسين التطبيق',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      suffix: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onPress: () => _openFeedbackForm(context),
    );
  }

  static void _openFeedbackForm(BuildContext context) async {
    final l10n = context.l10n;
    final url = Uri.parse('https://forms.gle/DVtTnGBukUqKhNxi9');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (context.mounted) {
          showFToast(
            context: context,
            title: Text(
              l10n?.translate('settings.feedback_error') ??
                  'لا يمكن فتح نموذج التعليقات: ${url.toString()}',
            ),
            variant: FToastVariant.destructive,
          );
        }
      }
    }
  }

  static Widget buildWebsiteTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return FItem(
      prefix: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.language,
          color: theme.colorScheme.onPrimary,
          size: 18,
        ),
      ),
      title: Text(
        l10n?.translate('settings.website') ?? 'موقع التطبيق',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        l10n?.translate('settings.website_description') ??
            'زيارة موقع التطبيق الرسمي',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      suffix: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onPress: () => _openWebsite(context),
    );
  }

  static void _openWebsite(BuildContext context) async {
    final l10n = context.l10n;
    final url = Uri.parse('https://wadhakir-app.netlify.app/');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (context.mounted) {
          showFToast(
            context: context,
            title: Text(
              l10n?.translate('settings.website_error') ??
                  'لا يمكن فتح موقع التطبيق: ${url.toString()}',
            ),
            variant: FToastVariant.destructive,
          );
        }
      }
    }
  }

  static Widget buildPrivacyTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return FItem(
      prefix: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.privacy_tip_outlined,
          color: theme.colorScheme.onPrimary,
          size: 18,
        ),
      ),
      title: Text(
        l10n?.translate('settings.privacy') ?? 'سياسة الخصوصية',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        l10n?.translate('settings.privacy_description') ??
            'اطلع على سياسة الخصوصية',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      suffix: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onPress: () => _openPrivacyPolicy(context),
    );
  }

  static void _openPrivacyPolicy(BuildContext context) async {
    final l10n = context.l10n;
    final url = Uri.parse('https://wadhakir-app.netlify.app/privacy');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (context.mounted) {
          showFToast(
            context: context,
            title: Text(
              l10n?.translate('settings.privacy_error') ??
                  'لا يمكن فتح سياسة الخصوصية: ${url.toString()}',
            ),
            variant: FToastVariant.destructive,
          );
        }
      }
    }
  }

  static Widget buildRateAppTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return FItem(
      prefix: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.star_rate,
          color: theme.colorScheme.onPrimary,
          size: 18,
        ),
      ),
      title: Text(
        l10n?.translate('settings.rate_app') ?? 'قيّم التطبيق',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        l10n?.translate('settings.rate_app_description') ??
            'قيّم التطبيق في متجر التطبيقات',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      suffix: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onPress: () => _openPlayStore(context),
    );
  }

  static void _openPlayStore(BuildContext context) async {
    final l10n = context.l10n;
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.bloom.wadhakir',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (context.mounted) {
          showFToast(
            context: context,
            title: Text(
              l10n?.translate('settings.rate_app_error') ??
                  'لا يمكن فتح متجر التطبيقات: ${url.toString()}',
            ),
            variant: FToastVariant.destructive,
          );
        }
      }
    }
  }
}

/// Renders `<label> <version>+<build>`, reading the version from the platform
/// package info at runtime.
///
/// The number deliberately does NOT live in the l10n strings. It used to, which
/// meant every release had to hand-copy it into pubspec.yaml, both lang files
/// and a constant — and when one was missed the About screen quietly showed a
/// stale version. pubspec.yaml's `version:` is now the single source of truth.
class _VersionText extends StatelessWidget {
  const _VersionText({required this.label, this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        // Bare label while the async read is in flight, and if it ever fails:
        // showing no version beats showing a wrong one.
        final version = info == null
            ? ''
            : ' ${info.version}+${info.buildNumber}';
        return Text('$label$version', style: style);
      },
    );
  }
}
