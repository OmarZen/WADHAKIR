import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

const Color prayerPrimaryColor = Color(0xFF20497D);

class PrayerTimesLoadingWidget extends StatelessWidget {
  final Size size;
  final Animation<double> fadeAnimation;

  const PrayerTimesLoadingWidget({
    super.key,
    required this.size,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FadeTransition(
      opacity: fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading container
            Container(
              width: size.width * 0.3,
              height: size.width * 0.3,
              decoration: BoxDecoration(
                color: prayerPrimaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.04),
                child: CircularProgressIndicator(
                  color: prayerPrimaryColor,
                  strokeWidth: 3,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.03),
            Text(
              l10n?.translate('prayer_times.loading') ??
                  "جاري تحميل مواقيت الصلاة...",
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: prayerPrimaryColor,
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Container(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
              child: Text(
                l10n?.translate('prayer_times.location_service') ??
                    "نقوم بتحديد موقعك وحساب مواقيت الصلاة",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: size.width * 0.035,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
