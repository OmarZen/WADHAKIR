import 'package:wadhakir/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/domain/usecases/get_surahs_usecase.dart';
import 'package:wadhakir/domain/usecases/set_basmala_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_language_usecase.dart';
import 'package:wadhakir/domain/usecases/set_font_size_usecase.dart';
import 'package:wadhakir/domain/usecases/set_theme_mode_usecase.dart';
import 'package:wadhakir/data/repositories/quran_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_place_of_revelation.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/get_surah_by_number_usecase.dart';
import 'package:wadhakir/domain/usecases/get_verses_by_surah_usecase.dart';
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
        setFontSizeUseCase: SetFontSizeUseCase(
          AppSettingsRepositoryImpl(sharedPreferences),
        ),
        setBasmalaUseCase: SetBasmalaUseCase(
          AppSettingsRepositoryImpl(sharedPreferences),
        ),
        setNotificationSettingsUseCase: SetNotificationSettingsUseCase(
          AppSettingsRepositoryImpl(sharedPreferences),
        ),
        getSurahsUseCase: GetSurahsUseCase(QuranRepositoryImpl()),
        getSurahByNumberUseCase: GetSurahByNumberUseCase(QuranRepositoryImpl()),
        getVersesBySurahUseCase: GetVersesBySurahUseCase(QuranRepositoryImpl()),
        getPlaceOfRevelationUseCase: GetPlaceOfRevelationUseCase(
          QuranRepositoryImpl(),
        ),
        getPrayerTimesUseCase: GetPrayerTimesUseCase(prayerTimesRepository),
        getPrayerTimesRangeUseCase:
            GetPrayerTimesRangeUseCase(prayerTimesRepository),
        getCalculationMethodUseCase:
            GetCalculationMethodUseCase(prayerTimesRepository),
        setCalculationMethodUseCase:
            SetCalculationMethodUseCase(prayerTimesRepository),
        prayerTimesRepository: prayerTimesRepository,
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
