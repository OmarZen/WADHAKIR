import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/utils/calculation_method_mapper.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/features/pray_times/views/widgets/prayer_card.dart';
import 'package:wadhakir/features/pray_times/views/widgets/countdown_timer.dart';

class PrayerTimesContent extends StatelessWidget {
  final PrayerTimesLoaded state;
  final Size size;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const PrayerTimesContent({
    super.key,
    required this.state,
    required this.size,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prayerTimes = state.selectedPrayerTimes;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    if (prayerTimes == null) {
      return Center(
        child: Text(
          l10n?.translate('prayer_times.no_prayer_times_available') ??
              'لا توجد مواقيت صلاة متاحة لهذا التاريخ',
          style: TextStyle(color: theme.colorScheme.tertiary),
        ),
      );
    }

    final now = DateTime.now();
    final selectedDate = state.selectedDate;
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Column(
              children: [
                _buildDateCard(
                    context, selectedDate, isToday, prayerTimes, theme, isDark),
                SizedBox(height: size.height * 0.03),

                // Prayer Times Grid or List based on screen width
                size.width > 600
                    ? _buildPrayerTimesGrid(
                        context, prayerTimes, isToday, isDark)
                    : _buildPrayerTimesList(
                        context, prayerTimes, isToday, isDark),

                // Qiyam times info card
                _buildQiyamTimesInfo(context, theme),

                _buildCalculationMethodInfo(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard(
    BuildContext context,
    DateTime selectedDate,
    bool isToday,
    dynamic prayerTimes,
    ThemeData theme,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final hijriDate = HijriCalendar.fromDate(selectedDate);
    final gregorianDate = DateFormat.yMMMEd().format(selectedDate);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: size.height * 0.03),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.3, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Date navigation arrows and date display
          Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildArrowButton(
                  icon: Icons.arrow_back_ios,
                  onPressed: () {
                    context.read<PrayerTimesCubit>().previousDay();
                  },
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isToday
                            ? (l10n?.translate('prayer_times.today') ?? 'اليوم')
                            : gregorianDate,
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear} هـ',
                        style: TextStyle(
                          fontSize: size.width * 0.045,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                _buildArrowButton(
                  icon: Icons.arrow_forward_ios,
                  onPressed: () {
                    context.read<PrayerTimesCubit>().nextDay();
                  },
                ),
              ],
            ),
          ),

          // Countdown timer if today
          if (isToday)
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: size.height * 0.02,
              ),
              padding: EdgeInsets.all(size.width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: CountdownTimer(
                timeLeft: prayerTimes.timeUntilNextPrayer,
                nextPrayerName: prayerTimes.nextPrayerName,
                totalInterval: prayerTimes.totalIntervalBetweenPrayers,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesGrid(
    BuildContext context,
    dynamic prayerTimes,
    bool isToday,
    bool isDark,
  ) {
    final l10n = context.l10n;

    // Use theme colors
    final fajrColor = isDark ? darkMorningAzkarColor : morningAzkarColor;
    final sunriseColor = isDark ? darkMosqueAzkarColor : mosqueAzkarColor;
    final dhuhrColor = isDark ? darkQuranDuaColor : quranDuaColor;
    final asrColor = isDark ? darkPrayerAzkarColor : prayerAzkarColor;
    final maghribColor = isDark ? darkSleepAzkarColor : sleepAzkarColor;
    final ishaColor = isDark ? darkEveningAzkarColor : eveningAzkarColor;
    final midnightColor = isDark ? darkMidnightPrayerColor : midnightPrayerColor;
    final lastThirdColor = isDark ? darkLastThirdPrayerColor : lastThirdPrayerColor;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        PrayerCard(
          size: size,
          icon: Icons.brightness_2_outlined,
          prayerName: l10n?.translate('prayer_times.fajr') ?? 'الفجر',
          prayerTime: prayerTimes.formatTime(prayerTimes.fajr),
          isNext: isToday && prayerTimes.nextPrayerName == 'الفجر',
          color: fajrColor,
          animation: fadeAnimation,
          delay: 0.1,
        ),
        PrayerCard(
          size: size,
          icon: Icons.wb_sunny_outlined,
          prayerName: l10n?.translate('prayer_times.sunrise') ?? 'الشروق',
          prayerTime: prayerTimes.formatTime(prayerTimes.sunrise),
          isNext: isToday && prayerTimes.nextPrayerName == 'الشروق',
          color: sunriseColor,
          animation: fadeAnimation,
          delay: 0.2,
        ),
        PrayerCard(
          size: size,
          icon: Icons.light_mode_outlined,
          prayerName: l10n?.translate('prayer_times.dhuhr') ?? 'الظهر',
          prayerTime: prayerTimes.formatTime(prayerTimes.dhuhr),
          isNext: isToday && prayerTimes.nextPrayerName == 'الظهر',
          color: dhuhrColor,
          animation: fadeAnimation,
          delay: 0.3,
        ),
        PrayerCard(
          size: size,
          icon: Icons.wb_twilight_outlined,
          prayerName: l10n?.translate('prayer_times.asr') ?? 'العصر',
          prayerTime: prayerTimes.formatTime(prayerTimes.asr),
          isNext: isToday && prayerTimes.nextPrayerName == 'العصر',
          color: asrColor,
          animation: fadeAnimation,
          delay: 0.4,
        ),
        PrayerCard(
          size: size,
          icon: Icons.nightlight_round,
          prayerName: l10n?.translate('prayer_times.maghrib') ?? 'المغرب',
          prayerTime: prayerTimes.formatTime(prayerTimes.maghrib),
          isNext: isToday && prayerTimes.nextPrayerName == 'المغرب',
          color: maghribColor,
          animation: fadeAnimation,
          delay: 0.5,
        ),
        PrayerCard(
          size: size,
          icon: Icons.nights_stay_outlined,
          prayerName: l10n?.translate('prayer_times.isha') ?? 'العشاء',
          prayerTime: prayerTimes.formatTime(prayerTimes.isha),
          isNext: isToday && prayerTimes.nextPrayerName == 'العشاء',
          color: ishaColor,
          animation: fadeAnimation,
          delay: 0.6,
        ),
        PrayerCard(
          size: size,
          icon: Icons.bedtime_outlined,
          prayerName: l10n?.translate('prayer_times.middle_of_the_night') ??
              'منتصف الليل',
          prayerTime: prayerTimes.formatTime(prayerTimes.middleOfTheNight),
          isNext: isToday && prayerTimes.nextPrayerName == 'منتصف الليل',
          color: midnightColor,
          animation: fadeAnimation,
          delay: 0.7,
        ),
        PrayerCard(
          size: size,
          icon: Icons.nightlight,
          prayerName: l10n?.translate('prayer_times.last_third_of_the_night') ??
              'الثلث الأخير من الليل',
          prayerTime: prayerTimes.formatTime(prayerTimes.lastThirdOfTheNight),
          isNext:
              isToday && prayerTimes.nextPrayerName == 'الثلث الأخير من الليل',
          color: lastThirdColor,
          animation: fadeAnimation,
          delay: 0.8,
        ),
      ],
    );
  }

  Widget _buildPrayerTimesList(
    BuildContext context,
    dynamic prayerTimes,
    bool isToday,
    bool isDark,
  ) {
    final l10n = context.l10n;

    // Use theme colors
    final fajrColor = isDark ? darkMorningAzkarColor : morningAzkarColor;
    final sunriseColor = isDark ? darkMosqueAzkarColor : mosqueAzkarColor;
    final dhuhrColor = isDark ? darkQuranDuaColor : quranDuaColor;
    final asrColor = isDark ? darkPrayerAzkarColor : prayerAzkarColor;
    final maghribColor = isDark ? darkSleepAzkarColor : sleepAzkarColor;
    final ishaColor = isDark ? darkEveningAzkarColor : eveningAzkarColor;
    final midnightColor = isDark ? darkMidnightPrayerColor : midnightPrayerColor;
    final lastThirdColor = isDark ? darkLastThirdPrayerColor : lastThirdPrayerColor;

    return Column(
      children: [
        PrayerCard(
          size: size,
          icon: Icons.brightness_2_outlined,
          prayerName: l10n?.translate('prayer_times.fajr') ?? 'الفجر',
          prayerTime: prayerTimes.formatTime(prayerTimes.fajr),
          isNext: isToday && prayerTimes.nextPrayerName == 'الفجر',
          color: fajrColor,
          animation: fadeAnimation,
          delay: 0.1,
        ),
        PrayerCard(
          size: size,
          icon: Icons.wb_sunny_outlined,
          prayerName: l10n?.translate('prayer_times.sunrise') ?? 'الشروق',
          prayerTime: prayerTimes.formatTime(prayerTimes.sunrise),
          isNext: isToday && prayerTimes.nextPrayerName == 'الشروق',
          color: sunriseColor,
          animation: fadeAnimation,
          delay: 0.2,
        ),
        PrayerCard(
          size: size,
          icon: Icons.light_mode_outlined,
          prayerName: l10n?.translate('prayer_times.dhuhr') ?? 'الظهر',
          prayerTime: prayerTimes.formatTime(prayerTimes.dhuhr),
          isNext: isToday && prayerTimes.nextPrayerName == 'الظهر',
          color: dhuhrColor,
          animation: fadeAnimation,
          delay: 0.3,
        ),
        PrayerCard(
          size: size,
          icon: Icons.wb_twilight_outlined,
          prayerName: l10n?.translate('prayer_times.asr') ?? 'العصر',
          prayerTime: prayerTimes.formatTime(prayerTimes.asr),
          isNext: isToday && prayerTimes.nextPrayerName == 'العصر',
          color: asrColor,
          animation: fadeAnimation,
          delay: 0.4,
        ),
        PrayerCard(
          size: size,
          icon: Icons.nightlight_round,
          prayerName: l10n?.translate('prayer_times.maghrib') ?? 'المغرب',
          prayerTime: prayerTimes.formatTime(prayerTimes.maghrib),
          isNext: isToday && prayerTimes.nextPrayerName == 'المغرب',
          color: maghribColor,
          animation: fadeAnimation,
          delay: 0.5,
        ),
        PrayerCard(
          size: size,
          icon: Icons.nights_stay_outlined,
          prayerName: l10n?.translate('prayer_times.isha') ?? 'العشاء',
          prayerTime: prayerTimes.formatTime(prayerTimes.isha),
          isNext: isToday && prayerTimes.nextPrayerName == 'العشاء',
          color: ishaColor,
          animation: fadeAnimation,
          delay: 0.6,
        ),
        PrayerCard(
          size: size,
          icon: Icons.bedtime_outlined,
          prayerName: l10n?.translate('prayer_times.middle_of_the_night') ??
              'منتصف الليل',
          prayerTime: prayerTimes.formatTime(prayerTimes.middleOfTheNight),
          isNext: isToday && prayerTimes.nextPrayerName == 'منتصف الليل',
          color: midnightColor,
          animation: fadeAnimation,
          delay: 0.7,
        ),
        PrayerCard(
          size: size,
          icon: Icons.nightlight,
          prayerName: l10n?.translate('prayer_times.last_third_of_the_night') ??
              'الثلث الأخير من الليل',
          prayerTime: prayerTimes.formatTime(prayerTimes.lastThirdOfTheNight),
          isNext:
              isToday && prayerTimes.nextPrayerName == 'الثلث الأخير من الليل',
          color: lastThirdColor,
          animation: fadeAnimation,
          delay: 0.8,
        ),
      ],
    );
  }

  Widget _buildCalculationMethodInfo(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;

    return FutureBuilder<CalculationParameters>(
      future: context.read<PrayerTimesCubit>().getCalculationMethod(),
      builder: (context, snapshot) {
        String methodName =
            l10n?.translate('prayer_times.loading_calculation_method') ??
                'جاري تحميل طريقة حساب مواقيت الصلاة';

        if (snapshot.hasData && snapshot.data != null) {
          final calculationMethodName = CalculationMethodMapper.getMethodName(
            snapshot.data!,
          );
          methodName =
              CalculationMethodMapper.getArabicName(calculationMethodName);
        }

        return Container(
          margin: EdgeInsets.only(top: size.height * 0.02),
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: size.width * 0.05,
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Text(
                  '${l10n?.translate('prayer_times.calculation_method') ?? 'طريقة الحساب'}: $methodName',
                  style: TextStyle(
                    fontSize: size.width * 0.032,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQiyamTimesInfo(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    final bool isDark = theme.brightness == Brightness.dark;
    final qiyamInfoColor =
        isDark ? const Color(0xFF4A148C) : const Color(0xFF7B1FA2);

    return Container(
      margin: EdgeInsets.only(top: size.height * 0.02),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            qiyamInfoColor.withValues(alpha: 0.08),
            qiyamInfoColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: qiyamInfoColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: qiyamInfoColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.nightlight,
                  color: qiyamInfoColor,
                  size: size.width * 0.06,
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.translate('prayer_times.qiyam_times') ??
                          'أوقات القيام',
                      style: TextStyle(
                        fontSize: size.width * 0.04,
                        color: qiyamInfoColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    Text(
                      l10n?.translate('prayer_times.qiyam_times_description') ??
                          'أوقات مستحبة لقيام الليل والدعاء',
                      style: TextStyle(
                        fontSize: size.width * 0.028,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
