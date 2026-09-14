import 'package:shared_preferences/shared_preferences.dart';

/// One feature-discovery nudge: a re-engagement notification that points the
/// user at a feature they haven't enabled/used yet.
class FeatureNudge {
  /// Stable id used for rotation bookkeeping (the "already shown" set).
  final String id;

  final String titleAr;
  final String bodyAr;

  /// A [NotificationRouter] destination token (e.g. 'open_zakat'), delivered in
  /// the payload as `{'type':'feature_nudge','target': <this>}`.
  final String target;

  /// Returns true when the feature is NOT yet used/enabled — i.e. the nudge is
  /// still worth showing. Reads existing SharedPreferences signals.
  final bool Function(SharedPreferences prefs) isEligible;

  const FeatureNudge({
    required this.id,
    required this.titleAr,
    required this.bodyAr,
    required this.target,
    required this.isEligible,
  });
}
