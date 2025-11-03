import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';

class CompactPrayerCardWidget extends StatefulWidget {
  const CompactPrayerCardWidget({super.key});

  @override
  State<CompactPrayerCardWidget> createState() =>
      _CompactPrayerCardWidgetState();
}

class _CompactPrayerCardWidgetState extends State<CompactPrayerCardWidget> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        if (state is PrayerTimesLoaded && state.selectedPrayerTimes != null) {
          final prayerTimes = state.selectedPrayerTimes!;
          final now = _now;

          // Find next prayer
          final prayers = [
            {
              'name': l10n?.translate('home.fajr') ?? 'الفجر',
              'time': prayerTimes.fajr,
              'icon': Icons.wb_sunny_outlined,
            },
            {
              'name': l10n?.translate('home.dhuhr') ?? 'الظهر',
              'time': prayerTimes.dhuhr,
              'icon': Icons.wb_sunny,
            },
            {
              'name': l10n?.translate('home.asr') ?? 'العصر',
              'time': prayerTimes.asr,
              'icon': Icons.wb_sunny,
            },
            {
              'name': l10n?.translate('home.maghrib') ?? 'المغرب',
              'time': prayerTimes.maghrib,
              'icon': Icons.nightlight_round,
            },
            {
              'name': l10n?.translate('home.isha') ?? 'العشاء',
              'time': prayerTimes.isha,
              'icon': Icons.nightlight_round,
            },
          ];

          DateTime? nextPrayerTime;
          String? nextPrayerName;

          for (final prayer in prayers) {
            final prayerTime = prayer['time'] as DateTime;
            if (prayerTime.isAfter(now)) {
              nextPrayerTime = prayerTime;
              nextPrayerName = prayer['name'] as String;
              break;
            }
          }

          // If no next prayer today, use first prayer tomorrow
          if (nextPrayerTime == null) {
            nextPrayerTime = prayerTimes.fajr.add(const Duration(days: 1));
            nextPrayerName = l10n?.translate('home.fajr') ?? 'الفجر';
          }

          final items = [
            {
              'label': l10n?.translate('home.fajr') ?? 'الفجر',
              'time': prayerTimes.fajr,
              'icon': Icons.brightness_2_outlined,
              'color': isDark ? darkMorningAzkarColor : morningAzkarColor,
              'delay': 0.1,
            },
            {
              'label': l10n?.translate('home.dhuhr') ?? 'الظهر',
              'time': prayerTimes.dhuhr,
              'icon': Icons.wb_sunny_outlined,
              'color': isDark ? darkQuranDuaColor : quranDuaColor,
              'delay': 0.2,
            },
            {
              'label': l10n?.translate('home.asr') ?? 'العصر',
              'time': prayerTimes.asr,
              'icon': Icons.wb_sunny,
              'color': isDark ? darkPrayerAzkarColor : prayerAzkarColor,
              'delay': 0.3,
            },
            {
              'label': l10n?.translate('home.maghrib') ?? 'المغرب',
              'time': prayerTimes.maghrib,
              'icon': Icons.nightlight_round,
              'color': isDark ? darkSleepAzkarColor : sleepAzkarColor,
              'delay': 0.4,
            },
            {
              'label': l10n?.translate('home.isha') ?? 'العشاء',
              'time': prayerTimes.isha,
              'icon': Icons.nights_stay_outlined,
              'color': isDark ? darkEveningAzkarColor : eveningAzkarColor,
              'delay': 0.5,
            },
          ];

          // Compute live remaining time
          final remaining = nextPrayerTime.difference(now);
          final rh = remaining.isNegative ? 0 : remaining.inHours;
          final rm = remaining.isNegative ? 0 : remaining.inMinutes % 60;
          final rs = remaining.isNegative ? 0 : remaining.inSeconds % 60;

          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.01,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.01), // Space above header

                // Header with modern design
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.03,
                    vertical: size.height * 0.01,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                        theme.colorScheme.primary.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n?.translate('home.prayer_times') ??
                                'Prayer Times',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Modern View All Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppConstants.prayerTimesRoute,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.03,
                              vertical: size.height * 0.008,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.15),
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n?.translate('home.view_all') ??
                                      'عرض الكل',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.015),

                // Location and Countdown Timer in same row - simplified
                Row(
                  children: [
                    // Location
                    Expanded(
                      child: _LocationNameWidget(theme: theme, size: size),
                    ),
                    SizedBox(width: size.width * 0.02),
                    // Countdown Timer - simplified
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.025,
                        vertical: size.height * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${rh.toString().padLeft(2, '0')}:${rm.toString().padLeft(2, '0')}:${rs.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.015),

                // Prayer cards horizontal scroll with proper padding for shadows
                Padding(
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.02,
                      vertical: size.height * 0.005,
                    ),
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        for (final item in items)
                          _PrayerTile(
                            label: item['label'] as String,
                            time: item['time'] as DateTime,
                            isNext: (item['label'] as String) == nextPrayerName,
                            iconData: item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: size,
                            theme: theme,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Loading state
        return Container(
          margin: EdgeInsets.all(size.width * 0.04),
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              SizedBox(width: size.width * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerTile extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool isNext;
  final IconData iconData;
  final Color color;
  final Size size;
  final ThemeData theme;

  const _PrayerTile({
    required this.label,
    required this.time,
    required this.isNext,
    required this.iconData,
    required this.color,
    required this.size,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(time);

    return Container(
      width: size.width * 0.22, // More compact: ~90px on standard devices
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.01),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main tile with gradient - reduced shadows
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.015,
              vertical: size.height * 0.012,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isNext
                    ? [
                        color,
                        color.withValues(alpha: 0.85),
                      ]
                    : [
                        color.withValues(alpha: 0.12),
                        color.withValues(alpha: 0.08),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isNext
                    ? color.withValues(alpha: 0.4)
                    : color.withValues(alpha: 0.25),
                width: 1.5,
              ),
              // Reduced shadows to prevent cutoff
              boxShadow: isNext
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isNext
                          ? [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.95),
                            ]
                          : [
                              color.withValues(alpha: 0.15),
                              color.withValues(alpha: 0.1),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: isNext ? color : color.withValues(alpha: 0.9),
                    size: 22,
                  ),
                ),

                SizedBox(height: size.height * 0.008),

                // Prayer name
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isNext ? Colors.white : color,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),

                SizedBox(height: size.height * 0.004),

                // Time with subtle background
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.018,
                    vertical: size.height * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: isNext
                        ? Colors.white.withValues(alpha: 0.25)
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    timeStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isNext ? Colors.white : color,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Next prayer badge
          if (isNext)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.95),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 14,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Location Name Widget - separated to avoid context issues
class _LocationNameWidget extends StatefulWidget {
  final ThemeData theme;
  final Size size;

  const _LocationNameWidget({required this.theme, required this.size});

  @override
  State<_LocationNameWidget> createState() => _LocationNameWidgetState();
}

class _LocationNameWidgetState extends State<_LocationNameWidget> {
  String? _locationName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocationName();
  }

  Future<void> _loadLocationName() async {
    try {
      final cubit = context.read<PrayerTimesCubit>();
      final name = await cubit.getCurrentLocationName();
      if (mounted) {
        setState(() {
          _locationName = name;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _locationName == null || _locationName!.contains('°')) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.size.width * 0.025,
        vertical: widget.size.height * 0.008,
      ),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 16,
            color: widget.theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _locationName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: widget.theme.textTheme.bodySmall?.copyWith(
                color: widget.theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
