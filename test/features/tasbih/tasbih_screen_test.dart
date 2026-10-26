import 'dart:convert';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/app_theme/app_theme.dart';
import 'package:wadhakir/core/app_theme/forui_theme.dart';
import 'package:wadhakir/core/localization/app_localizations_delegate.dart';
import 'package:wadhakir/features/tasbih/cubit/tasbih_cubit.dart';
import 'package:wadhakir/features/tasbih/data/tasbih_models.dart';
import 'package:wadhakir/features/tasbih/data/tasbih_repository.dart';
import 'package:wadhakir/features/tasbih/data/tasbih_texts.dart';
import 'package:wadhakir/features/tasbih/views/screens/electronic_tasbih_screen.dart';
import 'package:wadhakir/features/tasbih/views/widgets/dhikr_carousel.dart';
import 'package:wadhakir/features/tasbih/views/widgets/modes/beads_mode.dart';
import 'package:wadhakir/features/tasbih/views/widgets/modes/focus_mode.dart';
import 'package:wadhakir/features/tasbih/views/widgets/modes/ring_mode.dart';
import 'package:wadhakir/features/tasbih/views/widgets/modes/tap_mode.dart';
import 'package:wadhakir/features/tasbih/views/widgets/tasbih_mode_selector.dart';

import 'fake_tasbih_feedback.dart';

/// The السبحة screen, in Arabic and right to left unless a test says
/// otherwise, with a fake standing in for the phone's vibrator, speaker and
/// screen.

final _noon = DateTime(2026, 10, 25, 12);

String _v2WithTarget(int target, {int count = 0}) => jsonEncode({
  'v': 2,
  'selected': 'subhan_allah',
  'day': '2026-10-25',
  'todayTotal': 0,
  'dhikr': {
    'subhan_allah': {'c': count, 't': target, 'r': 0},
  },
});

Future<FakeTasbihFeedback> _pump(
  WidgetTester tester, {
  Map<String, Object> stored = const {},
  TasbihMode? mode,
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool dark = false,
  bool reduceMotion = false,
  FakeTasbihFeedback? feedback,
  Locale locale = const Locale('ar'),
  bool realStrings = false,
}) async {
  final values = <String, Object>{...stored};
  if (mode != null) {
    values[TasbihRepository.prefsKey] = TasbihPrefs(mode: mode).encode();
  }
  SharedPreferences.setMockInitialValues(values);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  if (realStrings) rootBundle.clear();

  final fb = feedback ?? FakeTasbihFeedback();
  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: [
        if (realStrings) const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: FTheme(data: buildForuiTheme(Theme.of(context)), child: child!),
      ),
      home: ElectronicTasbihScreen(feedback: fb, now: () => _noon),
    ),
  );
  if (realStrings) {
    // The language file is read by real I/O, which the fake clock never lets
    // finish. Give it real time (see qibla_ar_safety_notice_test.dart).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
  }
  await tester.pumpAndSettle();
  return fb;
}

TasbihCubit _cubit(WidgetTester tester) =>
    tester.element(find.byType(TasbihModeSelector)).read<TasbihCubit>();

Finder get _tapButton => find.text('اضغط للعدّ');

void main() {
  group('the four modes', () {
    final bodies = {
      TasbihMode.beads: BeadsModeBody,
      TasbihMode.tap: TapModeBody,
      TasbihMode.ring: RingModeBody,
      TasbihMode.focus: FocusModeBody,
    };

    for (final entry in bodies.entries) {
      testWidgets('${entry.key.name} renders', (tester) async {
        await _pump(tester, mode: entry.key);
        expect(find.byType(entry.value), findsOneWidget);
        expect(find.text('السبحة'), findsOneWidget);
        expect(find.text(TasbihTexts.subhanAllah), findsWidgets);
      });
    }

    testWidgets('the selector switches mode and remembers it', (tester) async {
      await _pump(tester);
      expect(find.byType(TapModeBody), findsOneWidget);
      await tester.tap(find.text('الحلقة'));
      await tester.pumpAndSettle();
      expect(find.byType(RingModeBody), findsOneWidget);
      expect(_cubit(tester).state.mode, TasbihMode.ring);

      final prefs = await SharedPreferences.getInstance();
      expect(
        TasbihPrefs.decode(prefs.getString(TasbihRepository.prefsKey)).mode,
        TasbihMode.ring,
      );
    });
  });

  group('counting', () {
    testWidgets('tap mode counts on its button', (tester) async {
      final fb = await _pump(tester);
      expect(find.text('من 33'), findsOneWidget);
      await tester.tap(_tapButton);
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.count, 1);
      expect(
        find.descendant(of: find.byType(TapModeBody), matching: find.text('1')),
        findsOneWidget,
      );
      expect(fb.taps, [(true, false)]);
    });

    testWidgets('ring mode counts a tap anywhere, the carousel included', (
      tester,
    ) async {
      await _pump(tester, mode: TasbihMode.ring);
      await tester.tap(find.byType(RingModeBody));
      await tester.pump();
      await tester.tap(find.text(TasbihTexts.subhanAllah).first);
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.count, 2);
    });

    testWidgets('focus mode counts a tap anywhere', (tester) async {
      await _pump(tester, mode: TasbihMode.focus);
      await tester.tap(find.byType(FocusModeBody));
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.count, 1);
      expect(find.text('1 من 33'), findsOneWidget);
    });

    testWidgets('beads: dragging left counts in Arabic, right does not', (
      tester,
    ) async {
      await _pump(tester, mode: TasbihMode.beads);
      await tester.drag(find.byType(BeadsArea), const Offset(140, 0));
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.count, 0);

      await tester.drag(find.byType(BeadsArea), const Offset(-140, 0));
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.count, greaterThan(0));
    });

    testWidgets('beads: a tap on the string counts one', (tester) async {
      await _pump(tester, mode: TasbihMode.beads);
      await tester.tap(find.byType(BeadsArea));
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.count, 1);
      expect(find.text('اسحب الحبة لليسار للعدّ'), findsOneWidget);
    });

    testWidgets('Space counts from a keyboard', (tester) async {
      await _pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(_cubit(tester).state.selected.count, 1);
    });

    testWidgets('a finished round is announced, then the next round shows', (
      tester,
    ) async {
      final fb = await _pump(
        tester,
        stored: {TasbihRepository.stateKey: _v2WithTarget(3, count: 2)},
      );
      await tester.tap(_tapButton);
      await tester.pump();
      expect(find.text('اكتملت الدورة 1'), findsOneWidget);
      expect(fb.rounds, hasLength(1));
      expect(fb.taps, isEmpty);
      // No dialog and no confetti: the next tasbiha is one tap away.
      expect(find.byType(Dialog), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('الهدف 3 · الدورة 2'), findsOneWidget);
    });
  });

  group('keyboard and mouse', () {
    testWidgets('the arrows change the dhikr, the way the carousel runs', (
      tester,
    ) async {
      await _pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(
        _cubit(tester).state.selectedIndex,
        1,
        reason: 'in Arabic the next dhikr lies to the left',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selectedIndex, 0);
      expect(_cubit(tester).state.selected.count, 0, reason: 'no counting');
    });

    testWidgets('in English the next dhikr is to the right', (tester) async {
      await _pump(tester, locale: const Locale('en'));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selectedIndex, 1);
    });

    testWidgets('Space on a focused button is the button\'s, not a count', (
      tester,
    ) async {
      await _pump(tester);
      Focus.of(tester.element(find.byIcon(Icons.tune_rounded))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.count, 0);
      expect(find.text('إعدادات السبحة'), findsOneWidget);
    });

    testWidgets('a mouse drags the carousel to the next dhikr', (tester) async {
      await _pump(tester);
      // Right to left: the next dhikr comes in from the left.
      await tester.drag(
        find.byType(DhikrCarousel),
        const Offset(200, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selectedIndex, 1);
    });

    testWidgets('a mouse wheel turns the carousel one dhikr a notch', (
      tester,
    ) async {
      await _pump(tester);
      final mouse = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        mouse.hover(tester.getCenter(find.byType(DhikrCarousel))),
      );
      Future<void> wheel(double dy, int ms) async {
        await tester.sendEventToBinding(
          mouse.scroll(Offset(0, dy), timeStamp: Duration(milliseconds: ms)),
        );
        await tester.pumpAndSettle();
      }

      await wheel(100, 1000);
      expect(_cubit(tester).state.selectedIndex, 1);
      // The tail of the same flick is not a second step.
      await wheel(20, 1050);
      expect(_cubit(tester).state.selectedIndex, 1);
      await wheel(-100, 2000);
      expect(_cubit(tester).state.selectedIndex, 0);
      await wheel(-100, 3000);
      expect(_cubit(tester).state.selectedIndex, 7, reason: 'it wraps');
    });

    testWidgets('closing the window writes the pending taps first', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(_tapButton);
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt('electronic_tasbih_counter'),
        0,
        reason: 'the tap is still waiting on the debounce',
      );
      expect(await tester.binding.handleRequestAppExit(), AppExitResponse.exit);
      expect(prefs.getInt('electronic_tasbih_counter'), 1);
    });
  });

  group('reset', () {
    testWidgets('asks first, in the exact words, then resets', (tester) async {
      await _pump(tester);
      await tester.tap(_tapButton);
      await tester.pump();
      await tester.tap(_tapButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      await tester.pumpAndSettle();
      expect(find.text('تصفير العداد؟'), findsOneWidget);
      expect(
        find.text(
          'سيُصفَّر العدد الحالي (2) ودورات «${TasbihTexts.subhanAllah}» '
          'لهذا اليوم. لا يمكن التراجع.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('تصفير'));
      await tester.pumpAndSettle();
      final state = _cubit(tester).state;
      expect(state.selected.count, 0);
      expect(state.todayTotal, 2, reason: 'those tasbihat were said');
    });

    testWidgets('cancel leaves the count alone', (tester) async {
      await _pump(tester);
      await tester.tap(_tapButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.count, 1);
    });
  });

  group('settings sheet', () {
    testWidgets('shows the targets and every switch', (tester) async {
      await _pump(tester);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      expect(find.text('إعدادات السبحة'), findsOneWidget);
      for (final chip in ['33', '99', '100', 'مخصص']) {
        expect(find.text(chip), findsOneWidget, reason: chip);
      }
      for (final row in [
        'الاهتزاز مع كل تسبيحة',
        'صوت النقر',
        'الانتقال للذكر التالي تلقائيًا',
        'إبقاء الشاشة مضاءة',
      ]) {
        expect(find.text(row), findsOneWidget, reason: row);
      }
      expect(find.text('المجموع منذ البداية'), findsOneWidget);

      await tester.tap(find.text('99'));
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.target, 99);
    });

    testWidgets('hides what the platform cannot do', (tester) async {
      await _pump(
        tester,
        mode: TasbihMode.focus,
        feedback: FakeTasbihFeedback(
          supportsHaptics: false,
          supportsSound: false,
          supportsKeepScreenOn: false,
        ),
      );
      expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
      expect(find.byIcon(Icons.vibration_rounded), findsNothing);
      // No promise the screen stays on where it will not.
      expect(find.text('اضغط في أي مكان للعدّ'), findsOneWidget);
      expect(find.textContaining('الشاشة تبقى مضاءة'), findsNothing);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      expect(find.text('الانتقال للذكر التالي تلقائيًا'), findsOneWidget);
      expect(find.text('الاهتزاز مع كل تسبيحة'), findsNothing);
      expect(find.text('صوت النقر'), findsNothing);
      expect(find.text('إبقاء الشاشة مضاءة'), findsNothing);
    });

    testWidgets('a custom target applies on «تطبيق», above the keyboard', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مخصص'));
      await tester.pumpAndSettle();

      // The keyboard comes up over the sheet.
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final apply = find.text('تطبيق');
      expect(apply, findsOneWidget);
      expect(tester.getBottomLeft(apply).dy, lessThanOrEqualTo(844 - 320));

      await tester.enterText(find.byType(TextField), '1000');
      await tester.pump();
      // Typing alone changes nothing: «1» on the way to «1000» is not a target.
      expect(_cubit(tester).state.selected.target, 33);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.target, 1000);
    });
  });

  group('keep the screen on', () {
    testWidgets('on while open, re-sent on resume, off on the way out', (
      tester,
    ) async {
      final fb = await _pump(tester);
      expect(fb.screenOn, [true]);

      _cubit(tester).setKeepScreenOn(false);
      await tester.pump();
      expect(fb.screenOn.last, isFalse);

      // Focus mode holds the screen whatever the switch says.
      _cubit(tester).setMode(TasbihMode.focus);
      await tester.pumpAndSettle();
      expect(fb.screenOn.last, isTrue);

      final before = fb.screenOn.length;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(fb.screenOn.length, before + 1);
      expect(fb.screenOn.last, isTrue);

      await tester.pumpWidget(const SizedBox());
      expect(fb.screenOn.last, isFalse);
      expect(fb.releases, 1);
    });
  });

  group('accessibility and layout', () {
    testWidgets('beads: TalkBack gets tap and increase, and no scroll', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, mode: TasbihMode.beads);
      final beads = find.semantics.byLabel('اسحب الحبة للعدّ');
      final data = beads.evaluate().single.getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.scrollLeft), isFalse);
      expect(data.hasAction(SemanticsAction.scrollRight), isFalse);
      // Nor anywhere else: the drag's own scroll actions used to sit on an
      // unlabelled node under this one, the node TalkBack's touch lands on,
      // and each was a fake pull of most of the width — about seven
      // tasbihat for one gesture.
      expect(
        find.semantics.byAnyAction([
          SemanticsAction.scrollLeft,
          SemanticsAction.scrollRight,
        ]),
        findsNothing,
      );

      tester.semantics.increase(beads);
      await tester.pumpAndSettle();
      expect(_cubit(tester).state.selected.count, 1);
      semantics.dispose();
    });

    testWidgets('a mode switch keeps the carousel and a round being '
        'announced', (tester) async {
      await _pump(
        tester,
        stored: {TasbihRepository.stateKey: _v2WithTarget(3, count: 2)},
      );
      final carousel = tester.state(find.byType(DhikrCarousel));
      await tester.tap(_tapButton);
      await tester.pump();
      expect(find.text('اكتملت الدورة 1'), findsOneWidget);

      // Tap mode to ring adds the whole-area tap above the column.
      _cubit(tester).setMode(TasbihMode.ring);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RingModeBody), findsOneWidget);
      expect(find.text('اكتملت الدورة 1'), findsOneWidget);
      expect(tester.state(find.byType(DhikrCarousel)), same(carousel));

      // And back to tap, where a tap on the carousel counts nothing again.
      _cubit(tester).setMode(TasbihMode.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.state(find.byType(DhikrCarousel)), same(carousel));
      await tester.tap(find.text(TasbihTexts.subhanAllah).first);
      await tester.pump();
      expect(_cubit(tester).state.todayTotal, 1);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('reduced motion leaves no frames pending', (tester) async {
      await _pump(
        tester,
        reduceMotion: true,
        stored: {TasbihRepository.stateKey: _v2WithTarget(3)},
      );
      for (var i = 0; i < 4; i++) {
        await tester.tap(_tapButton);
        await tester.pump();
      }
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(_cubit(tester).state.selected.roundsToday, 1);
    });

    for (final mode in TasbihMode.values) {
      testWidgets('${mode.name}: text scale 1.6 at 360×640 does not overflow', (
        tester,
      ) async {
        await _pump(
          tester,
          mode: mode,
          size: const Size(360, 640),
          textScale: 1.6,
        );
        expect(tester.takeException(), isNull);
        // And still counts.
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(_cubit(tester).state.selected.count, 1);
      });

      testWidgets('${mode.name}: renders in the dark theme', (tester) async {
        await _pump(tester, mode: mode, dark: true);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the sheet fits at text scale 1.6 on a small phone', (
      tester,
    ) async {
      await _pump(tester, size: const Size(360, 640), textScale: 1.6);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مخصص'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('no share button: the tasbih keeps no scoreboard', (
      tester,
    ) async {
      // Same rule as wird_share_test.dart: a count is not something to post.
      await _pump(tester);
      for (final icon in [
        Icons.share,
        Icons.share_rounded,
        Icons.share_outlined,
        Icons.ios_share,
        Icons.ios_share_rounded,
      ]) {
        expect(find.byIcon(icon), findsNothing);
      }
    });
  });

  testWidgets('in English, left to right, from the app\'s own strings', (
    tester,
  ) async {
    await _pump(
      tester,
      mode: TasbihMode.beads,
      locale: const Locale('en'),
      realStrings: true,
    );
    expect(find.text('Tasbih'), findsOneWidget);
    expect(find.text('Drag the bead right to count'), findsOneWidget);
    expect(find.text('Beads'), findsOneWidget);

    // Forward is to the right in English.
    await tester.drag(find.byType(BeadsArea), const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(_cubit(tester).state.selected.count, 0);
    await tester.drag(find.byType(BeadsArea), const Offset(140, 0));
    await tester.pumpAndSettle();
    expect(_cubit(tester).state.selected.count, greaterThan(0));
  });
}
