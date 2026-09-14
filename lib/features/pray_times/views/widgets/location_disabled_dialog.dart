import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class LocationDisabledDialog extends StatelessWidget {
  final AppLocalizations? l10n;

  const LocationDisabledDialog({super.key, this.l10n});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final goldColor = isDark ? darkQuranDuaColor : quranDuaColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              padding: EdgeInsets.all(size.width * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(size.width * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_off,
                      color: Colors.white,
                      size: size.width * 0.08,
                    ),
                  ),
                  SizedBox(width: size.width * 0.04),
                  Expanded(
                    child: Text(
                      l10n?.translate(
                            'prayer_times.location_services_disabled_title',
                          ) ??
                          'خدمات الموقع معطلة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.048,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(size.width * 0.05),
              child: Column(
                children: [
                  // Info icon and message
                  Icon(
                    Icons.info_outline,
                    size: size.width * 0.15,
                    color: goldColor,
                  ),
                  SizedBox(height: size.height * 0.02),

                  Text(
                    l10n?.translate('prayer_times.using_mecca_location') ??
                        'يتم استخدام موقع مكة المكرمة كموقع افتراضي',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width * 0.042,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontFamily: 'Almarai',
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),

                  Text(
                    l10n?.translate('prayer_times.enable_location_message') ??
                        'للحصول على أوقات الصلاة الدقيقة لموقعك الحالي، يرجى تفعيل خدمات الموقع من إعدادات جهازك.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width * 0.036,
                      color: Colors.grey[600],
                      height: 1.5,
                      fontFamily: 'Almarai',
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),

                  // Mecca coordinates info
                  Container(
                    margin: EdgeInsets.symmetric(vertical: size.height * 0.015),
                    padding: EdgeInsets.all(size.width * 0.04),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.colorScheme.primary,
                          size: size.width * 0.06,
                        ),
                        SizedBox(width: size.width * 0.03),
                        Expanded(
                          child: Text(
                            l10n?.translate('prayer_times.mecca_location') ??
                                'مكة المكرمة (21.42°, 39.83°)',
                            style: TextStyle(
                              fontSize: size.width * 0.035,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                              fontFamily: 'Almarai',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.fromLTRB(
                size.width * 0.04,
                0,
                size.width * 0.04,
                size.width * 0.04,
              ),
              child: Column(
                children: [
                  // Open Settings button
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: () async {
                        await Geolocator.openLocationSettings();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      prefix: const Icon(Icons.settings),
                      child: Text(
                        l10n?.translate(
                              'prayer_times.open_location_settings',
                            ) ??
                            'فتح إعدادات الموقع',
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      variant: FButtonVariant.ghost,
                      onPress: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        l10n?.translate('prayer_times.continue_with_mecca') ??
                            'المتابعة مع مكة المكرمة',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
