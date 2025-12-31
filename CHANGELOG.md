# Changelog 📝

All notable changes to Wadhakir will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.3.0] - 2025-12-31

### Added - Fasting Notifications System
- **Monday and Thursday Fasting Reminders**:
  - Configurable notification time (default: 21:00 / 9:00 PM)
  - Notifications sent the night before fasting days
  - Weekly recurring schedule using NotificationCalendar
  - Vibration support for fasting notifications
  - Arabic day names in notification content
  - Dedicated notification IDs: Monday (200), Thursday (201)
  - Individual toggles for Monday and Thursday
  - Custom time picker with 12-hour Arabic format display
  - Conditional UI: time picker shows only when at least one day enabled

- **Data Model Extensions**:
  - Extended NotificationSettingsModel with 4 required fields
  - mondayFastingEnabled, thursdayFastingEnabled (bool)
  - fastingNotificationTime (String in HH:mm format)
  - fastingVibration (bool)
  - Full integration with copyWith, toJson, fromJson, props

- **Repository Layer**:
  - scheduleFastingNotification() method
  - cancelFastingNotification() method
  - scheduleAllFastingNotifications() method
  - Dedicated _channelKeyFasting notification channel
  - High importance channel with proper Arabic/English naming

- **State Management**:
  - toggleMondayFasting() in SettingsCubit
  - toggleThursdayFasting() in SettingsCubit
  - setFastingNotificationTime() in SettingsCubit
  - toggleFastingVibration() in SettingsCubit
  - Each method: updates model → saves → reschedules notifications

- **UI Components**:
  - FastingNotificationSettingsWidget (new file)
  - buildMondayFastingToggle() method
  - buildThursdayFastingToggle() method
  - buildFastingTimePicker() method
  - Time picker with custom themed dialog
  - 12-hour format display with Arabic AM/PM (ص/م)

- **Localization**:
  - fasting_notifications key (AR/EN)
  - fasting_monday key with subtitle (AR/EN)
  - fasting_thursday key with subtitle (AR/EN)
  - fasting_time key with subtitle (AR/EN)

### Improved - Settings UI Complete Modernization
- **Design System Established**:
  - Consistent color patterns across all components
  - Selector backgrounds: isDark ? primaryContainer(0.2) : surface
  - Enabled states: isDark ? primary(0.15) : primary(0.08)
  - Icon containers: Solid primary with onPrimary contrast
  - Borders: onSurface(0.2) with 1px width
  - Standardized spacing: 12px/6px margins, 12px/8px padding
  - Border radius: 12px (components), 20px (dialogs)
  - Icon sizes: 18px standard (down from 24-30px)
  - Font sizes: 14px title, 12px subtitle/body

- **Animation Cleanup (Performance)**:
  - Removed 50+ TweenAnimationBuilder instances
  - Removed all Transform animations (rotate, translate, scale)
  - Removed Opacity fade animations
  - Removed continuous looping animations
  - Removed gradient backgrounds (replaced with solid colors)
  - Eliminated AnimatedBuilder overhead
  - 30-50% code reduction across components

- **11 Components Modernized**:
  1. **SettingsSection** (~15% smaller)
     - StatefulWidget → StatelessWidget
     - Removed hover animations and AnimatedController
     - Icon: 24px → 20px, 8px padding
     - Title: 17px → 15px, subtitle: 13px → 12px
  
  2. **ThemeSelectorWidget** (~33% smaller)
     - StatefulWidget → StatelessWidget
     - Removed gradient icon container
     - Dialog: showDialog → showGeneralDialog
     - Icon: 22px → 18px
  
  3. **LanguageSelectorWidget** (~38% smaller)
     - StatefulWidget → StatelessWidget
     - Removed slide-in animations
     - Flag size: 32px → 28px
  
  4. **NotificationMasterToggle**
     - Removed TweenAnimationBuilder wrapper
     - Removed gradient backgrounds
     - Compact padding and margins
  
  5. **PersistentNotificationToggle**
     - Same modernization as NotificationMasterToggle
     - Consistent with design system
  
  6. **NotificationTimingSelector**
     - Removed slide animations
     - Dialog with scale+fade transition
  
  7. **PrayerNotificationsSettings** (~35% smaller)
     - **Major Change**: ExpansionTile → Dialog conversion
     - showGeneralDialog with SingleChildScrollView
     - 5 prayer tiles: Fajr, Dhuhr, Asr, Maghrib, Isha
     - Compact tiles with zero margins in dialog
  
  8. **FastingNotificationSettings** (NEW FILE)
     - 3 static build methods
     - Time picker with Arabic format
     - Follows all established patterns
  
  9. **AdhanSoundSelector** (~35% smaller)
     - Removed Transform.translate wrapper
     - Removed slide-in animations for options
     - Icon: 24px → 18px
  
  10. **AboutSectionWidgets**
      - All 5 tiles modernized: About, Feedback, Website, Privacy, Rate
      - showDialog → showGeneralDialog
      - App icon: 80x80 → 70x70, icon: 40px → 36px
      - Consistent container wrappers
  
  11. **Settings Header** (~27% smaller)
      - Removed AnimatedBuilder wrapper
      - Removed 4 TweenAnimationBuilder animations
      - Removed gradient backgrounds and box shadows
      - Icon container: 60x60 → 48x48
      - Title: 24px → 20px, description: 13px → 12px
      - Stats bar: Compact padding, removed animations

- **Dialog Standardization**:
  - All 6 dialogs use showGeneralDialog
  - Scale + fade transitions (250ms, Curves.easeOut)
  - Consistent border radius (20px)
  - Compact padding (20px/16px)

### Fixed - Native Compatibility
- **Android Build System**:
  - Resolved Kotlin compilation cache issues
  - Fixed incremental build problems
  - Updated Gradle configuration for stability
  - Improved build reliability

### Changed - Code Quality
- **Architecture Improvements**:
  - 3 StatefulWidget → StatelessWidget conversions
  - Better separation of concerns
  - Cleaner, more maintainable code
  - Consistent design patterns

- **Performance Optimizations**:
  - Removed continuous animation loops
  - Reduced widget rebuilds significantly
  - Better memory usage (no animation controllers)
  - Simplified widget trees
  - Improved app responsiveness

### Technical Details
- **Files Modified**: 16 files
- **Lines Changed**: +2,318 insertions, -2,109 deletions
- **New Files**: 1 (fasting_notification_settings_widget.dart)
- **Quality Assurance**: All flutter analyze checks passing
- **Backward Compatibility**: Full - no breaking changes
- **Migration**: Automatic via model defaults

### User-Facing Changes
- **New Features**:
  - Monday/Thursday fasting notification reminders
  - Configurable reminder time with visual time picker
  
- **UI/UX Improvements**:
  - Cleaner, more professional interface
  - Faster, more responsive settings screen
  - Better dark mode support with improved contrast
  - Compact design showing more content
  - Prayer customization via dialog (cleaner than ExpansionTile)
  
- **Performance**:
  - Reduced animations for snappier responses
  - Better accessibility (less motion, clearer UI)
  - Improved battery life (no continuous animations)

### Migration Notes
- Update from 2.2.0 by installing 2.3.0+7
- All existing settings preserved
- New fasting notification fields have sensible defaults
- First launch after update: all notifications will be rescheduled
- No user action required

## [2.2.0] - 2025-12-14

### Added - Hadith Library Feature
- **Complete Hadith Library System** with comprehensive Islamic hadith collections
  - 17 major hadith collections with multilingual support
  - Data models: `bookmark_model.dart`, `hadith_model.dart`, `hadith_collection_metadata.dart`
  - Domain layer with repositories and use cases:
    - `bookmark_repository.dart` and `hadith_repository.dart`
    - `add_bookmark_usecase.dart`, `remove_bookmark_usecase.dart`, `get_all_bookmarks_usecase.dart`
    - `get_all_collections_usecase.dart`, `get_books_list_usecase.dart`, `get_hadith_book_usecase.dart`
  - State management with BLoC pattern:
    - `hadith_library_cubit.dart` and `hadith_library_state.dart`
    - `bookmark_cubit.dart` and `bookmark_state.dart`

- **17 Hadith Collections** with multilingual content (Arabic, English, Urdu, Bangla):
  - Sahih Bukhari (`bukhari_books/`) - 97 books with 7,563 hadiths
  - Sahih Muslim (`muslim_books/`) - 56 books with 7,190 hadiths
  - Sunan Abu Dawud (`abudawud_books/`) - 43 books
  - Jami' at-Tirmidhi (`tirmidhi_books/`) - 46 books
  - Sunan Ibn Majah (`ibnmajah_books/`) - 37 books
  - Sunan an-Nasa'i (`nasai_books/`) - 51 books
  - Muwatta Malik (`malik_books/`) - 61 books
  - Riyad as-Salihin (`riyadussalihin_books/`) - spiritual and ethical hadiths
  - 40 Hadith Nawawi (`forty_books/`) - classical collection
  - Bulugh al-Maram (`bulugh_books/`) - jurisprudence hadiths
  - Al-Adab Al-Mufrad (`adab_books/`) - etiquette and manners
  - Shamail Muhammadiyah (`shamail_books/`) - Prophet's characteristics
  - Mishkat al-Masabih (`mishkat_books/`) - comprehensive collection
  - Musnad Ahmad (`ahmad_books/`) - Imam Ahmad's collection
  - Sunan ad-Darimi (`darimi_books/`) - early hadith compilation

- **Hadith Library UI Components**:
  - `hadith_library_screen.dart` - Main library interface with modern flat design
  - `collection_books_screen.dart` - Browse books within collections
  - `book_hadiths_screen.dart` - View hadiths from specific books
  - `hadith_reader_screen.dart` - Full-screen hadith reader with translation support
  - `bookmarks_screen.dart` - Manage saved favorite hadiths
  - Collection cards, book items, bookmark cards, hadith preview widgets
  - Search functionality across collections and bookmarks
  - Multilingual support with translation toggle (Arabic/English/Urdu/Bangla)

- **Smart Bookmark System**:
  - Save and manage favorite hadiths locally
  - Bookmark cards with collection info and timestamp
  - Quick access to saved hadiths with search capability
  - Delete confirmation dialogs for bookmarks
  - Persistent storage using local database

- **Nearest Mosque Finder Feature**:
  - `mosque_model.dart` - Data model for mosque information
  - `nearest_mosque_grid_item.dart` - Home screen integration
  - `mosque_list_bottom_sheet.dart` - Interactive mosque list view
  - Integration with masjidnear.me API for mosque data
  - Interactive map integration for mosque locations
  - Search radius up to 10km showing up to 10 nearest mosques
  - Animated loading states with rotating mosque icon
  - Fade-in and slide-up animations for mosque cards
  - Navigation arrow indicators on mosque cards
  - Offline handling and error states
  - Localized mosque finder UI (Arabic/English)

- **Home Screen Integration**:
  - Hadith library grid item for quick access
  - Nearest mosque finder grid item
  - Updated home screen widgets for new features

- **Localization Updates**:
  - Added `hadith_library` section to `ar.json` and `en.json`
  - Complete translations for all hadith library features
  - Added `nearest_mosque` and `nearest_mosques` translations
  - 47+ new translation keys for hadith library interface
  - Translations for collection names, book titles, and UI elements

### Added - UI/UX Enhancements
- **Animated Islamic Splash Screen**:
  - Custom mosque pattern painter with Islamic decorative elements
  - Animated wave effects and gradient backgrounds
  - Smooth fade-in animations for app branding
  - Enhanced visual appeal with Islamic aesthetics

- **Azkar Screens Complete Redesign**:
  - Modern minimalist UI with clean card-based design
  - Removed excessive gradients, using consistent app theme colors
  - Custom header with back button (removed traditional AppBar)
  - Full-screen tap functionality for counter increment
  - Islamic pattern background with subtle overlay
  - Smooth fade-in and slide animations for list items
  - Tap scale animation for better UX feedback
  - Improved swipe animations with smooth page transitions
  - Enhanced counter circle with better animations
  - Auto-advance toggle with improved visual feedback
  - Proper bottom spacing for buttons with SafeArea
  - Simplified action buttons and progress indicators
  - Responsive layout improvements

### Added - Shorebird Integration
- **Over-The-Air (OTA) Updates**:
  - Integrated Shorebird Code Push for instant app updates
  - `shorebird.yaml` configuration file
  - Manual deployment guide (`SHOREBIRD_MANUAL_DEPLOYMENT.md`)
  - Removed automated Shorebird CI workflows (manual deployment preferred)

### Added - Quran Integration
- **Quran Library Package Integration**:
  - Integrated `quran_library` package v2.2.3+1 (local package)
  - Enhanced Quran reading experience
  - Improved page rendering and navigation

### Improved - Prayer Times System
- **Prayer Times Refactoring**:
  - Migrated to `adhan_dart` library for accurate calculations
  - Fixed state management in `prayer_times_cubit.dart`
  - Removed old widget implementations
  - Updated main app initialization
  - Persistent prayer notifications system
  - Home screen widgets for prayer times display
  - Enhanced prayer notification system with custom adhan sounds

### Improved - Settings & Notifications
- **Settings Screen Refactor**:
  - Comprehensive settings reorganization
  - Adhan customization features (Fajr and regular prayers)
  - Test notification functionality
  - Persistent notification settings for next prayer
  - Notification timing customization (on time, 5/10/15 min before)
  - Per-prayer notification customization
  - Version display updated to 2.2.0+6
  - Enhanced notification permission handling

### Fixed - Notifications & Permissions
- **Notification System Fixes**:
  - Resolved notification sound repetition issue
  - Fixed notification permission dialog and navigation issues
  - Improved exact alarm permission handling for Android
  - Better permission request flow with user-friendly dialogs
  - Fixed notification timing accuracy

### Fixed - Compatibility & Stability
- **Android 15 Compatibility**:
  - Fixed edge-to-edge display issues
  - Updated deprecated APIs for Android 15
  - Improved responsive layout across different screen sizes
  - Better SafeArea handling

- **Code Quality Improvements**:
  - Resolved all deprecated code warnings
  - Applied dart format for code consistency
  - Fixed dependency conflicts
  - Updated Flutter to 3.35.0 and Dart SDK to >=3.5.0
  - Improved app stability and performance

### Changed - Dependencies
- **Package Updates**:
  - Updated `flutter_bloc` to ^9.1.1
  - Updated `shared_preferences` to ^2.5.3
  - Updated `sqflite` to ^2.4.1
  - Updated `uuid` to ^4.5.1
  - Updated `share_plus` to ^10.1.4
  - Updated `geolocator` to ^13.0.4
  - Updated `geocoding` to ^4.0.0
  - Updated `awesome_notifications` to ^0.10.1
  - Updated `permission_handler` to ^11.3.1
  - Updated `rxdart` to ^0.28.0
  - Updated `hive` to ^2.2.3
  - Updated `hive_flutter` to ^1.1.0
  - Updated `hive_generator` to ^2.0.1
  - Updated `build_runner` to ^2.4.13
  - Updated `flutter_launcher_icons` to ^0.14.3
  - Updated `just_audio` to ^0.10.3
  - Updated `flutter_native_splash` to ^2.3.11
  - Updated `url_launcher` to ^6.3.1
  - Updated `http` to ^1.4.0
  - Updated `cached_network_image` to ^3.4.1
  - Updated `connectivity_plus` to ^7.0.0
  - Updated `flutter_dotenv` to ^5.2.1
  - Updated `google_nav_bar` to ^5.0.7
  - Updated `font_awesome_flutter` to ^10.9.1
  - Updated `country_flags` to ^2.1.1
  - Updated `home_widget` to ^0.8.1
  - Updated `flutter_lints` to ^5.0.0
  - Updated `json_serializable` to ^6.7.1

### Changed - Documentation & CI/CD
- **Documentation Updates**:
  - Added comprehensive GitHub setup guide (`GITHUB_SETUP_GUIDE.md`)
  - Added workflow documentation (`WORKFLOW.md`)
  - Added GitHub files guide (`GITHUB_FILES_GUIDE.md`)
  - Added Shorebird deployment documentation
  - Updated contributing guidelines

- **CI/CD Improvements**:
  - Implemented Git Flow branching strategy
  - Added conventional commit message guidelines
  - Created PR and issue templates
  - Added branch protection rules
  - Improved environment variable handling
  - Updated CI/CD workflows for Flutter 3.35.3
  - Added disk space cleanup to CI workflow
  - Removed hotfix branch from workflow structure

### Changed - Assets & Data
- **Hadith Collections Assets**:
  - Added extensive JSON data for 17 hadith collections
  - Organized by collection and language (Arabic, English, Urdu, Bangla)
  - Total of 15+ MB of hadith data across all collections
  - Structured book-wise organization for efficient loading

- **Asset Configuration**:
  - Updated `pubspec.yaml` with hadith JSON paths
  - Added all language-specific hadith book directories
  - Proper asset path organization for scalability

### Technical Details
- **Architecture Improvements**:
  - Clean Architecture implementation for hadith library
  - Separation of concerns: Data, Domain, and Presentation layers
  - BLoC pattern for state management
  - Repository pattern for data access
  - Use case pattern for business logic
  - Dependency injection improvements

- **Database & Storage**:
  - Hive database integration for bookmarks
  - SQLite for prayer times and settings
  - Efficient caching mechanisms
  - Local storage optimization

- **Performance Optimizations**:
  - Lazy loading for large hadith collections
  - Optimized JSON parsing and deserialization
  - Efficient image loading with caching
  - Reduced memory footprint
  - Improved app startup time

### Migration Notes
- Update from any previous version by installing v2.2.0+6
- Existing user data (bookmarks, settings) will be preserved
- First launch may take slightly longer due to hadith library initialization
- Location permissions required for mosque finder feature
- Notification permissions recommended for prayer alerts

## [2.1.0] - 2025-12-XX

### Added
- Git workflow with branch protection and CI/CD
- Conventional commit messages
- PR and issue templates
- Contributing guidelines

## [1.1.0] - 2024-10-XX

### Added
- Enhanced Radio Controls
- Persistent Dhikr Counters
- Floating radio player across the app

### Fixed
- Android 15 edge-to-edge compatibility
- Deprecated APIs updated
- Various UI improvements

### Changed
- Updated Flutter and packages
- Improved splash screen

## [1.0.0] - 2024-XX-XX

### Added
- Initial release of Wadhakir
- Core Islamic features implementation
- Prayer times functionality
- Qibla direction
- Dhikr and Tasbeeh counters
- Islamic names and content

### Fixed
- URLs in about developer section
- Palestine support button functionality
- URL launcher issues
- Default theme set to light

### Changed
- Updated package name
- Updated project structure
- Made light theme default

---

## Types of Changes

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes