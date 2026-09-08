import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/utils/calculation_method_mapper.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/features/pray_times/views/widgets/prayer_card.dart';
import 'package:wadhakir/features/pray_times/views/widgets/countdown_timer.dart';
import 'package:wadhakir/features/azkar_reminders/views/widgets/after_prayer_reminder_tile.dart';
import 'package:wadhakir/features/azkar_reminders/views/widgets/qiyam_reminder_tile.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_state.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_fard_status_badge.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_status_sheet.dart';
import 'package:wadhakir/features/salah_tracker/views/widgets/salah_status_ui.dart';

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
    final isToday =
        selectedDate.year == now.year &&
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
                  context,
                  selectedDate,
                  isToday,
                  prayerTimes,
                  theme,
                  isDark,
                ),
                SizedBox(height: size.height * 0.03),

                // Prayer Times Grid or List based on screen width
                size.width > 600
                    ? _buildPrayerTimesGrid(
                        context,
                        prayerTimes,
                        isToday,
                        isDark,
                      )
                    : _buildPrayerTimesList(
                        context,
                        prayerTimes,
                        isToday,
                        isDark,
                      ),

                // Qiyam times info card
                _buildQiyamTimesInfo(context, theme),

                // Contextual reminder toggles (after-prayer azkar + qiyam),
                // placed here because they relate directly to the prayer times.
                _buildRemindersSection(context, theme),

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
    final hijriDate = HijriDateTime.fromDateTime(selectedDate);
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
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hijriDate.day} ${_getHijriMonthName(hijriDate.month)} ${hijriDate.year} هـ',
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
    final midnightColor = isDark
        ? darkMidnightPrayerColor
        : midnightPrayerColor;
    final lastThirdColor = isDark
        ? darkLastThirdPrayerColor
        : lastThirdPrayerColor;

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
          onLogTap: (isToday && _due(prayerTimes, PrayerSlot.fajr))
              ? () => _onFardTap(context, PrayerSlot.fajr)
              : null,
          statusBadge: isToday
              ? SalahFardStatusBadge(
                  slot: PrayerSlot.fajr,
                  due: _due(prayerTimes, PrayerSlot.fajr),
                )
              : null,
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
          onLogTap: (isToday && _due(prayerTimes, PrayerSlot.dhuhr))
              ? () => _onFardTap(context, PrayerSlot.dhuhr)
              : null,
          statusBadge: isToday
              ? SalahFardStatusBadge(
                  slot: PrayerSlot.dhuhr,
                  due: _due(prayerTimes, PrayerSlot.dhuhr),
                )
              : null,
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
          onLogTap: (isToday && _due(prayerTimes, PrayerSlot.asr))
              ? () => _onFardTap(context, PrayerSlot.asr)
              : null,
          statusBadge: isToday
              ? SalahFardStatusBadge(
                  slot: PrayerSlot.asr,
                  due: _due(prayerTimes, PrayerSlot.asr),
                )
              : null,
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
          onLogTap: (isToday && _due(prayerTimes, PrayerSlot.maghrib))
              ? () => _onFardTap(context, PrayerSlot.maghrib)
              : null,
          statusBadge: isToday
              ? SalahFardStatusBadge(
                  slot: PrayerSlot.maghrib,
                  due: _due(prayerTimes, PrayerSlot.maghrib),
                )
              : null,
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
          onLogTap: (isToday && _due(prayerTimes, PrayerSlot.isha))
              ? () => _onFardTap(context, PrayerSlot.isha)
              : null,
          statusBadge: isToday
              ? SalahFardStatusBadge(
                  slot: PrayerSlot.isha,
                  due: _due(prayerTimes, PrayerSlot.isha),
                )
              : null,
        ),
        PrayerCard(
          size: size,
          icon: Icons.bedtime_outlined,
          prayerName:
              l10n?.translate('prayer_times.middle_of_the_night') ??
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
          prayerName:
              l10n?.translate('prayer_times.last_third_of_the_night') ??
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
    final midnightColor = isDark
        ? darkMidnightPrayerColor
        : midnightPrayerColor;
    final lastThirdColor = isDark
        ? darkLastThirdPrayerColor
        : lastThirdPrayerColor;

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
          onLogTap: (isToday && _due(prayerTimes, PrayerSlot.fajr))
              ? () => _onFardTap(context, PrayerSlot.fajr)
              : null,
          statusBadge: isToday
              ? SalahFardStatusBadge(
                  slot: PrayerSlot.fajr,
                  due: _due(prayerTimes, PrayerSlot.fajr),
                )
              : null,
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
          onLogTap: (isToday && _due(prayerTimes, PrayerSlot.dhuhr))
              ? () => _onFardTap(context, PrayerSlot.dhuhr)
              : null,
          statusBadge: isToday
              ? SalahFardStatusBadge(
                  slot: PrayerSlot.dhuhr,
                  due: _due(prayerTimes, PrayerSlot.dhuhr),
                )
              : null,
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
          onLogTap: (isToday && _due(prayerTimes, PrayerSlot.asr))
              ? () => _onFardTap(context, PrayerSlot.asr)
              : null,
          statusBadge: isToday
              ? SalahFardStatusBadge(
                  slot: PrayerSlot.asr,
                  due: _due(prayerTimes, PrayerSlot.asr),
                )
              : null,
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
          onLogTap: (isToday && _due(prayerTimes, PrayerSlot.maghrib))
              ? () => _onFardTap(context, PrayerSlot.maghrib)
              : null,
          statusBadge: isToday
              ? SalahFardStatusBadge(
                  slot: PrayerSlot.maghrib,
                  due: _due(prayerTimes, PrayerSlot.maghrib),
                )
              : null,
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
          onLogTap: (isToday && _due(prayerTimes, PrayerSlot.isha))
              ? () => _onFardTap(context, PrayerSlot.isha)
              : null,
          statusBadge: isToday
              ? SalahFardStatusBadge(
                  slot: PrayerSlot.isha,
                  due: _due(prayerTimes, PrayerSlot.isha),
                )
              : null,
        ),
        PrayerCard(
          size: size,
          icon: Icons.bedtime_outlined,
          prayerName:
              l10n?.translate('prayer_times.middle_of_the_night') ??
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
          prayerName:
              l10n?.translate('prayer_times.last_third_of_the_night') ??
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

  /// Whether [slot]'s adhan time has entered (so it can be logged). A prayer
  /// whose time hasn't arrived yet is shown inactive and is not loggable.
  bool _due(dynamic prayerTimes, PrayerSlot slot) {
    final DateTime t;
    switch (slot) {
      case PrayerSlot.fajr:
        t = prayerTimes.fajr;
      case PrayerSlot.dhuhr:
        t = prayerTimes.dhuhr;
      case PrayerSlot.asr:
        t = prayerTimes.asr;
      case PrayerSlot.maghrib:
        t = prayerTimes.maghrib;
      case PrayerSlot.isha:
        t = prayerTimes.isha;
    }
    return !DateTime.now().isBefore(t);
  }

  /// Log a fard prayer from its prayer-times card. First tap on an unlogged
  /// prayer auto-classifies it (on-time vs late) from the current window and
  /// shows a snackbar to change it; tapping an already-logged prayer opens the
  /// status sheet to edit/clear. Only wired for today's five fard cards.
  Future<void> _onFardTap(BuildContext context, PrayerSlot slot) async {
    final salahCubit = context.read<SalahTrackerCubit>();
    final model = state.selectedPrayerTimes;
    final sel = state.selectedDate;
    final today = DateTime(sel.year, sel.month, sel.day);

    final salahState = salahCubit.state;
    final current = salahState is SalahTrackerLoaded
        ? (salahState.todayStatuses[slot] ?? PrayerStatus.notLogged)
        : PrayerStatus.notLogged;

    if (current == PrayerStatus.notLogged && model != null) {
      final auto = salahCubit.classify(model, slot, DateTime.now());
      await salahCubit.logFard(today, slot, auto);
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            '${SalahStatusUi.slotLabel(context, slot)} • '
            '${SalahStatusUi.statusLabel(context, auto)}',
          ),
          action: SnackBarAction(
            label: context.l10n?.translate('salah_tracker.change') ?? 'تغيير',
            onPressed: () async {
              final chosen = await showSalahStatusSheet(
                context,
                slot: slot,
                current: auto,
              );
              if (chosen != null) {
                await salahCubit.logFard(today, slot, chosen);
              }
            },
          ),
        ),
      );
    } else {
      final chosen = await showSalahStatusSheet(
        context,
        slot: slot,
        current: current,
      );
      if (chosen != null) await salahCubit.logFard(today, slot, chosen);
    }
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
          methodName = CalculationMethodMapper.getArabicName(
            calculationMethodName,
          );
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
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Contextual azkar reminder toggles shown on the prayer-times page so the
  /// user can enable the after-prayer azkar and Qiyam reminders right where
  /// they're relevant (these also live on the azkar settings page).
  Widget _buildRemindersSection(BuildContext context, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(top: size.height * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n?.translate('azkar_reminders.title') ??
                    'تذكيرات الأذكار',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const AfterPrayerReminderTile(),
          const SizedBox(height: 8),
          const QiyamReminderTile(),
        ],
      ),
    );
  }

  Widget _buildQiyamTimesInfo(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    final bool isDark = theme.brightness == Brightness.dark;
    final qiyamInfoColor = isDark
        ? const Color(0xFF4A148C)
        : const Color(0xFF7B1FA2);

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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
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

String _getHijriMonthName(int month) {
  const monthNames = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];
  return month >= 1 && month <= 12 ? monthNames[month - 1] : '';
}
