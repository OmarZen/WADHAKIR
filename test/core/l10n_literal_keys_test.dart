import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every translation key the app's code names literally exists in BOTH
/// language files.
///
/// `AppLocalizations.translate()` returns the key itself when a string is
/// missing, so a missing key fails nothing at runtime: the user just sees
/// "qibla.map.km" on screen, and the `?? 'fallback'` written next to it never
/// runs. Only a test like this catches it.
///
/// A "literal key" is any quoted string shaped like `group.key` whose first
/// part is a top-level group of the language files. That covers direct
/// `translate('…')` calls and the features' own helpers
/// (`QiblaStrings.tr(context, 'qibla.…', …)`, `TasbihStrings.tr(…)`), and
/// keys parked in variables first. Keys assembled at runtime (`'x.$y'`) are
/// not literals and are not checked; the features avoid them.

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

final RegExp _literal = RegExp(r'''['"]([a-z_]+(?:\.[a-z0-9_]+)+)['"]''');

const Set<String> _fileExtensions = {
  'json',
  'dart',
  'png',
  'webp',
  'svg',
  'mp3',
  'wav',
  'txt',
};

void main() {
  final arJson = _load('ar');
  final enJson = _load('en');
  final ar = _flatten(arJson);
  final en = _flatten(enJson);
  final groups = {...arJson.keys, ...enJson.keys};

  // All of lib/, not just the features that brought this test: a key missing
  // anywhere shows the user the raw key, and it was only a matter of time
  // before one slipped in somewhere unscanned.
  for (final dir in ['lib']) {
    test('$dir names only keys that both language files have', () {
      final missing = <String>[];
      final seen = <String>{};
      final files = Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in files) {
        final source = file.readAsStringSync();
        for (final match in _literal.allMatches(source)) {
          final key = match.group(1)!;
          if (!groups.contains(key.split('.').first)) continue;
          // A file name that happens to start with a group ('settings.json').
          if (_fileExtensions.contains(key.split('.').last)) continue;
          seen.add(key);
          if (!ar.containsKey(key)) missing.add('$key: not in ar.json');
          if (!en.containsKey(key)) missing.add('$key: not in en.json');
        }
      }
      expect(seen, isNotEmpty, reason: 'no keys found under $dir at all');
      expect(missing.toSet().toList()..sort(), isEmpty);
    });
  }
}
