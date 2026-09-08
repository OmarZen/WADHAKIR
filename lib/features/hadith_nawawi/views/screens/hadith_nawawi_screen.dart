import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/branded_header.dart';
import 'package:wadhakir/data/models/hadith_nawawi_model.dart';
import 'package:wadhakir/data/repositories/hadith_nawawi_repository_impl.dart';
import 'package:wadhakir/features/hadith_nawawi/cubit/hadith_nawawi_cubit.dart';
import 'package:wadhakir/features/hadith_nawawi/cubit/hadith_nawawi_state.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';
import 'package:wadhakir/core/widgets/app_dialog.dart';

/// Lists Imam an-Nawawi's Forty Hadith from the bundled JSON asset.
class HadithNawawiScreen extends StatelessWidget {
  const HadithNawawiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => HadithNawawiCubit(HadithNawawiRepository())..load(),
      child: Scaffold(
        body: Column(
          children: [
            BrandedHeader(
              title:
                  l10n?.translate('hadith_nawawi.title') ?? 'الأربعون النووية',
            ),
            Expanded(
              child: BlocBuilder<HadithNawawiCubit, HadithNawawiState>(
                builder: (context, state) {
                  if (state is HadithNawawiLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is HadithNawawiError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 40,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(l10n?.translate('common.error') ?? 'حدث خطأ'),
                          const SizedBox(height: 12),
                          FButton(
                            onPress: () =>
                                context.read<HadithNawawiCubit>().load(),
                            mainAxisSize: MainAxisSize.min,
                            child: Text(
                              l10n?.translate('common.retry') ??
                                  'إعادة المحاولة',
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is HadithNawawiLoaded) {
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: state.hadiths.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _HadithCard(hadith: state.hadiths[i]),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  final HadithNawawi hadith;

  const _HadithCard({required this.hadith});

  static const List<String> _arDigits = [
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  String _ar(int n) =>
      n.toString().split('').map((c) => _arDigits[int.parse(c)]).join();

  String get _referenceLabel => 'الحديث ${_ar(hadith.id)}';

  Future<void> _copy(BuildContext context) async {
    final l10n = context.l10n;
    final buffer = StringBuffer()
      ..writeln(hadith.arabic)
      ..writeln()
      ..writeln(hadith.englishText)
      ..write(_referenceLabel);
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    showFToast(
      context: context,
      title: Text(l10n?.translate('hadith_nawawi.copied') ?? 'تم النسخ'),
    );
  }

  void _shareIn(BuildContext context, {required bool arabic}) {
    Navigator.of(context).pushNamed(
      AppConstants.shareRoute,
      arguments: arabic
          ? SharePayload(
              headline: hadith.arabic,
              categoryLabel: 'الأربعون النووية',
              reference: _referenceLabel,
              variant: ShareCardVariant.passage,
            )
          : SharePayload(
              headline: hadith.englishText,
              headlineRtl: false,
              categoryLabel: 'Forty Hadith of an-Nawawi',
              reference: 'Hadith ${hadith.id}',
              variant: ShareCardVariant.passage,
            ),
    );
  }

  /// Ask which language to share, then open the branded share card for it.
  Future<void> _share(BuildContext context) async {
    final l10n = context.l10n;
    final hasEnglish = hadith.englishText.isNotEmpty;
    if (!hasEnglish) {
      _shareIn(context, arabic: true);
      return;
    }
    await showFDialog<void>(
      context: context,
      builder: (dialogContext, style, animation) => AppDialog(
        title: Text(
          l10n?.translate('hadith_nawawi.share_lang') ?? 'لغة المشاركة',
        ),
        body: Text(
          l10n?.translate('hadith_nawawi.share_lang_hint') ??
              'اختر لغة الحديث المراد مشاركته',
        ),
        actions: [
          FButton(
            onPress: () {
              Navigator.of(dialogContext).pop();
              _shareIn(context, arabic: true);
            },
            child: Text(l10n?.translate('hadith_nawawi.arabic') ?? 'العربية'),
          ),
          FButton(
            onPress: () {
              Navigator.of(dialogContext).pop();
              _shareIn(context, arabic: false);
            },
            variant: FButtonVariant.outline,
            child: Text(l10n?.translate('hadith_nawawi.english') ?? 'English'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final hasEnglish = hadith.englishText.isNotEmpty;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${l10n?.translate('hadith_nawawi.hadith') ?? 'الحديث'} '
                    '${_ar(hadith.id)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.menu_book_rounded, size: 20, color: cs.primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hadith.arabic,
              textAlign: TextAlign.justify,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'ScheherazadeNew',
                height: 1.9,
                fontSize: 20,
              ),
            ),
            if (hasEnglish) ...[
              const SizedBox(height: 14),
              Divider(color: cs.onSurface.withValues(alpha: 0.08), height: 1),
              const SizedBox(height: 12),
              if (hadith.englishNarrator.isNotEmpty)
                Text(
                  hadith.englishNarrator,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              if (hadith.englishNarrator.isNotEmpty) const SizedBox(height: 4),
              Text(
                hadith.englishText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: cs.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: () => _copy(context),
                    variant: FButtonVariant.outline,
                    prefix: const Icon(Icons.copy_rounded, size: 18),
                    child: Text(l10n?.translate('hadith_nawawi.copy') ?? 'نسخ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FButton(
                    onPress: () => _share(context),
                    prefix: const Icon(Icons.ios_share_rounded, size: 18),
                    child: Text(
                      l10n?.translate('hadith_nawawi.share') ?? 'مشاركة',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
