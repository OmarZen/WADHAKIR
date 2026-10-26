import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/features/tasbih/views/tasbih_strings.dart';

/// `AppLocalizations.translate` hands back the key itself for a missing
/// entry, so a missing translation shows the user `tasbih.mode_beads` rather
/// than failing anything. These tests are the only thing that notices.

Map<String, String> _group(String lang) {
  final json =
      jsonDecode(File('assets/lang/$lang.json').readAsStringSync()) as Map;
  // Flat strings only: a nested map here would flatten to dotted keys the
  // screen never asks for.
  return (json['tasbih'] as Map).cast<String, String>();
}

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m.group(1)!).toSet();

void main() {
  final ar = _group('ar');
  final en = _group('en');

  test('ar and en hold the same tasbih keys', () {
    expect(en.keys.toSet(), ar.keys.toSet());
  });

  test('every Dart fallback is the ar.json value', () {
    for (final entry in TasbihStrings.fallbacks.entries) {
      final key = entry.key.substring('tasbih.'.length);
      expect(ar[key], entry.value, reason: entry.key);
      expect(en[key], isNotNull, reason: entry.key);
    }
  });

  test('every tasbih key the code names exists in both languages', () {
    final literal = RegExp(r"""['"]tasbih\.([a-z0-9_]+)['"]""");
    final used = <String>{};
    for (final file in Directory(
      'lib/features/tasbih',
    ).listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final m in literal.allMatches(file.readAsStringSync())) {
        used.add(m.group(1)!);
      }
    }
    expect(used, isNotEmpty);
    for (final key in used) {
      expect(ar, contains(key), reason: 'ar.json lacks tasbih.$key');
      expect(en, contains(key), reason: 'en.json lacks tasbih.$key');
      expect(
        TasbihStrings.fallbacks,
        contains('tasbih.$key'),
        reason: 'no Arabic fallback for tasbih.$key',
      );
    }
  });

  test('the tasbih group holds exactly the keys the code reads', () {
    // Nothing kept for a screen that is gone: a key no code reads is a
    // string translators keep up for nobody. The fallbacks file is left out
    // of "reads", or every key it lists would count as used.
    final literal = RegExp(r"""['"]tasbih\.([a-z0-9_]+)['"]""");
    final read = <String>{};
    for (final file in Directory(
      'lib/features/tasbih',
    ).listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('tasbih_strings.dart')) continue;
      for (final m in literal.allMatches(file.readAsStringSync())) {
        read.add(m.group(1)!);
      }
    }
    expect(read, isNotEmpty);
    expect(ar.keys.toSet(), read, reason: 'ar.json tasbih: unused or missing');
    expect(en.keys.toSet(), read, reason: 'en.json tasbih: unused or missing');
    expect(
      {
        for (final key in TasbihStrings.fallbacks.keys)
          key.substring('tasbih.'.length),
      },
      read,
      reason: 'TasbihStrings.fallbacks: unused or missing',
    );
  });

  test('translations keep their placeholders', () {
    for (final key in ar.keys) {
      expect(
        _placeholders(en[key]!),
        _placeholders(ar[key]!),
        reason: 'tasbih.$key',
      );
    }
  });
}
