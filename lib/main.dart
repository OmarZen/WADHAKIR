import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:quran_library/quran_library.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/routes/app_router.dart';
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
import 'package:wadhakir/features/app_lock/services/app_lock_platform_service.dart';
import 'package:wadhakir/features/app_lock/services/app_lock_prayer_window.dart';
import 'package:wadhakir/features/floating_dhikr/service/floating_dhikr_overlay_entry.dart';
import 'package:wadhakir/features/floating_dhikr/service/floating_dhikr_service.dart';

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

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Silently continue without .env file - hardcoded values will be used as fallback
    // This is expected in CI/CD environments and for developers who haven't set up .env yet
  }

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

  // Create repositories
  final appSettingsRepository = AppSettingsRepositoryImpl(sharedPreferences);
  final prayerTimesRepository = PrayerTimesRepositoryImpl();
  final fastingRemindersRepository = FastingRemindersRepositoryImpl(
    sharedPreferences,
  );
  final wirdRepository = WirdRepositoryImpl(sharedPreferences);

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
    ),
  );

  // Fire-and-forget: if the user previously enabled the floating adhkar
  // overlay, resume its ticker. No await — overlay-permission checks happen
  // inside bootstrap and a failure is silent.
  // ignore: unawaited_futures
  FloatingDhikrService.instance.bootstrap();

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
          // Listen to prayer times loaded and schedule notifications
          BlocListener<PrayerTimesCubit, PrayerTimesState>(
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
        ],
        child: _GlassWidgetResumeRefresher(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            buildWhen: (previous, current) =>
                previous != current && current is SettingsLoaded,
            builder: (context, state) {
              // Default settings if not loaded yet
              var themeMode = ThemeMode.light;
              var locale = const Locale('ar');

              // Update with loaded settings if available
              if (state is SettingsLoaded) {
                themeMode = state.settings.themeMode;
                locale = Locale(state.settings.languageCode);
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
                onGenerateRoute: AppRouter.onGenerateRoute,
                // Layer forui alongside Material: every route below gets an
                // FTheme derived from the active Material theme, so forui
                // components match the app's brand colors + light/dark mode.
                // Material widgets (Quran reader, syncfusion pickers) ignore it.
                builder: (context, child) => FTheme(
                  data: buildForuiTheme(Theme.of(context)),
                  // FToaster provides the overlay host for forui toasts so any
                  // screen can call showFToast(...) with the unified styling.
                  child: FToaster(child: child ?? const SizedBox.shrink()),
                ),
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final prayerCubit = context.read<PrayerTimesCubit>();

    // If the day rolled over while the app was backgrounded, silently recompute
    // (no spinner) so today's times, countdown and scheduled adhan are correct.
    // ignore: unawaited_futures
    prayerCubit.refreshIfStale();

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
