import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/core/utils/date_utils.dart';
import '../../../../core/constants/islamic_quotes.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/features/home/cubit/unsplash_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/features/home/views/widgets/about_developer_dialog.dart';
import 'package:wadhakir/features/home/views/widgets/hijri_calendar_bottom_sheet.dart';

class WelcomeSectionWidget extends StatefulWidget {
  final UnsplashPhoto? mosqueImage;
  final HijriDateTime hijriDate;

  const WelcomeSectionWidget({
    super.key,
    required this.mosqueImage,
    required this.hijriDate,
  });

  @override
  State<WelcomeSectionWidget> createState() => _WelcomeSectionWidgetState();
}

class _WelcomeSectionWidgetState extends State<WelcomeSectionWidget> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  late final IslamicQuote _quote;

  @override
  void initState() {
    super.initState();
    _quote = IslamicQuotes.getRandomQuote();
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
    final l10n = context.l10n;
    final now = _now;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = PlatformUtils.isDesktop;

    // Responsive sizing based on platform
    final maxWidth = isDesktop ? 1400.0 : double.infinity;
    final horizontalPadding = _getResponsivePadding(size.width, isDesktop);
    final verticalPadding = _getResponsiveVerticalPadding(
      size.height,
      isDesktop,
    );
    final borderRadius = isDesktop ? 24.0 : 32.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          ),
        ),
        child: Stack(
          children: [
            // Mosque Background Image
            if (widget.mosqueImage != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  ),
                  child: _buildMosqueBackground(context, widget.mosqueImage!),
                ),
              ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0C2F3A).withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: isDesktop ? 0.25 : 0.35),
                      Colors.black.withValues(alpha: isDesktop ? 0.55 : 0.75),
                    ],
                    stops: const [0.0, 0.2, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Header Content
            SafeArea(
              bottom: false,
              maintainBottomViewPadding: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Row with Date and Actions
                    _buildHeaderRow(context, size, isDesktop, l10n, now),

                    SizedBox(height: isDesktop ? 16 : 12),

                    // Welcome Message Section
                    _buildWelcomeSection(context, size, isDesktop, l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    Size size,
    bool isDesktop,
    AppLocalizations? l10n,
    DateTime now,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date Card - Clickable
        _buildDateCard(context, size, isDesktop, l10n, now),

        // Flexible spacer to push location to center-right and buttons to far right
        _buildActionButtons(context, size, isDesktop),
      ],
    );
  }

  Widget _buildDateCard(
    BuildContext context,
    Size size,
    bool isDesktop,
    AppLocalizations? l10n,
    DateTime now,
  ) {
    final iconSize = _getResponsiveIconSize(size.width, isDesktop, small: true);
    final fontSize = _getResponsiveFontSize(size.width, isDesktop, scale: 0.85);
    final smallFontSize = _getResponsiveFontSize(
      size.width,
      isDesktop,
      scale: 0.7,
    );
    final cardPadding = isDesktop ? 16.0 : size.width * 0.03;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                HijriCalendarBottomSheet(initialDate: widget.hijriDate),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gregorian Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: iconSize,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      SizedBox(width: isDesktop ? 8 : 6),
                      Text(
                        '${now.day} ${AppDateUtils.getGregorianMonthName(now.month, l10n)}',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.mosque,
                        size: iconSize * 0.9,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      SizedBox(width: isDesktop ? 8 : 6),
                      Text(
                        AppDateUtils.getShortFormattedHijriDate(
                          widget.hijriDate,
                          l10n,
                        ),
                        style: TextStyle(
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(width: isDesktop ? 12 : 8),
              // Click indicator
              Container(
                padding: EdgeInsets.all(isDesktop ? 8 : 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: iconSize * 0.7,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Size size, bool isDesktop) {
    final buttonSize = _getResponsiveIconSize(size.width, isDesktop);
    final buttonPadding = isDesktop ? 12.0 : size.width * 0.022;
    final spacing = isDesktop ? 16.0 : size.width * 0.012;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CompactIconButton(
          icon: Icons.info_outline,
          size: buttonSize,
          padding: buttonPadding,
          onPressed: () => showAboutDeveloperDialog(context),
        ),
        SizedBox(width: spacing),
        _CompactIconButton(
          icon: Icons.compass_calibration_rounded,
          size: buttonSize,
          padding: buttonPadding,
          onPressed: () => Navigator.pushNamed(context, '/campus'),
        ),
        SizedBox(width: spacing),
        _CompactIconButton(
          icon: Icons.radio_rounded,
          size: buttonSize,
          padding: buttonPadding,
          onPressed: () => Navigator.pushNamed(context, '/radio'),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(
    BuildContext context,
    Size size,
    bool isDesktop,
    AppLocalizations? l10n,
  ) {
    final titleFontSize = _getResponsiveFontSize(
      size.width,
      isDesktop,
      scale: 1.8,
    );
    final subtitleFontSize = _getResponsiveFontSize(
      size.width,
      isDesktop,
      scale: 0.9,
    );
    final quoteFontSize = _getResponsiveFontSize(
      size.width,
      isDesktop,
      scale: 0.8,
    );
    final sourceFontSize = _getResponsiveFontSize(
      size.width,
      isDesktop,
      scale: 0.65,
    );
    final iconSize = _getResponsiveIconSize(size.width, isDesktop, small: true);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Column: Welcome Message and Quote
        Expanded(
          flex: isDesktop ? 3 : 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Location Name - centered area
              Flexible(
                child: _LocationNameWidget(
                  theme: theme,
                  size: size,
                  isDark: isDark,
                  isDesktop: isDesktop,
                ),
              ),

              // Welcome Text
              Text(
                l10n?.translate('home.welcome_message') ?? 'السلام عليكم',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isDesktop ? 8 : 6),
              Text(
                l10n?.translate('home.app_name') ?? 'وذكّر',
                style: TextStyle(
                  fontSize: titleFontSize,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Almarai',
                ),
              ),
              SizedBox(height: isDesktop ? 16 : 12),

              // Islamic Quotes with source badge
              Builder(
                builder: (context) {
                  final languageCode =
                      Localizations.localeOf(context).languageCode;
                  final quoteText =
                      languageCode == 'en' ? _quote.textEn : _quote.text;
                  final quoteSource =
                      languageCode == 'en' ? _quote.sourceEn : _quote.source;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quoteText,
                        maxLines: isDesktop ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: quoteFontSize,
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          fontFamily:
                              languageCode == 'en' ? null : 'ScheherazadeNew',
                        ),
                      ),
                      SizedBox(height: isDesktop ? 10 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: iconSize * 0.9,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: isDesktop ? 8 : 6),
                          Flexible(
                            child: Text(
                              quoteSource,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: sourceFontSize,
                                fontWeight: FontWeight.w500,
                                fontFamily:
                                    languageCode == 'en' ? null : 'Almarai',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        SizedBox(width: isDesktop ? 22 : 10),

        // Right Column: Next Prayer Indicator
        _buildNextPrayerIndicator(context, size, isDesktop, l10n),
      ],
    );
  }

  Widget _buildNextPrayerIndicator(
    BuildContext context,
    Size size,
    bool isDesktop,
    AppLocalizations? l10n,
  ) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        if (state is! PrayerTimesLoaded) {
          return const SizedBox.shrink();
        }

        final prayerTimes = state.selectedPrayerTimes;
        if (prayerTimes == null) {
          return const SizedBox.shrink();
        }

        // Calculate live time difference using _now that updates every second
        final nextPrayerTime = prayerTimes.nextPrayer;
        final timeUntilNext = nextPrayerTime.difference(_now);
        final totalInterval = prayerTimes.totalIntervalBetweenPrayers;
        final progress =
            1 - (timeUntilNext.inSeconds / totalInterval.inSeconds);

        final hours = timeUntilNext.inHours;
        final minutes = timeUntilNext.inMinutes.remainder(60);
        final seconds = timeUntilNext.inSeconds.remainder(60);

        final nextPrayerName = prayerTimes.nextPrayerName;

        // Compact responsive sizing
        final circleSize = isDesktop ? 110.0 : size.width * 0.24;
        final strokeWidth = isDesktop ? 6.0 : size.width * 0.015;
        final prayerNameSize = _getResponsiveFontSize(
          size.width,
          isDesktop,
          scale: 0.85,
        );
        final timeSize = _getResponsiveFontSize(
          size.width,
          isDesktop,
          scale: 1.0,
        );
        final labelSize = _getResponsiveFontSize(
          size.width,
          isDesktop,
          scale: 0.6,
        );

        return Container(
          padding: EdgeInsets.all(isDesktop ? 12 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact Header with Prayer Name
              Column(
                children: [
                  Text(
                    l10n?.translate('home.next_prayer') ?? 'الصلاة القادمة',
                    style: TextStyle(
                      fontSize: labelSize,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Almarai',
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mosque_rounded,
                        color: Colors.white,
                        size: prayerNameSize * 0.9,
                      ),
                      SizedBox(width: 6),
                      Text(
                        nextPrayerName,
                        style: TextStyle(
                          fontSize: prayerNameSize,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: isDesktop ? 10 : 8),

              // Compact Circular Progress Indicator
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Circle
                    SizedBox(
                      width: circleSize,
                      height: circleSize,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: strokeWidth,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    // Progress Circle with gradient effect
                    SizedBox(
                      width: circleSize,
                      height: circleSize,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: strokeWidth,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Center Content - Minimalist Time Display
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Remaining Time - Always show H:MM:SS format
                        Text(
                          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: timeSize,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier',
                            height: 1.1,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        // Time Unit Label - Very compact
                        Text(
                          l10n?.translate('home.remaining') ?? 'متبقي',
                          style: TextStyle(
                            fontSize: labelSize,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Almarai',
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
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

  // Responsive sizing helpers
  double _getResponsivePadding(double width, bool isDesktop) {
    if (isDesktop) {
      if (width > 1400) return 48.0;
      if (width > 1200) return 40.0;
      return 32.0;
    }
    return width * 0.04; // Mobile: 4% of width
  }

  double _getResponsiveVerticalPadding(double height, bool isDesktop) {
    if (isDesktop) {
      return 24.0;
    }
    return height * 0.015; // Mobile: 1.5% of height
  }

  double _getResponsiveFontSize(
    double width,
    bool isDesktop, {
    double scale = 1.0,
  }) {
    if (isDesktop) {
      // Desktop: Fixed sizes with scale
      final baseSize = 16.0;
      return baseSize * scale;
    }
    // Mobile: Relative to width
    return (width * 0.035) * scale;
  }

  double _getResponsiveIconSize(
    double width,
    bool isDesktop, {
    bool small = false,
  }) {
    if (isDesktop) {
      return small ? 18.0 : 24.0;
    }
    return small ? width * 0.032 : width * 0.048;
  }

  Widget _buildMosqueBackground(
    BuildContext context,
    UnsplashPhoto mosqueImage,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 1.03, end: 1.0).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: Image.asset(
        mosqueImage.imageUrl,
        key: ValueKey(mosqueImage.id),
        fit: BoxFit.cover,
        color: Colors.black.withValues(alpha: 0.1),
        colorBlendMode: BlendMode.darken,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          log(
            'Error loading asset image: $error for path: ${mosqueImage.imageUrl}',
          );
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: const Icon(Icons.error, color: Colors.white),
          );
        },
      ),
    );
  }
}

// Compact Icon Button Widget for Header Actions
class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double padding;
  final VoidCallback onPressed;

  const _CompactIconButton({
    required this.icon,
    required this.size,
    required this.padding,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Icon(icon, color: Colors.white, size: size),
          ),
        ),
      ),
    );
  }
}

// Location Name Widget - listens to BlocBuilder for location updates
class _LocationNameWidget extends StatelessWidget {
  final ThemeData theme;
  final Size size;
  final bool isDark;
  final bool isDesktop;

  const _LocationNameWidget({
    required this.theme,
    required this.size,
    required this.isDark,
    required this.isDesktop,
  });

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
            // Don't show if loading or no data
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            }

            final locationName = snapshot.data!;

            // Don't show if it's the default "location not specified" message
            if (locationName == 'موقع غير محدد') {
              return const SizedBox.shrink();
            }

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 12.0 : size.width * 0.025,
                vertical: isDesktop ? 8.0 : size.height * 0.008,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: isDesktop ? 16 : 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  SizedBox(width: isDesktop ? 6 : 4),
                  Flexible(
                    child: Text(
                      locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: isDesktop ? 13 : 11,
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
