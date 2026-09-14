import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/notifications/reminder_interruption.dart';

void main() {
  group('reminderChannelImportance', () {
    test('stays High on Android so the heads-up banner is unchanged', () {
      expect(
        reminderChannelImportance(isIOS: false),
        NotificationImportance.High,
      );
    });

    test('drops to Default on iOS, which the plugin maps to .active', () {
      // High and Max both resolve to .timeSensitive in NotificationBuilder's
      // setImportance. Default is the highest level that does NOT break
      // through a Focus mode.
      expect(
        reminderChannelImportance(isIOS: true),
        NotificationImportance.Default,
      );
    });

    test('is never High or Max on iOS', () {
      // Stated separately from the equality above: the thing that must never
      // regress is the *category*, not the specific constant.
      const timeSensitive = [
        NotificationImportance.High,
        NotificationImportance.Max,
      ];
      expect(
        timeSensitive.contains(reminderChannelImportance(isIOS: true)),
        isFalse,
      );
    });
  });

  group('reminderWakeUpScreen', () {
    test('stays true on Android, where it actually wakes the screen', () {
      expect(reminderWakeUpScreen(isIOS: false), isTrue);
    });

    test('is false on iOS, where its only effect is Time-Sensitive', () {
      // setWakeUpScreen runs AFTER setImportance and overwrites it, so leaving
      // this true would silently undo reminderChannelImportance and hand every
      // azkar, wird, fasting and inspiration reminder the same Focus-breaking
      // authority as the adhan.
      expect(reminderWakeUpScreen(isIOS: true), isFalse);
    });
  });

  test('the two helpers agree: iOS is narrowed, Android is untouched', () {
    // Android must be byte-for-byte what these services shipped before R3.
    expect(
      reminderChannelImportance(isIOS: false),
      NotificationImportance.High,
    );
    expect(reminderWakeUpScreen(isIOS: false), isTrue);

    // iOS must not reach .timeSensitive by either route.
    expect(
      reminderChannelImportance(isIOS: true),
      NotificationImportance.Default,
    );
    expect(reminderWakeUpScreen(isIOS: true), isFalse);
  });
}
