import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/features/backup/services/backup_keys.dart';
import 'package:wadhakir/features/backup/services/backup_service.dart';
import 'package:wadhakir/features/backup/views/widgets/backup_summary_list.dart';

/// Renders the list with no `AppLocalizations` in the tree, so `context.l10n`
/// is null and every string falls back to its inline Arabic default. That is
/// exactly the path these assertions want: the fallbacks ship to users
/// whenever a key is missing, so they are worth testing.
Future<void> _pump(
  WidgetTester tester,
  BackupSummary summary, {
  bool emptyIsDevice = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: BackupSummaryList(summary: summary, emptyIsDevice: emptyIsDevice),
    ),
  ),
);

BackupSummary _summary({
  int? salahDays,
  bool wird = false,
  int counters = 0,
  Map<BackupSection, int> sections = const {},
}) => BackupSummary(
  salahDays: salahDays,
  hasActiveWirdPlan: wird,
  dhikrCounters: counters,
  keysBySection: sections,
);

void main() {
  testWidgets('names the records a person would recognise', (tester) async {
    await _pump(
      tester,
      _summary(
        salahDays: 412,
        wird: true,
        counters: 3,
        sections: const {
          BackupSection.worship: 6,
          BackupSection.settings: 9,
          BackupSection.location: 3,
        },
      ),
    );

    expect(find.text('412 يوم صلاة'), findsOneWidget);
    expect(find.text('خطة ورد'), findsOneWidget);
    expect(find.text('3 عدّاد ذِكر'), findsOneWidget);
    // 6 worship keys, 5 of them named above (salah + wird + 3 counters).
    expect(find.text('عنصر واحد'), findsOneWidget);
    expect(find.text('الإعدادات وكل التذكيرات'), findsOneWidget);
    expect(find.text('الموقع المحفوظ'), findsOneWidget);
    // Not carried, so not claimed.
    expect(find.text('طريقة حساب المواقيت، والمذهب، والتعديلات'), findsNothing);
  });

  testWidgets('a backup with data never reads as empty', (tester) async {
    // The regression this locks in: a salah log that exists but has no logged
    // days used to be subtracted out of the remainder, so the list said "there
    // is nothing to save yet" while the save button sat right below it.
    await _pump(
      tester,
      _summary(salahDays: 0, sections: const {BackupSection.worship: 1}),
    );

    expect(find.text('لا توجد بيانات لحفظها بعد.'), findsNothing);
    expect(find.text('عنصر واحد'), findsOneWidget);
  });

  testWidgets('an empty summary says so plainly', (tester) async {
    await _pump(tester, _summary());
    expect(find.text('لا توجد بيانات لحفظها بعد.'), findsOneWidget);
  });

  testWidgets('the restore confirmation phrases empty as the device', (
    tester,
  ) async {
    // On the "on this device now" column, the export wording ("nothing to
    // save yet") would be answering a question nobody asked.
    await _pump(tester, _summary(), emptyIsDevice: true);
    expect(find.text('لا توجد بيانات على هذا الجهاز.'), findsOneWidget);
    expect(find.text('لا توجد بيانات لحفظها بعد.'), findsNothing);
  });

  testWidgets('a count of one uses the singular phrasing', (tester) async {
    // With no interpolation and no plurals in AppLocalizations, composing
    // '$n $noun' produced "1 days of prayer" in English. The _one keys carry
    // the whole phrase so each language places the number itself.
    await _pump(
      tester,
      _summary(
        salahDays: 1,
        counters: 1,
        sections: const {BackupSection.worship: 3},
      ),
    );

    expect(find.text('يوم صلاة واحد'), findsOneWidget);
    expect(find.text('عدّاد ذِكر واحد'), findsOneWidget);
    expect(find.text('عنصر واحد'), findsOneWidget);
    // The bare "1 <noun>" forms must not appear at all.
    expect(find.text('1 يوم صلاة'), findsNothing);
    expect(find.text('1 عدّاد ذِكر'), findsNothing);
    expect(find.text('1 عنصر'), findsNothing);
  });

  testWidgets('a zero counter count is not mentioned', (tester) async {
    await _pump(
      tester,
      _summary(salahDays: 7, sections: const {BackupSection.worship: 1}),
    );
    expect(find.text('7 يوم صلاة'), findsOneWidget);
    expect(find.textContaining('عدّاد'), findsNothing);
    expect(find.textContaining('عنصر'), findsNothing);
  });
}
