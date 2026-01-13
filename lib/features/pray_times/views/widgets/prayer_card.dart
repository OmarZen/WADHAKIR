import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';

class PrayerCard extends StatelessWidget {
  final Size size;
  final IconData icon;
  final String prayerName;
  final String prayerTime;
  final bool isNext;
  final Color color;
  final Animation<double> animation;
  final double delay;

  const PrayerCard({
    super.key,
    required this.size,
    required this.icon,
    required this.prayerName,
    required this.prayerTime,
    required this.isNext,
    required this.color,
    required this.animation,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Create a delayed animation for staggered effect
    final delayedAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, 1.0, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: delayedAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - delayedAnimation.value)),
          child: Opacity(opacity: delayedAnimation.value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: size.height * 0.02),
        decoration: BoxDecoration(
          color: isNext ? color.withValues(alpha: 0.98) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isNext
                  ? color.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
          border: isNext
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              // Could be used for prayer details, notifications, etc.
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: isNext
                ? Colors.white.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.1),
            highlightColor: isNext
                ? Colors.white.withValues(alpha: 0.05)
                : color.withValues(alpha: 0.05),
            child: Stack(
              children: [
                // Islamic pattern in background
                if (isNext)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Opacity(
                        opacity: 0.08,
                        child: CustomPaint(
                          painter: IslamicPatternPainter(
                            color: Colors.white,
                            gridSize: 40,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Next prayer badge
                if (isNext)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n?.translate('prayer_times.next') ?? 'التالي',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Almarai',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.only(
                    top: isNext ? size.height * 0.05 : size.height * 0.02,
                    left: size.width * 0.04,
                    right: size.width * 0.04,
                    bottom: size.height * 0.02,
                  ),
                  child: Row(
                    children: [
                      // Prayer Icon
                      Container(
                        padding: EdgeInsets.all(size.width * 0.035),
                        decoration: BoxDecoration(
                          color: isNext
                              ? Colors.white.withValues(alpha: 0.25)
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          size: size.width * 0.08,
                          color: isNext ? Colors.white : color,
                        ),
                      ),

                      SizedBox(width: size.width * 0.04),

                      // Prayer Name and Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayerName,
                              style: TextStyle(
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.bold,
                                color: isNext ? Colors.white : Colors.grey[800],
                                fontFamily: 'Almarai',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n?.translate('prayer_times.time_of_pray') ??
                                  'وقت الصلاة',
                              style: TextStyle(
                                fontSize: size.width * 0.030,
                                color: isNext
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Time Display
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.012,
                        ),
                        decoration: BoxDecoration(
                          color: isNext
                              ? Colors.white.withValues(alpha: 0.2)
                              : color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          prayerTime,
                          style: TextStyle(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: isNext ? Colors.white : color,
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
        ),
      ),
    );
  }
}
