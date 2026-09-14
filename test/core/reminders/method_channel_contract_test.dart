import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/reminders/oem_autostart.dart';
import 'package:wadhakir/core/reminders/reminder_ledger.dart';
import 'package:wadhakir/core/reminders/reminder_ledger_entry.dart';
import 'package:wadhakir/core/reminders/reminder_platform_probe.dart';

/// Every one of these Dart calls is wrapped in a try/catch that degrades to
/// "this platform has nothing to report".
///
/// That is the right behaviour — a diagnostics read must never take down a
/// reminder — and it is also why a typo is invisible. `'ledgerAppend'` written
/// as `'ledgerApend'` raises `MissingPluginException`, gets swallowed, and the
/// health screen shows a device that has apparently never fired an alarm. No
/// test fails, no log a user sees, and the feature is simply gone.
///
/// So the names are pinned from both ends: what Dart sends, and what
/// `PrayerAlarmBridge.kt` has a `when` arm for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.bloom.wadhakir/prayer_alarms');

  final sent = <MethodCall>[];
  Object? reply;

  setUp(() {
    sent.clear();
    reply = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          sent.add(call);
          return reply;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // The Dart halves are Android-gated, so these assertions only mean anything
  // on a host that reports itself as Android. `flutter test` runs on the host
  // OS, so skip elsewhere rather than assert something vacuous.
  final onAndroid = Platform.isAndroid;

  group('what Dart sends', () {
    test('the ledger store sends the three ledger methods', () async {
      const store = MethodChannelReminderLedgerStore();
      reply = '';
      await store.append(
        ReminderLedgerEntry(type: ReminderEventType.armed, atEpochMs: 1),
      );
      await store.read();
      await store.clear();

      expect(sent.map((c) => c.method), [
        'ledgerAppend',
        'ledgerRead',
        'ledgerClear',
      ]);
    }, skip: onAndroid ? false : 'method-channel halves are Android-gated');

    test(
      'an appended row crosses as the wire-format map, not an object',
      () async {
        const store = MethodChannelReminderLedgerStore();
        await store.append(
          ReminderLedgerEntry(
            type: ReminderEventType.fired,
            atEpochMs: 10,
            id: 142,
            dueEpochMs: 5,
            outcome: ReminderFireOutcome.sounded,
          ),
        );

        final args = sent.single.arguments as Map;
        // The exact keys `ReminderLedgerStore.appendRaw` filters on. A rename on
        // either side silently drops the field.
        expect(args['t'], 'fired');
        expect(args['at'], 10);
        expect(args['id'], 142);
        expect(args['due'], 5);
        expect(args['o'], 'sounded');
      },
      skip: onAndroid ? false : 'method-channel halves are Android-gated',
    );

    test('the OEM bridge and the channel probe send their methods', () async {
      const oem = MethodChannelOemAutostart();
      await oem.resolveKey();
      await oem.open();
      const probe = MethodChannelReminderPlatformProbe();
      await probe.blockedChannel(const ['a', 'b']);

      expect(sent.map((c) => c.method), [
        'oemAutostartKey',
        'openOemAutostart',
        'blockedChannel',
      ]);
      expect(sent.last.arguments, ['a', 'b']);
    }, skip: onAndroid ? false : 'method-channel halves are Android-gated');

    test(
      'a missing native side degrades to nothing, never to a throw',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);

        const store = MethodChannelReminderLedgerStore();
        await expectLater(store.read(), completion(isEmpty));
        await expectLater(
          store.append(
            ReminderLedgerEntry(type: ReminderEventType.armed, atEpochMs: 1),
          ),
          completes,
        );
        await expectLater(
          const MethodChannelOemAutostart().resolveKey(),
          completion(isNull),
        );
        await expectLater(
          const MethodChannelReminderPlatformProbe().blockedChannel(const [
            'a',
          ]),
          completion(isNull),
        );
      },
    );
  });

  group('what Kotlin answers', () {
    final bridge = File(
      'android/app/src/main/kotlin/com/bloom/wadhakir/PrayerAlarmBridge.kt',
    ).readAsStringSync();

    // Read off the Kotlin rather than hand-listed, so this cannot drift into
    // agreeing with itself.
    final handled = RegExp(
      r'"([a-zA-Z]+)"\s*->',
    ).allMatches(bridge).map((m) => m.group(1)!).toSet();

    test('the bridge parses, and handles the methods it always did', () {
      // A canary: if this fails the regex has gone stale and every assertion
      // below is passing vacuously.
      expect(handled, containsAll(['clear', 'arm', 'commit', 'purge']));
    });

    test('commit observes lapses BEFORE it replaces the ledger', () {
      // The ordering IS the feature, and getting it wrong is silent.
      //
      // `replaceAll` overwrites the ledger with Dart's new plan, which contains
      // only future alarms. Observing after it therefore has nothing left to
      // match `armedIds` against — and a commit is exactly what happens when
      // someone opens the app after a force-stop has silenced it for days. With
      // these two lines swapped, every multi-day outage records nothing at all,
      // at the one moment a user has come looking for an explanation.
      //
      // Nothing else can catch this: both orderings compile, both pass every
      // other test, and the difference is only visible on a device that has
      // already been broken for days.
      final commitBlock = bridge.substring(
        bridge.indexOf('"commit" ->'),
        bridge.indexOf('"showPersistent"'),
      );
      final observeAt = commitBlock.indexOf('observeLapses(');
      final replaceAt = commitBlock.indexOf('replaceAll(');

      expect(
        observeAt,
        isNonNegative,
        reason: 'commit no longer observes lapses',
      );
      expect(replaceAt, isNonNegative, reason: 'commit block not found');
      expect(
        observeAt,
        lessThan(replaceAt),
        reason:
            'observeLapses must run against the OLD ledger, before '
            'replaceAll destroys the rows it needs',
      );
    });

    test('every method Dart can send has a Kotlin arm', () {
      // READ OFF THE DART, not hand-listed. A hand-written list cannot catch a
      // rename on the Dart side — the renamed method simply stops being
      // mentioned anywhere and the old name sits in the list, still matching
      // Kotlin, still green. Both ends are now derived from source, so a
      // rename on either one fails this.
      final sent = <String>{};
      for (final path in [
        'lib/features/pray_times/services/native_prayer_alarm_gateway.dart',
        'lib/core/reminders/reminder_ledger.dart',
        'lib/core/reminders/reminder_platform_probe.dart',
        'lib/core/reminders/oem_autostart.dart',
        'lib/core/utils/alarm_permission_helper.dart',
      ]) {
        final file = File(path);
        if (!file.existsSync()) continue;
        sent.addAll(
          RegExp(
            r"invokeMethod(?:<[^>]*>)?\(\s*'([a-zA-Z]+)'",
          ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!),
        );
      }

      // Canary: if the regex goes stale this set empties and every assertion
      // below passes vacuously.
      expect(
        sent,
        containsAll(['ledgerAppend', 'ledgerRead', 'blockedChannel']),
        reason: 'the Dart-side scan found nothing — the regex has gone stale',
      );

      for (final method in sent) {
        expect(
          handled,
          contains(method),
          reason:
              'Dart sends "$method" and PrayerAlarmBridge.kt has no arm '
              'for it — the call would raise MissingPluginException, be '
              'swallowed, and look exactly like a device with nothing to say',
        );
      }
    });

    test('the exact-alarm probe is answered natively', () {
      // The settings UI, the reminder health screen and the scheduler must
      // share ONE answer to "can this app schedule an exact alarm". Dart
      // cannot work it out: SCHEDULE_EXACT_ALARM is capped at API 32 in the
      // manifest and USE_EXACT_ALARM takes over from 33, so a permission-
      // library check reports "denied" on every modern device — the opposite
      // of the truth, and it sent users to a settings screen that cannot
      // exist for an app holding USE_EXACT_ALARM.
      expect(
        handled,
        contains('canScheduleExactAlarms'),
        reason: 'without this arm the helper falls back to the wrong answer',
      );

      final scheduler = File(
        'android/app/src/main/kotlin/com/bloom/wadhakir/PrayerAlarmScheduler.kt',
      ).readAsStringSync();

      // The bridge must delegate to the scheduler's own gate rather than
      // re-deriving one, or the two can disagree.
      expect(
        bridge,
        contains('PrayerAlarmScheduler.canScheduleExact'),
        reason: 'the bridge must answer with the gate the scheduler uses',
      );
      expect(scheduler, contains('fun canScheduleExact(context: Context)'));
    });
  });
}
