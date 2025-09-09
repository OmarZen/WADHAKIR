import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/islamic_icons.dart';
import 'package:adhan/adhan.dart' show CalculationMethod;
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_usecase.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/data/repositories/prayer_times_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_calculation_method_usecase.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_range_usecase.dart';
import 'package:wadhakir/domain/usecases/set_calculation_method_usecase.dart';
import 'package:wadhakir/features/pray_times/views/widgets/countdown_timer.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';
import 'package:wadhakir/features/pray_times/views/widgets/prayer_settings_dialog.dart';

// Define color constants for prayer times
const Color prayerPrimaryColor = Color(0xFF20497D); // Primary blue
const Color prayerAccentColor = Color(0xFF3498DB); // Bright blue
const Color prayerGoldColor = Color(0xFFDAA520); // Gold
const Color fajrColor = Color(0xFF3498DB); // Dawn blue
const Color sunriseColor = Color(0xFFE67E22); // Sunrise orange
const Color dhuhrColor = Color(0xFFDAA520); // Noon gold
const Color asrColor = Color(0xFF27AE60); // Afternoon green
const Color maghribColor = Color(0xFFE74C3C); // Sunset red
const Color ishaColor = Color(0xFF8E44AD); // Night purple

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Injecting dependencies manually for now (could be replaced with a proper DI solution)
    final repository = PrayerTimesRepositoryImpl();
    final getPrayerTimesUseCase = GetPrayerTimesUseCase(repository);
    final getPrayerTimesRangeUseCase = GetPrayerTimesRangeUseCase(repository);
    final getCalculationMethodUseCase = GetCalculationMethodUseCase(repository);
    final setCalculationMethodUseCase = SetCalculationMethodUseCase(repository);

    return BlocProvider(
      create: (context) => PrayerTimesCubit(
        getPrayerTimesUseCase,
        getPrayerTimesRangeUseCase,
        getCalculationMethodUseCase,
        setCalculationMethodUseCase,
        repository: repository,
      )..loadPrayerTimes(),
      child: const _PrayerTimesScreenContent(),
    );
  }
}

class _PrayerTimesScreenContent extends StatefulWidget {
  const _PrayerTimesScreenContent();

  @override
  State<_PrayerTimesScreenContent> createState() =>
      _PrayerTimesScreenContentState();
}

class _PrayerTimesScreenContentState extends State<_PrayerTimesScreenContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background with Islamic pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: prayerPrimaryColor,
                  gridSize: 60,
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
              builder: (context, state) {
                if (state is PrayerTimesLoading) {
                  return _buildLoadingState(size, context);
                } else if (state is PrayerTimesLoaded) {
                  return Column(
                    children: [
                      // Custom header instead of AppBar
                      _buildHeader(context, size),

                      // Main prayer times content
                      Expanded(
                        child: _buildPrayerTimesContent(context, state, size),
                      ),
                    ],
                  );
                } else if (state is PrayerTimesError) {
                  return _buildErrorState(context, state, size);
                } else {
                  return _buildLoadingState(size, context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Size size) {
    final l10n = context.l10n;
    return Container(
      padding: EdgeInsets.fromLTRB(
        size.width * 0.04,
        size.height * 0.02,
        size.width * 0.04,
        size.height * 0.02,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.translate('prayer_times.title') ?? 'مواقيت الصلاة',
                  style: TextStyle(
                    fontSize: size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: prayerPrimaryColor,
                    fontFamily: 'Almarai',
                  ),
                ),
                Text(
                  l10n?.translate('prayer_times.daily_prayers') ??
                      'الصلوات اليومية',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: prayerPrimaryColor,
            onPressed: () {
              _showSettings(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesContent(
      BuildContext context, PrayerTimesLoaded state, Size size) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final prayerTimes = state.selectedPrayerTimes;
    if (prayerTimes == null) {
      return Center(
        child: Text(
          l10n?.translate('prayer_times.no_prayer_times_available') ??
              'لا توجد مواقيت صلاة متاحة لهذا التاريخ',
          style: TextStyle(color: Colors.grey[800]),
        ),
      );
    }

    final now = DateTime.now();
    final selectedDate = state.selectedDate;
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    // Convert to Hijri date
    final hijriDate = HijriCalendar.fromDate(selectedDate);

    // Format the Gregorian date
    final gregorianDate = DateFormat.yMMMEd().format(selectedDate);

    // Calculate the fadeIn animations
    final fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    final slideAnimation = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

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
                // Date card with gradient
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: size.height * 0.03),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.9),
                        theme.colorScheme.secondary.withValues(alpha: 0.95),
                      ],
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
                      // Date navigation row
                      Padding(
                        padding: EdgeInsets.all(size.width * 0.04),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildArrowButton(
                              icon: Icons.chevron_left,
                              onPressed: () {
                                context.read<PrayerTimesCubit>().previousDay();
                              },
                            ),
                            Column(
                              children: [
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
                                      Container(
                                        width: size.width * 0.08,
                                        height: 1,
                                        color:
                                            Colors.white.withValues(alpha: 0.6),
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        child: IslamicIcons.ornamentIcon(
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        width: size.width * 0.08,
                                        height: 1,
                                        color:
                                            Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ],
                                  ),
                                ),

                                // Hijri date
                                Text(
                                  '${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear}هـ',
                                  style: TextStyle(
                                    fontSize: size.width * 0.04,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontFamily: 'Almarai',
                                  ),
                                ),
                              ],
                            ),
                            _buildArrowButton(
                              icon: Icons.chevron_right,
                              onPressed: () {
                                context.read<PrayerTimesCubit>().nextDay();
                              },
                            ),
                          ],
                        ),
                      ),

                      // Countdown timer for today
                      if (isToday) ...[
                        // Divider with Islamic pattern
                        Container(
                          width: double.infinity,
                          height: 25,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: CustomPaint(
                            painter: DividerPatternPainter(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                        ),

                        // Countdown timer
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.04,
                            vertical: size.height * 0.02,
                          ),
                          child: CountdownTimer(
                            timeLeft: prayerTimes.timeUntilNextPrayer,
                            nextPrayerName: prayerTimes.nextPrayerName,
                            totalInterval:
                                prayerTimes.totalIntervalBetweenPrayers,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Prayer Times Grid or List based on screen width
                size.width > 600
                    ? _buildPrayerTimesGrid(
                        context, size, prayerTimes, isToday, fadeAnimation)
                    : _buildPrayerTimesList(
                        context, size, prayerTimes, isToday, fadeAnimation),

                // Information about calculation method
                FutureBuilder<CalculationMethod>(
                  future:
                      context.read<PrayerTimesCubit>().getCalculationMethod(),
                  builder: (context, snapshot) {
                    String methodName = l10n?.translate(
                            'prayer_times.loading_calculation_method') ??
                        'جاري التحميل...';

                    if (snapshot.hasData) {
                      switch (snapshot.data) {
                        case CalculationMethod.muslim_world_league:
                          methodName = l10n?.translate(
                                  'prayer_times.muslim_world_league') ??
                              'رابطة العالم الإسلامي';
                          break;
                        case CalculationMethod.egyptian:
                          methodName =
                              l10n?.translate('prayer_times.egyptian') ??
                                  'الهيئة المصرية العامة للمساحة';
                          break;
                        case CalculationMethod.karachi:
                          methodName =
                              l10n?.translate('prayer_times.karachi') ??
                                  'جامعة العلوم الإسلامية، كراتشي';
                          break;
                        case CalculationMethod.umm_al_qura:
                          methodName =
                              l10n?.translate('prayer_times.umm_al_qura') ??
                                  'جامعة أم القرى، مكة المكرمة';
                          break;
                        case CalculationMethod.north_america:
                          methodName =
                              l10n?.translate('prayer_times.north_america') ??
                                  'الجمعية الإسلامية لأمريكا الشمالية';
                          break;
                        default:
                          methodName = l10n?.translate(
                                  'prayer_times.default_calculation_method') ??
                              'طريقة الحساب الافتراضية';
                      }
                    }

                    return Container(
                      margin: EdgeInsets.only(
                        top: size.height * 0.03,
                        bottom: size.height * 0.02,
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${l10n?.translate('prayer_times.calculation_method') ?? 'Prayer times calculation method:'} $methodName',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: size.width * 0.035,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Grid view for larger screens
  Widget _buildPrayerTimesGrid(BuildContext context, Size size,
      dynamic prayerTimes, bool isToday, Animation<double> fadeAnimation) {
    final l10n = context.l10n;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.brightness_2_outlined,
          prayerName: l10n?.translate('prayer_times.fajr') ?? 'الفجر',
          prayerTime: prayerTimes.formatTime(prayerTimes.fajr),
          isNext: isToday && prayerTimes.nextPrayerName == 'الفجر',
          color: fajrColor,
          animation: fadeAnimation,
          delay: 0.1,
        ),
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.wb_sunny_outlined,
          prayerName: l10n?.translate('prayer_times.sunrise') ?? 'الشروق',
          prayerTime: prayerTimes.formatTime(prayerTimes.sunrise),
          isNext: isToday && prayerTimes.nextPrayerName == 'الشروق',
          color: sunriseColor,
          animation: fadeAnimation,
          delay: 0.2,
        ),
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.light_mode_outlined,
          prayerName: l10n?.translate('prayer_times.dhuhr') ?? 'الظهر',
          prayerTime: prayerTimes.formatTime(prayerTimes.dhuhr),
          isNext: isToday && prayerTimes.nextPrayerName == 'الظهر',
          color: dhuhrColor,
          animation: fadeAnimation,
          delay: 0.3,
        ),
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.wb_twilight_outlined,
          prayerName: l10n?.translate('prayer_times.asr') ?? 'العصر',
          prayerTime: prayerTimes.formatTime(prayerTimes.asr),
          isNext: isToday && prayerTimes.nextPrayerName == 'العصر',
          color: asrColor,
          animation: fadeAnimation,
          delay: 0.4,
        ),
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.nightlight_round,
          prayerName: l10n?.translate('prayer_times.maghrib') ?? 'المغرب',
          prayerTime: prayerTimes.formatTime(prayerTimes.maghrib),
          isNext: isToday && prayerTimes.nextPrayerName == 'المغرب',
          color: maghribColor,
          animation: fadeAnimation,
          delay: 0.5,
        ),
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.nights_stay_outlined,
          prayerName: l10n?.translate('prayer_times.isha') ?? 'العشاء',
          prayerTime: prayerTimes.formatTime(prayerTimes.isha),
          isNext: isToday && prayerTimes.nextPrayerName == 'العشاء',
          color: ishaColor,
          animation: fadeAnimation,
          delay: 0.6,
        ),
      ],
    );
  }

  // List view for smaller screens
  Widget _buildPrayerTimesList(BuildContext context, Size size,
      dynamic prayerTimes, bool isToday, Animation<double> fadeAnimation) {
    final l10n = context.l10n;
    return Column(
      children: [
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.brightness_2_outlined,
          prayerName: l10n?.translate('prayer_times.fajr') ?? 'الفجر',
          prayerTime: prayerTimes.formatTime(prayerTimes.fajr),
          isNext: isToday && prayerTimes.nextPrayerName == 'الفجر',
          color: fajrColor,
          animation: fadeAnimation,
          delay: 0.1,
        ),
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.wb_sunny_outlined,
          prayerName: l10n?.translate('prayer_times.sunrise') ?? 'الشروق',
          prayerTime: prayerTimes.formatTime(prayerTimes.sunrise),
          isNext: isToday && prayerTimes.nextPrayerName == 'الشروق',
          color: sunriseColor,
          animation: fadeAnimation,
          delay: 0.2,
        ),
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.light_mode_outlined,
          prayerName: l10n?.translate('prayer_times.dhuhr') ?? 'الظهر',
          prayerTime: prayerTimes.formatTime(prayerTimes.dhuhr),
          isNext: isToday && prayerTimes.nextPrayerName == 'الظهر',
          color: dhuhrColor,
          animation: fadeAnimation,
          delay: 0.3,
        ),
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.wb_twilight_outlined,
          prayerName: l10n?.translate('prayer_times.asr') ?? 'العصر',
          prayerTime: prayerTimes.formatTime(prayerTimes.asr),
          isNext: isToday && prayerTimes.nextPrayerName == 'العصر',
          color: asrColor,
          animation: fadeAnimation,
          delay: 0.4,
        ),
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.nightlight_round,
          prayerName: l10n?.translate('prayer_times.maghrib') ?? 'المغرب',
          prayerTime: prayerTimes.formatTime(prayerTimes.maghrib),
          isNext: isToday && prayerTimes.nextPrayerName == 'المغرب',
          color: maghribColor,
          animation: fadeAnimation,
          delay: 0.5,
        ),
        _buildEnhancedPrayerCard(
          context: context,
          size: size,
          icon: Icons.nights_stay_outlined,
          prayerName: l10n?.translate('prayer_times.isha') ?? 'العشاء',
          prayerTime: prayerTimes.formatTime(prayerTimes.isha),
          isNext: isToday && prayerTimes.nextPrayerName == 'العشاء',
          color: ishaColor,
          animation: fadeAnimation,
          delay: 0.6,
        ),
      ],
    );
  }

  Widget _buildArrowButton(
      {required IconData icon, required VoidCallback onPressed}) {
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

  Widget _buildEnhancedPrayerCard({
    required BuildContext context,
    required Size size,
    required IconData icon,
    required String prayerName,
    required String prayerTime,
    required bool isNext,
    required Color color,
    required Animation<double> animation,
    required double delay,
  }) {
    // Create a delayed animation for staggered effect
    final delayedAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, 1.0, curve: Curves.easeOut),
    );
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: delayedAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - delayedAnimation.value)),
          child: Opacity(
            opacity: delayedAnimation.value,
            child: child,
          ),
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
                      borderRadius: BorderRadius.circular(18),
                      child: Opacity(
                        opacity: 0.1,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.03,
                        vertical: size.height * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: color,
                            size: size.width * 0.04,
                          ),
                          SizedBox(width: size.width * 0.01),
                          Text(
                            l10n?.translate('prayer_times.next') ?? 'التالي',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: size.width * 0.03,
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
                      // Prayer icon with circular background
                      Container(
                        padding: EdgeInsets.all(size.width * 0.03),
                        decoration: BoxDecoration(
                          color: isNext
                              ? Colors.white.withValues(alpha: 0.9)
                              : color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: isNext
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                    spreadRadius: -2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: size.width * 0.06,
                        ),
                      ),
                      SizedBox(width: size.width * 0.04),

                      // Prayer name and time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayerName,
                              style: TextStyle(
                                color: isNext ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: size.width * 0.045,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: size.height * 0.005),
                            Text(
                              l10n?.translate('prayer_times.time_of_pray') ??
                                  "وقت الصلاة",
                              style: TextStyle(
                                color: isNext
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : Colors.black54,
                                fontSize: size.width * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Prayer time with large font
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isNext
                              ? Colors.white.withValues(alpha: 0.25)
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          prayerTime,
                          style: TextStyle(
                            color: isNext ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                            fontSize: size.width * 0.055,
                            height: 1.1,
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

  Widget _buildLoadingState(Size size, BuildContext context) {
    final fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
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

  Widget _buildErrorState(
      BuildContext context, PrayerTimesError state, Size size) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: size.width * 0.15,
                color: Colors.red,
              ),
            ),
            SizedBox(height: size.height * 0.03),
            Text(
              state.message,
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              l10n?.translate('prayer_times.confirm_location_service') ??
                  "تأكد من تفعيل خدمة الموقع وإذن الوصول للموقع",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: size.width * 0.035,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.04),
            ElevatedButton.icon(
              onPressed: () {
                context.read<PrayerTimesCubit>().refreshPrayerTimes();
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.translate('prayer_times.retry') ?? 'إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: size.height * 0.015,
                ),
                backgroundColor: prayerPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSettings(BuildContext context) {
  final cubit = context.read<PrayerTimesCubit>();
  PrayerSettingsDialog.show(context, cubit);
}

// Add this custom painter for Islamic pattern divider
class DividerPatternPainter extends CustomPainter {
  final Color color;

  DividerPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double patternSize = 4;
    final double centerY = size.height / 2;

    // Draw center line
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint..strokeWidth = 1.5,
    );

    // Draw pattern circles
    for (double x = 0; x < size.width; x += patternSize * 4) {
      canvas.drawCircle(Offset(x, centerY), patternSize, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
