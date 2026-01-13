import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/mosque_list_bottom_sheet.dart';

class NearestMosqueGridItem extends StatelessWidget {
  const NearestMosqueGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = PlatformUtils.isDesktop;

    final padding = isDesktop ? 16.0 : 12.0;
    final verticalPadding = isDesktop ? 12.0 : 10.0;
    final iconPadding = isDesktop ? 10.0 : 8.0;
    final iconSize = isDesktop ? 22.0 : 20.0;
    final spacing = isDesktop ? 12.0 : 10.0;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _handleNearestMosqueTap(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.mosque,
                  size: iconSize,
                  color: isDark
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                      : theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  l10n?.translate('home.nearest_mosque') ?? 'أقرب مسجد',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: isDesktop ? 16 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNearestMosqueTap(BuildContext context) async {
    final l10n = context.l10n;

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;
      _showLocationServicesDialog(context);
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!context.mounted) return;
        _showPermissionDeniedDialog(context);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return;
      _showPermissionDeniedPermanentlyDialog(context);
      return;
    }

    // Show loading indicator
    if (!context.mounted) return;
    _showLoadingSnackBar(
      context,
      l10n?.translate('home.getting_location') ?? 'جارٍ الحصول على موقعك...',
    );

    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show mosque list bottom sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MosqueListBottomSheet(userPosition: position),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar(
        context,
        l10n?.translate('home.failed_to_get_location') ??
            'فشل الحصول على موقعك. يرجى المحاولة مرة أخرى',
      );
    }
  }

  void _showLocationServicesDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n?.translate('home.location_services_disabled') ??
              'خدمات الموقع معطلة',
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          l10n?.translate('home.location_services_disabled_message') ??
              'يرجى تفعيل خدمات الموقع للعثور على أقرب مسجد',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('common.cancel') ?? 'إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: Text(
              l10n?.translate('home.enable_location') ?? 'تفعيل الموقع',
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n?.translate('home.location_permission_denied') ??
              'تم رفض إذن الموقع',
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          l10n?.translate('home.location_permission_denied_message') ??
              'يرجى منح التطبيق إذن الوصول إلى الموقع للعثور على أقرب مسجد',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('common.ok') ?? 'موافق'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedPermanentlyDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n?.translate('home.location_permission_denied_permanently') ??
              'تم رفض إذن الموقع بشكل دائم',
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          l10n?.translate(
                'home.location_permission_denied_permanently_message',
              ) ??
              'يرجى الذهاب إلى الإعدادات وتفعيل إذن الموقع للعثور على أقرب مسجد',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate('common.cancel') ?? 'إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Text(
              l10n?.translate('home.open_settings') ?? 'فتح الإعدادات',
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
