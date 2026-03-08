import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';
import '../../../../core/localization/app_localizations.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return QuranLibraryScreen(
      parentContext: context,
      isDark: isDarkMode,
      isShowTabBar: true,
      isShowAudioSlider: true,
      showAyahBookmarkedIcon: true,
      enableWordSelection: true,
      appLanguageCode: l10n?.locale.languageCode ?? 'en',
      ayahIconColor: theme.colorScheme.primary,
      ayahSelectedFontColor: theme.colorScheme.onSurface,
      backgroundColor: theme.colorScheme.surface,
      ayahSelectedBackgroundColor: theme.colorScheme.primary.withValues(
        alpha: 0.25,
      ),
      downloadFontsDialogStyle: DownloadFontsDialogStyle(
        iconWidget: Icon(
          Icons.font_download_outlined,
          color: theme.colorScheme.primary,
        ),
        backgroundColor: theme.colorScheme.surface,
        dividerColor: isDarkMode
            ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
            : theme.colorScheme.onSurface.withValues(alpha: 0.08),
        downloadButtonBackgroundColor: isDarkMode
            ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
            : theme.colorScheme.onSurface.withValues(alpha: 0.08),
        downloadingStyle: TextStyle(color: theme.colorScheme.onSurface),
        iconColor: theme.colorScheme.primary,
        linearProgressBackgroundColor: isDarkMode
            ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
            : theme.colorScheme.onSurface.withValues(alpha: 0.08),
        linearProgressColor: theme.colorScheme.primary,
        notesColor: theme.colorScheme.onSurface,
        notesStyle: TextStyle(color: theme.colorScheme.onSurface),
        titleColor: isDarkMode
            ? theme.colorScheme.onSurface.withValues(alpha: 0.87)
            : theme.colorScheme.onSurface.withValues(alpha: 0.98),
        titleStyle: TextStyle(
          color: isDarkMode
              ? theme.colorScheme.onSurface.withValues(alpha: 0.87)
              : theme.colorScheme.onSurface.withValues(alpha: 0.98),
        ),
        tajweedOptionNames:
            l10n?.translate('quran.tajweed_options') ?? 'Tajweed Options',
      ),
      surahInfoStyle: SurahInfoStyle(
        closeIconColor: isDarkMode
            ? theme.colorScheme.onSurface.withValues(alpha: 0.87)
            : theme.colorScheme.onSurface.withValues(alpha: 0.98),
        surahNameColor: theme.colorScheme.onSurface,
        surahNumberColor: theme.colorScheme.surface,
        surahNumberDecorationColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        primaryColor: theme.colorScheme.primary,
        titleColor: isDarkMode
            ? theme.colorScheme.onSurface.withValues(alpha: 0.87)
            : theme.colorScheme.surface.withValues(alpha: 0.98),
        indicatorColor: theme.colorScheme.primary,
        // Text color for ayah count and tab labels - white in light mode to show over primary color
        textColor: isDarkMode
            ? Colors.white
            : theme.colorScheme.onSurface.withValues(alpha: 0.87),
        ayahCount: l10n?.translate('quran.ayah_count') ?? ' Ayah Count',
        firstTabText: l10n?.translate('quran.surah_names') ?? 'Surah Names',
        secondTabText: l10n?.translate('quran.surah_info') ?? 'Surah Info',
      ),
      topBarStyle: QuranTopBarStyle(
        backgroundColor: theme.colorScheme.surface,
        textColor: isDarkMode
            ? theme.colorScheme.onSurface.withValues(alpha: 0.87)
            : theme.colorScheme.onSurface.withValues(alpha: 0.98),
        iconColor: theme.colorScheme.primary,
        accentColor: theme.colorScheme.primary,
        shadowColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        handleColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
        menuIconPath: 'assets/icons/custom_menu.svg',
        audioIconPath: 'assets/icons/custom_audio.svg',
        // Translations
        fontsDialogTitle:
            l10n?.translate('quran.fonts_dialog_title') ?? 'Fonts',
        fontsDialogNotes: l10n?.translate('quran.fonts_dialog_notes') ??
            'Download Quran fonts to match Medina Mushaf style',
        fontsDialogDownloadingText:
            l10n?.translate('common.downloading') ?? 'Downloading',
        tabIndexLabel: l10n?.translate('quran.tab_index') ?? 'Index',
        tabSearchLabel: l10n?.translate('quran.tab_search') ?? 'Search',
        tabBookmarksLabel:
            l10n?.translate('quran.tab_bookmarks') ?? 'Bookmarks',
        tabSurahsLabel: l10n?.translate('quran.tab_surahs') ?? 'Surahs',
        tabJozzLabel: l10n?.translate('quran.tab_juzz') ?? 'Juzz',
        tabLabelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isDarkMode
              ? theme.colorScheme.onSurface.withValues(alpha: 0.87)
              : theme.colorScheme.onSurface.withValues(alpha: 0.98),
        ),
        showTajweedButton: true,
        quranTabText: l10n?.translate('quran.quran') ?? 'Quran',
        tenRecitationsTabText:
            l10n?.translate('quran.ten_recitations') ?? 'Ten Recitations',
        showAudioButton: true,
        showFontsButton: true,
        showMenuButton: true,
      ),
      topBottomQuranStyle: TopBottomQuranStyle(
        sajdaName: l10n?.translate('quran.sajda') ?? 'Sajda',
      ),
    );
  }
}
