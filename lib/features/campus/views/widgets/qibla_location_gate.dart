import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';

/// What a tab shows while there is no position to compute the qibla from:
/// the «سماح / ليس الآن» prompt, the locked card, the service-off card, a
/// failure with «إعادة المحاولة», or a calm "finding your location".
///
/// Every tab but AR's camera needs a position, so they all put this in place
/// of their content while [QiblaState.fix] is null. Only «سماح» reaches the
/// OS prompt (the cubit's `allowLocation`); nothing here prompts on its own.
class QiblaLocationGate extends StatelessWidget {
  /// A line under "finding your location", e.g. why the compass needs it.
  final String? locatingHint;

  const QiblaLocationGate({super.key, this.locatingHint});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QiblaCubit, QiblaState>(
      buildWhen: (a, b) =>
          a.locationStatus != b.locationStatus ||
          a.locationPermanentlyDenied != b.locationPermanentlyDenied ||
          a.failure != b.failure,
      builder: (context, state) {
        final cubit = context.read<QiblaCubit>();
        switch (state.locationStatus) {
          case QiblaLocationStatus.needsPrompt:
            return _GateCard(
              icon: Icons.location_on_rounded,
              title: QiblaStrings.tr(
                context,
                'qibla.location.prompt_title',
                'نحتاج موقعك',
              ),
              body: QiblaStrings.tr(
                context,
                'qibla.location.prompt_body',
                'اسمح لوذكّر بمعرفة موقعك لحساب اتجاه القبلة والمسافة إلى مكة المكرمة.',
              ),
              primaryLabel: QiblaStrings.tr(
                context,
                'qibla.location.allow',
                'سماح',
              ),
              onPrimary: cubit.allowLocation,
              secondaryLabel: QiblaStrings.tr(
                context,
                'qibla.location.not_now',
                'ليس الآن',
              ),
              onSecondary: cubit.declineLocation,
            );
          case QiblaLocationStatus.locked:
            final forever = state.locationPermanentlyDenied;
            return _GateCard(
              icon: Icons.lock_outline_rounded,
              title: QiblaStrings.tr(
                context,
                'qibla.location.locked_title',
                'الموقع غير متاح',
              ),
              body: forever
                  ? QiblaStrings.tr(
                      context,
                      'qibla.location.locked_body',
                      'إذن الموقع مرفوض. فعّله من إعدادات التطبيق لعرض اتجاه القبلة.',
                    )
                  : QiblaStrings.tr(
                      context,
                      'qibla.location.declined_body',
                      'لم تسمح لوذكّر بمعرفة موقعك بعد، فلا يمكن حساب اتجاه القبلة.',
                    ),
              primaryLabel: forever
                  ? QiblaStrings.tr(
                      context,
                      'qibla.location.open_settings',
                      'فتح الإعدادات',
                    )
                  : QiblaStrings.tr(context, 'qibla.location.allow', 'سماح'),
              onPrimary: forever ? cubit.openAppSettings : cubit.allowLocation,
            );
          case QiblaLocationStatus.serviceOff:
            return _GateCard(
              icon: Icons.location_off_rounded,
              title: QiblaStrings.tr(
                context,
                'qibla.location.service_off',
                'خدمة الموقع متوقفة',
              ),
              body: QiblaStrings.tr(
                context,
                'qibla.location.service_off_body',
                'شغّل خدمة الموقع ثم عُد إلى هنا.',
              ),
              primaryLabel: QiblaStrings.tr(
                context,
                'qibla.location.open_location_settings',
                'إعدادات الموقع',
              ),
              onPrimary: cubit.openLocationSettings,
            );
          case QiblaLocationStatus.failed:
            return _GateCard(
              icon: Icons.wrong_location_rounded,
              title: state.failure == QiblaFailure.timeout
                  ? QiblaStrings.tr(
                      context,
                      'qibla.location.timeout',
                      'تعذّر تحديد موقعك. جرّب مكانًا مكشوفًا ثم أعد المحاولة.',
                    )
                  : QiblaStrings.tr(
                      context,
                      'qibla.location.error',
                      'تعذّر تحديد موقعك. أعد المحاولة بعد قليل.',
                    ),
              primaryLabel: QiblaStrings.tr(
                context,
                'qibla.location.retry',
                'إعادة المحاولة',
              ),
              onPrimary: cubit.retryLocation,
            );
          case QiblaLocationStatus.unknown:
          case QiblaLocationStatus.locating:
          case QiblaLocationStatus.ready:
            return _Locating(hint: locatingHint);
        }
      },
    );
  }
}

class _GateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _GateCard({
    required this.icon,
    required this.title,
    this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = AppAccent.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: dark ? 0.22 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 34, color: accent),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: cs.onSurface,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: QiblaLook.body(
                    context,
                  ).copyWith(color: QiblaLook.muted(context)),
                ),
              ],
              const SizedBox(height: Spacing.xl),
              FButton(
                onPress: onPrimary,
                child: QiblaButtonLabel(primaryLabel),
              ),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: Spacing.sm),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: onSecondary,
                  child: QiblaButtonLabel(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Locating extends StatelessWidget {
  final String? hint;

  const _Locating({this.hint});

  @override
  Widget build(BuildContext context) {
    final accent = AppAccent.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: still
                  ? Icon(Icons.my_location_rounded, color: accent)
                  : CircularProgressIndicator(strokeWidth: 3, color: accent),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              QiblaStrings.tr(
                context,
                'qibla.location.locating',
                'جارٍ تحديد موقعك…',
              ),
              textAlign: TextAlign.center,
              style: QiblaLook.body(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            if (hint != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: QiblaLook.body(
                  context,
                ).copyWith(color: QiblaLook.muted(context), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
