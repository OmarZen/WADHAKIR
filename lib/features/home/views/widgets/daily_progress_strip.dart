import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/titled_section.dart';
import 'package:wadhakir/features/prayer_adhkar/prayer_adhkar_data.dart';
import 'package:wadhakir/features/prayer_adhkar/views/prayer_adhkar_screen.dart';
import 'package:wadhakir/features/wird/cubit/wird_cubit.dart';
import 'package:wadhakir/features/wird/cubit/wird_state.dart';
import 'package:wadhakir/features/wird/views/screens/wird_screen.dart';

/// "تقدّمك اليومي" — at-a-glance progress cards: daily wird (live from
/// WirdCubit) and after-prayer adhkar (from saved counters). Both tap through
/// to their screens.
class DailyProgressStrip extends StatefulWidget {
  const DailyProgressStrip({super.key});

  @override
  State<DailyProgressStrip> createState() => _DailyProgressStripState();
}

class _DailyProgressStripState extends State<DailyProgressStrip> {
  late Future<double> _adhkarFuture;

  @override
  void initState() {
    super.initState();
    _adhkarFuture = PrayerAdhkarData.completionFraction();
  }

  /// Open the adhkar screen, then refresh the card's progress on return so the
  /// home reflects any counters the user incremented.
  Future<void> _openAdhkar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrayerAdhkarScreen()),
    );
    if (!mounted) return;
    setState(() {
      _adhkarFuture = PrayerAdhkarData.completionFraction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TitledSection(
      title: l10n?.translate('home.daily_progress') ?? 'تقدّمك اليومي',
      icon: Icons.insights_rounded,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الورد اليومي — live from WirdCubit.
          Expanded(
            child: BlocBuilder<WirdCubit, WirdState>(
              builder: (context, state) {
                final progress = state is WirdLoaded ? state.progress : 0.0;
                return _ProgressCard(
                  icon: Icons.menu_book_rounded,
                  label: l10n?.translate('wird.home_title') ?? 'الورد اليومي',
                  progress: progress,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WirdScreen()),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // أذكار الصلاة — from the after-prayer adhkar counters.
          Expanded(
            child: FutureBuilder<double>(
              future: _adhkarFuture,
              builder: (context, snap) => _ProgressCard(
                icon: Icons.front_hand_rounded,
                label:
                    l10n?.translate('prayer_adhkar.title') ??
                    'أذكار بعد الصلاة',
                progress: snap.data ?? 0.0,
                onTap: _openAdhkar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double progress;
  final VoidCallback onTap;

  const _ProgressCard({
    required this.icon,
    required this.label,
    required this.progress,
    required this.onTap,
  });

  static const List<String> _arDigits = [
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', //
  ];

  String _ar(int n) =>
      n.toString().split('').map((c) => _arDigits[int.parse(c)]).join();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pct = (progress.clamp(0.0, 1.0) * 100).round();

    return FTappable(
      onPress: onTap,
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 4,
                        backgroundColor: cs.primary.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                    Icon(icon, size: 18, color: cs.primary),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_ar(pct)}٪',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
