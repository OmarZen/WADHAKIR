import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.01,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: size.height * 0.01), // Space above header

          // Header with modern design - OUTSIDE BlocBuilder so always accessible
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
                            theme.colorScheme.primary.withValues(alpha: 0.8),
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
                      l10n?.translate('home.prayer_times') ?? 'Prayer Times',
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
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                          ],
                        ),
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
                          Text(
                            l10n?.translate('home.view_all') ?? 'عرض الكل',
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

          // BlocBuilder only for prayer times content
          BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
            builder: (context, state) {
              if (state is PrayerTimesLoaded &&
                  state.selectedPrayerTimes != null) {
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
                  {
                    'name':
                        l10n?.translate('prayer_times.middle_of_the_night') ??
                            'منتصف الليل',
                    'time': prayerTimes.middleOfTheNight,
                    'icon': Icons.bedtime_outlined,
                  },
                  {
                    'name': l10n?.translate(
                            'prayer_times.last_third_of_the_night') ??
                        'الثلث الأخير من الليل',
                    'time': prayerTimes.lastThirdOfTheNight,
                    'icon': Icons.nightlight,
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
                  nextPrayerTime =
                      prayerTimes.fajr.add(const Duration(days: 1));
                  nextPrayerName = l10n?.translate('home.fajr') ?? 'الفجر';
                }

                // Main prayer times
                final mainPrayers = [
                  {
                    'label': l10n?.translate('home.fajr') ?? 'الفجر',
                    'time': prayerTimes.fajr,
                    'icon': Icons.brightness_2_outlined,
                  },
                  {
                    'label': l10n?.translate('home.dhuhr') ?? 'الظهر',
                    'time': prayerTimes.dhuhr,
                    'icon': Icons.wb_sunny_outlined,
                  },
                  {
                    'label': l10n?.translate('home.asr') ?? 'العصر',
                    'time': prayerTimes.asr,
                    'icon': Icons.wb_sunny,
                  },
                  {
                    'label': l10n?.translate('home.maghrib') ?? 'المغرب',
                    'time': prayerTimes.maghrib,
                    'icon': Icons.nightlight_round,
                  },
                  {
                    'label': l10n?.translate('home.isha') ?? 'العشاء',
                    'time': prayerTimes.isha,
                    'icon': Icons.nights_stay_outlined,
                  },
                ];

                // Qiyam prayer times
                final qiyamPrayers = [
                  {
                    'label':
                        l10n?.translate('prayer_times.middle_of_the_night') ??
                            'منتصف الليل',
                    'time': prayerTimes.middleOfTheNight,
                    'icon': Icons.bedtime_outlined,
                  },
                  {
                    'label': l10n?.translate(
                            'prayer_times.last_third_of_the_night') ??
                        'الثلث الأخير',
                    'time': prayerTimes.lastThirdOfTheNight,
                    'icon': Icons.nightlight,
                  },
                ];

                // Compute live remaining time
                final remaining = nextPrayerTime.difference(now);
                final rh = remaining.isNegative ? 0 : remaining.inHours;
                final rm = remaining.isNegative ? 0 : remaining.inMinutes % 60;
                final rs = remaining.isNegative ? 0 : remaining.inSeconds % 60;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
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

                    // Main prayer times row
                    Row(
                      children: [
                        for (int i = 0; i < mainPrayers.length; i++)
                          Expanded(
                            child: _PrayerTile(
                              label: mainPrayers[i]['label'] as String,
                              time: mainPrayers[i]['time'] as DateTime,
                              isNext: (mainPrayers[i]['label'] as String) ==
                                  nextPrayerName,
                              iconData: mainPrayers[i]['icon'] as IconData,
                              size: size,
                              theme: theme,
                              isFirst: i == 0,
                              isLast: i == mainPrayers.length - 1,
                            ),
                          ),
                      ],
                    ),

                    // Separator
                    Container(
                      margin: EdgeInsets.symmetric(
                        vertical: size.height * 0.005,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.02,
                            ),
                            child: Text(
                              l10n?.translate('prayer_times.qiyam_times') ??
                                  'أوقات القيام',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Qiyam prayer times row - simple design
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.03,
                        vertical: size.height * 0.012,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Midnight prayer
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    l10n?.translate(
                                            'prayer_times.middle_of_the_night') ??
                                        'منتصف الليل',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  ' : ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat('hh:mm').format(
                                      qiyamPrayers[0]['time'] as DateTime),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Vertical divider
                          Container(
                            height: 25,
                            width: 1,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),

                          // Last third prayer
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    l10n?.translate(
                                            'prayer_times.last_third_of_the_night') ??
                                        'الثلث الأخير',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  ' : ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat('hh:mm').format(
                                      qiyamPrayers[1]['time'] as DateTime),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Loading state
              return Container(
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
          ),
        ],
      ),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool isNext;
  final IconData iconData;
  final Size size;
  final ThemeData theme;
  final bool isFirst;
  final bool isLast;

  const _PrayerTile({
    required this.label,
    required this.time,
    required this.isNext,
    required this.iconData,
    required this.size,
    required this.theme,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm').format(time);

    return Container(
      margin: EdgeInsets.only(
        left: isFirst ? 0 : size.width * 0.01,
        right: isLast ? 0 : size.width * 0.01,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.01,
          vertical: size.height * 0.01,
        ),
        decoration: BoxDecoration(
          color: isNext ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNext
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: isNext
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isNext
                    ? Colors.white.withValues(alpha: 0.2)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isNext ? Colors.white : theme.colorScheme.primary,
                size: 16,
              ),
            ),

            SizedBox(height: size.height * 0.006),

            // Prayer name
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isNext ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
              ),
            ),

            SizedBox(height: size.height * 0.003),

            // Time
            Text(
              timeStr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isNext ? Colors.white : theme.colorScheme.primary,
                fontSize: 10,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Location Name Widget - listens to BlocBuilder for location updates
class _LocationNameWidget extends StatelessWidget {
  final ThemeData theme;
  final Size size;

  const _LocationNameWidget({required this.theme, required this.size});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        // Only show location when prayer times are loaded
        if (state is! PrayerTimesLoaded) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<String>(
          future: context.read<PrayerTimesCubit>().getCurrentLocationName(),
          builder: (context, snapshot) {
            // Don't show if loading, no data, or contains coordinates
            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.contains('°')) {
              return const SizedBox.shrink();
            }

            final locationName = snapshot.data!;

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.025,
                vertical: size.height * 0.008,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
