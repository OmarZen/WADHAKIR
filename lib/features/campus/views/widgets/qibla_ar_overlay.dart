import 'package:flutter/material.dart';

const Color _alignedColor = Color(0xFF27AE60); // Green when on-target.
const Color _markerColor = Color(0xFFDAA520); // Gold otherwise.

/// Camera-overlay marker that points at the Kaaba.
///
/// It maps the signed shortest angle between the qibla bearing and the device
/// heading across the camera's (approximate) horizontal field of view, so the
/// marker slides left/right as the user pans the phone. When the target is
/// outside the FOV the marker parks at the edge with a directional chevron.
class QiblaArOverlay extends StatelessWidget {
  final double qiblaDirection;
  final double compassDirection;
  final bool isAligned;

  /// Approximate horizontal camera FOV in degrees. Device-dependent; ~60° is a
  /// reasonable default for "point roughly there" guidance.
  final double fovDegrees;

  const QiblaArOverlay({
    super.key,
    required this.qiblaDirection,
    required this.compassDirection,
    required this.isAligned,
    this.fovDegrees = 60,
  });

  /// Signed shortest angle (qibla − heading), normalized to [-180, 180].
  /// Positive → qibla is to the user's right.
  double get _signedDelta {
    return ((qiblaDirection - compassDirection + 540) % 360 - 180).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final color = isAligned ? _alignedColor : _markerColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final centerX = width / 2;
        final markerY = height * 0.42;
        final halfFov = fovDegrees / 2;
        final delta = _signedDelta;
        final inFov = delta.abs() <= halfFov;

        const markerSize = 76.0;
        final usableHalf = (width / 2) - 40;
        final fraction = (delta / halfFov).clamp(-1.0, 1.0);
        final markerX = centerX + fraction * usableHalf;

        return Stack(
          children: [
            // Center vertical guide ("aim here").
            Positioned(
              left: centerX - 1,
              top: height * 0.18,
              bottom: height * 0.18,
              child: Container(width: 2, color: Colors.white24),
            ),
            // Fixed center reticle.
            Positioned(
              left: centerX - 22,
              top: markerY - 22,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
              ),
            ),
            // The qibla marker.
            Positioned(
              left: markerX - markerSize / 2,
              top: markerY - markerSize / 2,
              child: _Marker(
                size: markerSize,
                color: color,
                isAligned: isAligned,
                outOfFov: !inFov,
                turnRight: delta > 0,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Marker extends StatelessWidget {
  final double size;
  final Color color;
  final bool isAligned;
  final bool outOfFov;
  final bool turnRight;

  const _Marker({
    required this.size,
    required this.color,
    required this.isAligned,
    required this.outOfFov,
    required this.turnRight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.25),
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isAligned ? 0.7 : 0.4),
                blurRadius: isAligned ? 28 : 14,
                spreadRadius: isAligned ? 4 : 1,
              ),
            ],
          ),
          child: Icon(
            Icons.mosque_rounded,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
        if (outOfFov) ...[
          const SizedBox(height: 6),
          Icon(
            turnRight ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            color: color,
            size: 34,
          ),
        ],
      ],
    );
  }
}
