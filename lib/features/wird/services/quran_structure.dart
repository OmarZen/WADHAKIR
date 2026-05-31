import 'package:wadhakir/data/models/wird/wird_enums.dart';

/// Total pages in the standard Madani Mushaf.
const int kTotalPages = 604;

/// Start page (1-based) of each of the 30 ajzaa' in the standard Madani
/// Mushaf, followed by a sentinel (`kTotalPages + 1`) so segment lengths can
/// be computed as `kJuzStartPages[i + 1] - kJuzStartPages[i]`.
///
/// These are fixed, well-known constants — we hardcode them rather than query
/// the quran_library controller for start pages (those helpers are not part of
/// the package's public API).
const List<int> kJuzStartPages = <int>[
  1, // Juz 1
  22, // Juz 2
  42, // Juz 3
  62, // Juz 4
  82, // Juz 5
  102, // Juz 6
  121, // Juz 7
  142, // Juz 8
  162, // Juz 9
  182, // Juz 10
  201, // Juz 11
  222, // Juz 12
  242, // Juz 13
  262, // Juz 14
  282, // Juz 15
  302, // Juz 16
  322, // Juz 17
  342, // Juz 18
  362, // Juz 19
  382, // Juz 20
  402, // Juz 21
  422, // Juz 22
  442, // Juz 23
  462, // Juz 24
  482, // Juz 25
  502, // Juz 26
  522, // Juz 27
  542, // Juz 28
  562, // Juz 29
  582, // Juz 30
  605, // sentinel (end of page 604)
];

/// Returns the ordered list of start pages (1-based) for every segment of the
/// given [unit] across the whole Mushaf.
///
/// - [WirdUnit.juz]  → the 30 juz starts.
/// - [WirdUnit.hizb] → each juz split into 2 halves (نصف جزء) ⇒ 60 starts.
/// - [WirdUnit.rub]  → each juz split into 4 quarters (ربع جزء) ⇒ 120 starts.
///
/// Within a juz the sub-boundaries are interpolated evenly across the juz's
/// page span. This follows the app's own definitions (ربع = quarter-juz,
/// حزب = half-juz) and is page-accurate at juz boundaries.
List<int> quranUnitStartPages(WirdUnit unit) {
  if (unit == WirdUnit.pages) {
    // Pages don't use a boundary table; callers handle pages directly.
    return List<int>.generate(kTotalPages, (i) => i + 1);
  }

  final int divisions = switch (unit) {
    WirdUnit.juz => 1,
    WirdUnit.hizb => 2,
    WirdUnit.rub => 4,
    WirdUnit.pages => 1,
  };

  final starts = <int>[];
  for (var j = 0; j < 30; j++) {
    final juzStart = kJuzStartPages[j];
    final juzEnd = kJuzStartPages[j + 1]; // exclusive
    final span = juzEnd - juzStart;
    for (var d = 0; d < divisions; d++) {
      final page = juzStart + ((span * d) ~/ divisions);
      starts.add(page);
    }
  }
  return starts;
}
