import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/grids/feature_grid_card.dart';
import 'package:wadhakir/features/home/views/widgets/mosque_list_bottom_sheet.dart';
import 'package:wadhakir/core/widgets/app_dialog.dart';

class NearestMosqueGridItem extends StatelessWidget {
  const NearestMosqueGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FeatureGridCard(
      icon: Icons.mosque,
      label: l10n?.translate('home.nearest_mosque') ?? 'أقرب مسجد',
      onTap: () => _handleNearestMosqueTap(context),
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

    showFDialog(
      context: context,
      builder: (context, style, animation) => AppDialog(
        title: Text(
          l10n?.translate('home.location_services_disabled') ??
              'خدمات الموقع معطلة',
          style: theme.textTheme.titleLarge,
        ),
        body: Text(
          l10n?.translate('home.location_services_disabled_message') ??
              'يرجى تفعيل خدمات الموقع للعثور على أقرب مسجد',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          FButton(
            onPress: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: Text(
              l10n?.translate('home.enable_location') ?? 'تفعيل الموقع',
            ),
          ),
          FButton(
            onPress: () => Navigator.pop(context),
            variant: FButtonVariant.outline,
            child: Text(l10n?.translate('common.cancel') ?? 'إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    showFDialog(
      context: context,
      builder: (context, style, animation) => AppDialog(
        title: Text(
          l10n?.translate('home.location_permission_denied') ??
              'تم رفض إذن الموقع',
          style: theme.textTheme.titleLarge,
        ),
        body: Text(
          l10n?.translate('home.location_permission_denied_message') ??
              'يرجى منح التطبيق إذن الوصول إلى الموقع للعثور على أقرب مسجد',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          FButton(
            onPress: () => Navigator.pop(context),
            child: Text(l10n?.translate('common.ok') ?? 'موافق'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedPermanentlyDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    showFDialog(
      context: context,
      builder: (context, style, animation) => AppDialog(
        title: Text(
          l10n?.translate('home.location_permission_denied_permanently') ??
              'تم رفض إذن الموقع بشكل دائم',
          style: theme.textTheme.titleLarge,
        ),
        body: Text(
          l10n?.translate(
                'home.location_permission_denied_permanently_message',
              ) ??
              'يرجى الذهاب إلى الإعدادات وتفعيل إذن الموقع للعثور على أقرب مسجد',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          FButton(
            onPress: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Text(
              l10n?.translate('home.open_settings') ?? 'فتح الإعدادات',
            ),
          ),
          FButton(
            onPress: () => Navigator.pop(context),
            variant: FButtonVariant.outline,
            child: Text(l10n?.translate('common.cancel') ?? 'إلغاء'),
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
    showFToast(
      context: context,
      title: Text(message),
      variant: FToastVariant.destructive,
    );
  }
}
