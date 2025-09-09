import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class PalestineSupportCardWidget extends StatelessWidget {
  const PalestineSupportCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(decoration: _neonGlow(theme)),
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: _glassDecoration(theme),
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _flagPill(theme, context),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.translate('home.free_palestine') ?? 'فلسطين حرة',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            // tree leaf
                            FontAwesomeIcons.leaf,
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n?.translate('home.palestine_support') ?? 'اللهم انصر إخواننا في فلسطين، وادفع عنهم البلاء، واجعل لهم من كل هم فرجاً، ومن كل ضيق مخرجاً، وارزقهم الصبر والثبات، وأطعمهم من جوع وآمنهم من خوف واجعل لهم النصر المبين.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: _ctaButton(theme, context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _glassDecoration(ThemeData theme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surface.withValues(alpha: 0.06),
      border:
          Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.16)),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.12),
          theme.colorScheme.primary.withValues(alpha: 0.06),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  BoxDecoration _neonGlow(ThemeData theme) {
    final neon = theme.colorScheme.primary;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: neon.withValues(alpha: 0.24),
          blurRadius: 24,
          spreadRadius: 1,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: neon.withValues(alpha: 0.12),
          blurRadius: 48,
          spreadRadius: 6,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  Widget _flagPill(ThemeData theme, BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountryFlag.fromCountryCode('PS', width: 24, height: 16),
          const SizedBox(width: 8),
          Text(
            l10n?.translate('home.palestine_support_call_to_action') ?? 'دعاء ونصرة',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctaButton(ThemeData theme, BuildContext context) {
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Text(
                l10n?.translate('home.palestine_duah') ?? 'لا تنسوهم من دعائكم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
