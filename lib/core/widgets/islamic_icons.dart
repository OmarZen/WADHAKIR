import 'package:flutter/material.dart';

/// Custom Islamic-themed icons using built-in Flutter icons
class IslamicIcons {
  // Prayer time icons
  static const IconData fajr = Icons.wb_twilight;
  static const IconData sunrise = Icons.wb_sunny_outlined;
  static const IconData dhuhr = Icons.wb_sunny;
  static const IconData asr = Icons.sunny_snowing;
  static const IconData maghrib = Icons.nightlight_round;
  static const IconData isha = Icons.nights_stay;
  static const IconData prayer = Icons.access_time;

  // Decorative elements
  static const IconData mosque = Icons.mosque_rounded;
  static const IconData lantern = Icons.lightbulb_outline;
  static const IconData ornament = Icons.auto_awesome;
  static const IconData calendar = Icons.calendar_month;
  static const IconData quran = Icons.menu_book_rounded;
  static const IconData tasbih = Icons.grain_rounded;
  static const IconData compass = Icons.explore;
  static const IconData settings = Icons.settings;

  // Hasanat (good deeds) tracking icons
  static const IconData virtue = Icons.volunteer_activism;
  static const IconData reward = Icons.stars;
  static const IconData achievement = Icons.emoji_events;
  static const IconData charity = Icons.favorite;
  static const IconData fasting = Icons.hourglass_empty;
  static const IconData dhikr = Icons.all_inclusive;
  static const IconData sadaqah = Icons.attach_money;
  static const IconData dua = Icons.front_hand;
  static const IconData goodDeed = Icons.lightbulb;
  static const IconData progress = Icons.trending_up;
  static const IconData streak = Icons.local_fire_department;

  // Placeholder for mosque icon
  static Widget mosqueIcon({double size = 24, Color? color}) {
    return Icon(
      Icons.mosque_rounded,
      size: size,
      color: color,
    );
  }

  // Placeholder for calendar icon
  static Widget calendarIcon({double size = 24, Color? color}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.calendar_month,
          size: size,
          color: color,
        ),
        Positioned(
          bottom: size * 0.32,
          child: Icon(
            Icons.mosque_rounded,
            size: size * 0.4,
            color: color,
          ),
        ),
      ],
    );
  }

  // Placeholder for ornament icon
  static Widget ornamentIcon({double size = 24, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: size * 0.5,
          color: color,
        ),
        Icon(
          Icons.auto_awesome,
          size: size,
          color: color,
        ),
        Icon(
          Icons.star,
          size: size * 0.5,
          color: color,
        ),
      ],
    );
  }

  // Placeholder for lantern icon
  static Widget lanternIcon({double size = 24, Color? color}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.lightbulb,
          size: size,
          color: color,
        ),
        Positioned(
          top: size * 0.23,
          child: Icon(
            Icons.horizontal_rule,
            size: size * 0.5,
            color: color,
          ),
        ),
      ],
    );
  }

  // Hasanat (reward) icon
  static Widget hasanatIcon({double size = 24, Color? color}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.star_border_rounded,
          size: size,
          color: color,
        ),
        Icon(
          Icons.star_rounded,
          size: size * 0.7,
          color: color,
        ),
      ],
    );
  }

  // Virtuous deed icon
  static Widget virtuousDeedIcon({double size = 24, Color? color}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.volunteer_activism,
          size: size,
          color: color,
        ),
        Positioned(
          bottom: size * 0.1,
          right: size * 0.1,
          child: Icon(
            Icons.check_circle_outline,
            size: size * 0.4,
            color: color,
          ),
        ),
      ],
    );
  }

  // Achievement icon for tracking progress
  static Widget achievementIcon({double size = 24, Color? color}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.emoji_events,
          size: size,
          color: color,
        ),
        Positioned(
          top: size * 0.2,
          child: Icon(
            Icons.star,
            size: size * 0.3,
            color: color,
          ),
        ),
      ],
    );
  }
}
