import 'package:flutter/material.dart';
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

    return ListTile(
      title: Text(l10n?.translate('settings.about_app') ?? 'حول التطبيق'),
      subtitle: Text(
        l10n?.translate('settings.app_description') ??
            'تطبيق وذكّر لمساعدتك في شعائر الإسلام',
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.info_outline, color: theme.colorScheme.primary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showAboutDialog(context),
    );
  }

  static void _showAboutDialog(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(l10n?.translate('settings.about_app') ?? 'حول التطبيق'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 40,
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
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                l10n?.translate('settings.version') ?? 'الإصدار 2.2.0+5',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.translate('settings.app_description') ??
                  'تطبيق وذكّر لمساعدتك في شعائر الإسلام',
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.translate('settings.copyright') ??
                  '© 2025 جميع الحقوق محفوظة',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('settings.close') ?? 'إغلاق'),
          ),
        ],
      ),
    );
  }

  static Widget buildFeedbackTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.feedback') ?? 'إرسال تعليق'),
      subtitle: Text(
        l10n?.translate('settings.feedback_description') ??
            'شاركنا رأيك لتحسين التطبيق',
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.feedback_outlined, color: theme.colorScheme.primary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _openFeedbackForm(context),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.translate('settings.feedback_error') ??
                    'لا يمكن فتح نموذج التعليقات: ${url.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  static Widget buildWebsiteTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.website') ?? 'موقع التطبيق'),
      subtitle: Text(
        l10n?.translate('settings.website_description') ??
            'زيارة موقع التطبيق الرسمي',
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.language, color: theme.colorScheme.primary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _openWebsite(context),
    );
  }

  static void _openWebsite(BuildContext context) async {
    final l10n = context.l10n;
    final url = Uri.parse('https://wadhakir.vercel.app/');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.translate('settings.website_error') ??
                    'لا يمكن فتح موقع التطبيق: ${url.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  static Widget buildPrivacyTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.privacy') ?? 'سياسة الخصوصية'),
      subtitle: Text(
        l10n?.translate('settings.privacy_description') ??
            'اطلع على سياسة الخصوصية',
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.privacy_tip_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _openPrivacyPolicy(context),
    );
  }

  static void _openPrivacyPolicy(BuildContext context) async {
    final l10n = context.l10n;
    final url = Uri.parse('https://wadhakir.vercel.app/privacy');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.translate('settings.privacy_error') ??
                    'لا يمكن فتح سياسة الخصوصية: ${url.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  static Widget buildRateAppTile(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(l10n?.translate('settings.rate_app') ?? 'قيّم التطبيق'),
      subtitle: Text(
        l10n?.translate('settings.rate_app_description') ??
            'قيّم التطبيق في متجر التطبيقات',
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.star_rate, color: theme.colorScheme.primary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _openPlayStore(context),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.translate('settings.rate_app_error') ??
                    'لا يمكن فتح متجر التطبيقات: ${url.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
