import 'package:wadhakir/data/repositories/fasting_reminders_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_fasting_reminder_settings_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/get_fasting_reminder_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_fasting_reminder_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_onboarding_completed_usecase.dart';
import 'package:wadhakir/main.dart';
import 'package:wadhakir/domain/usecases/set_app_lock_settings_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/domain/usecases/get_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_language_usecase.dart';
import 'package:wadhakir/domain/usecases/set_theme_mode_usecase.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_stream_usecase.dart';
import 'package:wadhakir/data/repositories/app_settings_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_range_usecase.dart';
import 'package:wadhakir/domain/usecases/get_calculation_method_usecase.dart';
import 'package:wadhakir/domain/usecases/set_calculation_method_usecase.dart';
import 'package:wadhakir/data/repositories/prayer_times_repository_impl.dart';
import 'package:wadhakir/domain/usecases/set_notification_settings_usecase.dart';
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // shared preferences
    final sharedPreferences = await SharedPreferences.getInstance();
    final prayerTimesRepository = PrayerTimesRepositoryImpl();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(
        getSettingsUseCase: GetSettingsUseCase(
          AppSettingsRepositoryImpl(sharedPreferences),
        ),
        getSettingsStreamUseCase: GetSettingsStreamUseCase(
          AppSettingsRepositoryImpl(sharedPreferences),
        ),
        setThemeModeUseCase: SetThemeModeUseCase(
          AppSettingsRepositoryImpl(sharedPreferences),
        ),
        setLanguageUseCase: SetLanguageUseCase(
          AppSettingsRepositoryImpl(sharedPreferences),
        ),
        setNotificationSettingsUseCase: SetNotificationSettingsUseCase(
          AppSettingsRepositoryImpl(sharedPreferences),
        ),
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
          FastingRemindersRepositoryImpl(sharedPreferences),
        ),
        setFastingReminderSettingsUseCase: SetFastingReminderSettingsUseCase(
          FastingRemindersRepositoryImpl(sharedPreferences),
        ),
        getFastingReminderSettingsStreamUseCase:
            GetFastingReminderSettingsStreamUseCase(
          FastingRemindersRepositoryImpl(sharedPreferences),
        ),
        setAppLockSettingsUseCase: SetAppLockSettingsUseCase(
          AppSettingsRepositoryImpl(sharedPreferences),
        ),
        setOnboardingCompletedUseCase: SetOnboardingCompletedUseCase(
          AppSettingsRepositoryImpl(sharedPreferences),
        ),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
