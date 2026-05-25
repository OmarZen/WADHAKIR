// import 'dart:json' as json_stub; // placeholder to ensure file context
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class ProgressButtonShared extends StatelessWidget {
  final double progress;
  final String label;
  final VoidCallback onTap;

  const ProgressButtonShared({
    super.key,
    required this.progress,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class IslamicDividerShared extends StatelessWidget {
  const IslamicDividerShared({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(Icons.star, size: 12, color: theme.colorScheme.primary),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class GridProgressBadge extends StatelessWidget {
  final String assetPath;
  final String prefsPrefix;

  const GridProgressBadge({
    super.key,
    required this.assetPath,
    required this.prefsPrefix,
  });

  Future<_Counts> _loadCounts() async {
    final data = await rootBundle.loadString(assetPath);
    final map = json.decode(data) as Map<String, dynamic>;
    final List<dynamic> content = map['content'] as List<dynamic>;
    final prefs = await SharedPreferences.getInstance();
    int completed = 0;
    for (final item in content) {
      final text = (item as Map<String, dynamic>)['text'] as String? ?? '';
      final key = '$prefsPrefix${text.hashCode}';
      final value = prefs.getInt(key) ?? 0;
      if (value > 0) completed += 1;
    }
    return _Counts(completed: completed, total: content.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<_Counts>(
      future: _loadCounts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final counts = snapshot.data!;
        if (counts.total == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            '${counts.completed}/${counts.total}',
            style: theme.textTheme.bodySmall,
          ),
        );
      },
    );
  }
}

class _Counts {
  final int completed;
  final int total;
  _Counts({required this.completed, required this.total});
}
