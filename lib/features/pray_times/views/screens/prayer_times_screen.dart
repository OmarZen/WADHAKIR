import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/utils/arabic_text.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/features/pray_times/utils/prayer_times_share.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';
import 'package:wadhakir/features/pray_times/views/widgets/prayer_times_error.dart';
import 'package:wadhakir/features/pray_times/views/widgets/prayer_times_header.dart';
import 'package:wadhakir/features/pray_times/views/widgets/prayer_times_content.dart';
import 'package:wadhakir/features/pray_times/views/widgets/location_disabled_dialog.dart';
import 'package:wadhakir/features/pray_times/views/widgets/prayer_times_loading.dart'
    as loading_widget;

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PrayerTimesScreenContent();
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
  bool _hasCheckedLocation = false;
  bool _hasTriggeredLoad = false;

  /// City for the shared card's subhead, resolved once when the screen opens.
  ///
  /// Resolved here rather than inside the share button because
  /// `getCurrentLocationName()` is async — it geocodes — while
  /// `ShareActionButton.payloadBuilder` is deliberately synchronous. Null until
  /// it lands, and null leaves the city off the card rather than delaying the
  /// share.
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerLoadIfNeeded();
      _resolveLocationName();
    });

    // Check location services after a short delay to let the screen load
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkLocationServices();
    });
  }

  void _triggerLoadIfNeeded() {
    if (!mounted || _hasTriggeredLoad) return;
    final cubit = context.read<PrayerTimesCubit>();
    if (cubit.state is PrayerTimesInitial) {
      _hasTriggeredLoad = true;
      cubit.loadPrayerTimes();
    }
  }

  Future<void> _resolveLocationName() async {
    if (!mounted) return;
    try {
      final name = await context
          .read<PrayerTimesCubit>()
          .getCurrentLocationName();
      if (!mounted) return;
      setState(() => _locationName = name);
    } catch (e) {
      // A card without a city is still a useful card. Never block the share.
      debugPrint('Could not resolve a city for the share card: $e');
    }
  }

  /// The card, built at tap time.
  ///
  /// Reads `cubit.state` rather than closing over the state this screen was
  /// built with, because the date arrows emit a new one: capturing early is how
  /// a share button sends yesterday's timetable after the user has paged to
  /// tomorrow.
  SharePayload? _buildSharePayload() {
    final state = context.read<PrayerTimesCubit>().state;
    if (state is! PrayerTimesLoaded) return null;
    final times = state.selectedPrayerTimes;
    if (times == null) return null;

    final l10n = AppLocalizations.of(context);
    String tr(String key, String fallback) {
      final value = l10n?.translate(key);
      // `translate` hands back the key itself on a miss, so `?? fallback`
      // alone would put "prayer_times.fajr" on a card people broadcast.
      return value == null || value == key ? fallback : value;
    }

    return PrayerTimesShare.build(
      times: times,
      labels: PrayerTimesShareLabels(
        title: tr('prayer_times.title', 'مواقيت الصلاة'),
        fajr: tr('prayer_times.fajr', 'الفجر'),
        sunrise: tr('prayer_times.sunrise', 'الشروق'),
        dhuhr: tr('prayer_times.dhuhr', 'الظهر'),
        asr: tr('prayer_times.asr', 'العصر'),
        maghrib: tr('prayer_times.maghrib', 'المغرب'),
        isha: tr('prayer_times.isha', 'العشاء'),
      ),
      cityName: _locationName,
      dateLine: _dateLine(state.selectedDate),
    );
  }

  /// «٢١ ربيع الأول ١٤٤٧ هـ · Sat, Sep 13, 2025» — both calendars, because a
  /// card read in either one has to be unambiguous about which day it is for.
  String _dateLine(DateTime date) {
    final hijri = HijriDateTime.fromDateTime(date);
    final month = hijri.month >= 1 && hijri.month <= 12
        ? ArabicText.hijriMonths[hijri.month - 1]
        : '';
    final hijriLine = '${hijri.day} $month ${hijri.year} هـ';
    return '$hijriLine · ${DateFormat.yMMMEd().format(date)}';
  }

  Future<void> _checkLocationServices() async {
    if (!mounted || _hasCheckedLocation) return;
    _hasCheckedLocation = true;

    final cubit = context.read<PrayerTimesCubit>();

    // Only show the dialog when we have NO saved coordinates and are truly
    // falling back to Mecca. If a saved location exists, the user already
    // sees the city pill in the welcome section — interrupting them with
    // a "location disabled" dialog is misleading.
    final isUsingFallback = await cubit.isUsingFallbackLocation();

    if (isUsingFallback && mounted) {
      _showLocationDisabledDialog();
    }
  }

  void _showLocationDisabledDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => LocationDisabledDialog(l10n: l10n),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cubit = context.read<PrayerTimesCubit>();
    final theme = Theme.of(context);

    // Calculate animations
    final fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    final slideAnimation = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

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
                  color: theme.colorScheme.primary,
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
                  return loading_widget.PrayerTimesLoadingWidget(
                    size: size,
                    fadeAnimation: fadeAnimation,
                  );
                } else if (state is PrayerTimesLoaded) {
                  return Column(
                    children: [
                      // Custom header
                      PrayerTimesHeader(
                        size: size,
                        cubit: cubit,
                        payloadBuilder: _buildSharePayload,
                      ),

                      // Main prayer times content
                      Expanded(
                        child: PrayerTimesContent(
                          state: state,
                          size: size,
                          fadeAnimation: fadeAnimation,
                          slideAnimation: slideAnimation,
                        ),
                      ),
                    ],
                  );
                } else if (state is PrayerTimesError) {
                  return PrayerTimesErrorWidget(size: size, state: state);
                } else {
                  return loading_widget.PrayerTimesLoadingWidget(
                    size: size,
                    fadeAnimation: fadeAnimation,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
