import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/reading/reading_comfort.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/data/repositories/app_settings_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_settings_stream_usecase.dart';
import 'package:wadhakir/domain/usecases/get_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_app_lock_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_language_usecase.dart';
import 'package:wadhakir/domain/usecases/set_notification_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_reading_comfort_usecase.dart';
import 'package:wadhakir/domain/usecases/set_theme_mode_usecase.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/view/widgets/reading_comfort_selector.dart';

/// Roadmap #24 — the reading-comfort control itself.
///
/// The choices it offers were already tested in `core/reading`. What is tested
/// here is the thing that makes them *choosable*: the sample. Neither spacing
/// nor face has a right answer, so the control is only as good as the preview,
/// and a preview that renders on one line is not previewing line spacing at all.

Future<SettingsCubit> _cubit() async {
  SharedPreferences.setMockInitialValues({});
  final repo = AppSettingsRepositoryImpl(await SharedPreferences.getInstance());
  return SettingsCubit(
    getSettingsUseCase: GetSettingsUseCase(repo),
    getSettingsStreamUseCase: GetSettingsStreamUseCase(repo),
    setThemeModeUseCase: SetThemeModeUseCase(repo),
    setLanguageUseCase: SetLanguageUseCase(repo),
    setNotificationSettingsUseCase: SetNotificationSettingsUseCase(repo),
    setAppLockSettingsUseCase: SetAppLockSettingsUseCase(repo),
    setReadingComfortUseCase: SetReadingComfortUseCase(repo),
  );
}

AppSettingsModel _settings(ReadingComfort comfort) =>
    AppSettingsModel.defaultSettings().copyWith(readingComfort: comfort);

/// Pumps the selector at [width] with no localisations installed, so every
/// string falls through to the Arabic fallback the widget carries.
Future<void> _pump(
  WidgetTester tester,
  SettingsCubit cubit, {
  ReadingComfort comfort = ReadingComfort.defaults,
  double width = 360,
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(
                child: ReadingComfortSelector(
                  settings: _settings(comfort),
                  cubit: cubit,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The sample text, found by the string the widget falls back to.
Finder get _sample => find.textContaining('رَبَّنَا آتِنَا');

void main() {
  late SettingsCubit cubit;

  setUp(() async => cubit = await _cubit());
  tearDown(() async => cubit.close());

  group('the sample', () {
    testWidgets('breaks over more than one line', (tester) async {
      // The whole point. At 19pt with 2.0 leading a single line is ~38px, so
      // anything under ~60 means the sample fit on one line and the spacing
      // control has nothing to demonstrate.
      await _pump(tester, cubit);

      final height = tester.getSize(_sample).height;
      expect(
        height,
        greaterThan(60),
        reason: 'a one-line sample cannot preview line spacing',
      );
    });

    testWidgets('stays at its measure on a wide surface', (tester) async {
      // A tablet is where this breaks: given the full width, the sample fits on
      // one line and the preview silently stops working.
      await _pump(tester, cubit, width: 1000);

      final size = tester.getSize(_sample);
      expect(size.width, lessThanOrEqualTo(321));
      expect(
        size.height,
        greaterThan(60),
        reason: 'the measure exists so a wide screen still shows the leading',
      );
    });

    testWidgets('grows when the reader picks a wider leading', (tester) async {
      await _pump(tester, cubit);
      final comfortable = tester.getSize(_sample).height;

      await _pump(
        tester,
        cubit,
        comfort: const ReadingComfort(spacing: ReadingSpacing.airy),
      );
      final airy = tester.getSize(_sample).height;

      expect(
        airy,
        greaterThan(comfortable),
        reason: 'the sample must actually reflect the chosen spacing',
      );
    });

    testWidgets('tightens when the reader picks a compact leading', (
      tester,
    ) async {
      await _pump(tester, cubit);
      final comfortable = tester.getSize(_sample).height;

      await _pump(
        tester,
        cubit,
        comfort: const ReadingComfort(spacing: ReadingSpacing.compact),
      );

      expect(tester.getSize(_sample).height, lessThan(comfortable));
    });
  });

  group('the options', () {
    testWidgets('every spacing and every font is offered', (tester) async {
      await _pump(tester, cubit);

      for (final label in ['متقارب', 'مريح', 'متباعد']) {
        expect(find.text(label), findsWidgets, reason: '$label is missing');
      }
      for (final label in ['كما هو', 'المراعي', 'شهرزاد', 'عارف رقعة']) {
        expect(find.text(label), findsWidgets, reason: '$label is missing');
      }
    });

    testWidgets('each spacing chip carries a picture of its leading', (
      tester,
    ) async {
      await _pump(tester, cubit);

      // One glyph per spacing option — the part that makes «متباعد» mean
      // something before you tap it.
      final glyphs = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_SpacingGlyph',
      );
      expect(glyphs, findsNWidgets(ReadingSpacing.values.length));
    });

    testWidgets('a font chip renders in the face it offers', (tester) async {
      await _pump(tester, cubit);

      final chip = tester.widget<Text>(
        find.descendant(
          of: find.byType(ReadingComfortSelector),
          matching: find.text('شهرزاد'),
        ),
      );
      expect(chip.style?.fontFamily, 'ScheherazadeNew');
    });
  });

  group('the reset', () {
    testWidgets('is absent while nothing has been changed', (tester) async {
      await _pump(tester, cubit);
      expect(find.text('إعادة الضبط'), findsNothing);
    });

    testWidgets('appears once a choice has been made', (tester) async {
      await _pump(
        tester,
        cubit,
        comfort: const ReadingComfort(font: ReadingFont.arefRuqaa),
      );
      expect(find.text('إعادة الضبط'), findsOneWidget);
    });

    testWidgets('puts the defaults back', (tester) async {
      await _pump(
        tester,
        cubit,
        comfort: const ReadingComfort(
          spacing: ReadingSpacing.airy,
          font: ReadingFont.arefRuqaa,
        ),
      );

      await tester.tap(find.text('إعادة الضبط'));
      await tester.pumpAndSettle();

      // Asserted through storage rather than through the cubit's state: the
      // reset has to survive the trip to disk, which is what the reader will
      // see on the next launch.
      final repo = AppSettingsRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
      expect((await repo.getSettings()).readingComfort.isDefault, isTrue);
    });
  });

  group('the header summary', () {
    testWidgets('names the spacing but not an untouched font', (tester) async {
      // «كما هو» means "unchanged". Printing it in the summary would make a
      // setting nobody has touched look like a decision somebody made.
      await _pump(tester, cubit);
      expect(find.text('مريح · كما هو'), findsNothing);
      expect(find.text('مريح'), findsWidgets);
    });

    testWidgets('names both once a font has been chosen', (tester) async {
      await _pump(
        tester,
        cubit,
        comfort: const ReadingComfort(font: ReadingFont.scheherazade),
      );
      expect(find.text('مريح · شهرزاد'), findsOneWidget);
    });
  });
}
