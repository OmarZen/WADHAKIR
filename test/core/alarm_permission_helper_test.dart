import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/utils/alarm_permission_helper.dart';
import 'package:wadhakir/features/backup/services/backup_keys.dart';

final _now = DateTime(2026, 3, 14, 12);

int _millisDaysAgo(int days) =>
    _now.subtract(Duration(days: days)).millisecondsSinceEpoch;

void main() {
  group('the battery-optimization prompt is not silenced by one "later"', () {
    test('a device that has never been asked is due', () {
      expect(
        AlarmPermissionHelper.shouldPromptBatteryOptimization(
          alreadyGranted: false,
          deferredAtMillis: null,
          now: _now,
        ),
        isTrue,
      );
    });

    test('declining today does not silence it forever', () {
      // The bug: the old code wrote "prompted = true" BEFORE showing the
      // dialog, so one tap on "لاحقاً" meant the exemption was never asked for
      // again — and without it Doze can defer or drop every adhan on an
      // aggressive OEM ROM. Declining now must postpone, not cancel.
      expect(
        AlarmPermissionHelper.shouldPromptBatteryOptimization(
          alreadyGranted: false,
          deferredAtMillis: _millisDaysAgo(0),
          now: _now,
        ),
        isFalse,
        reason: 'not immediately — that would be nagging',
      );

      expect(
        AlarmPermissionHelper.shouldPromptBatteryOptimization(
          alreadyGranted: false,
          deferredAtMillis: _millisDaysAgo(13),
          now: _now,
        ),
        isFalse,
      );

      expect(
        AlarmPermissionHelper.shouldPromptBatteryOptimization(
          alreadyGranted: false,
          deferredAtMillis: _millisDaysAgo(14),
          now: _now,
        ),
        isTrue,
        reason: 'after the cooling-off period the user gets another chance',
      );
    });

    test('once granted it is never asked again', () {
      expect(
        AlarmPermissionHelper.shouldPromptBatteryOptimization(
          alreadyGranted: true,
          deferredAtMillis: null,
          now: _now,
        ),
        isFalse,
      );
      expect(
        AlarmPermissionHelper.shouldPromptBatteryOptimization(
          alreadyGranted: true,
          deferredAtMillis: _millisDaysAgo(400),
          now: _now,
        ),
        isFalse,
      );
    });

    test('a deferral stamped in the future is not trusted', () {
      // A device whose clock jumped forward and back would otherwise carry a
      // timestamp that never elapses, silencing the prompt indefinitely.
      expect(
        AlarmPermissionHelper.shouldPromptBatteryOptimization(
          alreadyGranted: false,
          deferredAtMillis: _now
              .add(const Duration(days: 3650))
              .millisecondsSinceEpoch,
          now: _now,
        ),
        isTrue,
      );
    });
  });

  group('neither half of the gate may travel in a backup', () {
    test('both keys are denied', () {
      // Restoring either one onto a new phone imports a decision that phone
      // never made: `battery_opt_prompted` suppresses the prompt outright,
      // and `battery_opt_deferred_at` imports a cooling-off period it has not
      // earned. Both keep every scheduled reminder exposed to Doze.
      expect(BackupKeys.specFor('battery_opt_prompted'), isNull);
      expect(BackupKeys.specFor('battery_opt_deferred_at'), isNull);
      expect(
        BackupKeys.denyKeys,
        containsAll(<String>[
          'battery_opt_prompted',
          'battery_opt_deferred_at',
        ]),
      );
    });

    test('the deny list names the keys the helper actually writes', () {
      // Guards the one thing a string-based deny list cannot check itself: a
      // rename in the helper that leaves the deny list pointing at nothing.
      expect(
        BackupKeys.denyKeys,
        contains(AlarmPermissionHelper.batteryPromptedKey),
      );
      expect(
        BackupKeys.denyKeys,
        contains(AlarmPermissionHelper.batteryDeferredAtKey),
      );
    });
  });
}
