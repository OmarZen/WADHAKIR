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
  testWidgets('morning after a 7-day excused stretch', (tester) async {
    // Build the log EXACTLY as the reviewer's scenario says: real model calls,
    // no hand-built maps.
    var log = SalahLogModel.defaultSettings();
    for (final ago in [8, 9, 10]) {
      final key = SalahLogModel.dateKey(_today.subtract(Duration(days: ago)));
      for (final slot in PrayerSlot.values) {
        log = log.setFard(key, slot, PrayerStatus.onTime);
      }
    }
    // The user marks today-7 .. today-1 excused (a 7-day period).
    log = log.setExcusedRange(
      _today.subtract(const Duration(days: 7)),
      _today.subtract(const Duration(days: 1)),
      true,
    );

    // Sanity: the reviewer's arithmetic.
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
      'istiqamah pct: ${(_stats.istiqamah(log, _today, window: 30) * 100).round()}',
    );

    await _pump(tester, log);

    // The reviewer says this renders the "welcome back" lapse copy.
    // ignore: avoid_print
    print(
      'returning copy present: '
      '${find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة').evaluate().length}',
    );
    // ignore: avoid_print
    print(
      'steady copy present: ${find.textContaining('المداومة').evaluate().length}',
    );
    // ignore: avoid_print
    print('paused copy present: ${find.text('يوم عذر').evaluate().length}');

    // The assertion a reviewer-written test would make:
    expect(find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة'), findsNothing);
  });
}
