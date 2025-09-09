import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:wadhakir/core/utils/date_utils.dart';
import '../../../../core/constants/islamic_quotes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wadhakir/features/home/cubit/unsplash_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/home/views/widgets/about_developer_dialog.dart';

class WelcomeSectionWidget extends StatelessWidget {
  final UnsplashPhoto? mosqueImage;
  final HijriCalendar hijriDate;

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
                  padding: EdgeInsets.only(
                    left: size.width * 0.05,
                    right: size.width * 0.05,
                    top: size.height * 0.02,
                    bottom: size.height * 0.02,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Date Card
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Day Number
                          Container(
                            padding: EdgeInsets.all(size.width * 0.02),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              now.day.toString(),
                              style: TextStyle(
                                fontSize: size.width * 0.06,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: size.width * 0.03),
                          // Month and Hijri Date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Gregorian Date
                              Text(
                                AppDateUtils.getGregorianMonthName(
                                    now.month, l10n),
                                style: TextStyle(
                                  fontSize: size.width * 0.035,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: size.height * 0.005),
                              // Hijri Date
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.040,
                                  vertical: size.height * 0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppDateUtils.getShortFormattedHijriDate(
                                      hijriDate, l10n),
                                  style: TextStyle(
                                    fontSize: size.width * 0.025,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: size.width * 0.03),
                          // Info about the developer
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: size.width * 0.06,
                              ),
                              onPressed: () {
                                showAboutDeveloperDialog(context);
                              },
                            ),
                          ),
                        ],
                      ),

                      Spacer(),

                      // Action Buttons
                      Row(
                        children: [
                          // Campus/Qibla Button
                          Container(
                            margin: EdgeInsets.only(right: size.width * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.compass_calibration_rounded,
                                color: Colors.white,
                                size: size.width * 0.06,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/campus');
                              },
                              tooltip:
                                  l10n?.translate('home.qibla') ?? 'القبلة',
                            ),
                          ),

                          // Radio Button
                          Container(
                            margin: EdgeInsets.only(right: size.width * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.radio_rounded,
                                color: Colors.white,
                                size: size.width * 0.06,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/radio');
                              },
                              tooltip:
                                  l10n?.translate('home.radio') ?? 'الراديو',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Welcome Message Section
                Padding(
                  padding: EdgeInsets.only(
                    left: size.width * 0.05,
                    right: size.width * 0.05,
                    bottom: size.height * 0.03,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Text
                      Text(
                        l10n?.translate('home.welcome_message') ??
                            'السلام عليكم',
                        style: TextStyle(
                          fontSize: size.width * 0.045,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        l10n?.translate('home.app_name') ?? 'وذكّر',
                        style: TextStyle(
                          fontSize: size.width * 0.08,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),

                      // Islamic Quotes with source badge
                      Builder(
                        builder: (context) {
                          final quote = IslamicQuotes.getRandomQuote();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quote.text,
                                style: TextStyle(
                                  fontSize: size.width * 0.035,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: size.height * 0.008),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.028,
                                  vertical: size.height * 0.004,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.menu_book_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: size.width * 0.01),
                                    Text(
                                      quote.source,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: size.width * 0.028,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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
