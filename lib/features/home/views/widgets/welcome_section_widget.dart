import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/core/utils/date_utils.dart';
import '../../../../core/constants/islamic_quotes.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wadhakir/features/home/cubit/unsplash_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/about_developer_dialog.dart';
import 'package:wadhakir/features/home/views/widgets/hijri_calendar_bottom_sheet.dart';

class WelcomeSectionWidget extends StatelessWidget {
  final UnsplashPhoto? mosqueImage;
  final HijriDateTime hijriDate;

  const WelcomeSectionWidget({
    super.key,
    required this.mosqueImage,
    required this.hijriDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = PlatformUtils.isDesktop;

    // Responsive sizing based on platform
    final maxWidth = isDesktop ? 1400.0 : double.infinity;
    final horizontalPadding = _getResponsivePadding(size.width, isDesktop);
    final verticalPadding = _getResponsiveVerticalPadding(
      size.height,
      isDesktop,
    );
    final borderRadius = isDesktop ? 24.0 : 32.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          ),
        ),
        child: Stack(
          children: [
            // Mosque Background Image
            if (mosqueImage != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  ),
                  child: _buildMosqueBackground(context, mosqueImage!),
                ),
              ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: isDesktop ? 0.2 : 0.3),
                      Colors.black.withValues(alpha: isDesktop ? 0.5 : 0.7),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Header Content
            SafeArea(
              bottom: false,
              maintainBottomViewPadding: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Row with Date and Actions
                    _buildHeaderRow(context, size, isDesktop, l10n, now),

                    SizedBox(height: isDesktop ? 24 : 16),

                    // Welcome Message Section
                    _buildWelcomeSection(context, size, isDesktop, l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    Size size,
    bool isDesktop,
    AppLocalizations? l10n,
    DateTime now,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date Card - Clickable
        Flexible(child: _buildDateCard(context, size, isDesktop, l10n, now)),

        SizedBox(width: isDesktop ? 20 : 12),

        // Action Buttons
        _buildActionButtons(context, size, isDesktop),
      ],
    );
  }

  Widget _buildDateCard(
    BuildContext context,
    Size size,
    bool isDesktop,
    AppLocalizations? l10n,
    DateTime now,
  ) {
    final iconSize = _getResponsiveIconSize(size.width, isDesktop, small: true);
    final fontSize = _getResponsiveFontSize(size.width, isDesktop, scale: 0.85);
    final smallFontSize = _getResponsiveFontSize(
      size.width,
      isDesktop,
      scale: 0.7,
    );
    final cardPadding = isDesktop ? 16.0 : size.width * 0.03;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                HijriCalendarBottomSheet(initialDate: hijriDate),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gregorian Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: iconSize,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      SizedBox(width: isDesktop ? 8 : 6),
                      Text(
                        '${now.day} ${AppDateUtils.getGregorianMonthName(now.month, l10n)}',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.mosque,
                        size: iconSize * 0.9,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      SizedBox(width: isDesktop ? 8 : 6),
                      Text(
                        AppDateUtils.getShortFormattedHijriDate(
                          hijriDate,
                          l10n,
                        ),
                        style: TextStyle(
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(width: isDesktop ? 12 : 8),
              // Click indicator
              Container(
                padding: EdgeInsets.all(isDesktop ? 8 : 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: iconSize * 0.7,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Size size, bool isDesktop) {
    final buttonSize = _getResponsiveIconSize(size.width, isDesktop);
    final buttonPadding = isDesktop ? 12.0 : size.width * 0.022;
    final spacing = isDesktop ? 16.0 : size.width * 0.012;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CompactIconButton(
          icon: Icons.info_outline,
          size: buttonSize,
          padding: buttonPadding,
          onPressed: () => showAboutDeveloperDialog(context),
        ),
        SizedBox(width: spacing),
        _CompactIconButton(
          icon: Icons.compass_calibration_rounded,
          size: buttonSize,
          padding: buttonPadding,
          onPressed: () => Navigator.pushNamed(context, '/campus'),
        ),
        SizedBox(width: spacing),
        _CompactIconButton(
          icon: Icons.radio_rounded,
          size: buttonSize,
          padding: buttonPadding,
          onPressed: () => Navigator.pushNamed(context, '/radio'),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(
    BuildContext context,
    Size size,
    bool isDesktop,
    AppLocalizations? l10n,
  ) {
    final titleFontSize = _getResponsiveFontSize(
      size.width,
      isDesktop,
      scale: 1.8,
    );
    final subtitleFontSize = _getResponsiveFontSize(
      size.width,
      isDesktop,
      scale: 0.9,
    );
    final quoteFontSize = _getResponsiveFontSize(
      size.width,
      isDesktop,
      scale: 0.8,
    );
    final sourceFontSize = _getResponsiveFontSize(
      size.width,
      isDesktop,
      scale: 0.65,
    );
    final iconSize = _getResponsiveIconSize(size.width, isDesktop, small: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Text
        Text(
          l10n?.translate('home.welcome_message') ?? 'السلام عليكم',
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isDesktop ? 8 : 6),
        Text(
          l10n?.translate('home.app_name') ?? 'وذكّر',
          style: TextStyle(
            fontSize: titleFontSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Almarai',
          ),
        ),
        SizedBox(height: isDesktop ? 12 : 8),

        // Islamic Quotes with source badge
        Builder(
          builder: (context) {
            final quote = IslamicQuotes.getRandomQuote();
            final languageCode = Localizations.localeOf(context).languageCode;
            final quoteText = languageCode == 'en' ? quote.textEn : quote.text;
            final quoteSource = languageCode == 'en'
                ? quote.sourceEn
                : quote.source;

            return Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quoteText,
                    maxLines: isDesktop ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: quoteFontSize,
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      fontFamily: languageCode == 'en'
                          ? null
                          : 'ScheherazadeNew',
                    ),
                  ),
                  SizedBox(height: isDesktop ? 8 : 6),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: iconSize * 0.9,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      SizedBox(width: isDesktop ? 8 : 6),
                      Flexible(
                        child: Text(
                          quoteSource,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: sourceFontSize,
                            fontWeight: FontWeight.w500,
                            fontFamily: languageCode == 'en' ? null : 'Almarai',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Responsive sizing helpers
  double _getResponsivePadding(double width, bool isDesktop) {
    if (isDesktop) {
      if (width > 1400) return 48.0;
      if (width > 1200) return 40.0;
      return 32.0;
    }
    return width * 0.04; // Mobile: 4% of width
  }

  double _getResponsiveVerticalPadding(double height, bool isDesktop) {
    if (isDesktop) {
      return 24.0;
    }
    return height * 0.015; // Mobile: 1.5% of height
  }

  double _getResponsiveFontSize(
    double width,
    bool isDesktop, {
    double scale = 1.0,
  }) {
    if (isDesktop) {
      // Desktop: Fixed sizes with scale
      final baseSize = 16.0;
      return baseSize * scale;
    }
    // Mobile: Relative to width
    return (width * 0.035) * scale;
  }

  double _getResponsiveIconSize(
    double width,
    bool isDesktop, {
    bool small = false,
  }) {
    if (isDesktop) {
      return small ? 18.0 : 24.0;
    }
    return small ? width * 0.032 : width * 0.048;
  }

  Widget _buildMosqueBackground(
    BuildContext context,
    UnsplashPhoto mosqueImage,
  ) {
    // Check if it's a network image or local asset
    if (mosqueImage.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        key: ValueKey(mosqueImage.id),
        imageUrl: mosqueImage.imageUrl,
        fit: BoxFit.cover,
        color: Colors.black.withValues(alpha: 0.1),
        colorBlendMode: BlendMode.darken,
        maxHeightDiskCache: 1500,
        memCacheWidth: 1000,
        cacheKey: "mosque_${mosqueImage.id}",
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          log('Error loading image: $error for URL: $url');
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: const Icon(Icons.error, color: Colors.white),
          );
        },
      );
    } else {
      // Local asset image
      return Image.asset(
        mosqueImage.imageUrl,
        key: ValueKey(mosqueImage.id),
        fit: BoxFit.cover,
        color: Colors.black.withValues(alpha: 0.1),
        colorBlendMode: BlendMode.darken,
        errorBuilder: (context, error, stackTrace) {
          log(
            'Error loading asset image: $error for path: ${mosqueImage.imageUrl}',
          );
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: const Icon(Icons.error, color: Colors.white),
          );
        },
      );
    }
  }
}

// Compact Icon Button Widget for Header Actions
class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double padding;
  final VoidCallback onPressed;

  const _CompactIconButton({
    required this.icon,
    required this.size,
    required this.padding,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Icon(icon, color: Colors.white, size: size),
          ),
        ),
      ),
    );
  }
}
