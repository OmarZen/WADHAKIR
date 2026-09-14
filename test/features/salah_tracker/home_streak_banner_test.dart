import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/app_theme/forui_theme.dart';
import 'package:wadhakir/data/models/salah/salah_enums.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/features/home/views/widgets/home_streak_banner.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_cubit.dart';
import 'package:wadhakir/features/salah_tracker/cubit/salah_tracker_state.dart';
import 'package:wadhakir/features/salah_tracker/services/salah_stats_service.dart';

/// Fixed so the 30-day window is deterministic; a banner test that reads the
/// wall clock fails on the day a month boundary lands wrong.
final _today = DateTime(2026, 3, 14);

const _stats = SalahStatsService();

/// Feeds the banner a state directly rather than driving the real cubit, which
/// would need the whole use-case graph. The banner reads only `log`, `today`
/// and `todayStatuses`, and derives everything else itself.
class _FixedCubit extends Cubit<SalahTrackerState>
    implements SalahTrackerCubit {
  _FixedCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SalahLogModel _log({
  /// Day offsets back from [_today] on which all five fard were prayed.
  List<int> prayedDaysAgo = const [],

  /// Day offsets back from [_today] on which all five were marked missed —
  /// logged, but nothing kept.
  List<int> missedDaysAgo = const [],

  /// Day offset back from [_today] at which tracking was paused. Both
  /// `excusedSince` and the filled `excusedDays` set are written, because that
  /// is the shape `SalahTrackerCubit.syncPause()` leaves on disk — the anchor
  /// is the state, the set is what `isExcusedDay` actually reads.
  int? excusedSinceDaysAgo,
}) {
  final days = <String, Map<PrayerSlot, PrayerStatus>>{};
  for (final ago in prayedDaysAgo) {
    days[SalahLogModel.dateKey(_today.subtract(Duration(days: ago)))] = {
      for (final slot in PrayerSlot.values) slot: PrayerStatus.onTime,
    };
  }
  for (final ago in missedDaysAgo) {
    days[SalahLogModel.dateKey(_today.subtract(Duration(days: ago)))] = {
      for (final slot in PrayerSlot.values) slot: PrayerStatus.missed,
    };
  }
  final excusedDays = <String>{};
  if (excusedSinceDaysAgo != null) {
    for (var ago = excusedSinceDaysAgo; ago >= 0; ago--) {
      excusedDays.add(
        SalahLogModel.dateKey(_today.subtract(Duration(days: ago))),
      );
    }
  }

  return SalahLogModel.defaultSettings().copyWith(
    days: days,
    excusedDays: excusedDays,
    excusedSince: excusedSinceDaysAgo == null
        ? null
        : SalahLogModel.dateKey(
            _today.subtract(Duration(days: excusedSinceDaysAgo)),
          ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  SalahLogModel log, {
  Locale locale = const Locale('ar'),
}) async {
  final todayStatuses =
      log.days[SalahLogModel.dateKey(_today)] ??
      const <PrayerSlot, PrayerStatus>{};
  final state = SalahTrackerLoaded(
    log: log,
    today: _today,
    currentStreak: _stats.currentStreak(log, _today),
    bestStreak: _stats.bestStreak(log),
    todayStatuses: todayStatuses,
    todayCompletion: todayStatuses.values.where((s) => s.isPrayed).length / 5,
    totalMakeUp: 0,
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      // Needed for `ar`: without them Flutter warns (and fails the test) that
      // no Material/Cupertino delegate covers the locale.
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // No AppLocalizations delegate: `context.l10n` is null and the widget's
      // inline Arabic fallbacks render, which is the path these assertions
      // read. The strings are identical to assets/lang/ar.json.
      home: Builder(
        // FTappable needs forui's accessibility scope, which main.dart
        // installs for every route via MaterialApp.builder. Mirrored here or
        // the banner throws before it can render anything.
        builder: (context) => FTheme(
          data: buildForuiTheme(Theme.of(context)),
          child: Scaffold(
            body: BlocProvider<SalahTrackerCubit>.value(
              value: _FixedCubit(state),
              child: const HomeStreakBanner(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the banner never reports a nought', () {
    testWidgets('a perfect month reads 100%', (tester) async {
      await _pump(tester, _log(prayedDaysAgo: List.generate(30, (i) => i)));
      expect(find.text('المداومة ١٠٠٪'), findsOneWidget);
      expect(find.text('آخر ٣٠ يومًا'), findsOneWidget);
    });

    testWidgets('one missed day costs a few points, not everything', (
      tester,
    ) async {
      // The whole point of the change: under the old streak this state showed
      // "0" and "start your streak today". 29 of 30 days kept is 97%.
      await _pump(
        tester,
        _log(prayedDaysAgo: List.generate(30, (i) => i)..remove(5)),
      );

      expect(find.text('المداومة ٩٧٪'), findsOneWidget);
      expect(find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة'), findsNothing);
    });

    testWidgets('a fortnight of nothing shows the welcome, not 0%', (
      tester,
    ) async {
      await _pump(tester, _log(prayedDaysAgo: [20, 21, 22]));

      expect(find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة'), findsOneWidget);
      expect(find.textContaining('٪'), findsNothing);
      expect(find.textContaining('٠٪'), findsNothing);
    });

    testWidgets('a month logged entirely as missed still shows no nought', (
      tester,
    ) async {
      // Reachable without any lapse: every day is logged, so daysSinceLastLog
      // is 0, but nothing was kept so the ratio is exactly zero. Without the
      // explicit guard this is where "المداومة ٠٪" would appear.
      await _pump(tester, _log(missedDaysAgo: List.generate(30, (i) => i)));

      expect(find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة'), findsOneWidget);
      expect(find.text('المداومة ٠٪'), findsNothing);
    });

    testWidgets('an empty log invites rather than measures', (tester) async {
      await _pump(tester, _log());
      expect(find.text('ابدأ اليوم — ولو بصلاة واحدة'), findsOneWidget);
      expect(find.textContaining('المداومة'), findsNothing);
    });
  });

  group('an excused day is not a lapse', () {
    testWidgets('a paused log says so instead of welcoming the user back', (
      tester,
    ) async {
      // The bug أيام العذر exists to prevent: telling a woman in hayd that she
      // has been away, and showing her a 0/5 debt for a day that owes nothing.
      await _pump(
        tester,
        _log(prayedDaysAgo: [10, 11, 12], excusedSinceDaysAgo: 4),
      );

      expect(find.text('يوم عذر'), findsOneWidget);
      expect(find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة'), findsNothing);
      // No today ring at all: nothing is owed, so there is no fraction to show.
      expect(find.text('٠/٥'), findsNothing);
      expect(find.text('اليوم'), findsNothing);
    });

    testWidgets('an excused stretch is not a lapse when the pause lifts', (
      tester,
    ) async {
      // The day her excuse ends, the pause is lifted and the banner starts
      // measuring again. daysSinceLastLog counts calendar days, so it reads
      // "7 days away" and the banner would tell a woman who was excused that
      // she had lapsed — the exact reproach أيام العذر exists to prevent,
      // arriving from the one screen she sees on every app open.
      //
      // Prayed a solid month up to 8 days ago, then 7 excused days that ended
      // yesterday. Nothing was owed in the gap, so nothing was missed.
      final log =
          _log(
            prayedDaysAgo: List.generate(22, (i) => i + 8),
            excusedSinceDaysAgo: 7,
          ).copyWith(
            // The pause has been lifted: excusedDays still records the stretch,
            // but today is no longer one of them.
            excusedDays: {
              for (var ago = 7; ago >= 1; ago--)
                SalahLogModel.dateKey(_today.subtract(Duration(days: ago))),
            },
            clearExcusedSince: true,
          );

      await _pump(tester, log);

      expect(find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة'), findsNothing);
      expect(find.textContaining('المداومة'), findsOneWidget);
    });

    testWidgets('a real lapse still shows the welcome', (tester) async {
      // Same shape, but the empty days were never excused.
      await _pump(tester, _log(prayedDaysAgo: List.generate(22, (i) => i + 8)));
      expect(find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة'), findsOneWidget);
    });
  });

  group('numerals follow the locale', () {
    testWidgets('Arabic renders Arabic-Indic digits', (tester) async {
      await _pump(tester, _log(prayedDaysAgo: List.generate(30, (i) => i)));
      expect(find.text('المداومة ١٠٠٪'), findsOneWidget);
      expect(find.text('٥/٥'), findsOneWidget);
    });

    testWidgets('English renders Western digits', (tester) async {
      // The banner used to print ٣/٥ in the middle of an English screen.
      await _pump(
        tester,
        _log(prayedDaysAgo: List.generate(30, (i) => i)),
        locale: const Locale('en'),
      );
      expect(find.textContaining('100%'), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);
      expect(find.text('٥/٥'), findsNothing);
    });
  });
}
