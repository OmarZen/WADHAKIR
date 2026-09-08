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

DateTime _ago(int d) => _today.subtract(Duration(days: d));

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
  testWidgets('probe: diligent user, ended 7-day pause, nothing logged today', (
    tester,
  ) async {
    // 30 straight days of complete prayer ending at today-8, then a 7-day
    // pause (today-7 .. today-1) applied the way the cubit applies it, then
    // the pause is over (excusedSince cleared) and today is untouched.
    var log = SalahLogModel.defaultSettings();
    for (var i = 8; i <= 37; i++) {
      final key = SalahLogModel.dateKey(_ago(i));
      for (final slot in PrayerSlot.values) {
        log = log.setFard(key, slot, PrayerStatus.onTime);
      }
    }
    log = log.setExcusedRange(_ago(7), _ago(1), true);

    // ignore: avoid_print
    print('daysSinceLastLog = ${_stats.daysSinceLastLog(log, _today)}');
    // ignore: avoid_print
    print(
      'istiqamah        = ${(_stats.istiqamah(log, _today) * 100).round()}%',
    );
    // ignore: avoid_print
    print('isExcusedToday   = ${log.isExcusedDay(_today)}');

    await _pump(tester, log);

    final welcome = find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة');
    // ignore: avoid_print
    print('welcome-back shown? ${welcome.evaluate().isNotEmpty}');
    final steady = find.textContaining('المداومة');
    // ignore: avoid_print
    print('steady shown? ${steady.evaluate().isNotEmpty}');
  });

  testWidgets('probe: short 2-day pause, nothing logged today', (tester) async {
    var log = SalahLogModel.defaultSettings();
    for (var i = 3; i <= 32; i++) {
      final key = SalahLogModel.dateKey(_ago(i));
      for (final slot in PrayerSlot.values) {
        log = log.setFard(key, slot, PrayerStatus.onTime);
      }
    }
    log = log.setExcusedRange(_ago(2), _ago(1), true);

    // ignore: avoid_print
    print('2-day: daysSinceLastLog = ${_stats.daysSinceLastLog(log, _today)}');
    await _pump(tester, log);
    // ignore: avoid_print
    print(
      '2-day welcome-back shown? '
      '${find.text('ما فات يُدرَك — ابدأ الآن ولو بصلاة').evaluate().isNotEmpty}',
    );
  });
}
