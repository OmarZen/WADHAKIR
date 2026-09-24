import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/localization/app_localizations_delegate.dart';
import 'package:wadhakir/core/localization/language_manager.dart';
import 'package:wadhakir/features/campus/services/qibla_ar_camera_service.dart';
import 'package:wadhakir/features/campus/views/screens/qibla_ar_screen.dart';

/// The Qibla camera mode's safety notice.
///
/// Google Play rejected version code 23 under the Families policy's
/// Augmented Reality restriction: an AR section in an app whose audience
/// includes children must open on a warning about parental supervision and
/// about being aware of your surroundings. These tests hold the screen to
/// that — the notice is the first thing shown, it says both things in both
/// languages, nothing covers it, and the camera (including its permission
/// prompt) is not touched until the user has tapped through it.

class _FakeCamera {
  _FakeCamera([this.status = QiblaArAvailability.permissionDenied]);

  /// What every attempt reports. Never `ready`: a real controller needs the
  /// platform camera, which a widget test does not have.
  final QiblaArAvailability status;
  int calls = 0;

  Future<QiblaArCameraResult> prepare() async {
    calls++;
    return QiblaArCameraResult(status);
  }
}

Map<String, String> _campusStrings(String lang) {
  final json =
      jsonDecode(File('assets/lang/$lang.json').readAsStringSync()) as Map;
  return (json['campus'] as Map).cast<String, String>();
}

/// Pushes the AR screen from a stub page, as the Qibla screen does. With a
/// [locale], the app's real localization loads, so the strings on screen are
/// the ones in `assets/lang/` rather than the Dart fallbacks.
Future<void> _pumpArScreen(
  WidgetTester tester,
  _FakeCamera camera, {
  Locale? locale,
}) async {
  // rootBundle caches the load's Future, and a cached one belongs to the
  // (finished) fake clock of whichever test loaded it first — awaiting it
  // from a later test never completes. Load fresh each time.
  if (locale != null) rootBundle.clear();
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: LanguageManager.supportedLocales,
      localizationsDelegates: locale == null
          ? null
          : const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QiblaArScreen(prepareCamera: camera.prepare),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  if (locale != null) {
    // The app's localization reads its language file by real I/O (and, the
    // file being large, decodes it on another isolate), which the test's fake
    // clock never lets finish. Give it real time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
  }
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('in the app\'s own strings', () {
    for (final lang in ['ar', 'en']) {
      testWidgets('[$lang] shows the whole warning, in the right direction', (
        tester,
      ) async {
        final strings = _campusStrings(lang);
        await _pumpArScreen(tester, _FakeCamera(), locale: Locale(lang));

        for (final key in [
          'ar_safety_title',
          'ar_safety_supervision_title',
          'ar_safety_supervision',
          'ar_safety_surroundings_title',
          'ar_safety_surroundings',
          'ar_safety_continue',
          'back_to_compass',
        ]) {
          expect(
            find.text(strings[key]!),
            findsOneWidget,
            reason: 'campus.$key is not on the notice',
          );
        }
        expect(
          Directionality.of(
            tester.element(find.text(strings['ar_safety_supervision']!)),
          ),
          lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
      });
    }
  });

  testWidgets('the top bar stays at the top, clear of the notice', (
    tester,
  ) async {
    await _pumpArScreen(tester, _FakeCamera());

    final back = tester.getRect(find.byIcon(Icons.arrow_back));
    final shield = tester.getRect(find.byIcon(Icons.health_and_safety_rounded));
    expect(
      back.bottom,
      lessThanOrEqualTo(shield.top),
      reason: 'the top bar is drawn over the notice',
    );
  });

  testWidgets('fits a small phone at the largest text size', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpArScreen(tester, _FakeCamera(), locale: const Locale('ar'));

    // An overflow would have failed the pump; the notice scrolls instead.
    final continueLabel = _campusStrings('ar')['ar_safety_continue']!;
    await tester.scrollUntilVisible(find.text(continueLabel), 100);
    expect(find.text(continueLabel).hitTestable(), findsOneWidget);
  });

  testWidgets('does not touch the camera before the notice is accepted', (
    tester,
  ) async {
    final camera = _FakeCamera();
    await _pumpArScreen(tester, camera);

    expect(find.text('إشراف الوالدين'), findsOneWidget);
    expect(camera.calls, 0, reason: 'no camera permission prompt yet');

    // Not even when the app comes back to the foreground.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.calls, 0);
  });

  testWidgets('accepting the notice is what starts the camera', (tester) async {
    final camera = _FakeCamera();
    await _pumpArScreen(tester, camera);

    await tester.tap(find.text('فهمت، افتح الكاميرا'));
    await tester.pumpAndSettle();

    expect(camera.calls, 1);
    expect(find.text('إشراف الوالدين'), findsNothing);
    // The fake denies the permission, so the existing fallback takes over.
    expect(find.text('يحتاج وضع الكاميرا إلى إذن الكاميرا'), findsOneWidget);
  });

  testWidgets('backing out of the notice never touches the camera', (
    tester,
  ) async {
    final camera = _FakeCamera();
    await _pumpArScreen(tester, camera);

    await tester.tap(find.text('العودة للبوصلة'));
    await tester.pumpAndSettle();

    expect(find.byType(QiblaArScreen), findsNothing);
    expect(camera.calls, 0);
  });

  group('coming back to the app', () {
    testWidgets('after a plain denial, does not ask again on its own', (
      tester,
    ) async {
      // The permission prompt itself makes the app inactive and then resumed;
      // retrying on resume here would put the prompt straight back up.
      final camera = _FakeCamera(QiblaArAvailability.permissionDenied);
      await _pumpArScreen(tester, camera);
      await tester.tap(find.text('فهمت، افتح الكاميرا'));
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(camera.calls, 1);
    });

    testWidgets('after being sent to settings, looks at the permission again', (
      tester,
    ) async {
      final camera = _FakeCamera(
        QiblaArAvailability.permissionPermanentlyDenied,
      );
      await _pumpArScreen(tester, camera);
      await tester.tap(find.text('فهمت، افتح الكاميرا'));
      await tester.pumpAndSettle();
      expect(camera.calls, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(camera.calls, 2);
    });
  });

  test('both languages carry the notice', () {
    const keys = [
      'ar_safety_title',
      'ar_safety_supervision_title',
      'ar_safety_supervision',
      'ar_safety_surroundings_title',
      'ar_safety_surroundings',
      'ar_safety_continue',
      'back_to_compass',
    ];
    for (final lang in ['ar', 'en']) {
      final campus = _campusStrings(lang);
      for (final key in keys) {
        expect(
          campus.keys,
          contains(key),
          reason: 'assets/lang/$lang.json has no campus.$key',
        );
        expect(campus[key]!.trim(), isNotEmpty);
      }
    }
  });

  test('the Dart fallbacks say what the Arabic file says', () {
    // Only seen when localization has not loaded, but then they must still
    // be the same warning.
    final source = File(
      'lib/features/campus/views/screens/qibla_ar_screen.dart',
    ).readAsStringSync();
    final ar = _campusStrings('ar');
    for (final key in [
      'ar_safety_title',
      'ar_safety_supervision_title',
      'ar_safety_supervision',
      'ar_safety_surroundings_title',
      'ar_safety_surroundings',
      'ar_safety_continue',
      'back_to_compass',
    ]) {
      expect(
        source,
        contains("'${ar[key]}'"),
        reason: 'the fallback for campus.$key differs from ar.json',
      );
    }
  });
}
