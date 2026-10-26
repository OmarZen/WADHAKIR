import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/geo/heading_math.dart';
import 'package:wadhakir/features/campus/services/qibla_platform_bridge.dart';

/// The Dart half of the contract with `QiblaBridge.kt`: channel names,
/// argument keys and the accuracy scale. A rename on either side breaks the
/// declination silently (it falls back to 0), so the names are pinned here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel(MethodChannelQiblaBridge.methodChannelName);
  const accuracy = EventChannel(MethodChannelQiblaBridge.accuracyChannelName);
  const bridge = MethodChannelQiblaBridge();

  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockStreamHandler(accuracy, null);
  });

  test('channel names match QiblaBridge.kt', () {
    expect(
      MethodChannelQiblaBridge.methodChannelName,
      'com.bloom.wadhakir/qibla',
    );
    expect(
      MethodChannelQiblaBridge.accuracyChannelName,
      'com.bloom.wadhakir/qibla_mag_accuracy',
    );
  });

  test('declination sends latitude, longitude and altitude', () async {
    MethodCall? seen;
    messenger.setMockMethodCallHandler(methods, (call) async {
      seen = call;
      return 4.6;
    });
    final value = await bridge.declination(
      latitude: 30.0444,
      longitude: 31.2357,
      altitudeM: 23,
    );
    expect(value, 4.6);
    expect(seen!.method, 'declination');
    expect(seen!.arguments, {
      'latitude': 30.0444,
      'longitude': 31.2357,
      'altitude': 23.0,
    });
  });

  test('declination falls back to 0 on any native failure', () async {
    messenger.setMockMethodCallHandler(methods, (call) async {
      throw PlatformException(code: 'declination_failed');
    });
    expect(await bridge.declination(latitude: 0, longitude: 0), 0);
  });

  test('a missing native side means no declination, not a crash', () async {
    // No handler at all: MissingPluginException.
    expect(await bridge.declination(latitude: 0, longitude: 0), 0);
  });

  test('hasMagnetometer answers, and assumes yes when it cannot ask', () async {
    messenger.setMockMethodCallHandler(methods, (call) async {
      expect(call.method, 'hasMagnetometer');
      return false;
    });
    expect(await bridge.hasMagnetometer(), isFalse);

    messenger.setMockMethodCallHandler(methods, null);
    expect(await bridge.hasMagnetometer(), isTrue);
  });

  test('the accuracy stream maps 15 / 30 / 45 / -1', () async {
    messenger.setMockStreamHandler(
      accuracy,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          events
            ..success(45)
            ..success(30)
            ..success(15)
            ..success(-1)
            ..endOfStream();
        },
      ),
    );
    expect(await bridge.magnetometerAccuracy().toList(), [
      CompassAccuracyLevel.low,
      CompassAccuracyLevel.medium,
      CompassAccuracyLevel.high,
      CompassAccuracyLevel.unknown,
    ]);
  });
}
