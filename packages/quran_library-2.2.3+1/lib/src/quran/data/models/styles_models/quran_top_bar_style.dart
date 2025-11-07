part of '/quran.dart';

/// Style configuration for Quran Top Bar (previously DefaultDrawer)
/// Allows customizing colors, texts, spacings, and icons
class QuranTopBarStyle {
  // Colors
  final Color? backgroundColor;
  final Color? textColor;
  final Color? accentColor;
  final Color? shadowColor;
  final Color? handleColor; // drag handle on bottom sheet

  // Elevation / shape
  final double? elevation;
  final double? borderRadius;

  // Spacing
  final EdgeInsetsGeometry? padding;
  final double? height;

  // Icons - can use either IconData or String path
  final String? menuIconPath;
  final IconData? menuIcon;
  final String? backIconPath;
  final IconData? backIcon;
  final String? audioIconPath;
  final IconData? audioIcon;
  final String? optionsIconPath;
  final double? iconSize;
  final Color? iconColor; // overrides textColor for icons if provided

  // Fonts dialog text overrides
  final String? fontsDialogTitle;
  final String? fontsDialogNotes;
  final String? fontsDialogDownloadingText;

  // Tab labels
  final String? tabIndexLabel;
  final String? tabSearchLabel;
  final String? tabBookmarksLabel;
  final String? tabSurahsLabel;
  final String? tabJozzLabel;

  // Visibility toggles
  final bool? showMenuButton;
  final bool? showAudioButton;
  final bool? showFontsButton;
  final bool? showBackButton;

  const QuranTopBarStyle({
    this.showBackButton,
    this.backIconPath,
    this.backIcon,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
    this.shadowColor,
    this.handleColor,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.height,
    this.menuIconPath,
    this.menuIcon,
    this.audioIconPath,
    this.audioIcon,
    this.iconSize,
    this.iconColor,
    this.fontsDialogTitle,
    this.fontsDialogNotes,
    this.fontsDialogDownloadingText,
    this.tabIndexLabel,
    this.tabSearchLabel,
    this.tabBookmarksLabel,
    this.tabSurahsLabel,
    this.tabJozzLabel,
    this.showMenuButton,
    this.showAudioButton,
    this.showFontsButton,
    this.optionsIconPath,
  });

  QuranTopBarStyle copyWith({
    String? backIconPath,
    IconData? backIcon,
    Color? backgroundColor,
    Color? textColor,
    Color? accentColor,
    Color? shadowColor,
    Color? handleColor,
    double? elevation,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    double? height,
    String? menuIconPath,
    IconData? menuIcon,
    String? audioIconPath,
    IconData? audioIcon,
    double? iconSize,
    Color? iconColor,
    String? fontsDialogTitle,
    String? fontsDialogNotes,
    String? fontsDialogDownloadingText,
    String? tabIndexLabel,
    String? tabSearchLabel,
    String? tabBookmarksLabel,
    String? tabSurahsLabel,
    String? tabJozzLabel,
    bool? showMenuButton,
    bool? showAudioButton,
    bool? showFontsButton,
    bool? showBackButton,
    String? optionsIconPath,
  }) =>
      QuranTopBarStyle(
        backIconPath: backIconPath ?? this.backIconPath,
        backIcon: backIcon ?? this.backIcon,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textColor: textColor ?? this.textColor,
        accentColor: accentColor ?? this.accentColor,
        shadowColor: shadowColor ?? this.shadowColor,
        handleColor: handleColor ?? this.handleColor,
        elevation: elevation ?? this.elevation,
        borderRadius: borderRadius ?? this.borderRadius,
        padding: padding ?? this.padding,
        height: height ?? this.height,
        menuIconPath: menuIconPath ?? this.menuIconPath,
        menuIcon: menuIcon ?? this.menuIcon,
        audioIconPath: audioIconPath ?? this.audioIconPath,
        audioIcon: audioIcon ?? this.audioIcon,
        iconSize: iconSize ?? this.iconSize,
        iconColor: iconColor ?? this.iconColor,
        fontsDialogTitle: fontsDialogTitle ?? this.fontsDialogTitle,
        fontsDialogNotes: fontsDialogNotes ?? this.fontsDialogNotes,
        fontsDialogDownloadingText:
            fontsDialogDownloadingText ?? this.fontsDialogDownloadingText,
        tabIndexLabel: tabIndexLabel ?? this.tabIndexLabel,
        tabSearchLabel: tabSearchLabel ?? this.tabSearchLabel,
        tabBookmarksLabel: tabBookmarksLabel ?? this.tabBookmarksLabel,
        tabSurahsLabel: tabSurahsLabel ?? this.tabSurahsLabel,
        tabJozzLabel: tabJozzLabel ?? this.tabJozzLabel,
        showMenuButton: showMenuButton ?? this.showMenuButton,
        showAudioButton: showAudioButton ?? this.showAudioButton,
        showFontsButton: showFontsButton ?? this.showFontsButton,
        showBackButton: showBackButton ?? this.showBackButton,
        optionsIconPath: optionsIconPath ?? this.optionsIconPath,
      );

  /// Provide sensible defaults based on theme (isDark)
  factory QuranTopBarStyle.defaults({required bool isDark}) {
    return QuranTopBarStyle(
      backIcon: Icons.arrow_back,
      backgroundColor: AppColors.getBackgroundColor(isDark),
      textColor: AppColors.getTextColor(isDark),
      accentColor: const Color(0xFF20497D),
      shadowColor: Colors.black.withValues(alpha: .2),
      handleColor: AppColors.getTextColor(isDark).withValues(alpha: 0.25),
      elevation: 5,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 55,
      menuIcon: Icons.menu,
      audioIcon: Icons.headphones,
      iconSize: 24,
      iconColor: null, // will fallback to textColor
      fontsDialogTitle: 'الخطوط',
      fontsDialogNotes:
          'لجعل مظهر المصحف مشابه لمصحف المدينة يمكنك تحميل خطوط المصحف',
      fontsDialogDownloadingText: 'جارِ التحميل',
      tabIndexLabel: 'الفهرس',
      tabSearchLabel: 'البحث',
      tabBookmarksLabel: 'الفواصل',
      tabSurahsLabel: 'السور',
      tabJozzLabel: 'الأجزاء',
      showMenuButton: true,
      showAudioButton: true,
      showFontsButton: true,
      showBackButton: false,
    );
  }
}
