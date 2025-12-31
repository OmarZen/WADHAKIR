import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/core/utils/date_utils.dart';
import '../../../../core/constants/islamic_quotes.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Mosque Background Image
          if (mosqueImage != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: _buildMosqueBackground(context, mosqueImage!),
              ),
            ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Date and Actions
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.015,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact Date Card - Now Clickable!
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => HijriCalendarBottomSheet(
                                initialDate: hijriDate,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.03,
                              vertical: size.height * 0.01,
                            ),
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
                                          size: size.width * 0.032,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                        SizedBox(width: size.width * 0.015),
                                        Text(
                                          '${now.day} ${AppDateUtils.getGregorianMonthName(now.month, l10n)}',
                                          style: TextStyle(
                                            fontSize: size.width * 0.033,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: size.height * 0.003),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.mosque,
                                          size: size.width * 0.03,
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                        ),
                                        SizedBox(width: size.width * 0.015),
                                        Text(
                                          AppDateUtils
                                              .getShortFormattedHijriDate(
                                                  hijriDate, l10n),
                                          style: TextStyle(
                                            fontSize: size.width * 0.028,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(width: size.width * 0.025),
                                // Click indicator
                                Container(
                                  padding: EdgeInsets.all(size.width * 0.015),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: size.width * 0.03,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Spacer(),

                      // Compact Action Buttons - at the end of the row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Info Button
                          _CompactIconButton(
                            icon: Icons.info_outline,
                            size: size.width * 0.048,
                            padding: size.width * 0.022,
                            onPressed: () => showAboutDeveloperDialog(context),
                          ),
                          SizedBox(width: size.width * 0.012),
                          // Qibla Button
                          _CompactIconButton(
                            icon: Icons.compass_calibration_rounded,
                            size: size.width * 0.048,
                            padding: size.width * 0.022,
                            onPressed: () =>
                                Navigator.pushNamed(context, '/campus'),
                          ),
                          SizedBox(width: size.width * 0.012),
                          // Radio Button
                          _CompactIconButton(
                            icon: Icons.radio_rounded,
                            size: size.width * 0.048,
                            padding: size.width * 0.022,
                            onPressed: () =>
                                Navigator.pushNamed(context, '/radio'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Welcome Message Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                  ).copyWith(bottom: size.height * 0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Text
                      Text(
                        l10n?.translate('home.welcome_message') ??
                            'السلام عليكم',
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: size.height * 0.006),
                      Text(
                        l10n?.translate('home.app_name') ?? 'وذكّر',
                        style: TextStyle(
                          fontSize: size.width * 0.065,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),
                      SizedBox(height: size.height * 0.008),

                      // Islamic Quotes with source badge
                      Builder(
                        builder: (context) {
                          final quote = IslamicQuotes.getRandomQuote();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quote.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: size.width * 0.03,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: size.height * 0.006),
                              Row(
                                children: [
                                  Icon(
                                    Icons.menu_book,
                                    size: size.width * 0.028,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  SizedBox(width: size.width * 0.01),
                                  Flexible(
                                    child: Text(
                                      quote.source,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.75),
                                        fontSize: size.width * 0.025,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMosqueBackground(
      BuildContext context, UnsplashPhoto mosqueImage) {
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
          log('Error loading asset image: $error for path: ${mosqueImage.imageUrl}');
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
            child: Icon(
              icon,
              color: Colors.white,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}
