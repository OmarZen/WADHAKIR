import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
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
      body: BlocBuilder<WirdCubit, WirdState>(
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
