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
  Map<String, dynamic>? _metadata;
  List<Map<String, dynamic>> _hadiths = const [];
  int _currentIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/json_data/40-hadith-nawawi.json',
      );
      final Map<String, dynamic> data =
          json.decode(jsonString) as Map<String, dynamic>;
      final metadata = data['metadata'] as Map<String, dynamic>?;
      final hadithsList = (data['hadiths'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .where((h) => h['arabic'] != null || h['english'] != null)
          .toList(growable: false);

      if (mounted) {
        setState(() {
          _metadata = metadata;
          _hadiths = hadithsList;
          _currentIndex = _randomIndex(hadithsList.length);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _metadata = null;
          _hadiths = const [];
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
    if (_hadiths.isEmpty) return;
    setState(() {
      var next = _randomIndex(_hadiths.length);
      if (next == _currentIndex && _hadiths.length > 1) {
        next = (next + 1) % _hadiths.length;
      }
      _currentIndex = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection: languageCode == 'en'
          ? TextDirection.ltr
          : TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: _loading
            ? _buildSkeleton(theme, languageCode)
            : _hadiths.isEmpty
            ? _buildError(theme, languageCode)
            : _buildGlassCard(theme, languageCode, _hadiths[_currentIndex]),
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme, String languageCode) {
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final title = languageCode == 'en'
        ? 'Forty Hadith of an-Nawawi'
        : (l10n?.translate('home.hadith_nawawi') ?? 'من الأربعين النووية');
    return Container(
      decoration: _glassDecoration(theme, isDark),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerRow(theme, languageCode, title, null),
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

  Widget _buildError(ThemeData theme, String languageCode) {
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final title = languageCode == 'en'
        ? 'Forty Hadith of an-Nawawi'
        : (l10n?.translate('home.hadith_nawawi') ?? 'من الأربعين النووية');
    return Container(
      decoration: _glassDecoration(theme, isDark),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerRow(theme, languageCode, title, null),
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

  Widget _buildGlassCard(
    ThemeData theme,
    String languageCode,
    Map<String, dynamic> hadith,
  ) {
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(16);

    final hadithNumber =
        hadith['idInBook'] as int? ?? hadith['id'] as int? ?? 0;
    final title = _getCollectionTitle(languageCode);
    final hadithText = _getHadithText(hadith, languageCode);
    final author = _getAuthor(languageCode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showHadithSheet(context, languageCode, hadith),
        borderRadius: borderRadius,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 100, maxHeight: 240),
            child: Container(
              decoration: _glassDecoration(theme, isDark),
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerRow(theme, languageCode, title, author),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      hadithText,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: languageCode == 'en'
                            ? null
                            : 'ScheherazadeNew',
                        height: 1.4,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionChip(
                        context,
                        icon: Icons.autorenew_rounded,
                        label:
                            l10n?.translate('home.hadith_shuffle') ??
                            (languageCode == 'en' ? 'Another' : 'حديث آخر'),
                        onTap: _shuffle,
                      ),
                      Text(
                        languageCode == 'en'
                            ? 'Hadith $hadithNumber / ${_hadiths.length}'
                            : 'الحديث $hadithNumber / ${_hadiths.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _accent(theme),
                        ),
                      ),
                      _iconCircle(
                        context,
                        icon: Icons.share_rounded,
                        tooltip:
                            l10n?.translate('home.hadith_share') ??
                            (languageCode == 'en' ? 'Share' : 'مشاركة'),
                        onTap: () => _shareHadith(hadith, languageCode),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showHadithSheet(
    BuildContext context,
    String languageCode,
    Map<String, dynamic> hadith,
  ) async {
    final theme = Theme.of(context);
    final hadithText = _getHadithText(hadith, languageCode);
    _getCollectionTitle(languageCode);
    final hadithNumber =
        hadith['idInBook'] as int? ?? hadith['id'] as int? ?? 0;
    final author = _getAuthor(languageCode);

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
          textDirection: languageCode == 'en'
              ? TextDirection.ltr
              : TextDirection.rtl,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageCode == 'en'
                                      ? 'Hadith $hadithNumber'
                                      : 'الحديث $hadithNumber',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  author,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip:
                                l10n?.translate('home.hadith_share') ??
                                (languageCode == 'en' ? 'Share' : 'مشاركة'),
                            onPressed: () => _shareHadith(hadith, languageCode),
                            icon: const Icon(Icons.share_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      hadithText,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: languageCode == 'en'
                            ? null
                            : 'ScheherazadeNew',
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

  Widget _headerRow(
    ThemeData theme,
    String languageCode,
    String title,
    String? author,
  ) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _badge(theme, title),
                  if (author != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      author,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _accent(theme).withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            _iconCircle(
              context,
              icon: languageCode == 'en'
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              tooltip:
                  l10n?.translate('home.hadith_previous') ??
                  (languageCode == 'en' ? 'Previous' : 'السابق'),
              onTap: () {
                if (_hadiths.isEmpty) return;
                setState(() {
                  _currentIndex = (_currentIndex - 1) % _hadiths.length;
                  if (_currentIndex < 0) _currentIndex += _hadiths.length;
                });
              },
            ),
            const SizedBox(width: 6),
            _iconCircle(
              context,
              icon: languageCode == 'en'
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_new_rounded,
              tooltip:
                  l10n?.translate('home.hadith_next') ??
                  (languageCode == 'en' ? 'Next' : 'التالي'),
              onTap: () {
                if (_hadiths.isEmpty) return;
                setState(() {
                  _currentIndex = (_currentIndex + 1) % _hadiths.length;
                });
              },
            ),
          ],
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

  Widget _actionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _accent(theme)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: _accent(theme),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconCircle(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
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
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
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

  String _getCollectionTitle(String languageCode) {
    if (_metadata == null) {
      return languageCode == 'en'
          ? 'Forty Hadith of an-Nawawi'
          : 'الأربعون النووية';
    }
    final lang = languageCode == 'en' ? 'english' : 'arabic';
    final metadataLang = _metadata![lang] as Map<String, dynamic>?;
    return metadataLang?['title'] as String? ??
        (languageCode == 'en'
            ? 'Forty Hadith of an-Nawawi'
            : 'الأربعون النووية');
  }

  String _getAuthor(String languageCode) {
    if (_metadata == null) {
      return languageCode == 'en' ? 'Imam Nawawi' : 'الإمام النووي';
    }
    final lang = languageCode == 'en' ? 'english' : 'arabic';
    final metadataLang = _metadata![lang] as Map<String, dynamic>?;
    return metadataLang?['author'] as String? ??
        (languageCode == 'en' ? 'Imam Nawawi' : 'الإمام النووي');
  }

  String _getHadithText(Map<String, dynamic> hadith, String languageCode) {
    if (languageCode == 'en') {
      final english = hadith['english'] as Map<String, dynamic>?;
      if (english != null) {
        final narrator = english['narrator'] as String? ?? '';
        final text = english['text'] as String? ?? '';
        return narrator.isNotEmpty ? '$narrator\n\n$text' : text;
      }
    }
    return hadith['arabic'] as String? ?? '';
  }

  void _shareHadith(Map<String, dynamic> hadith, String languageCode) {
    final hadithText = _getHadithText(hadith, languageCode);
    final title = _getCollectionTitle(languageCode);
    final hadithNumber =
        hadith['idInBook'] as int? ?? hadith['id'] as int? ?? 0;
    final author = _getAuthor(languageCode);

    final shareText = languageCode == 'en'
        ? '$title\nHadith $hadithNumber\nBy: $author\n\n$hadithText\n\nDownload Wadhakir App: https://play.google.com/store/apps/details?id=com.bloom.wadhakir'
        : '$title\nالحديث $hadithNumber\nجمع: $author\n\n$hadithText\n\nتطبيق وذكر حمله الان: https://play.google.com/store/apps/details?id=com.bloom.wadhakir';

    SharePlus.instance.share(ShareParams(text: shareText, subject: title));
  }
}
