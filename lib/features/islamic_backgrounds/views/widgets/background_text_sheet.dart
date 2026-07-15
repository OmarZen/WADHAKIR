import 'package:flutter/material.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/islamic_backgrounds/models/background_quote.dart';
import 'package:wadhakir/features/islamic_backgrounds/services/background_quotes_service.dart';

/// Opens the text editor sheet. Returns the chosen [BackgroundQuote] (custom
/// text or a ready-made phrase), or null if dismissed.
Future<BackgroundQuote?> showBackgroundTextSheet(
  BuildContext context, {
  required String initialText,
}) {
  return showModalBottomSheet<BackgroundQuote>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BackgroundTextSheet(initialText: initialText),
  );
}

/// Lets the user type a custom phrase or pick a ready-made one from the
/// curated verses, the app's existing quotes, or the 40 Nawawi hadith.
class BackgroundTextSheet extends StatefulWidget {
  const BackgroundTextSheet({super.key, required this.initialText});

  final String initialText;

  @override
  State<BackgroundTextSheet> createState() => _BackgroundTextSheetState();
}

class _BackgroundTextSheetState extends State<BackgroundTextSheet> {
  final _service = BackgroundQuotesService();
  late final TextEditingController _controller;

  /// 0 = custom text, otherwise a [QuoteSource] tab.
  int _tab = 0;
  Future<List<BackgroundQuote>>? _quotesFuture;
  QuoteSource _loadedSource = QuoteSource.curated;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectTab(int tab, [QuoteSource? source]) {
    setState(() {
      _tab = tab;
      if (source != null &&
          (_quotesFuture == null || _loadedSource != source)) {
        _loadedSource = source;
        _quotesFuture = _service.forSource(source);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.title_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.translate('islamic_backgrounds.text') ?? 'النص',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _tabChip(
                    l10n?.translate('islamic_backgrounds.custom_text') ??
                        'نص مخصص',
                    0,
                  ),
                  _tabChip(
                    l10n?.translate('islamic_backgrounds.verses') ??
                        'آيات وأذكار',
                    1,
                    QuoteSource.curated,
                  ),
                  _tabChip(
                    l10n?.translate('islamic_backgrounds.quotes') ?? 'اقتباسات',
                    2,
                    QuoteSource.appQuotes,
                  ),
                  _tabChip(
                    l10n?.translate('islamic_backgrounds.hadith') ?? 'الأربعون',
                    3,
                    QuoteSource.hadith,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _tab == 0 ? _customEditor(theme, l10n) : _quoteList(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, int tab, [QuoteSource? source]) {
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _selectTab(tab, source),
      ),
    );
  }

  Widget _customEditor(ThemeData theme, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.top,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'ScheherazadeNew',
                fontSize: 20,
                height: 1.8,
              ),
              decoration: InputDecoration(
                hintText:
                    l10n?.translate('islamic_backgrounds.text_hint') ??
                    'اكتب نصك هنا…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context, BackgroundQuote(text));
            },
            icon: const Icon(Icons.check_rounded),
            label: Text(
              l10n?.translate('islamic_backgrounds.apply_text') ?? 'تطبيق النص',
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteList(ThemeData theme) {
    return FutureBuilder<List<BackgroundQuote>>(
      future: _quotesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final quotes = snapshot.data ?? const <BackgroundQuote>[];
        if (quotes.isEmpty) {
          return const SizedBox.shrink();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: quotes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final q = quotes[i];
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pop(context, q),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  ),
                  color: theme.colorScheme.primary.withValues(alpha: 0.04),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      q.text,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 19,
                        height: 1.8,
                      ),
                    ),
                    if (q.reference != null && q.reference!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        q.reference!,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
