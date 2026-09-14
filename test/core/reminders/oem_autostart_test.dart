import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/core/reminders/oem_autostart.dart';

/// Item #16 spans three files that cannot import each other — Kotlin, the
/// Android manifest, and Dart — and every way they can drift apart fails
/// **silently and identically to "this device does not have that screen"**.
/// That is the one failure mode no device test would catch either, because the
/// correct behaviour on most hardware is also to show nothing.
///
/// So the agreement between them is asserted here, by reading the sources.
void main() {
  final kotlin = File(
    'android/app/src/main/kotlin/com/bloom/wadhakir/OemAutostart.kt',
  ).readAsStringSync();
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  /// Every `Target("vendor", cmp("package", "class"))` in the Kotlin.
  final targets = RegExp(
    r'Target\(\s*"([a-z]+)"\s*,\s*cmp\(\s*"([\w.]+)"\s*,\s*"([\w.]+)"\s*\)',
  ).allMatches(kotlin).toList();

  test('the Kotlin candidate list parses, and is the size it should be', () {
    // An EXACT count, not a floor.
    //
    // A floor catches total regex breakage and nothing else: with `>= 14`,
    // deleting five of the nineteen candidates — five vendors' worth of users
    // losing the only button that helps them — passes silently, and so does a
    // reformat that makes the pattern miss a few. Every legitimate change to
    // the list updates this number, which is the point: it forces one
    // deliberate look at what changed.
    expect(
      targets.length,
      19,
      reason:
          'candidate count changed — confirm it was on purpose, then '
          'update this number, the <queries> block, and both language files',
    );
  });

  test('every candidate package is declared in <queries>', () {
    // From Android 11 a package this app has no relationship with is invisible
    // to PackageManager unless it is named in the manifest. A target added to
    // the Kotlin without its <queries> entry resolves to null on EVERY device,
    // forever, with no error anywhere.
    final declared = RegExp(
      r'<package android:name="([\w.]+)"',
    ).allMatches(manifest).map((m) => m.group(1)!).toSet();

    for (final target in targets) {
      final package = target.group(2)!;
      expect(
        declared,
        contains(package),
        reason:
            '$package is probed by OemAutostart.kt but is not in <queries>, '
            'so it can never resolve on Android 11+',
      );
    }
  });

  test('every vendor key has an Arabic label', () {
    // A key with no label falls back to the generic string. That is a safe
    // failure, not a silent one — but it is still a button that says less than
    // it could, and the vendor's own menu name is what makes a user believe
    // they are in the right place.
    for (final target in targets) {
      final vendor = target.group(1)!;
      expect(
        OemAutostartLabels.known,
        contains(vendor),
        reason: 'OemAutostart.kt can return "$vendor" and Dart has no label',
      );
    }
  });

  test('every vendor key resolves in BOTH language files', () {
    // The label key is built at runtime from a vendor name that lives in
    // Kotlin, so nothing greppable connects `OemAutostart.kt` to `ar.json`.
    // `AppLocalizations.translate` returns the KEY on a miss, so a vendor added
    // natively without a translation would put a literal
    // `reminder_health.oem.<vendor>` on a button.
    for (final lang in ['ar', 'en']) {
      final json =
          jsonDecode(File('assets/lang/$lang.json').readAsStringSync()) as Map;
      final oem = (json['reminder_health'] as Map)['oem'] as Map;
      for (final target in targets) {
        final vendor = target.group(1)!;
        expect(
          oem.keys,
          contains(vendor),
          reason: 'assets/lang/$lang.json has no reminder_health.oem.$vendor',
        );
        expect((oem[vendor] as String).trim(), isNotEmpty);
      }
    }
  });

  test('no label is orphaned', () {
    final vendors = targets.map((m) => m.group(1)!).toSet();
    for (final key in OemAutostartLabels.known) {
      expect(
        vendors,
        contains(key),
        reason: '"$key" is labelled in Dart but nothing native returns it',
      );
    }
  });

  test('an unknown vendor key still produces a usable label', () {
    expect(OemAutostartLabels.fallbackFor('some-new-vendor'), isNotEmpty);
    expect(
      OemAutostartLabels.fallbackFor('some-new-vendor'),
      isNot(contains('reminder_health')),
      reason: 'a raw key must never reach the screen',
    );
  });

  test('the null bridge offers nothing, which is the iOS path', () {
    const bridge = NullOemAutostartBridge();
    expect(bridge.resolveKey(), completion(isNull));
    expect(bridge.open(), completion(isFalse));
  });
}
