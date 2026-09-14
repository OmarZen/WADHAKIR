import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';

/// Renders the two "glass" prayer widgets (Prayer Detail + Prayer Next) as
/// Flutter-drawn PNG images via [HomeWidget.renderFlutterWidget], then tells
/// the native providers to refresh.
///
/// A rendered image has nothing behind it to blur, so these widgets paint a
/// *faux-glass* dark gradient card (not a real [BackdropFilter]) — it matches
/// the screenshots and is theme-independent. The countdown is a snapshot at
/// render time; it refreshes whenever prayer times recompute or the app is
/// resumed (renderFlutterWidget can't run while the app is fully backgrounded).
class GlassPrayerHomeWidget {
  static const String detailWidgetProvider = 'GlassPrayerDetailWidgetProvider';
  static const String nextWidgetProvider = 'GlassPrayerNextWidgetProvider';

  static const String _detailImageKey = 'glass_prayer_detail_image';
  static const String _nextImageKey = 'glass_prayer_next_image';

  static const Size _detailSize = Size(360, 172);
  static const Size _nextSize = Size(360, 172);

  static Future<void> updateGlassWidgets(PrayerTimesModel model) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return;

    try {
      final vm = _buildViewModel(model);

      await HomeWidget.renderFlutterWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _GlassPrayerCard(
            width: _detailSize.width,
            height: _detailSize.height,
            child: _DetailContent(vm: vm),
          ),
        ),
        key: _detailImageKey,
        logicalSize: _detailSize,
        pixelRatio: 3.0,
      );

      await HomeWidget.renderFlutterWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _GlassPrayerCard(
            width: _nextSize.width,
            height: _nextSize.height,
            child: _NextContent(vm: vm),
          ),
        ),
        key: _nextImageKey,
        logicalSize: _nextSize,
        pixelRatio: 3.0,
      );

      await HomeWidget.updateWidget(
        androidName: detailWidgetProvider,
        iOSName: 'GlassPrayerDetailWidget',
        qualifiedAndroidName: 'com.bloom.wadhakir.$detailWidgetProvider',
      );
      await HomeWidget.updateWidget(
        androidName: nextWidgetProvider,
        iOSName: 'GlassPrayerNextWidget',
        qualifiedAndroidName: 'com.bloom.wadhakir.$nextWidgetProvider',
      );

      debugPrint('✅ Glass prayer widgets rendered + updated');
    } catch (e) {
      debugPrint('❌ Error updating glass prayer widgets: $e');
    }
  }

  static _GlassVM _buildViewModel(PrayerTimesModel model) {
    final now = DateTime.now();
    final rowFmt = DateFormat('h:mm');
    final bigFmt = DateFormat('HH:mm');

    final cells = <_Cell>[
      _Cell('Fajr', rowFmt.format(model.fajr)),
      _Cell('Dhuhr', rowFmt.format(model.dhuhr)),
      _Cell('Asr', rowFmt.format(model.asr)),
      _Cell('Maghrib', rowFmt.format(model.maghrib)),
      _Cell('Isha', rowFmt.format(model.isha)),
    ];

    // Highlighted dot = next upcoming among the five row prayers.
    final rowTimes = [
      model.fajr,
      model.dhuhr,
      model.asr,
      model.maghrib,
      model.isha,
    ];
    var highlightIndex = rowTimes.indexWhere(now.isBefore);
    if (highlightIndex < 0) highlightIndex = 0;

    // Progress through the current → next prayer interval (includes sunrise).
    final total = model.totalIntervalBetweenPrayers.inSeconds;
    final remaining = model.timeUntilNextPrayer.inSeconds;
    final progress = (total > 0 ? 1 - remaining / total : 0.0).clamp(0.0, 1.0);

    final d = model.timeUntilNextPrayer;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final countdown = h > 0 ? '${h}h ${m}m' : '${m}m';

    final nextAr = model.nextPrayerName;
    final hijri = HijriDateTime.fromDateTime(now);

    return _GlassVM(
      cells: cells,
      highlightIndex: highlightIndex,
      progress: progress.toDouble(),
      countdown: countdown,
      nextNameAr: nextAr,
      nextNameEn: _englishName(nextAr),
      nextTimeBig: bigFmt.format(model.nextPrayer),
      headerLine1:
          '${DateFormat('EEEE', 'en_US').format(now)}, '
          '${hijri.day} ${_hijriMonthEn(hijri.month)}',
      headerLine2: DateFormat('d MMMM', 'en_US').format(now),
    );
  }

  static String _englishName(String ar) {
    switch (ar) {
      case 'الفجر':
        return 'Fajr';
      case 'الشروق':
        return 'Sunrise';
      case 'الظهر':
        return 'Dhuhr';
      case 'العصر':
        return 'Asr';
      case 'المغرب':
        return 'Maghrib';
      case 'العشاء':
        return 'Isha';
      case 'منتصف الليل':
        return 'Midnight';
      case 'الثلث الأخير من الليل':
        return 'Last Third';
      default:
        return ar;
    }
  }

  static String _hijriMonthEn(int m) {
    const names = [
      'Muharram',
      'Safar',
      'Rabi al-Awwal',
      'Rabi al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      "Sha'ban",
      'Ramadan',
      'Shawwal',
      "Dhu al-Qi'dah",
      'Dhu al-Hijjah',
    ];
    return (m >= 1 && m <= 12) ? names[m - 1] : '';
  }
}

// ---------------------------------------------------------------------------
// View model
// ---------------------------------------------------------------------------

class _Cell {
  final String name;
  final String time;
  const _Cell(this.name, this.time);
}

class _GlassVM {
  final List<_Cell> cells;
  final int highlightIndex;
  final double progress;
  final String countdown;
  final String nextNameAr;
  final String nextNameEn;
  final String nextTimeBig;
  final String headerLine1;
  final String headerLine2;

  const _GlassVM({
    required this.cells,
    required this.highlightIndex,
    required this.progress,
    required this.countdown,
    required this.nextNameAr,
    required this.nextNameEn,
    required this.nextTimeBig,
    required this.headerLine1,
    required this.headerLine2,
  });
}

// ---------------------------------------------------------------------------
// Render-only widgets (no Theme/MediaQuery ancestor off-screen — all styles
// are explicit constants).
// ---------------------------------------------------------------------------

const _accent = Color(0xFF8FB8E0);

TextStyle _ts(
  double size, {
  FontWeight weight = FontWeight.w400,
  double alpha = 1.0,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Almarai',
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: Colors.white.withValues(alpha: alpha),
  );
}

/// The card content is authored at a fixed reference size, then scaled with a
/// [FittedBox] to fit whatever size the card is rendered at. This makes the
/// layout overflow-proof and responsive to any widget cell size — content can
/// never overflow because it is always scaled down to fit.
const Size _designSize = Size(316, 144);

Widget _fit(Widget child) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: _designSize.width,
        height: _designSize.height,
        child: child,
      ),
    ),
  );
}

class _GlassPrayerCard extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _GlassPrayerCard({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Deep base gradient.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF27324F), Color(0xFF0B0E18)],
                ),
              ),
            ),
            // 2. Soft coloured light orbs, heavily blurred → the frosted-glass
            //    glow (ImageFiltered renders reliably off-screen).
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
              child: Stack(
                children: [
                  Positioned(
                    top: -55,
                    right: -25,
                    child: _orb(170, const Color(0xFF4E7FE1)),
                  ),
                  Positioned(
                    bottom: -65,
                    left: -35,
                    child: _orb(200, const Color(0xFF8A5CD0)),
                  ),
                  Positioned(
                    bottom: -28,
                    right: 70,
                    child: _orb(120, const Color(0xFF2FA6C9)),
                  ),
                ],
              ),
            ),
            // 3. Frost veil unifying the blur into a glass surface.
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
            // 4. Specular sheen along the top edge.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // 5. Hairline glass border.
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
            ),
            // 6. Content.
            child,
          ],
        ),
      ),
    );
  }

  static Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final _GlassVM vm;
  const _DetailContent({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _fit(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.headerLine1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(16, weight: FontWeight.w700, height: 1.15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vm.headerLine2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(13, alpha: 0.6, height: 1.15),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    vm.nextNameEn,
                    maxLines: 1,
                    style: _ts(26, weight: FontWeight.w700, height: 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'in ${vm.countdown}',
                    maxLines: 1,
                    style: _ts(13, alpha: 0.7, height: 1.15),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _PrayerRow(vm: vm),
        ],
      ),
    );
  }
}

class _NextContent extends StatelessWidget {
  final _GlassVM vm;
  const _NextContent({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _fit(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.nextTimeBig,
                      maxLines: 1,
                      style: _ts(32, weight: FontWeight.w700, height: 1.0),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Next prayer in',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(12, alpha: 0.55, height: 1.15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vm.countdown,
                      maxLines: 1,
                      style: _ts(
                        16,
                        weight: FontWeight.w700,
                        alpha: 0.9,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Cap the calligraphy width and scale long prayer names down so
              // they never overflow the row.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    vm.nextNameAr,
                    maxLines: 1,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'ArefRuqaa',
                      fontSize: 38,
                      height: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _PrayerRow(vm: vm),
        ],
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final _GlassVM vm;
  const _PrayerRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(vm.cells.length, (i) {
            final cell = vm.cells[i];
            final isCurrent = i == vm.highlightIndex;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: isCurrent ? 1.0 : 0.26,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    cell.name,
                    maxLines: 1,
                    style: _ts(10, alpha: 0.6, height: 1.2),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cell.time,
                    maxLines: 1,
                    style: _ts(12.5, weight: FontWeight.w700, height: 1.1),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 13),
        _ProgressBar(progress: vm.progress),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            children: [
              Container(
                width: w,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                width: w * progress.clamp(0.0, 1.0),
                height: 5,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
