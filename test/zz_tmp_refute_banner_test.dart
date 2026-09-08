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

final _today = DateTime(2026, 3, 14);
const _stats = SalahStatsService();

class _FixedCubit extends Cubit<SalahTrackerState>
    implements SalahTrackerCubit {
  _FixedCubit(super.initialState);
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, SalahLogModel log) async {
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
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
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
  testWidgets('post-pause morning, built the way the cubit builds it', (
    tester,
  ) async {
    // Start from a log with prayers logged on days 8,9,10 (the days before the
    // period started), then run the REAL pause flow: startPause anchored at
    // today-7, syncPause filling forward, endPause today.
    var log = SalahLogModel.defaultSettings();
    for (final ago in [8, 9, 10]) {
      final key = SalahLogModel.dateKey(_today.subtract(Duration(days: ago)));
      for (final slot in PrayerSlot.values) {
        log = log.setFard(key, slot, PrayerStatus.onTime);
      }
    }
    // syncPause() marks start..today excused; the woman ends the pause today,
    // and endPause() only clears the anchor. Reproduce exactly: excused
    // today-7..today-1, today NOT excused (she lifted it), anchor cleared.
    log = log.setExcusedRange(
      _today.subtract(const Duration(days: 7)),
      _today.subtract(const Duration(days: 1)),
      true,
    );

    // ignore: avoid_print
    print('days keys: ${log.days.keys.toList()..sort()}');
    // ignore: avoid_print
    print('excused: ${log.excusedDays.toList()..sort()}');
    // ignore: avoid_print
    print('isExcusedDay(today): ${log.isExcusedDay(_today)}');
    // ignore: avoid_print
    print('daysSinceLastLog: ${_stats.daysSinceLastLog(log, _today)}');
    // ignore: avoid_print
    print(
      'istiqamah%: ${(_stats.istiqamah(log, _today) * 100).round()}',
    );

    await _pump(tester, log);

    // ignore: avoid_print
    print(
      'welcome-back shown: '
      '${find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة').evaluate().length}',
    );
    // ignore: avoid_print
    print('paused shown: ${find.text('يوم عذر').evaluate().length}');
    // ignore: avoid_print
    print(
      'percent shown: ${find.textContaining('المداومة').evaluate().length}',
    );
  });

  testWidgets('same, but today still excused (pause not yet lifted)', (
    tester,
  ) async {
    var log = SalahLogModel.defaultSettings();
    for (final ago in [8, 9, 10]) {
      final key = SalahLogModel.dateKey(_today.subtract(Duration(days: ago)));
      for (final slot in PrayerSlot.values) {
        log = log.setFard(key, slot, PrayerStatus.onTime);
      }
    }
    log = log.setExcusedRange(
      _today.subtract(const Duration(days: 7)),
      _today,
      true,
    );
    await _pump(tester, log);
    // ignore: avoid_print
    print('paused shown: ${find.text('يوم عذر').evaluate().length}');
  });

  testWidgets('the day AFTER the pause ends, nothing logged yet', (
    tester,
  ) async {
    // Pause ran today-8 .. today-1 inclusive; she never tapped resume, the
    // anchor was cleared yesterday. Today is a fresh, unexcused day.
    var log = SalahLogModel.defaultSettings();
    for (final ago in [9, 10, 11]) {
      final key = SalahLogModel.dateKey(_today.subtract(Duration(days: ago)));
      for (final slot in PrayerSlot.values) {
        log = log.setFard(key, slot, PrayerStatus.onTime);
      }
    }
    log = log.setExcusedRange(
      _today.subtract(const Duration(days: 8)),
      _today.subtract(const Duration(days: 1)),
      true,
    );
    await _pump(tester, log);
    // ignore: avoid_print
    print(
      'welcome-back shown: '
      '${find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة').evaluate().length}',
    );
  });
}
