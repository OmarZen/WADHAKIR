import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quran_library/quran_library.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wadhakir/core/routes/app_router.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/data/models/hive_adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/features/radio/cubit/radio_cubit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:wadhakir/core/localization/language_manager.dart';
import 'package:wadhakir/domain/usecases/get_radios_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_language_usecase.dart';
import 'package:wadhakir/features/splash_screen/splash_screen.dart';
import 'package:wadhakir/domain/usecases/set_theme_mode_usecase.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/data/repositories/radio_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_stream_usecase.dart';
import 'package:wadhakir/core/localization/app_localizations_delegate.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/data/repositories/app_settings_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_range_usecase.dart';
import 'package:wadhakir/domain/usecases/get_calculation_method_usecase.dart';
import 'package:wadhakir/domain/usecases/set_calculation_method_usecase.dart';
import 'package:wadhakir/data/repositories/prayer_times_repository_impl.dart';
import 'package:wadhakir/domain/usecases/set_notification_settings_usecase.dart';
import 'package:wadhakir/features/pray_times/services/prayer_notification_service.dart';
import 'package:wadhakir/features/prayer_times/presentation/widgets/prayer_times_home_widget.dart';

void main() async {
  // Initialize widgets binding and preserve splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Set system UI overlay style for edge-to-edge experience
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Initialize home widget
  await PrayerTimesHomeWidget.setupBackgroundCallback();

  // Initialize notification service
  final notificationService = PrayerNotificationService();
  await notificationService.initialize();

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

  // Initialize Quran Library
  await QuranLibrary.init();

  // Create repositories
  final appSettingsRepository = AppSettingsRepositoryImpl(sharedPreferences);
  final prayerTimesRepository = PrayerTimesRepositoryImpl();

  // Create settings use cases
  final getSettingsUseCase = GetSettingsUseCase(appSettingsRepository);
  final getSettingsStreamUseCase = GetSettingsStreamUseCase(
    appSettingsRepository,
  );
  final setThemeModeUseCase = SetThemeModeUseCase(appSettingsRepository);
  final setLanguageUseCase = SetLanguageUseCase(appSettingsRepository);

  final setNotificationSettingsUseCase =
      SetNotificationSettingsUseCase(appSettingsRepository);

  // Create prayer times use cases
  final getPrayerTimesUseCase = GetPrayerTimesUseCase(prayerTimesRepository);
  final getPrayerTimesRangeUseCase =
      GetPrayerTimesRangeUseCase(prayerTimesRepository);
  final getCalculationMethodUseCase =
      GetCalculationMethodUseCase(prayerTimesRepository);
  final setCalculationMethodUseCase =
      SetCalculationMethodUseCase(prayerTimesRepository);

  runApp(
    MyApp(
      // Settings
      getSettingsUseCase: getSettingsUseCase,
      getSettingsStreamUseCase: getSettingsStreamUseCase,
      setThemeModeUseCase: setThemeModeUseCase,
      setLanguageUseCase: setLanguageUseCase,
      setNotificationSettingsUseCase: setNotificationSettingsUseCase,
      // Quran

      // Prayer Times
      getPrayerTimesUseCase: getPrayerTimesUseCase,
      getPrayerTimesRangeUseCase: getPrayerTimesRangeUseCase,
      getCalculationMethodUseCase: getCalculationMethodUseCase,
      setCalculationMethodUseCase: setCalculationMethodUseCase,
      prayerTimesRepository: prayerTimesRepository,
    ),
  );

  // Remove splash screen once app is ready
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  // Settings
  final GetSettingsUseCase getSettingsUseCase;
  final GetSettingsStreamUseCase getSettingsStreamUseCase;
  final SetThemeModeUseCase setThemeModeUseCase;
  final SetLanguageUseCase setLanguageUseCase;
  final SetNotificationSettingsUseCase setNotificationSettingsUseCase;

  // Quran

  // Prayer Times
  final GetPrayerTimesUseCase getPrayerTimesUseCase;
  final GetPrayerTimesRangeUseCase getPrayerTimesRangeUseCase;
  final GetCalculationMethodUseCase getCalculationMethodUseCase;
  final SetCalculationMethodUseCase setCalculationMethodUseCase;
  final PrayerTimesRepositoryImpl prayerTimesRepository;

  const MyApp({
    super.key,
    // Settings
    required this.getSettingsUseCase,
    required this.getSettingsStreamUseCase,
    required this.setThemeModeUseCase,
    required this.setLanguageUseCase,
    required this.setNotificationSettingsUseCase,
    // Quran

    // Prayer Times
    required this.getPrayerTimesUseCase,
    required this.getPrayerTimesRangeUseCase,
    required this.getCalculationMethodUseCase,
    required this.setCalculationMethodUseCase,
    required this.prayerTimesRepository,
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
          ),
          lazy: false,
        ),
        BlocProvider<RadioCubit>(
          create: (_) => RadioCubit(GetRadiosUseCase(RadioRepositoryImpl()))
            ..loadStations(),
          lazy: false,
        ),
        BlocProvider<PrayerTimesCubit>(
          create: (_) => PrayerTimesCubit(
            getPrayerTimesUseCase,
            getPrayerTimesRangeUseCase,
            getCalculationMethodUseCase,
            setCalculationMethodUseCase,
            repository: prayerTimesRepository,
          )..loadPrayerTimes(),
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
              }
            },
          ),
        ],
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
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: LanguageManager.supportedLocales,
              locale: locale,
              onGenerateRoute: AppRouter.onGenerateRoute,
              home: const WadhakirSplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
