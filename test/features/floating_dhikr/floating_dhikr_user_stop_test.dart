import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/features/floating_dhikr/data/floating_dhikr_settings.dart';
import 'package:wadhakir/features/floating_dhikr/service/floating_dhikr_service.dart';

/// «إيقاف» on the floating-dhikr notification must turn the feature off for
/// good. Native can only leave a marker; these pin how the Dart side takes it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.bloom.wadhakir/floating_dhikr');
  final calls = <String>[];
  late bool marker;
  late List<String> savedWhenAcked;

  Future<String?> saved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(FloatingDhikrSettings.prefsKey);
  }

  setUp(() {
    calls.clear();
    marker = false;
    savedWhenAcked = [];
    FloatingDhikrService.debugSupportedOverride = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'peekUserStop':
              return marker;
            case 'ackUserStop':
              savedWhenAcked.add(await saved() ?? '');
              marker = false;
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    FloatingDhikrService.debugSupportedOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void enabledOnDisk() {
    SharedPreferences.setMockInitialValues({
      FloatingDhikrSettings.prefsKey: const FloatingDhikrSettings(
        enabled: true,
      ).encode(),
    });
  }

  test(
    'a notification stop is saved as "off" before it is acknowledged',
    () async {
      enabledOnDisk();
      marker = true;

      final settings = await FloatingDhikrService.instance.getSettings();

      expect(settings.enabled, isFalse);
      expect(FloatingDhikrSettings.decode((await saved())!).enabled, isFalse);
      // Acknowledged exactly once, and only after "off" was on disk: a reader
      // that died between the two would otherwise lose the user's stop.
      expect(calls.where((c) => c == 'ackUserStop'), hasLength(1));
      expect(
        FloatingDhikrSettings.decode(savedWhenAcked.single).enabled,
        isFalse,
      );
    },
  );

  test(
    'without a notification stop the saved settings are untouched',
    () async {
      enabledOnDisk();

      final settings = await FloatingDhikrService.instance.getSettings();

      expect(settings.enabled, isTrue);
      expect(calls, isNot(contains('ackUserStop')));
    },
  );

  test('a stale marker on a disabled feature is just acknowledged', () async {
    SharedPreferences.setMockInitialValues({});
    marker = true;

    final settings = await FloatingDhikrService.instance.getSettings();

    expect(settings.enabled, isFalse);
    expect(calls, contains('ackUserStop'));
    expect(marker, isFalse);
  });

  test(
    'bootstrap does not restart a feature stopped from the notification',
    () async {
      enabledOnDisk();
      marker = true;

      await FloatingDhikrService.instance.bootstrap();

      expect(calls, isNot(contains('start')));
    },
  );
}
