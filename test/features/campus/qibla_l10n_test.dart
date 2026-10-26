import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The qibla screens' strings: both languages carry the same `qibla` keys
/// with the same placeholders, and every Arabic fallback written in Dart is
/// the `ar.json` text, so a screen that loses its localization still says the
/// same thing.
///
/// `campus` is kept flat (the AR safety test reads it as a string map) and
/// holds only what the AR screen still reads.

Map<String, String> _flatten(Map<String, dynamic> map, [String prefix = '']) {
  final out = <String, String>{};
  map.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      out.addAll(_flatten(value, path));
    } else {
      out[path] = '$value';
    }
  });
  return out;
}

Map<String, dynamic> _load(String lang) =>
    jsonDecode(File('assets/lang/$lang.json').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

Iterable<File> _campusSources() => Directory('lib/features/campus')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  final arJson = _load('ar');
  final enJson = _load('en');
  final ar = _flatten(arJson);
  final en = _flatten(enJson);

  group('qibla group', () {
    test('both languages have the same keys, all non-empty strings', () {
      final arQibla = ar.keys.where((k) => k.startsWith('qibla.')).toSet();
      final enQibla = en.keys.where((k) => k.startsWith('qibla.')).toSet();
      expect(arQibla, isNotEmpty);
      expect(arQibla.difference(enQibla), isEmpty, reason: 'missing in en');
      expect(enQibla.difference(arQibla), isEmpty, reason: 'missing in ar');
      for (final key in arQibla) {
        expect(ar[key]!.trim(), isNotEmpty, reason: 'ar $key');
        expect(en[key]!.trim(), isNotEmpty, reason: 'en $key');
      }
    });

    test('each string has the same placeholders in both languages', () {
      for (final key in ar.keys.where((k) => k.startsWith('qibla.'))) {
        expect(_placeholders(en[key]!), _placeholders(ar[key]!), reason: key);
      }
    });

    test('numbers stay Western in the Arabic copy', () {
      final easternDigits = RegExp('[\u0660-\u0669\u06F0-\u06F9]');
      for (final key in ar.keys.where((k) => k.startsWith('qibla.'))) {
        expect(easternDigits.hasMatch(ar[key]!), isFalse, reason: key);
      }
    });
  });

  test('every QiblaStrings.tr fallback is the ar.json text', () {
    final call = RegExp(
      r"""QiblaStrings\.tr\(\s*\w+,\s*'([^']+)',\s*'([^']*)'""",
    );
    var checked = 0;
    for (final file in _campusSources()) {
      final source = file.readAsStringSync();
      for (final match in call.allMatches(source)) {
        final key = match.group(1)!;
        final fallback = match.group(2)!;
        checked++;
        expect(ar.containsKey(key), isTrue, reason: '$key in ${file.path}');
        expect(en.containsKey(key), isTrue, reason: '$key in ${file.path}');
        expect(
          fallback,
          ar[key],
          reason: 'the fallback for $key in ${file.path} differs from ar.json',
        );
      }
    }
    // Guards the pattern itself: a reformat that broke it would otherwise
    // make this test pass by checking nothing.
    expect(checked, greaterThan(80));
  });

  test("every `translate('campus.…') ?? '…'` fallback is the ar.json text", () {
    final call = RegExp(
      r"""translate\('(campus\.[a-z_]+)'\)\s*\?\?\s*'([^']*)'""",
    );
    var checked = 0;
    for (final file in _campusSources()) {
      for (final match in call.allMatches(file.readAsStringSync())) {
        checked++;
        expect(match.group(2), ar[match.group(1)!], reason: match.group(1));
      }
    }
    expect(checked, greaterThan(5));
  });

  group('campus group', () {
    test('is flat: only strings', () {
      for (final json in [arJson, enJson]) {
        final campus = json['campus'] as Map<String, dynamic>;
        for (final entry in campus.entries) {
          expect(entry.value, isA<String>(), reason: 'campus.${entry.key}');
        }
      }
    });

    test('keeps exactly the keys the AR screen reads', () {
      final read = <String>{};
      for (final file in _campusSources()) {
        read.addAll(
          RegExp(
            r"'campus\.([a-z_]+)'",
          ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!),
        );
      }
      final arCampus = (arJson['campus'] as Map).keys.toSet();
      final enCampus = (enJson['campus'] as Map).keys.toSet();
      expect(arCampus, read, reason: 'ar.json campus has unused or missing');
      expect(enCampus, read, reason: 'en.json campus has unused or missing');
      // The mistranslated one is gone ("Close" in English, "near" in Arabic).
      expect(arCampus.contains('close'), isFalse);
    });
  });
}
