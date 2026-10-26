import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';

/// The place shown in the header: the saved or looked-up name, else the
/// coordinates, else nothing yet.
String? qiblaPlaceText(BuildContext context, QiblaState state) {
  final fix = state.fix;
  if (fix == null) return null;
  final name = state.placeName;
  if (name != null && name.trim().isNotEmpty) return name;
  return QiblaFormat.coordinates(context, fix.latitude, fix.longitude);
}

/// How much to trust the position on screen, said only when it needs saying:
/// «موقع تقريبي» (the prayer-times location, after «ليس الآن»), «آخر موقع
/// معروف» (a fresh reading did not come) or «جارٍ تحسين دقة الموقع…». A fresh
/// fix needs no label; the header already names the place.
class QiblaLocationLabel extends StatelessWidget {
  const QiblaLocationLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QiblaCubit, QiblaState>(
      buildWhen: (a, b) =>
          a.fix != b.fix ||
          a.approximate != b.approximate ||
          a.lastKnown != b.lastKnown ||
          a.refiningFix != b.refiningFix,
      builder: (context, state) {
        if (state.fix == null) return const SizedBox.shrink();
        final String text;
        final IconData icon;
        if (state.approximate) {
          text = QiblaStrings.tr(
            context,
            'qibla.location.approximate',
            'موقع تقريبي',
          );
          icon = Icons.location_searching_rounded;
        } else if (state.lastKnown) {
          text = QiblaStrings.tr(
            context,
            'qibla.location.last_known',
            'آخر موقع معروف',
          );
          icon = Icons.history_rounded;
        } else if (state.refiningFix) {
          text = QiblaStrings.tr(
            context,
            'qibla.location.refining',
            'جارٍ تحسين دقة الموقع…',
          );
          icon = Icons.gps_not_fixed_rounded;
        } else {
          return const SizedBox.shrink();
        }
        final color = QiblaLook.muted(context);
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: Spacing.xs + Spacing.xxs),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
