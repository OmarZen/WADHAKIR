import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/islamic_icons.dart';
import 'package:wadhakir/features/pray_times/views/widgets/countdown_timer.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'dart:math' show pi, cos, sin;

class EnhancedDateCard extends StatelessWidget {
  final DateTime selectedDate;
  final PrayerTimesModel? prayerTimes;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onCalendarToggle;

  const EnhancedDateCard({
    super.key,
    required this.selectedDate,
    required this.prayerTimes,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onCalendarToggle,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);
    final primaryColor = const Color(0xFF20497D);

    // Check if today
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    // Convert to Hijri date
    final hijriDate = HijriCalendar.fromDate(selectedDate);

    // Format dates
    final gregorianDate = DateFormat.yMMMEd().format(selectedDate);
    final dayName = isToday
        ? l10n?.translate('today') ?? 'اليوم'
        : DateFormat.EEEE().format(selectedDate);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.01,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFDAA520).withValues(alpha: 0.8), // Gold
              primaryColor.withValues(alpha: 0.95), // Primary blue
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle Islamic pattern background
              Positioned.fill(
                child: Opacity(
                  opacity: 0.07,
                  child: CustomPaint(
                    painter: _IslamicPatternPainter(
                      color: Colors.white,
                      gridSize: 30,
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  // Date navigation row
                  Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDateNavigationButton(
                          context,
                          Icons.chevron_left,
                          onPreviousDay,
                        ),

                        // Date information - tappable to show calendar
                        GestureDetector(
                          onTap: onCalendarToggle,
                          child: Column(
                            children: [
                              // Day name with highlight for today
                              if (isToday)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width * 0.03,
                                    vertical: size.height * 0.004,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.today,
                                        color: Colors.white,
                                        size: size.width * 0.04,
                                      ),
                                      SizedBox(width: size.width * 0.01),
                                      Text(
                                        dayName,
                                        style: TextStyle(
                                          fontSize: size.width * 0.035,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: size.width * 0.035,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),

                              SizedBox(height: size.height * 0.01),

                              // Gregorian date
                              Text(
                                gregorianDate,
                                style: TextStyle(
                                  fontSize: size.width * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Almarai',
                                ),
                              ),

                              // Islamic divider
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: size.height * 0.01),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: size.width * 0.08,
                                      child: Divider(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 4),
                                      child: IslamicIcons.ornamentIcon(
                                        size: size.width * 0.03,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    SizedBox(
                                      width: size.width * 0.08,
                                      child: Divider(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Hijri date
                              Text(
                                '${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear}هـ',
                                style: TextStyle(
                                  fontSize: size.width * 0.04,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontFamily: 'Almarai',
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildDateNavigationButton(
                          context,
                          Icons.chevron_right,
                          onNextDay,
                        ),
                      ],
                    ),
                  ),

                  // Countdown timer for today
                  if (isToday && prayerTimes != null) ...[
                    // Islamic ornament separator
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: size.height * 0.01),
                      child: IslamicIcons.ornamentIcon(
                        size: size.width * 0.06,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),

                    // Countdown timer
                    Padding(
                      padding: EdgeInsets.only(
                        left: size.width * 0.04,
                        right: size.width * 0.04,
                        bottom: size.height * 0.03,
                      ),
                      child: CountdownTimer(
                        timeLeft: prayerTimes!.timeUntilNextPrayer,
                        nextPrayerName: prayerTimes!.nextPrayerName,
                        totalInterval: prayerTimes!.totalIntervalBetweenPrayers,
                      ),
                    ),
                  ] else ...[
                    // Spacer for aesthetic balance when no countdown
                    SizedBox(height: size.height * 0.01),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateNavigationButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: size.width * 0.055,
        splashRadius: size.width * 0.06,
      ),
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double gridSize;

  _IslamicPatternPainter({
    required this.color,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Calculate grid dimensions
    final cols = (size.width / gridSize).ceil() + 1;
    final rows = (size.height / gridSize).ceil() + 1;

    // Draw the pattern
    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final centerX = i * gridSize;
        final centerY = j * gridSize;

        if ((i + j) % 2 == 0) {
          // Draw octagon
          final path = Path();
          final r = gridSize / 3;

          path.moveTo(centerX, centerY - r);
          path.lineTo(centerX + r * 0.7, centerY - r * 0.7);
          path.lineTo(centerX + r, centerY);
          path.lineTo(centerX + r * 0.7, centerY + r * 0.7);
          path.lineTo(centerX, centerY + r);
          path.lineTo(centerX - r * 0.7, centerY + r * 0.7);
          path.lineTo(centerX - r, centerY);
          path.lineTo(centerX - r * 0.7, centerY - r * 0.7);
          path.close();

          canvas.drawPath(path, paint);
        } else {
          // Draw star
          final path = Path();
          final outerRadius = gridSize / 3;
          final innerRadius = outerRadius * 0.4;
          final numPoints = 8;

          for (var k = 0; k < numPoints * 2; k++) {
            final radius = k % 2 == 0 ? outerRadius : innerRadius;
            final angle = k * pi / numPoints;
            final x = centerX + radius * cos(angle);
            final y = centerY + radius * sin(angle);

            if (k == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }

          path.close();
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
