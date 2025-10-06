import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';

// Colors aligned with PrayerTimesScreen
const Color _fajrColor = Color(0xFF3498DB);
const Color _dhuhrColor = Color(0xFFDAA520);
const Color _asrColor = Color(0xFF27AE60);
const Color _maghribColor = Color(0xFFE74C3C);
const Color _ishaColor = Color(0xFF8E44AD);

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
              'color': _fajrColor,
              'delay': 0.1,
            },
            {
              'label': l10n?.translate('home.dhuhr') ?? 'الظهر',
              'time': prayerTimes.dhuhr,
              'icon': Icons.wb_sunny_outlined,
              'color': _dhuhrColor,
              'delay': 0.2,
            },
            {
              'label': l10n?.translate('home.asr') ?? 'العصر',
              'time': prayerTimes.asr,
              'icon': Icons.wb_sunny,
              'color': _asrColor,
              'delay': 0.3,
            },
            {
              'label': l10n?.translate('home.maghrib') ?? 'المغرب',
              'time': prayerTimes.maghrib,
              'icon': Icons.nightlight_round,
              'color': _maghribColor,
              'delay': 0.4,
            },
            {
              'label': l10n?.translate('home.isha') ?? 'العشاء',
              'time': prayerTimes.isha,
              'icon': Icons.nights_stay_outlined,
              'color': _ishaColor,
              'delay': 0.5,
            },
          ];

          // Compute live remaining time
          final remaining = nextPrayerTime.difference(now);
          final rh = remaining.isNegative ? 0 : remaining.inHours;
          final rm = remaining.isNegative ? 0 : remaining.inMinutes % 60;
          final rs = remaining.isNegative ? 0 : remaining.inSeconds % 60;

          return Container(
            margin: EdgeInsets.all(size.width * 0.04),
            // subtle card glow using theme primary
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n?.translate('home.prayer_times') ??
                                'Prayer Times',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppConstants.prayerTimesRoute,
                          );
                        },
                        child: Text(
                          l10n?.translate('home.view_all') ?? 'عرض الكل',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (final item in items)
                        _PrayerTile(
                          label: item['label'] as String,
                          time: item['time'] as DateTime,
                          isNext: (item['label'] as String) == nextPrayerName,
                          iconData: item['icon'] as IconData,
                          color: item['color'] as Color,
                          context: context,
                          prayerName: item['label'] as String,
                          prayerTime: DateFormat(
                            'hh:mm a',
                          ).format(item['time'] as DateTime),
                          animation: const AlwaysStoppedAnimation(1.0),
                          delay: item['delay'] as double,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.028,
                    vertical: size.height * 0.004,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_bottom,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${rh.toString().padLeft(2, '0')}:${rm.toString().padLeft(2, '0')}:${rs.toString().padLeft(2, '0')} ${l10n?.translate('home.remaining') ?? 'متبقي'}',
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
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
  final BuildContext context;
  final String prayerName;
  final String prayerTime;
  final Animation<double> animation;
  final double delay;

  const _PrayerTile({
    required this.context,
    required this.prayerName,
    required this.prayerTime,
    required this.isNext,
    required this.color,
    required this.animation,
    required this.delay,
    required this.iconData,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('hh:mm a').format(time);

    final tile = Container(
      width: 115,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Islamic geometric pattern for next prayer
            if (isNext)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.12,
                  child: CustomPaint(
                    painter: IslamicPatternPainter(
                      color: Colors.white,
                      gridSize: 40,
                    ),
                  ),
                ),
              ),
            // Main tile content
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isNext
                    ? color.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      color:
                          isNext ? Colors.white : color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: isNext ? color : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isNext ? Colors.white : color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isNext
                          ? Colors.white.withValues(alpha: 0.25)
                          : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timeStr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isNext ? Colors.white : color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Next-badge in the top-right corner
            if (isNext)
              Positioned(
                right: 60,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active, size: 14, color: color),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return tile;
  }
}
