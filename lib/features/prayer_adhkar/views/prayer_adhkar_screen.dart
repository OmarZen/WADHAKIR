import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/branded_header.dart';
import 'package:wadhakir/features/prayer_adhkar/prayer_adhkar_data.dart';

/// "أذكار بعد الصلاة" — the after-salam adhkar with a branded header, an
/// overall completion counter, and a tap-to-count card per dhikr (progress
/// persisted in SharedPreferences).
class PrayerAdhkarScreen extends StatefulWidget {
  const PrayerAdhkarScreen({super.key});

  @override
  State<PrayerAdhkarScreen> createState() => _PrayerAdhkarScreenState();
}

class _PrayerAdhkarScreenState extends State<PrayerAdhkarScreen> {
  late Future<List<PrayerDhikr>> _future;
  final Map<String, int> _counts = {};

  static const List<String> _arDigits = [
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', //
  ];

  String _ar(int n) =>
      n.toString().split('').map((c) => _arDigits[int.parse(c)]).join();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PrayerDhikr>> _load() async {
    final items = await PrayerAdhkarData.getItems();
    final prefs = await SharedPreferences.getInstance();
    for (final it in items) {
      _counts[it.text] = prefs.getInt(PrayerAdhkarData.prefsKey(it.text)) ?? 0;
    }
    return items;
  }

  Future<void> _increment(PrayerDhikr d) async {
    final current = _counts[d.text] ?? 0;
    if (current >= d.count) return;
    setState(() => _counts[d.text] = current + 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrayerAdhkarData.prefsKey(d.text), current + 1);
  }

  Future<void> _resetAll(List<PrayerDhikr> items) async {
    setState(() {
      for (final it in items) {
        _counts[it.text] = 0;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    for (final it in items) {
      await prefs.setInt(PrayerAdhkarData.prefsKey(it.text), 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: FutureBuilder<List<PrayerDhikr>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? const <PrayerDhikr>[];
          final done = items
              .where((it) => (_counts[it.text] ?? 0) >= it.count)
              .length;

          return Column(
            children: [
              BrandedHeader(
                title:
                    l10n?.translate('prayer_adhkar.title') ??
                    'أذكار بعد الصلاة',
                actions: [
                  if (items.isNotEmpty)
                    IconButton(
                      onPressed: () => _resetAll(items),
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      tooltip:
                          l10n?.translate('prayer_adhkar.reset') ??
                          'إعادة تعيين',
                    ),
                ],
              ),
              Expanded(
                child: !snap.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          _ProgressSummary(
                            done: done,
                            total: items.length,
                            ar: _ar,
                          ),
                          const SizedBox(height: 14),
                          ...items.map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DhikrCard(
                                dhikr: d,
                                current: _counts[d.text] ?? 0,
                                ar: _ar,
                                onTap: () => _increment(d),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final int done;
  final int total;
  final String Function(int) ar;

  const _ProgressSummary({
    required this.done,
    required this.total,
    required this.ar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final frac = total == 0 ? 0.0 : done / total;

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.front_hand_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n?.translate('prayer_adhkar.progress') ?? 'أتممت'} '
                    '${ar(done)} ${l10n?.translate('prayer_adhkar.of') ?? 'من'} '
                    '${ar(total)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${ar((frac * 100).round())}٪',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 8,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  final PrayerDhikr dhikr;
  final int current;
  final String Function(int) ar;
  final VoidCallback onTap;

  const _DhikrCard({
    required this.dhikr,
    required this.current,
    required this.ar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDone = current >= dhikr.count;
    final frac = dhikr.count == 0
        ? 1.0
        : (current / dhikr.count).clamp(0.0, 1.0);

    return FTappable(
      onPress: onTap,
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                dhikr.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'ScheherazadeNew',
                  height: 1.9,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      value: frac,
                      strokeWidth: 3,
                      backgroundColor: cs.primary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(
                        isDone ? cs.primary : cs.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${ar(current)} / ${ar(dhikr.count)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isDone) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, size: 20, color: cs.primary),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
