import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class TasbihGridItem extends StatelessWidget {
  const TasbihGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = PlatformUtils.isDesktop;

    final padding = isDesktop ? 16.0 : 12.0;
    final verticalPadding = isDesktop ? 12.0 : 10.0;
    final iconPadding = isDesktop ? 10.0 : 8.0;
    final iconSize = isDesktop ? 22.0 : 20.0;
    final spacing = isDesktop ? 12.0 : 10.0;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _showAzkarSheet(context, 'assets/json_data/tassbih.json'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: padding, vertical: verticalPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.format_list_numbered_rounded,
                  size: iconSize,
                  color: isDark
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                      : theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  l10n?.translate('home.tasbih') ?? 'تسابيح',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: isDesktop ? 16 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAzkarSheet(BuildContext context, String assetPath) async {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final data = await rootBundle.loadString(assetPath);
    final map = json.decode(data) as Map<String, dynamic>;
    final List<dynamic> content = map['content'] as List<dynamic>;

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.translate('home.tasbih') ?? 'تسابيح',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const _IslamicDivider(),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: content.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = content[index] as Map<String, dynamic>;
                    final text = item['text'] as String? ?? '';
                    final repeat = (item['repeat'] as num?)?.toInt() ?? 1;
                    final reference = item['reference'] as String?;
                    final benefit = item['benefit'] as String?;
                    return _AzkarCard(
                      text: text,
                      repeat: repeat,
                      reference: reference,
                      benefit: benefit,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AzkarCard extends StatefulWidget {
  final String text;
  final int repeat;
  final String? reference;
  final String? benefit;

  const _AzkarCard({
    required this.text,
    required this.repeat,
    this.reference,
    this.benefit,
  });

  @override
  State<_AzkarCard> createState() => _AzkarCardState();
}

class _AzkarCardState extends State<_AzkarCard> {
  int completed = 0;

  @override
  void initState() {
    super.initState();
    _loadCounter();
  }

  String get _counterKey => 'tasbih_${widget.text.hashCode}';

  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCount = prefs.getInt(_counterKey) ?? 0;
    if (mounted) {
      setState(() => completed = savedCount);
    }
  }

  Future<void> _saveCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_counterKey, completed);
  }

  void _increment() {
    if (completed < widget.repeat) {
      setState(() => completed += 1);
      _saveCounter();
    }
  }

  void _reset() {
    setState(() => completed = 0);
    _saveCounter();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final double progress =
        widget.repeat <= 0 ? 0 : (completed / widget.repeat).clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _increment,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      l10n?.translate('home.repeat') ??
                          'التكرار: ${widget.repeat}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  const Spacer(),
                  // Reset button
                  IconButton(
                    onPressed: completed > 0 ? _reset : null,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: completed > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    tooltip: l10n?.translate('home.reset') ?? 'إعادة تعيين',
                  ),
                  const SizedBox(width: 4),
                  _ProgressButton(
                    progress: progress,
                    label: '$completed/${widget.repeat}',
                    onTap: _increment,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.6),
              ),
              if (widget.reference != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.reference!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (widget.benefit != null) ...[
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    widget.benefit!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressButton extends StatelessWidget {
  final double progress;
  final String label;
  final VoidCallback onTap;

  const _ProgressButton({
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
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
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

class _IslamicDivider extends StatelessWidget {
  const _IslamicDivider();
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
