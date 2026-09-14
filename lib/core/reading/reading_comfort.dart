import 'package:flutter/widgets.dart';

/// How much air sits between lines of a reading surface.
///
/// Arabic script needs more of it than Latin does — the diacritics live above
/// and below the baseline, and at a tight leading they collide with the line
/// above. Every reading surface in this app hardcoded `height: 2.0`, which is a
/// reasonable guess and nobody's actual preference.
enum ReadingSpacing {
  /// More text on screen, for someone reading a long passage on a small phone.
  compact('compact', 1.7),

  /// What every surface shipped hardcoded before this existed. The default, so
  /// an install that never touches this setting looks exactly as it did.
  comfortable('comfortable', 2.0),

  /// For large type, and for anyone who finds dense Arabic hard to track.
  airy('airy', 2.4);

  final String id;
  final double height;
  const ReadingSpacing(this.id, this.height);

  static ReadingSpacing fromId(String? id) {
    for (final value in ReadingSpacing.values) {
      if (value.id == id) return value;
    }
    return ReadingSpacing.comfortable;
  }
}

/// Which of the bundled Arabic faces a reading surface uses.
///
/// The app has shipped four families since long before this setting — Almarai,
/// ScheherazadeNew, ArefRuqaa, Jomhuria — and offered the user none of them.
/// Three are offered here; Jomhuria is a display face, unreadable at body size,
/// and is deliberately not on the list.
enum ReadingFont {
  /// Leave each surface's own font alone.
  ///
  /// **The default, and it matters that it is.** Surfaces do not agree today —
  /// azkar detail renders in Almarai, the after-salam adhkar and the mushaf in
  /// ScheherazadeNew — and those choices were made per surface for reasons that
  /// are still good. Shipping a global default would silently restyle half the
  /// app for every existing user on upgrade, to fix a problem none of them had
  /// reported. This changes nothing until somebody chooses.
  system('system', null),

  /// The app's UI face. Modern, even colour, best at small sizes.
  almarai('almarai', 'Almarai'),

  /// A Naskh face designed for Quranic typesetting. What the mushaf uses.
  scheherazade('scheherazade', 'ScheherazadeNew'),

  /// Ruqʿah calligraphy. Beautiful and demanding; some readers find it slow.
  arefRuqaa('aref_ruqaa', 'ArefRuqaa');

  final String id;

  /// The family name as declared in `pubspec.yaml`, or null for [system].
  final String? family;

  const ReadingFont(this.id, this.family);

  static ReadingFont fromId(String? id) {
    for (final value in ReadingFont.values) {
      if (value.id == id) return value;
    }
    return ReadingFont.system;
  }
}

/// The user's reading preferences, and the one place that turns them into a
/// [TextStyle].
///
/// ## What this is NOT
///
/// It is not text *size*. That shipped in R1 as `textScale`, multiplied over
/// the OS scaler in `main.dart`, and it applies to the whole app rather than to
/// reading surfaces alone. Putting size in here too would give the app two
/// controls that both make text bigger and disagree about by how much.
///
/// What was left over from R1 — and what this is — is **line spacing and font
/// choice**, applied only where somebody is reading rather than operating.
@immutable
class ReadingComfort {
  final ReadingSpacing spacing;
  final ReadingFont font;

  const ReadingComfort({
    this.spacing = ReadingSpacing.comfortable,
    this.font = ReadingFont.system,
  });

  static const ReadingComfort defaults = ReadingComfort();

  /// Whether this is the untouched default — used to keep a settings row quiet
  /// until it has something to say.
  bool get isDefault =>
      spacing == ReadingSpacing.comfortable && font == ReadingFont.system;

  /// Applies the preferences to [base].
  ///
  /// Pure, and the reason this class exists: "what does a reading surface look
  /// like at 1.7 leading in ArefRuqaa" is a question a test can answer without
  /// a device or a screenshot.
  ///
  /// A null [base] returns a style carrying only the preferences, for a caller
  /// with nothing to start from. [ReadingFont.system] leaves the family
  /// untouched — including leaving it null, so the surface's own theme decides.
  TextStyle apply(TextStyle? base) {
    final style = base ?? const TextStyle();
    return style.copyWith(
      height: spacing.height,
      fontFamily: font.family ?? style.fontFamily,
    );
  }

  ReadingComfort copyWith({ReadingSpacing? spacing, ReadingFont? font}) =>
      ReadingComfort(spacing: spacing ?? this.spacing, font: font ?? this.font);

  @override
  bool operator ==(Object other) =>
      other is ReadingComfort && other.spacing == spacing && other.font == font;

  @override
  int get hashCode => Object.hash(spacing, font);
}

/// Reaches [ReadingComfort] from any reading surface without threading it
/// through every widget in between.
///
/// An `InheritedWidget` rather than a `BlocBuilder` at each call site: these
/// are leaf `Text` widgets deep inside lists, and subscribing every one of them
/// to the settings cubit would rebuild whole screens on an unrelated settings
/// change.
class ReadingComfortScope extends InheritedWidget {
  const ReadingComfortScope({
    super.key,
    required this.comfort,
    required super.child,
  });

  final ReadingComfort comfort;

  /// The preferences in scope, or the defaults where none is installed — so a
  /// surface rendered outside the app shell (a test, a preview) still works.
  static ReadingComfort of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ReadingComfortScope>()
          ?.comfort ??
      ReadingComfort.defaults;

  @override
  bool updateShouldNotify(ReadingComfortScope oldWidget) =>
      oldWidget.comfort != comfort;
}
