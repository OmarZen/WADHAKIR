import 'package:wadhakir/data/repositories/fasting_reminders_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_fasting_reminder_settings_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/get_fasting_reminder_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_fasting_reminder_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_onboarding_completed_usecase.dart';
import 'package:wadhakir/domain/usecases/set_user_name_usecase.dart';
import 'package:wadhakir/domain/usecases/set_text_scale_usecase.dart';
import 'package:wadhakir/main.dart';
import 'package:wadhakir/domain/usecases/set_app_lock_settings_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/domain/usecases/get_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_language_usecase.dart';
import 'package:wadhakir/domain/usecases/set_theme_mode_usecase.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_stream_usecase.dart';
import 'package:wadhakir/data/repositories/app_settings_repository_impl.dart';
import 'package:wadhakir/data/repositories/daily_inspiration_settings_repository_impl.dart';
import 'package:wadhakir/data/repositories/azkar_reminder_settings_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_range_usecase.dart';
import 'package:wadhakir/domain/usecases/get_calculation_method_usecase.dart';
import 'package:wadhakir/domain/usecases/set_calculation_method_usecase.dart';
import 'package:wadhakir/data/repositories/prayer_times_repository_impl.dart';
import 'package:wadhakir/domain/usecases/set_notification_settings_usecase.dart';
import 'package:wadhakir/data/repositories/wird_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_wird_plan_usecase.dart';
import 'package:wadhakir/domain/usecases/set_wird_plan_usecase.dart';
import 'package:wadhakir/domain/usecases/get_wird_plan_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/clear_wird_plan_usecase.dart';
import 'package:wadhakir/data/repositories/salah_tracker_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_salah_log_usecase.dart';
import 'package:wadhakir/domain/usecases/set_salah_log_usecase.dart';
import 'package:wadhakir/domain/usecases/get_salah_log_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/clear_salah_log_usecase.dart';

// Smoke test: verify MyApp can be constructed with all its dependencies.
//
// We don't pumpWidget the full app here — the splash screen schedules a raw
// Future.delayed timer and the notification plugins aren't available under the
// test binding, which would make a full-tree pump flaky. Constructing MyApp is
// enough to catch a broken constructor signature (the most common breakage).
void main() {
  test('MyApp builds with all dependencies', () async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();
    final appSettingsRepository = AppSettingsRepositoryImpl(sharedPreferences);
    final prayerTimesRepository = PrayerTimesRepositoryImpl();
    final fastingRepository = FastingRemindersRepositoryImpl(sharedPreferences);
    final wirdRepository = WirdRepositoryImpl(sharedPreferences);
    final salahTrackerRepository = SalahTrackerRepositoryImpl(
      sharedPreferences,
    );

    final app = MyApp(
      getSettingsUseCase: GetSettingsUseCase(appSettingsRepository),
      getSettingsStreamUseCase: GetSettingsStreamUseCase(appSettingsRepository),
      setThemeModeUseCase: SetThemeModeUseCase(appSettingsRepository),
      setLanguageUseCase: SetLanguageUseCase(appSettingsRepository),
      setNotificationSettingsUseCase: SetNotificationSettingsUseCase(
        appSettingsRepository,
      ),
      setAppLockSettingsUseCase: SetAppLockSettingsUseCase(
        appSettingsRepository,
      ),
      setOnboardingCompletedUseCase: SetOnboardingCompletedUseCase(
        appSettingsRepository,
      ),
      setUserNameUseCase: SetUserNameUseCase(appSettingsRepository),
      setTextScaleUseCase: SetTextScaleUseCase(appSettingsRepository),
      getPrayerTimesUseCase: GetPrayerTimesUseCase(prayerTimesRepository),
      getPrayerTimesRangeUseCase: GetPrayerTimesRangeUseCase(
        prayerTimesRepository,
      ),
      getCalculationMethodUseCase: GetCalculationMethodUseCase(
        prayerTimesRepository,
      ),
      setCalculationMethodUseCase: SetCalculationMethodUseCase(
        prayerTimesRepository,
      ),
      prayerTimesRepository: prayerTimesRepository,
      getFastingReminderSettingsUseCase: GetFastingReminderSettingsUseCase(
        fastingRepository,
      ),
      setFastingReminderSettingsUseCase: SetFastingReminderSettingsUseCase(
        fastingRepository,
      ),
      getFastingReminderSettingsStreamUseCase:
          GetFastingReminderSettingsStreamUseCase(fastingRepository),
      getWirdPlanUseCase: GetWirdPlanUseCase(wirdRepository),
      setWirdPlanUseCase: SetWirdPlanUseCase(wirdRepository),
      getWirdPlanStreamUseCase: GetWirdPlanStreamUseCase(wirdRepository),
      clearWirdPlanUseCase: ClearWirdPlanUseCase(wirdRepository),
      dailyInspirationRepository: DailyInspirationSettingsRepositoryImpl(
        sharedPreferences,
      ),
      azkarReminderRepository: AzkarReminderSettingsRepositoryImpl(
        sharedPreferences,
      ),
      getSalahLogUseCase: GetSalahLogUseCase(salahTrackerRepository),
      setSalahLogUseCase: SetSalahLogUseCase(salahTrackerRepository),
      getSalahLogStreamUseCase: GetSalahLogStreamUseCase(
        salahTrackerRepository,
      ),
      clearSalahLogUseCase: ClearSalahLogUseCase(salahTrackerRepository),
    );

    expect(app, isNotNull);
  });
}
