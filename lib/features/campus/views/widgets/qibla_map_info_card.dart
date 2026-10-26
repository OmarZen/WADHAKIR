import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';

/// Under the map: the straight-line distance to Makkah, the qibla bearing,
/// and where they were measured from. All three are pure arithmetic on the
/// fix, so they stay right when the tiles cannot load.
class QiblaMapInfoCard extends StatelessWidget {
  final double distanceKm;
  final double bearing;
  final double latitude;
  final double longitude;
  final String? placeName;

  const QiblaMapInfoCard({
    super.key,
    required this.distanceKm,
    required this.bearing,
    required this.latitude,
    required this.longitude,
    this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = AppAccent.of(context);
    final coords = QiblaFormat.coordinates(context, latitude, longitude);
    final name = placeName?.trim();
    final from = (name == null || name.isEmpty) ? coords : '$name: $coords';

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: QiblaLook.card(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Stat(
                    label: QiblaStrings.tr(
                      context,
                      'qibla.map.distance',
                      'المسافة المباشرة',
                    ),
                    value: QiblaStrings.fill(
                      QiblaStrings.tr(context, 'qibla.map.km', '{n} كم'),
                      {'n': QiblaFormat.km(distanceKm)},
                    ),
                    color: cs.onSurface,
                  ),
                ),
                VerticalDivider(
                  width: Spacing.xl,
                  thickness: 1,
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _Stat(
                    label: QiblaStrings.tr(
                      context,
                      'qibla.map.bearing',
                      'اتجاه القبلة',
                    ),
                    value: QiblaFormat.degrees(bearing),
                    valueDirection: TextDirection.ltr,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            from,
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 13,
              height: 1.5,
              color: QiblaLook.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final TextDirection? valueDirection;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    this.valueDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 13,
            color: QiblaLook.muted(context),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        // A standalone number keeps its own left-to-right order, and its
        // alignment follows the card (start) rather than the number.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            textDirection: valueDirection,
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
