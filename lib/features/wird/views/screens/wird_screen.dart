import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/celebration.dart';
import 'package:wadhakir/features/wird/cubit/wird_cubit.dart';
import 'package:wadhakir/features/wird/cubit/wird_state.dart';
import 'package:wadhakir/features/wird/views/screens/wird_setup_view.dart';
import 'package:wadhakir/features/wird/views/screens/wird_progress_view.dart';
import 'package:wadhakir/features/wird/views/widgets/wird_header.dart';

/// Entry screen for the daily Quran wird. A branded gradient header (no
/// AppBar) tops a body that routes between setup (no active plan) and
/// progress (active plan) based on cubit state.
class WirdScreen extends StatelessWidget {
  const WirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<WirdCubit, WirdState>(
        // Fire confetti only on a genuine transition: a day newly marked
        // complete (the completed-set grew) or the whole khatma just finished.
        // The first observed state has no `previous`, so listenWhen is skipped
        // on screen entry — no celebration for an already-complete day.
        listenWhen: (prev, curr) {
          if (prev is! WirdLoaded || curr is! WirdLoaded) return false;
          final grew =
              curr.plan.completedDayIndices.length >
              prev.plan.completedDayIndices.length;
          final justFinished = curr.isFinished && !prev.isFinished;
          return grew || justFinished;
        },
        listener: (context, state) {
          if (state is! WirdLoaded) return;
          if (state.isFinished) {
            // Finishing a whole khatma is a rare, earned moment → big
            // gold-star celebration with an achievement card.
            Celebration.milestone(
              context,
              title:
                  l10n?.translate('celebration.wird_finished') ??
                  'أتممت ختمتك! تقبّل الله',
              subtitle:
                  l10n?.translate('celebration.wird_finished_subtitle') ??
                  'إنجاز عظيم — نسأل الله أن يتقبّل',
            );
          } else {
            Celebration.burst(
              context,
              message:
                  l10n?.translate('celebration.wird_day') ??
                  'أحسنت! أكملت وردك اليوم',
            );
          }
        },
        builder: (context, state) {
          final isActive = state is WirdLoaded && state.plan.isActive;
          final title = isActive
              ? (l10n?.translate('wird.progress_title') ?? 'خطة ختم القرآن')
              : (l10n?.translate('wird.setup_title') ?? 'ابدأ ختمتك');

          return Column(
            children: [
              WirdHeader(title: title),
              Expanded(child: _body(context, state, l10n, theme)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WirdState state,
    AppLocalizations? l10n,
    ThemeData theme,
  ) {
    if (state is WirdLoading || state is WirdInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is WirdError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(state.message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FButton(
              onPress: () => context.read<WirdCubit>().loadPlan(),
              mainAxisSize: MainAxisSize.min,
              child: Text(l10n?.translate('common.retry') ?? 'إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (state is WirdLoaded) {
      return state.plan.isActive
          ? WirdProgressView(state: state)
          : const WirdSetupView();
    }
    return const SizedBox.shrink();
  }
}
