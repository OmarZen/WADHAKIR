import 'package:flutter/material.dart';

/// Mock pill bar shown in the settings hero preview. Matches the visual
/// styling of the real overlay so users get an accurate sense of what
/// will appear over their other apps.
class PillPreview extends StatelessWidget {
  final double opacity;
  const PillPreview({super.key, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          // Same primary-blue gradient as the live overlay so the preview
          // is a faithful representation of what the user will see.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF20497D).withValues(alpha: opacity),
              const Color(0xFF2C5A92).withValues(alpha: opacity),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF20497D).withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.nightlight_round,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Almarai',
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
