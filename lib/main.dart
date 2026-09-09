import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quran_library/quran_library.dart';
import 'package:forui/forui.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:wadhakir/core/app/restart_required.dart';
import 'package:wadhakir/core/routes/app_router.dart';
import 'package:wadhakir/core/notifications/app_notification_listeners.dart';
import 'package:wadhakir/core/notifications/notification_router.dart';
import 'package:wadhakir/core/notifications/native_prayer_tap.dart';
import 'package:wadhakir/core/notifications/pending_notification_action.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/app_theme/forui_theme.dart';
import 'package:wadhakir/data/models/hive_adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/features/radio/cubit/radio_cubit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:wadhakir/core/localization/language_manager.dart';
import 'package:wadhakir/domain/usecases/get_radios_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_app_lock_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_language_usecase.dart';
import 'package:wadhakir/features/splash_screen/splash_screen.dart';
import 'package:wadhakir/domain/usecases/set_theme_mode_usecase.dart';
import 'package:wadhakir/domain/usecases/set_onboarding_completed_usecase.dart';
import 'package:wadhakir/domain/usecases/set_user_name_usecase.dart';
import 'package:wadhakir/domain/usecases/set_text_scale_usecase.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/data/repositories/radio_repository_impl.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_stream_usecase.dart';
import 'package:wadhakir/core/localization/app_localizations_delegate.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/features/home_screen_widgets/presentation/widgets/glass_prayer_home_widget.dart';
import 'package:wadhakir/features/home_screen_widgets/presentation/widgets/prayer_times_home_widget.dart';
import 'package:wadhakir/data/repositories/app_settings_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_range_usecase.dart';
import 'package:wadhakir/domain/usecases/get_calculation_method_usecase.dart';
import 'package:wadhakir/domain/usecases/set_calculation_method_usecase.dart';
import 'package:wadhakir/data/repositories/prayer_times_repository_impl.dart';
import 'package:wadhakir/data/repositories/notification_repository_impl.dart';
import 'package:wadhakir/domain/usecases/set_notification_settings_usecase.dart';
import 'package:wadhakir/data/repositories/fasting_reminders_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_fasting_reminder_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_fasting_reminder_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/get_fasting_reminder_settings_stream_usecase.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_cubit.dart';
import 'package:wadhakir/data/repositories/wird_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_wird_plan_usecase.dart';
import 'package:wadhakir/domain/usecases/set_wird_plan_usecase.dart';
import 'package:wadhakir/domain/usecases/get_wird_plan_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/clear_wird_plan_usecase.dart';
import 'package:wadhakir/features/wird/cubit/wird_cubit.dart';
import 'package:wadhakir/data/repositories/salah_tracker_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_salah_log_usecase.dart';
import 'package:wadhakir/domain/usecases/set_salah_log_usecase.dart';
import 'package:wadhakir/domain/usecases/get_salah_log_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/clear_salah_log_usecase.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/data/repositories/daily_inspiration_settings_repository_impl.dart';
import 'package:wadhakir/features/daily_inspiration/cubit/daily_inspiration_cubit.dart';
import 'package:wadhakir/data/repositories/azkar_reminder_settings_repository_impl.dart';
import 'package:wadhakir/features/azkar_reminders/cubit/azkar_reminders_cubit.dart';
import 'package:wadhakir/features/azkar_reminders/cubit/azkar_reminders_state.dart';
import 'package:wadhakir/features/app_lock/services/app_lock_platform_service.dart';
import 'package:wadhakir/features/app_lock/services/app_lock_prayer_window.dart';
import 'package:wadhakir/features/floating_dhikr/service/floating_dhikr_overlay_entry.dart';
import 'package:wadhakir/features/floating_dhikr/service/floating_dhikr_service.dart';
import 'package:wadhakir/features/feature_discovery/services/feature_discovery_service.dart';

/// Entry point used by `flutter_overlay_window` for the secondary engine
/// that renders the floating adhkar pill bar over other apps. Delegates to
/// the feature-local entry function so all overlay UI stays in
/// `lib/features/floating_dhikr/`.
@pragma('vm:entry-point')
void overlayMain() => floatingDhikrOverlayEntry();

void main() async {
  // Initialize widgets binding and preserve splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Diagnostic hook for the framework warning
  //   "ListTile background color or ink splashes may be invisible."
  // The default presenter prints the message but not enough context to find
  // the offending widget. This wrapper logs the intermediate widget that
  // is hiding the splash (the one named in Flutter's error description)
  // before delegating to the normal presenter. Debug-only — release builds
  // keep the default behavior.
  if (!kReleaseMode) {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final summary = details.exceptionAsString();
      if (summary.contains('may be invisible')) {
        // Walk the diagnostics tree for the "intermediate" widget Flutter
        // attaches as a DiagnosticsProperty so we can see exactly which
        // class is hiding the splash and where in the tree it sits.
        final buf = StringBuffer()
          ..writeln('⚠️  ListTile-invisible-splash warning fired')
          ..writeln('   message: ${summary.split('\n').first}');
        details.informationCollector?.call().forEach((node) {
          buf.writeln('   • ${node.toStringDeep().trim()}');
        });
        debugPrint(buf.toString());
      }
      (previousOnError ?? FlutterError.presentError)(details);
    };
  }

  // Set system UI overlay style for edge-to-edge experience
  // Note: In Android 15+, color settings are deprecated for edge-to-edge.
  // Only icon brightness should be controlled.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Defer home widgets and notification initialization for faster cold start
  // These will be initialized lazily when features are first accessed

  // Initialize Hive
  await Hive.initFlutter();

  // Register custom adapters for types not handled by Hive
  Hive.registerAdapter(DateTimeAdapter());
  Hive.registerAdapter(StringIntMapAdapter());

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Overlap the two slowest remaining initializations (they're independent of
  // each other) instead of running them one-after-another — faster cold start.
  // Both are awaited before runApp. Kept after Hive in case QuranLibrary relies
  // on Hive being initialized.
  //
  // QuranLibrary.init() must complete before the Quran screen builds.
  final quranInitFuture = QuranLibrary.init();

  // awesome_notifications + register ALL channels ONCE, up front. The
  // fasting/wird cubits are eager (lazy:false) and schedule at cold start; if
  // the plugin isn't initialized first their createNotification/setChannel
  // calls fail silently. Bounded + guarded so it never blocks cold start.
  final notificationInitFuture = NotificationRepositoryImpl()
      .initialize()
      .timeout(const Duration(seconds: 3))
      .catchError((Object e) {
        debugPrint('Notification init failed/timed out (non-fatal): $e');
      });

  // Ensure the Quran package and notification channels are ready before the
  // app builds / eager cubits schedule notifications.
  await quranInitFuture;
  await notificationInitFuture;

  // Register the single app-wide notification listener set (channels are ready
  // now). This MUST be the only setListeners call — feature services no longer
  // register their own, which would otherwise overwrite the router-aware one.
  AppNotificationListeners.register();

  // If a notification tap launched the app from a killed state, capture it so
  // the splash can route to the right page once the navigator is mounted.
  try {
    final launchAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true)
        .timeout(const Duration(seconds: 2));
    if (launchAction != null) {
      PendingNotificationAction.capture(launchAction.payload);
    }
  } catch (e) {
    debugPrint('getInitialNotificationAction failed (non-fatal): $e');
  }

  // The same thing for an adhan posted by the native alarm path. That
  // notification never passes through the plugin, so the call above cannot see
  // it — its payload waits in the Kotlin side's own storage instead.
  await NativePrayerTap.drain();

  // Set the home_widget App Group id ONCE, up front — BEFORE any cubit renders
  // or saves widget data. Without it, iOS widget writes fail with "No groupId
  // defined" / "AppGroupId not set" because the shared container can't be
  // resolved. Also registers the interactivity callback. No-op on desktop.
  await PrayerTimesHomeWidget.setupBackgroundCallback();

  // Create repositories
  final appSettingsRepository = AppSettingsRepositoryImpl(sharedPreferences);
  final prayerTimesRepository = PrayerTimesRepositoryImpl();
  final fastingRemindersRepository = FastingRemindersRepositoryImpl(
    sharedPreferences,
  );
  final wirdRepository = WirdRepositoryImpl(sharedPreferences);
  final salahTrackerRepository = SalahTrackerRepositoryImpl(sharedPreferences);

  // Create settings use cases
  final getSettingsUseCase = GetSettingsUseCase(appSettingsRepository);
  final getSettingsStreamUseCase = GetSettingsStreamUseCase(
    appSettingsRepository,
  );
  final setThemeModeUseCase = SetThemeModeUseCase(appSettingsRepository);
  final setLanguageUseCase = SetLanguageUseCase(appSettingsRepository);

  final setNotificationSettingsUseCase = SetNotificationSettingsUseCase(
    appSettingsRepository,
  );
  final setAppLockSettingsUseCase = SetAppLockSettingsUseCase(
    appSettingsRepository,
  );
  final setOnboardingCompletedUseCase = SetOnboardingCompletedUseCase(
    appSettingsRepository,
  );
  final setUserNameUseCase = SetUserNameUseCase(appSettingsRepository);
  final setTextScaleUseCase = SetTextScaleUseCase(appSettingsRepository);

  // Create prayer times use cases
  final getPrayerTimesUseCase = GetPrayerTimesUseCase(prayerTimesRepository);
  final getPrayerTimesRangeUseCase = GetPrayerTimesRangeUseCase(
    prayerTimesRepository,
  );
  final getCalculationMethodUseCase = GetCalculationMethodUseCase(
    prayerTimesRepository,
  );
  final setCalculationMethodUseCase = SetCalculationMethodUseCase(
    prayerTimesRepository,
  );

  // Create fasting reminders use cases
  final getFastingReminderSettingsUseCase = GetFastingReminderSettingsUseCase(
    fastingRemindersRepository,
  );
  final setFastingReminderSettingsUseCase = SetFastingReminderSettingsUseCase(
    fastingRemindersRepository,
  );
  final getFastingReminderSettingsStreamUseCase =
      GetFastingReminderSettingsStreamUseCase(fastingRemindersRepository);

  // Create wird (Quran reading plan) use cases
  final getWirdPlanUseCase = GetWirdPlanUseCase(wirdRepository);
  final setWirdPlanUseCase = SetWirdPlanUseCase(wirdRepository);
  final getWirdPlanStreamUseCase = GetWirdPlanStreamUseCase(wirdRepository);
  final clearWirdPlanUseCase = ClearWirdPlanUseCase(wirdRepository);

  // Salah tracker use cases
  final getSalahLogUseCase = GetSalahLogUseCase(salahTrackerRepository);
  final setSalahLogUseCase = SetSalahLogUseCase(salahTrackerRepository);
  final getSalahLogStreamUseCase = GetSalahLogStreamUseCase(
    salahTrackerRepository,
  );
  final clearSalahLogUseCase = ClearSalahLogUseCase(salahTrackerRepository);

  // Daily inspiration (Verse/Dua of the Day) settings repository.
  final dailyInspirationRepository = DailyInspirationSettingsRepositoryImpl(
    sharedPreferences,
  );

  // Daily azkar reminders settings repository. Shared between the eager
  // AzkarRemindersCubit (repeating reminders) and PrayerTimesCubit (the
  // prayer-time-driven reminders).
  final azkarReminderRepository = AzkarReminderSettingsRepositoryImpl(
    sharedPreferences,
  );

  // Defer fasting notification service initialization
  // It will be lazily initialized when fasting reminders are accessed

  runApp(
    MyApp(
      // Settings
      getSettingsUseCase: getSettingsUseCase,
      getSettingsStreamUseCase: getSettingsStreamUseCase,
      setThemeModeUseCase: setThemeModeUseCase,
      setLanguageUseCase: setLanguageUseCase,
      setNotificationSettingsUseCase: setNotificationSettingsUseCase,
      setAppLockSettingsUseCase: setAppLockSettingsUseCase,
      setOnboardingCompletedUseCase: setOnboardingCompletedUseCase,
      setUserNameUseCase: setUserNameUseCase,
      setTextScaleUseCase: setTextScaleUseCase,
      // Quran

      // Prayer Times
      getPrayerTimesUseCase: getPrayerTimesUseCase,
      getPrayerTimesRangeUseCase: getPrayerTimesRangeUseCase,
      getCalculationMethodUseCase: getCalculationMethodUseCase,
      setCalculationMethodUseCase: setCalculationMethodUseCase,
      prayerTimesRepository: prayerTimesRepository,
      // Fasting Reminders
      getFastingReminderSettingsUseCase: getFastingReminderSettingsUseCase,
      setFastingReminderSettingsUseCase: setFastingReminderSettingsUseCase,
      getFastingReminderSettingsStreamUseCase:
          getFastingReminderSettingsStreamUseCase,
      // Wird (Quran reading plan)
      getWirdPlanUseCase: getWirdPlanUseCase,
      setWirdPlanUseCase: setWirdPlanUseCase,
      getWirdPlanStreamUseCase: getWirdPlanStreamUseCase,
      clearWirdPlanUseCase: clearWirdPlanUseCase,
      // Daily inspiration (Verse/Dua of the Day)
      dailyInspirationRepository: dailyInspirationRepository,
      // Daily azkar reminders
      azkarReminderRepository: azkarReminderRepository,
      // Salah tracker
      getSalahLogUseCase: getSalahLogUseCase,
      setSalahLogUseCase: setSalahLogUseCase,
      getSalahLogStreamUseCase: getSalahLogStreamUseCase,
      clearSalahLogUseCase: clearSalahLogUseCase,
    ),
  );

  // Fire-and-forget: if the user previously enabled the floating adhkar
  // overlay, resume its ticker. No await — overlay-permission checks happen
  // inside bootstrap and a failure is silent.
  // ignore: unawaited_futures
  FloatingDhikrService.instance.bootstrap();

  // Fire-and-forget: maybe schedule a feature-discovery nudge (rate-capped to
  // once every few days inside the service). No await — failures are silent.
  // ignore: unawaited_futures
  FeatureDiscoveryService.instance.maybeScheduleNext(sharedPreferences);

  // The native splash is removed on the Dart splash's first frame
  // (see WadhakirSplashScreen) so the hand-off is seamless with no white flash.
}

class MyApp extends StatelessWidget {
  // Settings
  final GetSettingsUseCase getSettingsUseCase;
  final GetSettingsStreamUseCase getSettingsStreamUseCase;
  final SetThemeModeUseCase setThemeModeUseCase;
  final SetLanguageUseCase setLanguageUseCase;
  final SetNotificationSettingsUseCase setNotificationSettingsUseCase;
  final SetAppLockSettingsUseCase setAppLockSettingsUseCase;
  final SetOnboardingCompletedUseCase setOnboardingCompletedUseCase;
  final SetUserNameUseCase setUserNameUseCase;
  final SetTextScaleUseCase setTextScaleUseCase;

  // Quran

  // Prayer Times
  final GetPrayerTimesUseCase getPrayerTimesUseCase;
  final GetPrayerTimesRangeUseCase getPrayerTimesRangeUseCase;
  final GetCalculationMethodUseCase getCalculationMethodUseCase;
  final SetCalculationMethodUseCase setCalculationMethodUseCase;
  final PrayerTimesRepositoryImpl prayerTimesRepository;

  // Fasting Reminders
  final GetFastingReminderSettingsUseCase getFastingReminderSettingsUseCase;
  final SetFastingReminderSettingsUseCase setFastingReminderSettingsUseCase;
  final GetFastingReminderSettingsStreamUseCase
  getFastingReminderSettingsStreamUseCase;

  // Wird (Quran reading plan)
  final GetWirdPlanUseCase getWirdPlanUseCase;
  final SetWirdPlanUseCase setWirdPlanUseCase;
  final GetWirdPlanStreamUseCase getWirdPlanStreamUseCase;
  final ClearWirdPlanUseCase clearWirdPlanUseCase;

  // Daily inspiration (Verse/Dua of the Day)
  final DailyInspirationSettingsRepositoryImpl dailyInspirationRepository;

  // Daily azkar reminders
  final AzkarReminderSettingsRepositoryImpl azkarReminderRepository;

  // Salah tracker
  final GetSalahLogUseCase getSalahLogUseCase;
  final SetSalahLogUseCase setSalahLogUseCase;
  final GetSalahLogStreamUseCase getSalahLogStreamUseCase;
  final ClearSalahLogUseCase clearSalahLogUseCase;

  final _appLockPrayerSync = _AppLockPrayerSync(const AppLockPlatformService());

  MyApp({
    super.key,
    // Settings
    required this.getSettingsUseCase,
    required this.getSettingsStreamUseCase,
    required this.setThemeModeUseCase,
    required this.setLanguageUseCase,
    required this.setNotificationSettingsUseCase,
    required this.setAppLockSettingsUseCase,
    required this.setOnboardingCompletedUseCase,
    required this.setUserNameUseCase,
    required this.setTextScaleUseCase,
    // Quran

    // Prayer Times
    required this.getPrayerTimesUseCase,
    required this.getPrayerTimesRangeUseCase,
    required this.getCalculationMethodUseCase,
    required this.setCalculationMethodUseCase,
    required this.prayerTimesRepository,
    // Fasting Reminders
    required this.getFastingReminderSettingsUseCase,
    required this.setFastingReminderSettingsUseCase,
    required this.getFastingReminderSettingsStreamUseCase,
    // Wird (Quran reading plan)
    required this.getWirdPlanUseCase,
    required this.setWirdPlanUseCase,
    required this.getWirdPlanStreamUseCase,
    required this.clearWirdPlanUseCase,
    // Daily inspiration (Verse/Dua of the Day)
    required this.dailyInspirationRepository,
    // Daily azkar reminders
    required this.azkarReminderRepository,
    // Salah tracker
    required this.getSalahLogUseCase,
    required this.setSalahLogUseCase,
    required this.getSalahLogStreamUseCase,
    required this.clearSalahLogUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(
            getSettingsUseCase: getSettingsUseCase,
            getSettingsStreamUseCase: getSettingsStreamUseCase,
            setThemeModeUseCase: setThemeModeUseCase,
            setLanguageUseCase: setLanguageUseCase,
            setNotificationSettingsUseCase: setNotificationSettingsUseCase,
            setAppLockSettingsUseCase: setAppLockSettingsUseCase,
            setOnboardingCompletedUseCase: setOnboardingCompletedUseCase,
            setUserNameUseCase: setUserNameUseCase,
            setTextScaleUseCase: setTextScaleUseCase,
          ),
          lazy: false,
        ),
        BlocProvider<RadioCubit>(
          create: (_) => RadioCubit(GetRadiosUseCase(RadioRepositoryImpl())),
          lazy: true,
        ),
        BlocProvider<PrayerTimesCubit>(
          create: (_) => PrayerTimesCubit(
            getPrayerTimesUseCase,
            getPrayerTimesRangeUseCase,
            getCalculationMethodUseCase,
            setCalculationMethodUseCase,
            repository: prayerTimesRepository,
            azkarReminderRepository: azkarReminderRepository,
          ),
          // Eager so prayer times load at cold start and the BlocListeners
          // schedule the adhan notifications without needing the user to open
          // the prayer-times screen first.
          lazy: false,
        ),
        BlocProvider<FastingRemindersCubit>(
          create: (_) => FastingRemindersCubit(
            getSettingsUseCase: getFastingReminderSettingsUseCase,
            setSettingsUseCase: setFastingReminderSettingsUseCase,
            getSettingsStreamUseCase: getFastingReminderSettingsStreamUseCase,
          ),
          // Eager creation so the cubit's loadSettings() kicks off at
          // app start and the section is Loaded by the time the user
          // navigates to Settings. With lazy: true, the cubit only
          // instantiated when BlocBuilder accessed it, and the widget
          // showed SizedBox.shrink() during the async load — making the
          // whole "تذكيرات الصيام" section invisible.
          lazy: false,
        ),
        BlocProvider<WirdCubit>(
          create: (_) => WirdCubit(
            getPlanUseCase: getWirdPlanUseCase,
            setPlanUseCase: setWirdPlanUseCase,
            getPlanStreamUseCase: getWirdPlanStreamUseCase,
            clearPlanUseCase: clearWirdPlanUseCase,
          ),
          // Eager so the daily reminder is (re)scheduled at app start.
          lazy: false,
        ),
        BlocProvider<DailyInspirationCubit>(
          create: (_) => DailyInspirationCubit(dailyInspirationRepository),
          // Eager so today's notification is (re)scheduled and the home
          // widget is pushed at cold start.
          lazy: false,
        ),
        BlocProvider<AzkarRemindersCubit>(
          create: (_) => AzkarRemindersCubit(azkarReminderRepository),
          // Eager so the repeating azkar reminders (morning/evening/etc.) are
          // (re)scheduled at cold start without opening any screen.
          lazy: false,
        ),
        BlocProvider<SalahTrackerCubit>(
          create: (_) => SalahTrackerCubit(
            getLogUseCase: getSalahLogUseCase,
            setLogUseCase: setSalahLogUseCase,
            getLogStreamUseCase: getSalahLogStreamUseCase,
            clearLogUseCase: clearSalahLogUseCase,
          ),
          // Eager so the home card's today ring + streak are ready and the
          // day-rollover refresh works without opening the tracker screen.
          lazy: false,
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          // Listen to settings changes and reschedule notifications
          BlocListener<SettingsCubit, SettingsState>(
            listener: (context, state) {
              if (state is SettingsLoaded) {
                final prayerTimesCubit = context.read<PrayerTimesCubit>();
                final notificationSettings =
                    state.settings.notificationSettings;

                _appLockPrayerSync.sync(context);

                // Only schedule if prayer times are already loaded
                if (prayerTimesCubit.state is PrayerTimesLoaded) {
                  prayerTimesCubit.scheduleNotificationsWithSettings(
                    notificationSettings,
                  );
                }
              }
            },
          ),
          // Listen to prayer times loaded and schedule notifications.
          // Only react to a genuine (re)load — the cubit's countdown timer
          // re-emits PrayerTimesLoaded every few seconds reusing the SAME
          // prayerTimes map reference; skipping those prevents a wasteful
          // cancel+reschedule churn (and a race at the exact prayer minute).
          BlocListener<PrayerTimesCubit, PrayerTimesState>(
            listenWhen: (previous, current) {
              if (current is! PrayerTimesLoaded) return false;
              if (previous is! PrayerTimesLoaded) return true;
              return !identical(previous.prayerTimes, current.prayerTimes);
            },
            listener: (context, state) {
              if (state is PrayerTimesLoaded) {
                final settingsCubit = context.read<SettingsCubit>();

                // Only schedule if settings are loaded
                if (settingsCubit.state is SettingsLoaded) {
                  final settingsState = settingsCubit.state as SettingsLoaded;
                  final prayerTimesCubit = context.read<PrayerTimesCubit>();

                  prayerTimesCubit.scheduleNotificationsWithSettings(
                    settingsState.settings.notificationSettings,
                  );
                }

                _appLockPrayerSync.sync(context);
              }
            },
          ),
          // When azkar reminder settings change, refresh the prayer-time-driven
          // ones (after-prayer, Duha, last-third Qiyam) right away so toggles
          // take effect without waiting for the next prayer-times refresh.
          BlocListener<AzkarRemindersCubit, AzkarRemindersState>(
            listenWhen: (previous, current) =>
                previous.settings != current.settings,
            listener: (context, state) {
              // ignore: unawaited_futures
              context.read<PrayerTimesCubit>().rescheduleAzkarPrayerDriven();
            },
          ),
        ],
        child: _GlassWidgetResumeRefresher(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            buildWhen: (previous, current) =>
                previous != current && current is SettingsLoaded,
            builder: (context, state) {
              // Default settings if not loaded yet
              var themeMode = ThemeMode.light;
              var locale = const Locale('ar');
              var textScale = 1.0;

              // Update with loaded settings if available
              if (state is SettingsLoaded) {
                themeMode = state.settings.themeMode;
                locale = Locale(state.settings.languageCode);
                textScale = state.settings.textScale;
              }

              return MaterialApp(
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: themeMode,
                localizationsDelegates: const [
                  AppLocalizationsDelegate(),
                  SfGlobalLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: LanguageManager.supportedLocales,
                locale: locale,
                navigatorKey: AppRouter.navigatorKey,
                onGenerateRoute: AppRouter.onGenerateRoute,
                // Layer forui alongside Material: every route below gets an
                // FTheme derived from the active Material theme, so forui
                // components match the app's brand colors + light/dark mode.
                // Material widgets (Quran reader, syncfusion pickers) ignore it.
                builder: (context, child) {
                  // Compose the user's in-app scale ON TOP of whatever the OS
                  // is already asking for, rather than replacing it — someone
                  // who has enlarged text system-wide should not have that
                  // silently undone by opening this app. The product of the two
                  // is clamped so the combination can't reach a size where the
                  // fixed-height cards clip.
                  final osScaler = MediaQuery.textScalerOf(context);
                  final effective = (osScaler.scale(1.0) * textScale).clamp(
                    AppSettingsModel.minTextScale,
                    AppSettingsModel.maxTextScale,
                  );
                  return MediaQuery.withClampedTextScaling(
                    minScaleFactor: effective,
                    maxScaleFactor: effective,
                    child: FTheme(
                      data: buildForuiTheme(Theme.of(context)),
                      // FToaster provides the overlay host for forui toasts so
                      // any screen can call showFToast(...) with the unified
                      // styling.
                      child: FToaster(child: child ?? const SizedBox.shrink()),
                    ),
                  );
                },
                home: const WadhakirSplashScreen(),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Re-renders the Flutter-drawn glass prayer widgets (Prayer Detail + Prayer
/// Next) whenever the app is resumed, so their snapshot (countdown, progress)
/// is fresh. `renderFlutterWidget` cannot run while the app is fully
/// backgrounded, so this resume hook is the moment to refresh them.
class _GlassWidgetResumeRefresher extends StatefulWidget {
  final Widget child;
  const _GlassWidgetResumeRefresher({required this.child});

  @override
  State<_GlassWidgetResumeRefresher> createState() =>
      _GlassWidgetResumeRefresherState();
}

class _GlassWidgetResumeRefresherState
    extends State<_GlassWidgetResumeRefresher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Warm taps (app alive): route the tapped notification once the frame is
    // ready. Cold-start taps are consumed by the splash instead.
    PendingNotificationAction.notifier.addListener(_onPendingNotification);
  }

  @override
  void dispose() {
    PendingNotificationAction.notifier.removeListener(_onPendingNotification);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onPendingNotification() {
    final payload = PendingNotificationAction.notifier.value;
    if (payload == null) return;
    // Clear the holder so a later cold-start consume can't double-dispatch.
    PendingNotificationAction.consume();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationRouter.dispatch(payload);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // Everything below is day-rollover housekeeping that writes through
    // cache-first repositories. After a backup restore those caches hold the
    // data that was just replaced, so running any of it would quietly undo the
    // restore — SalahTrackerCubit.refreshIfStale() reaches syncPause(), which
    // persists from the stale log. The app is waiting to be restarted at that
    // point and none of this housekeeping matters. See RestartRequired.
    if (RestartRequired.isLatched) return;

    // A tap on a natively-posted adhan resumes the app rather than delivering a
    // plugin action, so this is where a warm tap is collected. Placed after the
    // restart latch on purpose: the native side only clears the payload when it
    // hands it over, so it keeps until a resume that can actually route it.
    // ignore: unawaited_futures
    NativePrayerTap.drain();

    // If the device changed timezone while the app was closed, the native path
    // kept the old schedule ringing and marked it stale. This is where that
    // debt is paid: a real location fix and a full re-plan.
    // ignore: unawaited_futures
    context.read<PrayerTimesCubit>().replanIfScheduleWentStale();

    // Daily inspiration: if the day rolled over while backgrounded, advance to
    // today's item and reschedule the notification with the new body.
    // ignore: unawaited_futures
    context.read<DailyInspirationCubit>().refreshForToday();

    // Feature-discovery: maybe schedule the next nudge (rate-capped inside the
    // service, so this is a no-op until the cadence window opens).
    // ignore: unawaited_futures
    SharedPreferences.getInstance().then(
      FeatureDiscoveryService.instance.maybeScheduleNext,
    );

    final prayerCubit = context.read<PrayerTimesCubit>();

    // If the day rolled over while the app was backgrounded, silently recompute
    // (no spinner) so today's times, countdown and scheduled adhan are correct.
    // ignore: unawaited_futures
    prayerCubit.refreshIfStale();

    // Re-anchor the Salah tracker's "today" so the streak + today rows roll
    // over too (cheap no-op when the day hasn't changed).
    context.read<SalahTrackerCubit>().refreshIfStale();

    final prayerState = prayerCubit.state;
    if (prayerState is! PrayerTimesLoaded) return;
    final now = DateTime.now();
    final dateKey = DateTime(now.year, now.month, now.day);
    final today = prayerState.prayerTimes[dateKey];
    if (today != null) {
      // Fire-and-forget; failures are logged inside the manager.
      // ignore: unawaited_futures
      GlassPrayerHomeWidget.updateGlassWidgets(today);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AppLockPrayerSync {
  final AppLockPlatformService _platformService;
  int? _lastWindowStartMs;
  int? _lastNextPrayerMs;
  bool _lastEnabled = false;

  _AppLockPrayerSync(this._platformService);

  Future<void> sync(BuildContext context) async {
    final settingsState = context.read<SettingsCubit>().state;
    final prayerState = context.read<PrayerTimesCubit>().state;

    if (settingsState is! SettingsLoaded || prayerState is! PrayerTimesLoaded) {
      return;
    }

    final appLockSettings = settingsState.settings.appLockSettings;
    if (!appLockSettings.enabled ||
        appLockSettings.lockedAppPackageNames.isEmpty) {
      _lastEnabled = false;
      return;
    }

    final now = DateTime.now();
    final dateKey = DateTime(now.year, now.month, now.day);
    final todayTimes = prayerState.prayerTimes[dateKey];
    if (todayTimes == null) return;

    final window = AppLockPrayerWindow.fromPrayerTimes(todayTimes, now);
    if (window == null) return;

    final windowStartMs = window.windowStart.millisecondsSinceEpoch;
    final nextPrayerMs = window.nextPrayerStart.millisecondsSinceEpoch;

    if (_lastEnabled &&
        _lastWindowStartMs == windowStartMs &&
        _lastNextPrayerMs == nextPrayerMs) {
      return;
    }

    _lastEnabled = true;
    _lastWindowStartMs = windowStartMs;
    _lastNextPrayerMs = nextPrayerMs;

    await _platformService.updatePrayerWindow(
      prayerWindowStartMs: windowStartMs,
      nextPrayerStartMs: nextPrayerMs,
    );
  }
}
