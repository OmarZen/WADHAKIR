import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

import 'pill_preview.dart';

/// Hero header for the floating dhikr settings screen. Replaces the
/// default AppBar with a richer surface: app-primary gradient, Almarai
/// Arabic title, status pill, and a small inline preview of the pill bar
/// so users immediately understand what the feature does.
class FloatingDhikrHeader extends StatelessWidget {
  /// `true` if the feature is fully active (enabled + permission granted +
  /// supported). Drives the status pill's colour and copy.
  final bool isActive;

  /// `true` if the overlay permission is granted. Used to show a more
  /// specific status when the feature is supported but disabled.
  final bool hasPermission;

  final double previewOpacity;
  final VoidCallback onBack;

  const FloatingDhikrHeader({
    super.key,
    required this.isActive,
    required this.hasPermission,
    required this.previewOpacity,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            Color.lerp(primary, secondary, 0.45) ?? primary,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(Radii.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative orbs to add depth without imagery.
          Positioned(
            top: -40,
            right: -30,
            child: _orb(110, Colors.white.withValues(alpha: 0.10)),
          ),
          Positioned(
            top: 60,
            left: -50,
            child: _orb(160, Colors.white.withValues(alpha: 0.06)),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.sm,
                Spacing.lg,
                Spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: back button + status pill
                  Row(
                    children: [
                      _HeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: onBack,
                      ),
                      const Spacer(),
                      _StatusPill(
                        isActive: isActive,
                        hasPermission: hasPermission,
                        l10n: l10n,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  // Title
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: const Icon(
                          Icons.bubble_chart_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.translate('floating_dhikr.title') ??
                                  'تذكير الأذكار العائم',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Almarai',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n?.translate(
                                    'floating_dhikr.header_subtitle',
                                  ) ??
                                  'ذكر هادئ يظهر فوق التطبيقات الأخرى',
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.85),
                                fontFamily: 'Almarai',
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  // Inline preview of the pill bar
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.preview_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Text(
                              l10n?.translate(
                                    'floating_dhikr.preview_label',
                                  ) ??
                                  'معاينة',
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.92),
                                fontFamily: 'Almarai',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.sm),
                        PillPreview(opacity: previewOpacity),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  final bool hasPermission;
  final AppLocalizations? l10n;

  const _StatusPill({
    required this.isActive,
    required this.hasPermission,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? const Color(0xFF36CF74) // bright green (matches darkPrayerAzkarColor)
        : (hasPermission ? Colors.amber.shade300 : Colors.white70);
    final text = isActive
        ? (l10n?.translate('floating_dhikr.status_active') ?? 'مفعّل')
        : (hasPermission
            ? (l10n?.translate('floating_dhikr.status_paused') ?? 'متوقف')
            : (l10n?.translate('floating_dhikr.status_needs_permission') ??
                'يحتاج صلاحية'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Almarai',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
