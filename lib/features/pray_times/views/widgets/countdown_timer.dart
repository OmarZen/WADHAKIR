import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class CountdownTimer extends StatefulWidget {
  final Duration timeLeft;
  final String nextPrayerName;
  final Duration totalInterval;

  const CountdownTimer({
    super.key,
    required this.timeLeft,
    required this.nextPrayerName,
    required this.totalInterval,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _remainingTime;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.timeLeft;

    // Animation for pulsing effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start timer that updates every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    // Calculate progress percentage (inverted because we're counting down)
    final progress = widget.totalInterval.inSeconds > 0
        ? 1 - (_remainingTime.inSeconds / widget.totalInterval.inSeconds)
        : 0.0;

    // Format time
    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes % 60;
    final seconds = _remainingTime.inSeconds % 60;

    final formattedTime =
        '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n?.translate('prayer_times.time_until_next_prayer') ??
                  'الوقت المتبقي حتى',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.normal,
              ),
            ),
            SizedBox(width: size.width * 0.02),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Text(
                    widget.nextPrayerName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.055,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Almarai',
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: size.height * 0.02),

        // Time display with decorative elements
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.06, vertical: size.height * 0.01),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: size.width * 0.05,
                  ),
                  SizedBox(width: size.width * 0.02),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.07,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontFamily: 'Digital',
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.01),
              // Progress bar with animated fill
              Container(
                height: size.height * 0.015,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: (size.width - (size.width * 0.08)) *
                          progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.7),
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.01),
            ],
          ),
        ),
      ],
    );
  }
}
