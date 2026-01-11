import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wadhakir/core/localization/app_localizations.dart';

class HadithCardWidget extends StatefulWidget {
  const HadithCardWidget({super.key});

  @override
  State<HadithCardWidget> createState() => _HadithCardWidgetState();
}

class _HadithCardWidgetState extends State<HadithCardWidget> {
  List<String> _hadithTexts = const [];
  int _currentIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/json_data/40-hadith-nawawi.json');
      final List<dynamic> data = json.decode(jsonString) as List<dynamic>;
      final texts = data
          .map((e) => (e as Map<String, dynamic>)['hadith'])
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      if (mounted) {
        setState(() {
          _hadithTexts = texts;
          _currentIndex = _randomIndex(texts.length);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hadithTexts = const [];
          _loading = false;
        });
      }
    }
  }

  int _randomIndex(int length) {
    if (length <= 1) return 0;
    final seed = DateTime.now().microsecondsSinceEpoch;
    return Random(seed).nextInt(length);
  }

  void _shuffle() {
    if (_hadithTexts.isEmpty) return;
    setState(() {
      var next = _randomIndex(_hadithTexts.length);
      if (next == _currentIndex && _hadithTexts.length > 1) {
        next = (next + 1) % _hadithTexts.length;
      }
      _currentIndex = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: _loading
            ? _buildSkeleton(theme)
            : _hadithTexts.isEmpty
                ? _buildError(theme)
                : _buildGlassCard(theme, _hadithTexts[_currentIndex]),
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: _glassDecoration(theme, isDark),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerRow(theme,
              l10n?.translate('home.hadith_nawawi') ?? 'من الأربعين النووية'),
          const SizedBox(height: 12),
          _shimmerBar(theme, 18, 0.85),
          const SizedBox(height: 8),
          _shimmerBar(theme, 16, 0.95),
          const SizedBox(height: 8),
          _shimmerBar(theme, 16, 0.7),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: _glassDecoration(theme, isDark),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerRow(theme,
              l10n?.translate('home.hadith_nawawi') ?? 'من الأربعين النووية'),
          const SizedBox(height: 12),
          Text(
            l10n?.translate('home.hadith_error') ??
                'تعذر تحميل الأحاديث. يرجى المحاولة لاحقاً.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(ThemeData theme, String fullText) {
    final title = _extractTitle(fullText);
    final body = _extractBody(fullText);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final borderRadius = BorderRadius.circular(16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showHadithSheet(context, title, body),
        borderRadius: borderRadius,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 140, maxHeight: 220),
            child: Container(
              decoration: _glassDecoration(theme, isDark),
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerRow(theme, title),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'ScheherazadeNew',
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionChip(
                        context,
                        icon: Icons.autorenew_rounded,
                        label: l10n?.translate('home.hadith_shuffle') ??
                            'حديث آخر',
                        onTap: _shuffle,
                      ),
                      Text(
                        '${_currentIndex + 1} / ${_hadithTexts.length}',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: _accent(theme)),
                      ),
                      _iconCircle(
                        context,
                        icon: Icons.share_rounded,
                        tooltip:
                            l10n?.translate('home.hadith_share') ?? 'مشاركة',
                        onTap: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text: 'من الأربعين النووية\n\n$title\n\n$body\n تطبيق وذكر حمله الان: \nhttps://play.google.com/store/apps/details?id=com.bloom.wadhakir',
                              subject: 'من الأربعين النووية',
                            ),
                          );
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showHadithSheet(
      BuildContext context, String title, String body) async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final l10n = context.l10n;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip:
                            l10n?.translate('home.hadith_share') ?? 'مشاركة',
                        onPressed: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text: 'من الأربعين النووية\n\n$title\n\n$body\n تطبيق وذكر حمله الان: \nhttps://play.google.com/store/apps/details?id=com.bloom.wadhakir',
                              subject: 'من الأربعين النووية',
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      body,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'ScheherazadeNew',
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerRow(ThemeData theme, String title) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _badge(theme,
                l10n?.translate('home.hadith_nawawi') ?? 'الأربعون النووية'),
            const Spacer(),
            _iconCircle(
              context,
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: l10n?.translate('home.hadith_previous') ?? 'السابق',
              onTap: () {
                if (_hadithTexts.isEmpty) return;
                setState(() {
                  _currentIndex = (_currentIndex - 1) % _hadithTexts.length;
                  if (_currentIndex < 0) _currentIndex += _hadithTexts.length;
                });
              },
            ),
            const SizedBox(width: 6),
            _iconCircle(
              context,
              icon: Icons.arrow_forward_ios_rounded,
              tooltip: l10n?.translate('home.hadith_next') ?? 'التالي',
              onTap: () {
                if (_hadithTexts.isEmpty) return;
                setState(() {
                  _currentIndex = (_currentIndex + 1) % _hadithTexts.length;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'ScheherazadeNew',
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  BoxDecoration _glassDecoration(ThemeData theme, bool isDark) {
    // Simplified: solid surface, subtle border, no gradient or shadow
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: isDark
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
          : theme.colorScheme.surface.withValues(alpha: 0.6),
      border: Border.all(color: _accent(theme).withValues(alpha: 0.16)),
    );
  }

  static Color _accent(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? theme.colorScheme.onSurface : theme.colorScheme.primary;
  }

  // Reserved for future outline tuning

  Widget _badge(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _accent(theme).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent(theme).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 16, color: _accent(theme)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _accent(theme),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _accent(theme)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: _accent(theme), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconCircle(BuildContext context,
      {required IconData icon,
      required String tooltip,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? theme.colorScheme.surface.withValues(alpha: 0.12)
                : theme.colorScheme.primary.withValues(alpha: 0.08),
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: _accent(theme)),
        ),
      ),
    );
  }

  Widget _shimmerBar(ThemeData theme, double height, double widthFactor) {
    final isDark = theme.brightness == Brightness.dark;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
              : theme.colorScheme.onSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _extractTitle(String text) {
    final lines = text.split('\n');
    // Expect pattern: "الحديث الأول" on first line
    final firstNonEmpty =
        lines.firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    if (firstNonEmpty.contains('الحديث')) {
      return 'من الأربعين النووية • ${firstNonEmpty.trim()}';
    }
    return 'من الأربعين النووية';
  }

  String _extractBody(String text) {
    // Remove the title line and any empty lines around
    final parts = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (parts.isEmpty) return text.trim();
    if (parts.first.contains('الحديث')) {
      parts.removeAt(0);
    }
    return parts.join('\n').trim();
  }
}
