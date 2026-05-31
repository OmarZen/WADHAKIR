# Changelog 📝

All notable changes to Wadhakir will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.0+18] - 2026-05-31

### Added

- **Daily Quran Reading Plan (Wird)** — set a daily reading goal (pages, rubʿ, ḥizb, or juzʾ) and a start page, get a generated schedule with the expected khatma (completion) date, a daily reminder at your chosen time, and day-by-day progress tracking. Reachable from the home grid and the new daily-progress strip.
- **40 Hadith of Imam an-Nawawi** — browse the full collection with Arabic text + English translation; copy or share any hadith as a branded card.
- **After-Prayer Adhkar** — post-prayer remembrances with per-dhikr counters, an overall progress indicator, and reset; progress persists between sessions.
- **Home-screen sections** — a **daily-progress strip** (Wird + after-prayer Adhkar at a glance) and a **religious-occasions strip** (upcoming notable Islamic days) above a reorganized, labelled feature grid with new Wird and 40-Hadith tiles.
- **Background reliability** — the app now requests a one-time **battery-optimization exemption** and adds a boot receiver + a native foreground service, so prayer notifications, fasting reminders, and the floating-dhikr overlay keep working in the background and survive a device reboot.
- **Two new glassmorphism prayer widgets** — "Prayer Detail" (English) and "Prayer Next" (Arabic). Rendered as Flutter images via `home_widget`'s `renderFlutterWidget`, with a real frosted-glass effect (blurred coloured light-orbs + frost veil + specular edge), the five daily prayers with a progress bar, and ornate **Aref Ruqaa** Arabic calligraphy for the next-prayer name. Both open the app on tap; the content is `FittedBox`-scaled so it never overflows at any widget size.
- **Live "Prayer Clock" widget** — a glassy native widget with a self-ticking `TextClock` (current time) and a live `Chronometer` countdown to the next prayer, plus the Hijri/Gregorian date and next-prayer name.
- **Live clock** added to the compact prayer-times widget header.
- **Aref Ruqaa** font registered in `pubspec.yaml`; **Almarai** bundled as an Android font resource (`res/font/almarai`) so the native widgets share the app's typography.

### Changed

- **Settings redesigned** — sections (App Lock, Fasting, Notifications) now open as their own standalone pages with a branded header instead of expanding inline, keeping the main Settings screen clean.
- **Share-as-image is now single-language** (no longer bilingual). A new passage layout supports long content (e.g. the 40 Hadith) at full height, with an optional translation block below a divider.
- **forui theming** now derives its colours from the active Material `ColorScheme`, so forui and Material components stay visually in sync across light/dark.
- **Native widgets restyled to glass** — the Hijri calendar, compact prayer, and prayer-times list widgets now share a frosted dark-glass background, translucent inner sections, the Almarai font, and a unified blue accent palette.
- **Hijri calendar month scrolling is now instant** — arrow navigation is computed natively in Kotlin from a pre-computed month cache instead of round-tripping through a Flutter background isolate, eliminating the lag/flashing. Day taps update the date card instantly too.
- **Widget default sizes tuned** — the Hijri calendar defaults to a usable 4×5 size with tighter day cells (numbers are no longer squashed on placement); the compact prayer widget defaults to 3×2; the list widget is taller and vertically resizable.
- **Glass widgets spacing/polish** — larger render size, more generous internal spacing, slightly larger fonts, and a glowing current-prayer dot.
- **Prayer-times list widget** now highlights the **next** upcoming prayer instead of the one that already passed.
- **Compact prayer widget** opens the app on the **first** tap (previously required a double tap) and was rebuilt to stay compact so it fits without clipping at smaller heights.
- **Quran daily-wird settings** — the bare pages-per-day and start-page text fields were replaced with a polished stepper input (− / + buttons that is also directly typeable).
- Widget picker thumbnails refreshed for every widget.

### Fixed

- **Fasting advance reminders** — fixed bugs in the "remind me before a fasting day" notifications; the advance-reminder settings dialog was reworked (migrated to a forui dialog with a constrained stepper that no longer overflows).
- **"Prayer Clock" widget failing to load** — a plain `<View>` divider (not permitted in RemoteViews) was replaced with a `FrameLayout`.
- Compact prayer widget no longer clips its content at constrained heights.
- **Android 15/16 edge-to-edge compliance** — addressed the Play Console "edge-to-edge" advisories. The splash theme's display-cutout mode was changed from the deprecated `shortEdges` to `always` and the legacy `windowFullscreen` flag was removed; the app no longer triggers the deprecated `Window.setNavigationBarColor` (the `SystemUiOverlayStyle.light/.dark` presets carry a black nav-bar colour) — replaced with icon-brightness-only overlay styles that leave the system bars transparent, which is the correct edge-to-edge behaviour.
- **Bottom-sheet insets** — the tall modal sheets (tasbih / raqia / after-prayer azkar, Allah's names, adhan-sound picker, Islamic-history detail, radio now-playing, nearest-mosque) now pad their content by the system navigation-bar inset so the last item is no longer hidden behind the gesture bar under edge-to-edge.

### Version

- App version bumped from `3.1.1+17` to `3.2.0+18`.
- MSIX version bumped from `3.0.0.0` to `3.2.0.0`.
- Updated the displayed app version in the Arabic and English settings strings.

## [3.1.1+17] - 2026-05-27

### Fixed

Change the privacy link in app about

## [3.1.0+16] - 2026-05-26

### Added

- **Onboarding redesign** — 5-page flow with `PageView` swipe + parallax background. Single brand-blue palette across every page (no off-brand accents). Animated hero icon, polished progress bar, always-visible Skip in the header. EN + AR translations refreshed.
- **Floating dhikr overlay feature** — pill-bar reminder that floats over other apps at a chosen interval. Settings screen, position picker (top/bottom only), permission flow, live pill preview.
- **Moon phases feature**:
  - Calendar with animated moon hero and tappable monthly grid.
  - Detail screen with phase info, 30-day illumination sparkline, and live moon disc.
  - **Islamic context section** with three Quranic verse cards: Surah Yunus 10:5 (the moon as one of Allah's signs), Surah Al-Qamar 54:1 (انشقاق القمر, with Bukhari/Muslim citation), Surah Al-Baqarah 2:189 (new crescents as timings for Hajj). Importance bullets covering the Hijri month, Ramadan/Eid, Hajj, and the White Days.
  - **Crescent sighting card** for new-moon and waxing-crescent days, with moon age + when/where/how to look + a Yallop-style visibility verdict.
  - Same Islamic content also surfaced under the calendar grid.
- **Branded share-as-image flow** — new share screen with a 4:5 brand card (logo, gradient, ScheherazadeNew Arabic body). Captures via `RepaintBoundary.toImage` + `share_plus`. Wired into Azkar and Fasting Info.
- **Core design tokens** — new `lib/core/design/` module (spacing, radii, motion, glass, breakpoints) + shared `glass_card` widget.
- **Per-screen brand palette** — onboarding, share card, floating dhikr settings, and moon phases all derive from the same primary `#20497D` / accent `#3A6BA8` / glow `#7BA7D9` family.

### Changed

- **Default prayer calculation method** for first-install users is now `egyptian` (الهيئة المصرية العامة للمساحة). Existing users with a saved preference are unaffected.
- **Floating dhikr settings** — minimalist redesign. Removed the heavy gradient header (which used `colorScheme.secondary` ≈ near-black). One grouped settings surface with subtle dividers replaces five separate cards. Custom brand-tinted chips and slider theme.
- **Settings ListTile warnings** — fixed the framework `"ListTile background color or ink splashes may be invisible"` warning. Diagnostic hook in `main.dart` logs the intermediate widget for future occurrences.
- **Moon UI polish** — calendar + detail screens now use the brand-derived `#0F1A2A` night-sky surface (same family as floating dhikr dark mode + onboarding dark surface).

### Removed

- **Zodiac / astrology** entirely from the moon phases feature — enum, computation, UI rows, and 13 translation keys (label + 12 sign names) in both EN and AR. `eclipticLongitude` is kept since it's a real astronomical quantity, not a horoscope.
- **Hadith library** feature retired (cubits, screens, widgets, repository, home grid item).

### Fixed

- **Fasting reminders**: channel registration is now idempotent and no longer wipes the prayer channels on every toggle. Cancellation uses `cancelNotificationsByChannelKey` (single hop) instead of the previous 1002-iteration loop, so the section loads instantly. Weekly schedule now passes an explicit timezone (avoids the OEM `TimeZone.getDefault` NPE). UI emits Loaded before scheduling so the section never gets stuck on a spinner.
- **Fasting info share** previously had a broken `String as ShareParams` cast that would throw at runtime — fixed by routing through the new share screen.

### Tooling

- `.gitignore` now excludes local Claude/agent tooling directories.

## [3.0.0+15] - 2026-05-06

### Added

- App Lock (prayer-aware) improvements:
  - New Android `AppLockMonitorService` and platform bridge updates to drive a secure overlay during prayer windows.
  - Hadith/quote payload support for overlay messages (local JSON asset and platform transfer).
  - `AppLock` settings UI: selection of locked apps, emergency bypass, lock duration options, and accessibility fallback.
  - `_AppLockPrayerSync` in `main.dart` to keep the native monitor in sync with prayer windows (auto updates when prayer window changes).
- Quran reader improvements (package-driven):
  - Auto-scrolling support with configurable speed control and stop points (page-level control and user-accessible speed/stop settings).

### Changed

- Overlay behavior and visuals:
  - Removed RenderEffect / view-level blur from overlay card (Android S+). Overlay content is now sharp and readable.
  - Removed Flutter `BackdropFilter` blur from bottom navigation bar and switched to a solid, accessible surface style.
  - Test/developer overlay APIs and buttons removed from production (no more manual "Test overlay" action in settings or method channel).
- App structure & docs:
  - Updated `README.md`, `CONTRIBUTING.md`, and PR template to match open-source workflows and branch strategy.
  - Added MIT `LICENSE` file.

### Fixed

- Fixed unreadable overlay issue caused by blur being applied to child views.
- Ensured overlay only activates during configured prayer windows and remains until the user confirms completion or the next prayer window starts.

### Dependencies

- Updated multiple dependencies in `pubspec.yaml` to newer compatible versions (bug fixes, performance and API improvements). Notable upgrades include runtime, UI and platform packages used by the app (examples): `quran_library`, `flutter_bloc`, `google_nav_bar`, `hugeicons`, `just_audio`, `hive` & `hive_flutter`, `flutter_native_splash`, `flutter_dotenv`, `permission_handler`, `adhan_dart`, `syncfusion_*` packages, and others. These upgrades enabled the new Quran auto-scrolling feature, improved audio/player stability, and ensured compatibility with the latest Flutter SDK.

### Removed

- Removed the `showTestOverlay` method channel and the test overlay UI from settings (was a temporary developer tool).

### Migration Notes

- If you previously relied on the `showTestOverlay` testing API, remove any calls and use the prayer-window flow to validate overlays.
- App Lock now requires overlay & usage access permissions (same as before); if overlay permission is missing the service will fall back to sending the user to Home.

## [2.4.1+14] - 2026-03-13

### Added

- **Home Shortcut for Fasting Calendar**:
  - Added a new card in "مقتطفات إسلامية" on the home screen
  - Opens the same interactive fasting calendar dialog used in Settings
- **Update the Quran Library**:
  - Updated Quran verses and translations
  - Improved search functionality
  - Fix Tafsir issue of disappearing

### Changed

- **Version Updates**:
  - App version bumped from `2.4.0+13` to `2.4.1+14`
  - MSIX version bumped from `2.4.0.0` to `2.4.1.0`
  - Updated displayed app version text in Arabic and English settings resources
- **Quran Screen**:
  - Explicitly enabled `withPageView: true` to keep default horizontal PageView reading mode

### Technical Details

- **Version Code**: 14 (was 13)
- **MSIX Version**: 2.4.1.0 (was 2.4.0.0)

### Migration Notes

- Update from 2.4.0+13 by installing 2.4.1+14

## [2.4.0+13] - 2026-03-09

### Added - Fasting Reminders System

- **Comprehensive Islamic Fasting Reminders**:
  - Interactive Hijri calendar showing all Islamic fasting days
  - Complete fasting reminder system with notification integration
  - Dual date display (Gregorian + Hijri) throughout calendar
  - Coverage: Ayyam al-Bid (13-15), 9th-10th, Monday/Thursday, special days (Ashura, Tasu'a, Arafah)
  - 12-month calendar navigation limit for optimal UX
  - Shows ALL fasting days without settings-based filtering

- **Enhanced Prayer Notifications**:
  - Real-time countdown with 1-second precision updates
  - Improved persistent notification UI showing hours:minutes:seconds
  - Better system notification panel integration

- **Settings UI Improvements**:
  - Redesigned appearance settings (theme/language) into compact side-by-side layout
  - Reorganized adhan sounds for Fajr and other prayers into single row
  - Fixed render overflow issues with proper Expanded wrappers
  - Integrated HugeIcons package throughout fasting features

- **Architecture & Code Quality**:
  - Clean architecture with FastingRemindersCubit for state management
  - Repository pattern with FastingRemindersRepository
  - Domain use cases for fasting reminder settings
  - Dedicated services: HijriDateCalculatorService, FastingNotificationService
  - Modern compact UI design following Material Design 3

- **Localization**:
  - Added 30+ new translation keys for fasting features
  - Fixed Quran screen tab translations
  - Full bilingual support (Arabic/English)

### Changed

- Fasting settings moved from general notifications to dedicated section
- Unified all fasting-related colors to theme.colorScheme.primary

### Technical Details

- **Version Code**: 13 (was 12)
- **MSIX Version**: 2.4.0.0 (was 2.3.5.0)
- **Files Modified**: 48 files changed (+7,657 insertions, -2,240 deletions)
- **Breaking Changes**: Old fasting_notification_settings_widget.dart removed

### Migration Notes

- Update from 2.3.5+12 by installing 2.4.0+13
- Fasting reminders now in dedicated section under Settings
- All existing settings and data preserved

## [2.3.5+12] - 2026-01-28

### Added - Radio Station Bilingual Categories

- **Complete Radio Categorization System**:
  - Organized all 174 radio stations into 12 thematic categories
  - Full bilingual support for category names (Arabic and English)
  - Categories include: القراء (Reciters), القراءات العشر (Ten Readings), ترجمة معاني القرآن الكريم (Quran Translations), التفسير وعلوم القرآن (Tafsir & Quran Sciences), السيرة والقصص (Biography & Stories), تلاوات متميزة (Distinguished Recitations), الرقية الشرعية (Ruqyah), الفتاوى (Fatwas), الأدعية والأذكار (Supplications), مواسم الخير (Blessed Seasons), السنة النبوية (Prophetic Sunnah)
  - Added "كل الإذاعات (All Radios)" option to show all stations

- **Enhanced Radio Data Model**:
  - Added `category` field (Arabic name) to RadioStationModel
  - Added `category_en` field (English name) to RadioStationModel
  - Added `getLocalizedCategory()` method for language-aware category display
  - Updated JSON structure to include category fields for all 174 stations

- **Category Filtering System**:
  - Interactive category filter chips with icons in radio screen
  - Category names automatically switch between Arabic and English based on app language
  - Smooth category filtering using actual JSON category fields
  - Category-specific icons for better visual recognition

### Changed - Radio Feature Improvements

- **UI/UX Enhancements**:
  - Redesigned category selection with horizontal scrollable chips
  - Added dedicated icons for each category (reciters, translations, tafsir, etc.)
  - Category filter now uses actual data fields instead of hardcoded name matching
  - Improved category chip styling with selected state visualization

- **Data Management**:
  - Migrated from hardcoded category logic to JSON-based categorization
  - Simplified filtering algorithm using category field lookups
  - Better maintainability with centralized category definitions

- **Category Distribution**:
  - القراء (Reciters): 107 stations
  - القراءات العشر (Ten Readings): 23 stations
  - ترجمة معاني القرآن الكريم (Quran Translations): 22 stations
  - تلاوات متميزة (Distinguished Recitations): 5 stations
  - التفسير وعلوم القرآن (Tafsir & Quran Sciences): 4 stations
  - السيرة والقصص (Biography & Stories): 4 stations
  - الأدعية والأذكار (Supplications): 3 stations
  - السنة النبوية (Prophetic Sunnah): 2 stations
  - الرقية الشرعية (Ruqyah): 2 stations
  - الفتاوى (Fatwas): 2 stations

### Improved - Radio Code Quality

- **Architecture Improvements**:
  - Refactored `_applyCategory()` method for cleaner filtering logic
  - Removed 500+ lines of hardcoded station name lists
  - Implemented data-driven category system
  - Better separation of concerns between UI and data layers

- **Maintainability**:
  - Category management now centralized in JSON data file
  - Easy to add/modify categories without code changes
  - Reduced code complexity in radio_screen.dart
  - Better scalability for future category additions

### Fixed - Radio Feature Issues

- **Category Assignment**:
  - Properly categorized all "القراءات العشر (Ten Readings)" stations
  - Fixed station name matching with leading/trailing spaces
  - Ensured accurate categorization for all 174 stations
  - Validated category distribution totals

### Technical Details

- **Version Code**: 12 (was 11)
- **MSIX Version**: 2.3.5.0 (was 2.3.4.0)
- **Files Modified**: 3 (radio_screen.dart, RadioStationModel, api_response.json)
- **JSON Updates**: Added category and category_en fields to all 174 stations
- **Code Reduction**: ~500 lines of hardcoded logic replaced with data-driven approach
- **Quality Assurance**: All categories tested and validated
- **Backward Compatibility**: Full - existing functionality preserved with enhanced categorization

### User-Facing Changes

- **New Features**:
  - Browse radio stations by 12 thematic categories
  - Category names appear in user's preferred language (Arabic/English)
  - Visual category chips with icons for easy navigation
  - "All Radios" option to see complete station list

- **UI Improvements**:
  - Cleaner, more organized radio station browsing
  - Better discovery of specific types of Islamic radio content
  - Consistent bilingual experience throughout radio feature
  - Intuitive category filtering with visual feedback

- **Content Organization**:
  - Reciters grouped separately from special recitations (Ten Readings)
  - Quran translations easily accessible in dedicated category
  - Educational content (Tafsir, Biography) properly categorized
  - Seasonal and special content (Supplications, Ruqyah) organized

### Migration Notes

- Update from 2.3.4+11 by installing 2.3.5+12
- All existing radio stations remain available with enhanced categorization
- Previous favorites and playback history preserved
- Category filter automatically appears in radio screen
- No user action required - categories work immediately

---

## [2.3.4+11] - 2026-01-25

### Changed - Asset Updates for Shorebird Compatibility

- **Version Bump**:
  - Updated app version to 2.3.4+11 for new Shorebird release
  - Updated all localization files (ar.json, en.json)
  - Updated settings screen version display
  - Updated MSIX version to 2.3.4.0
  
- **Release Strategy**:
  - Created new release to enable Shorebird code push
  - Asset changes from previous version now properly included in release
  - Enables future over-the-air patches for bug fixes without store updates

### Technical Details

- **Version Code**: 11 (was 10)
- **MSIX Version**: 2.3.4.0 (was 2.3.3.0)
- **Shorebird**: Release created to enable code push capabilities
- **Backward Compatibility**: Full - seamless update from 2.3.3+10

### Migration Notes

- Update from 2.3.3+10 by installing 2.3.4+11
- All previous features and data preserved
- Shorebird code push now enabled for future quick updates
- No user action required

---

## [2.3.3+10] - 2026-01-13

### Added - Electronic Tasbih Feature

- **Electronic Tasbih (Prayer Beads Counter)**:
  - Interactive prayer beads counter with circular visualization of 33 beads
  - Animated beads that rotate and highlight as you count
  - Counter display with progress tracking (current/target format)
  - Large tap button with pulsing animation for easy interaction
  - Haptic feedback for tactile response on each count
  - Target selection with presets: 33, 99, 100, 1000, or custom count
  - Completion dialog with celebration animation when target is reached
  - Persistent storage using SharedPreferences (saves progress automatically)
  - Statistics card showing: Total Counter, Target, Progress Percentage
  - Reset functionality for current count and total count
  - Clean, modern UI with gradient backgrounds and smooth animations
  - Integrated into home screen grid for easy access
  - Full Arabic and English localization support
  - Compact single-screen layout optimized for all screen sizes
  - About dialog with usage instructions

- **Islamic History Feature Improvements**:
  - Refactored Islamic History screen to use BLoC pattern with proper state management
  - Implemented pagination system for better performance (20 events per page)
  - Added infinite scroll with "load more" functionality
  - Created dedicated data models and repository layer
  - Separated business logic into domain layer with repository interface
  - Added search debouncing (500ms) for improved user experience
  - Improved UI with loading states and better error handling
  - Added "load more" indicator and "end of list" message
  - Better separation of concerns following Clean Architecture principles

- **Documentation**:
  - Added comprehensive Google Play crash fix guide (GOOGLE_PLAY_CRASH_FIX_GUIDE.md)
  - Added Microsoft Store submission guide (MICROSOFT_STORE_SUBMISSION_GUIDE.md)
  - Added MSIX package ready guide (MSIX_PACKAGE_READY.md)
  - Detailed proguard configuration documentation
  - Step-by-step submission instructions for both stores

### Fixed - Google Play & Microsoft Store Submission

- **Proguard Configuration**:
  - Added comprehensive proguard rules to prevent release build crashes
  - Protected Flutter framework and all plugin classes from obfuscation
  - Fixed code shrinking issues that caused app crashes during Google Play testing
  - Added rules for all plugins: Awesome Notifications, Just Audio, Hive, Syncfusion, Geolocator, Home Widget, etc.
  - Configured proper Gson serialization rules
  - Added Android X and Material Components protection
  
- **Android Manifest Updates**:
  - Added intent queries for Android 11+ compatibility
  - Added queries for URL launching (http/https)
  - Added queries for sharing functionality
  - Added query for app settings navigation
  
- **Build Configuration**:
  - Enabled minifyEnabled and shrinkResources for optimized APK size
  - Configured proguard-android-optimize.txt with custom rules
  - Added Google Play Core dependencies for proper feature delivery
  
- **Microsoft Store**:
  - Fixed display name to match Partner Center reservation: "Wadhakir - وَذَكِّر"
  - Updated publisher ID and identity name for Store submission
  - Configured proper MSIX settings for Windows Store deployment
  - Set correct version format (2.3.3.0)

### Improved - UI/UX Enhancements

- **Prayer Times Screen**:
  - Added back button to header for better navigation
  - Improved desktop responsiveness with proper spacing
  - Enhanced header layout with circular button containers
  - Added box shadows for better visual depth
  - Better tooltip support for accessibility

- **Settings Screen**:
  - Updated version display to 2.3.3+10
  - Improved about section layout and styling

- **Home Screen**:
  - Added electronic tasbih grid item with gradient icon
  - Better grid layout organization
  - Consistent styling across all grid items

### Changed - Code Quality & Architecture

- **Architecture Improvements**:
  - Implemented Clean Architecture for Islamic History feature
  - Added proper data, domain, and presentation layers
  - Created repository pattern for data access
  - Implemented BLoC pattern for state management
  - Better separation of concerns throughout the codebase
  - Created reusable models: HistoryEvent model with search capabilities
  - Improved error handling and state management

- **Dependencies**:
  - Updated msix package to 3.16.12

### Technical Details

- **Version Code**: 10 (was 9)
- **MSIX Version**: 2.3.3.0
- **Build Type**: Release with full optimization and obfuscation
- **Files Modified**: 16+ files
- **New Files**: 8 (including models, repositories, cubits, screens, widgets, and documentation)
- **Quality Assurance**: All features tested and working
- **Backward Compatibility**: Full - no breaking changes

### User-Facing Changes

- **New Features**:
  - Electronic Tasbih (prayer beads counter) with beautiful animations
  - Improved Islamic History browsing with pagination and search
  
- **UI Improvements**:
  - Better navigation with back buttons on all screens
  - Smoother animations and transitions
  - Improved loading states and feedback
  - Better desktop support throughout the app
  
- **Reliability**:
  - Fixed potential crashes in release builds
  - Better error handling across all features
  - Improved performance with pagination
  - Persistent storage for all user progress

### Migration Notes

- Update from 2.3.2+9 by installing 2.3.3+10
- All existing user data preserved
- New electronic tasbih feature available in home grid
- Islamic History now uses new architecture (transparent to users)
- No user action required

---

## [2.3.2+9] - 2026-01-13

### Added

- **Flutter 3.38.6 Compatibility**: Full support for latest Flutter stable version
- **Enhanced Home Screen Widgets**:
  - Hijri Calendar Widget with interactive month navigation
  - Redesigned Prayer Times List Widget with improved UI
  - Better widget data persistence and updates

### Changed

- **SDK Requirements**: Updated minimum SDK to 3.10.0 and Flutter to 3.24.0+
- **Code Quality**: Applied comprehensive code formatting across entire codebase
- **Dependencies**: Updated all packages to ensure compatibility with Flutter 3.38.6
- **Build System**: Updated Gradle and build configurations for better stability

### Improved

- **App Performance**: Enhanced overall app responsiveness and stability
- **CI/CD Pipeline**:
  - Multi-platform workflow improvements
  - Analytics disabled in CI builds for faster processing
  - Better error handling in automated builds

### Fixed

- **Flutter Version Conflicts**: Resolved compatibility issues after Flutter upgrade
- **Widget Loading**: Fixed RemoteViews compatibility issues in home widgets
- **Build Issues**: Resolved dependencies conflicts and build warnings

### Technical

- Total of 103 files updated with code formatting improvements
- Improved code consistency and maintainability
- Better error handling across features
- Enhanced widget-to-app communication

## [2.3.2] - 2026-01-12

### Added - Home Screen Widgets

- **Hijri Calendar Widget**:
  - Interactive home screen widget displaying Hijri calendar
  - Month navigation (next/previous) with smooth transitions
  - Day selection with visual feedback and highlighting
  - Today indicator with distinct styling
  - Displays current Hijri and Gregorian dates
  - Bidirectional communication between widget and app
  - Compact 4x2 grid layout optimized for home screens

- **Prayer Times List Widget Enhanced**:
  - Redesigned compact 4x1 widget layout
  - Added header section with three date displays:
    - Hijri date (right-aligned)
    - Day name in center (highlighted in light blue)
    - Gregorian date (left-aligned)
  - Rounded corners with modern card-like appearance
  - Custom drawable backgrounds for professional look
  - Optimized text sizing to prevent line wrapping
  - All text set to single-line with ellipsize
  - App theme color integration (#20497D primary, #B3D9FF accent)

### Improved - Widget System

- **Widget Architecture**:
  - Proper RemoteViews compatibility
  - Removed problematic View separators causing loading issues
  - Simplified layouts for better performance
  - Background drawables with rounded corners (8dp radius)
  - Header with darker blue background (#1A3A5D) for visual separation

- **Data Flow**:
  - Enhanced Hijri date calculation using Syncfusion
  - Arabic month and day name formatting
  - Automatic date field updates in widget data
  - SharedPreferences integration for widget state

### Fixed - CI/CD & Build

- **GitHub Actions**:
  - Updated Flutter version in CI from 3.35.3 to 3.27.1
  - Fixed timezone package dependency resolution error
  - Dart SDK compatibility with timezone ^0.11.0
  - All build checks now passing

- **Widget Stability**:
  - Fixed "can't load widget" errors in prayer times widget
  - Resolved RemoteViews compatibility issues
  - Simplified widget layouts for reliability
  - Removed complex UI elements causing rendering failures

### Changed - UI/UX Polish

- **Text Optimization**:
  - Header dates: 9-10sp for compact display
  - Prayer labels: 8sp
  - Prayer times: 11sp (bold)
  - All text with singleLine and ellipsize attributes
  - Prevented text wrapping in small widget spaces

- **Color Scheme**:
  - Day name changed from gold to light blue (#B3D9FF)
  - Consistent blue theme throughout widgets
  - Better contrast and readability

### Technical Details

- **Files Modified**: 15+ files
- **New Drawables**: 3 (widget_background_rounded, widget_header_background, current_prayer_background)
- **Removed Drawables**: 5 prayer icon XMLs (simplified approach)
- **Widget Providers**: 2 (HijriCalendarWidgetProvider, PrayerTimesListWidgetProvider)
- **Quality Assurance**: All flutter analyze checks passing
- **Backward Compatibility**: Full - existing widgets update seamlessly

### User-Facing Changes

- **New Features**:
  - Hijri calendar widget on home screen
  - Enhanced prayer times widget with dates
  
- **UI Improvements**:
  - Cleaner, more compact widget designs
  - Better readability with optimized text sizes
  - Professional appearance with rounded corners
  - Consistent color theming
  
- **Reliability**:
  - Widgets load consistently without errors
  - Simplified design prevents rendering issues
  - Better performance on all Android versions

### Migration Notes

- Update from 2.3.1 by installing 2.3.2+9
- Existing widgets will update automatically
- No user action required
- Widget sizes: Hijri Calendar (4x2), Prayer Times (4x1)

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
