import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
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
                      PrayerTimesHeader(size: size, cubit: cubit),

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
