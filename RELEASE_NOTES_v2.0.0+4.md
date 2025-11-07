# 📱 Wadhakir v2.0.0+4 - Release Notes

## 🎉 Major Release - Complete Quran Library Integration & Enhanced User Experience

---

## 🌟 **NEW MAJOR FEATURES**

### 📖 **Complete Quran Library Package Integration (v2.2.3+1)**
One of the most significant updates in Wadhakir history! We've integrated a comprehensive Quran library that transforms the Quran reading experience:

#### **Enhanced Quran Reading Experience:**
- **Multiple Font Options**: Choose from 4 beautiful Arabic fonts:
  - Uthmanic Hafs V20 (Traditional Mushaf style)
  - Noto Naskh Arabic (Modern readable style)
  - Kufam Regular (Contemporary style)
  - Custom Surah Name font
  
- **Advanced Page Display**:
  - Authentic Mushaf-style page layout
  - Page-by-page navigation (604 pages)
  - Surah-by-surah reading mode
  - Single Ayah display with detailed view
  - Smooth page transitions with gesture controls

- **Rich Text Features**:
  - Adjustable font sizes with 5 preset levels
  - Custom text scaling from 0.5x to 2.0x
  - Beautiful Basmala display at Surah beginnings
  - Surah headers with decorative banners
  - Ayah numbering with Arabic numerals
  - Sajda (prostration) indicators with icons

#### **Comprehensive Tafsir (Interpretation) System:**
- **Multiple Tafsir Sources**: Access various interpretations including:
  - Tafsir As-Sa'di (Arabic) - 43,654 lines of scholarly interpretation
  - English translations available
  - More interpretations can be downloaded on-demand
  
- **Tafsir Features**:
  - Long-press any Ayah to view its Tafsir
  - Beautiful dialog presentation with scrollable content
  - Switch between different Tafsir books seamlessly
  - Bookmark specific interpretations
  - Share Tafsir with others

#### **Advanced Audio Recitation System:**
- **28+ World-Class Reciters**: Including:
  - Abdul Basit Abdul Samad
  - Mishary Rashid Alafasy
  - Mahmoud Khalil Al-Hussary
  - Saad Al-Ghamdi
  - Ahmed Al-Ajmi
  - And 23 more renowned Qaris

- **Powerful Audio Features**:
  - Stream Quran recitation online or download for offline listening
  - Ayah-by-Ayah recitation with auto-scroll
  - Surah-by-Surah continuous playback
  - Download manager for offline access
  - Track download progress with pause/resume
  - Beautiful audio player interface with seek bar
  - Repeat single Ayah or entire Surah
  - Background playback support
  - Play/Pause/Skip controls
  - Last listening position memory
  - Multiple playback speeds

#### **Advanced Search & Navigation:**
- **Powerful Search Engine**:
  - Search across all 6,236 Ayahs
  - Instant results as you type
  - Highlight search terms in results
  - Jump directly to any Ayah from search
  
- **Smart Bookmarks System**:
  - Bookmark any Ayah with one tap
  - Manage all your bookmarks
  - Quick access to bookmarked Ayahs
  - Sync bookmarks across app restarts
  - Beautiful bookmark indicators

#### **Quran Data Infrastructure:**
- Complete Quran data with 113,346+ lines of structured JSON
- Hafs narration text (81,092 lines)
- Surah metadata with names in Arabic and transliteration (1,376 lines)
- English translations (28,463 lines)
- 604 Mushaf pages accurately mapped
- All 114 Surahs with complete metadata

---

### 🎨 **Beautiful Animated Islamic Splash Screen**
Welcome users with a stunning, professionally designed splash screen featuring:

- **Islamic Architectural Elements**:
  - Animated mosque silhouettes with domes and minarets
  - Traditional Islamic crescents and decorative patterns
  - Warm gradient background (teal to deep purple)
  
- **Smooth Animations**:
  - Logo entrance with elastic bounce effect (0.5x → 1.15x → 1.0x scale)
  - Three-layer animated wave patterns at the bottom
  - Expanding background effect for depth
  - Synchronized timing for professional feel
  - 3.5-second total animation duration

- **Brand Identity**:
  - Features the official Wadhakir logo
  - App name displayed in both Arabic and English
  - Tagline: "Your Daily Islamic Companion"
  - Consistent with app's Islamic theme

---

### 🔔 **Advanced Prayer Notifications System**

#### **Persistent Prayer Time Notifications:**
- **Always-On Notification**: Persistent notification in the status bar showing:
  - Next prayer name and time
  - Countdown to next prayer
  - Quick access to prayer times
  - Updates automatically in real-time
  
- **Scheduled Prayer Alerts**:
  - Individual notifications for each of the 5 daily prayers
  - Customizable notification sounds per prayer
  - Vibration support
  - Pre-prayer reminders (configurable)
  - Post-prayer notifications

#### **Custom Adhan (Call to Prayer) System:**
- **13 High-Quality Adhan Sounds** from renowned Muezzins:
  - Mecca (Makkah Al-Mukarramah) - 2 variations
  - Medina (Al-Madinah Al-Munawwarah)
  - Cairo (Egypt)
  - Riyadh (Saudi Arabia)
  - Turkey (Istanbul)
  - Al-Aqsa Mosque
  - Bahrain
  - Egypt (Cairo variation)
  - Algeria
  - Morocco
  - Libya
  - And more traditional styles
  
- **Adhan Customization**:
  - Play different Adhan for each prayer
  - Preview Adhan sounds before selecting
  - Adjust volume independently
  - Choose between classic and modern styles
  - Option to disable Adhan for specific prayers

---

### 📍 **Enhanced Prayer Times & Qibla Features**

#### **Upgraded Prayer Times Calculation:**
- **Migration to adhan_dart Package**: More accurate prayer time calculations
- **Multiple Calculation Methods** (17 methods):
  - Muslim World League
  - Egyptian General Authority
  - University of Islamic Sciences, Karachi
  - Umm Al-Qura University, Makkah
  - Islamic Society of North America (ISNA)
  - Union of Islamic Organizations of France (UOIF)
  - Spiritual Administration of Muslims of Russia
  - Majlis Ugama Islam Singapura (MUIS)
  - Gulf Region
  - Kuwait
  - Qatar
  - And 6 more regional methods

- **Smart Location Handling**:
  - Automatic location detection using GPS
  - Display location name using geocoding
  - Save last known location for offline use
  - Manual location entry option
  - Handle disabled location services gracefully
  - Timeout protection for API calls

#### **Improved Prayer Times UI:**
- **Beautiful Prayer Cards**:
  - Large, easy-to-read prayer times
  - Current prayer highlighted with accent color
  - Next prayer countdown display
  - Gradient backgrounds for visual appeal
  - Prayer status indicators (passed/upcoming)
  
- **Monthly Calendar View**:
  - Full month prayer times at a glance
  - Islamic date display alongside Gregorian
  - Swipe to navigate between months
  - Hijri calendar integration
  - Today's date highlighted

- **Date Navigation**:
  - Quick jump to any date
  - Today button for instant return
  - Previous/Next day navigation
  - Islamic date converter
  - Hijri calendar support

---

### 📻 **Redesigned Islamic Radio Feature**

- **Complete UI Overhaul**:
  - Modern, clean interface design
  - Large station cards with better readability
  - Smooth animations and transitions
  - Better error handling and loading states
  
- **Enhanced Playback**:
  - Background audio support
  - Buffering indicators
  - Connection status display
  - Auto-retry on connection loss
  - Volume controls
  
- **Improved Station Management**:
  - Categorized radio stations
  - Station search functionality
  - Favorite stations
  - Recently played stations
  - Station metadata display

---

### ⚙️ **Completely Redesigned Settings Screen**

The settings screen has been completely rebuilt from the ground up with a focus on organization and user experience:

#### **New Settings Architecture:**
- **Modular Section-Based Design**: Settings organized into logical sections
- **Beautiful UI Components**: Each setting type has its own custom widget
- **Live Preview**: See changes in real-time before applying

#### **Settings Sections:**

1. **🌍 Language & Region Settings**:
   - Elegant language selector with flag icons
   - Arabic (العربية) and English support
   - RTL layout support for Arabic
   - Instant language switching without restart

2. **🎨 Theme & Appearance**:
   - Custom theme selector widget
   - Light mode with fresh colors
   - Dark mode with OLED-friendly blacks
   - System theme option (follows device settings)
   - Beautiful theme preview cards
   - Smooth theme transitions

3. **🔔 Notification Settings** (NEW):
   - Enable/disable persistent notification
   - Configure notification sound
   - Vibration settings
   - Notification priority levels
   - Custom notification channel settings
   - Do Not Disturb integration
   
4. **📿 Adhan Customization** (NEW):
   - Dedicated Adhan sounds section
   - Individual sound picker for each prayer:
     - Fajr (Dawn)
     - Dhuhr (Noon)
     - Asr (Afternoon)
     - Maghrib (Sunset)
     - Isha (Night)
   - Preview button for each Adhan
   - Volume control per prayer
   - Enable/disable Adhan per prayer

5. **🕌 Prayer Calculation Settings**:
   - Detailed calculation method selector
   - 17 different calculation methods
   - Method descriptions and regions
   - High/Mid/Low latitude adjustments
   - Asr calculation method (Standard/Hanafi)
   - Manual angle adjustments for advanced users

6. **ℹ️ About & Information**:
   - App version display (2.0.0+4)
   - Developer information
   - Contact and social media links
   - Privacy policy
   - Terms of service
   - Open source licenses

---

### 💚 **InstaPay Donation Integration**

Support the developer and app development through InstaPay:

- **Easy Donation Button**: Added to "About Developer" dialog
- **One-Tap Donation**: Opens InstaPay app directly
- **Beautiful Green Button**: Distinctive color with heart icon
- **Secure Payment**: Through official InstaPay service
- **Optional Support**: Help keep the app free and ad-free

---

## 🏠 **Home Screen Widgets**

Two beautiful home screen widgets for Android:

### **Prayer Times Widget (Compact)**:
- Shows next prayer and countdown
- Current location
- Today's Islamic date
- Compact design for small spaces
- Auto-updates every minute
- Tappable to open app

### **Prayer Times List Widget (Detailed)**:
- All 5 prayer times displayed
- Current prayer highlighted
- Time remaining to next prayer
- Location and date information
- Larger layout with more details
- Quick glance at full prayer schedule

**Widget Features**:
- Auto-refresh on boot
- Updates when prayer times change
- Supports light and dark themes
- Customizable from widget settings
- Low battery consumption
- Works offline with cached data

---

## 🔧 **TECHNICAL IMPROVEMENTS**

### **Performance Enhancements:**
- Optimized app startup time (faster splash screen transition)
- Reduced memory footprint with lazy loading
- Improved scroll performance in long lists
- Better image caching for faster loading
- Database query optimization for prayer times
- Efficient state management with Cubit pattern

### **Code Architecture:**
- Clean Architecture implementation
- Better separation of concerns
- Improved dependency injection
- More maintainable codebase
- Enhanced error handling
- Better null safety implementation

### **Audio Service Improvements:**
- Fixed MainActivity.kt configuration for audio_service plugin
- Proper FlutterEngine registration
- Background audio playback support
- Better audio focus handling
- Improved notification media controls

### **State Management:**
- Migrated to improved Cubit pattern
- Better state persistence
- Reduced unnecessary rebuilds
- More predictable state updates
- Enhanced error state handling

### **Database & Storage:**
- Optimized local database structure
- Better caching mechanisms
- Faster data retrieval
- Reduced storage footprint
- Improved data synchronization

---

## 🐛 **BUG FIXES**

### **Prayer Times Fixes:**
- ✅ Fixed incorrect prayer time calculations in certain time zones
- ✅ Resolved state management issues causing prayer times not to update
- ✅ Fixed location service timeout issues
- ✅ Corrected Hijri date display errors
- ✅ Fixed prayer times not showing after location change
- ✅ Resolved calculation method not persisting after app restart

### **UI/UX Fixes:**
- ✅ Fixed RTL layout issues in Arabic mode
- ✅ Corrected text overflow in prayer time cards
- ✅ Fixed theme not applying consistently across all screens
- ✅ Resolved dialog positioning issues
- ✅ Fixed keyboard covering input fields
- ✅ Corrected animation stuttering on low-end devices

### **Audio & Notifications:**
- ✅ Fixed audio playback stopping unexpectedly
- ✅ Resolved notification not showing on Android 13+
- ✅ Fixed Adhan not playing at scheduled times
- ✅ Corrected audio focus issues with other apps
- ✅ Fixed notification permission request on older Android versions

### **Permission System Fixes (v2.0.0+4 - Latest):**
- ✅ **Fixed notification permission dialog not showing on some Android devices**
  - Issue: System permission dialog (Permission.notification.request()) was not appearing on certain devices
  - Solution: Changed to directly open app settings page for manual permission grant
  - Result: Users can now reliably enable notification permissions through system settings
  
- ✅ **Fixed black screen issue when returning from settings**
  - Issue: App showed black screen after user returned from system settings
  - Root Cause: Extra navigation pop was interfering with dialog dismissal
  - Solution: Removed redundant Navigator.pop() call - dialog closes automatically via showDialog return value
  - Result: Smooth transition back to app after granting permissions in settings
  
- ✅ **Improved permission request flow**
  - Beautiful explanation dialog shows before opening settings
  - Clear instructions in Arabic about what to enable
  - Automatic permission status check when user returns
  - Debug logging for troubleshooting permission issues
  
- ✅ **Enhanced user experience for permission grants**
  - Single-tap process: Confirm → Settings Opens → Enable → Return
  - No navigation stack issues or black screens
  - Proper context handling for mounted widgets
  - Works reliably across all Android versions and device manufacturers

### **Quran Features:**
- ✅ Fixed bookmark synchronization issues
- ✅ Resolved page navigation edge cases
- ✅ Fixed text rendering on some devices
- ✅ Corrected Ayah highlighting accuracy
- ✅ Fixed search results not displaying correctly

### **General Fixes:**
- ✅ Fixed app crash on startup (MainActivity.kt issue)
- ✅ Resolved memory leaks in animation controllers
- ✅ Fixed widget not updating on some devices
- ✅ Corrected language switching requiring app restart
- ✅ Fixed settings not saving properly
- ✅ **Fixed notification permission system for Android 13+ devices** (v2.0.0+4)
- ✅ **Resolved navigation issues in permission dialogs** (v2.0.0+4)
- ✅ **Improved permission grant reliability across all Android devices** (v2.0.0+4)

---

## 📱 **NEW PERMISSIONS REQUIRED**

This version requires several new permissions to support advanced features:

### **Critical Permissions:**

1. **📬 POST_NOTIFICATIONS** (Android 13+)
   - **Why**: Required to show prayer time notifications on Android 13 and above
   - **Usage**: Display prayer time reminders, Adhan notifications, and persistent prayer countdown
   - **User Control**: Can be disabled in app settings or system settings

2. **⏰ SCHEDULE_EXACT_ALARM**
   - **Why**: Ensures prayer notifications appear at precise prayer times
   - **Usage**: Schedule exact-time notifications for each prayer
   - **Importance**: Critical for accurate Adhan timing

3. **⏰ USE_EXACT_ALARM**
   - **Why**: Alternative exact alarm permission for different Android versions
   - **Usage**: Backup permission for exact alarm scheduling
   - **Importance**: Ensures compatibility across Android versions

4. **🔔 RECEIVE_BOOT_COMPLETED**
   - **Why**: Reschedule prayer notifications after device restart
   - **Usage**: Automatically set up prayer reminders when phone boots
   - **Importance**: Ensures notifications work after device restart

5. **🔋 WAKE_LOCK**
   - **Why**: Wake device for prayer notifications
   - **Usage**: Ensure notification appears even when device is sleeping
   - **Importance**: Critical for timely prayer reminders

### **Existing Permissions (Still Required):**

6. **📍 ACCESS_FINE_LOCATION**
   - **Why**: Calculate accurate prayer times based on GPS location
   - **Usage**: Get precise latitude/longitude for prayer calculations
   - **User Control**: Can manually enter location instead

7. **📍 ACCESS_COARSE_LOCATION**
   - **Why**: Backup location method if GPS unavailable
   - **Usage**: Approximate location for prayer times
   - **Privacy**: Less precise than fine location

8. **🌐 INTERNET**
   - **Why**: Stream Islamic radio, download Quran audio, sync data
   - **Usage**: Online features like radio streaming, Quran recitation
   - **User Control**: Most features work offline with cached data

9. **📳 VIBRATE**
   - **Why**: Vibration feedback for prayer notifications
   - **Usage**: Alert user even when phone is on silent
   - **User Control**: Can be disabled in notification settings

### **Hardware Features:**

10. **🧭 ACCELEROMETER** (Required)
    - **Why**: Qibla compass needs accelerometer for device orientation
    - **Usage**: Detect phone tilt for accurate Qibla direction

11. **🧭 COMPASS/MAGNETOMETER** (Required)
    - **Why**: Determine magnetic north for Qibla direction
    - **Usage**: Calculate direction to Mecca from user's location

### **Privacy Notice:**
- ✅ All permissions used only for their stated purposes
- ✅ Location data never shared with third parties
- ✅ No tracking or analytics
- ✅ All sensitive data stored locally
- ✅ User can revoke permissions anytime in system settings

---

## 📦 **DEPENDENCIES & PACKAGES**

### **New Package Additions:**
- `quran_library: 2.2.3+1` - Complete Quran library with audio and tafsir
- `adhan_dart: ^2.0.0` - Accurate prayer time calculations
- `home_widget: ^0.6.0` - Android home screen widgets
- Additional supporting packages for enhanced functionality

### **Updated Packages:**
- Updated all existing packages to latest stable versions
- Security patches applied
- Performance improvements in dependencies
- Bug fixes from upstream packages

---

## 📊 **VERSION STATISTICS**

### **Files Changed**: 266 files
### **Code Changes**:
- ✅ **+299,180 lines added** (new features, Quran library, improvements)
- ✅ **-6,050 lines removed** (deprecated code, optimizations)
- ✅ **Net Change**: +293,130 lines

### **Major Components Added**:
- 📖 Complete Quran library infrastructure (150+ files)
- 🎵 Audio recitation system with 28+ reciters
- 📚 Tafsir interpretation system
- 🔔 Advanced notification system
- 🎨 New splash screen with animations
- ⚙️ Redesigned settings architecture
- 🏠 Home screen widgets (2 variants)

### **Assets Added**:
- 13 high-quality Adhan audio files (5.5+ MB)
- 4 custom Arabic fonts for Quran display
- 20+ SVG icons for UI elements
- Comprehensive Quran JSON data (113K+ lines)
- Tafsir As-Sa'di complete text (43K+ lines)

---

## 🌍 **LOCALIZATION**

### **Enhanced Translations**:
- **Arabic (العربية)**: 106 new translation strings
- **English**: 106 new translation strings

### **New Translation Categories**:
- Prayer notification messages
- Adhan customization labels
- Settings section titles and descriptions
- Quran feature labels
- Error messages and help text
- Widget text content
- Donation button text

### **Translation Quality**:
- Native speaker reviewed
- Culturally appropriate terminology
- Consistent Islamic terms usage
- Clear, concise descriptions

---

## 🎯 **TARGET PLATFORMS**

This version is optimized for:

- ✅ **Android**: Full feature support (API 21+)
  - Tested on Android 8.0 - 14.0
  - Home widgets exclusive to Android
  - Notification features for Android 13+
  
- ✅ **iOS**: Core features supported (iOS 12.0+)
  - Prayer times and Qibla
  - Quran reading and audio
  - Limited notification features (iOS restrictions)
  
- ⚠️ **Web**: Basic features only
  - Quran reading (no audio)
  - Prayer times (manual location)
  - Limited functionality due to browser restrictions

- ⚠️ **Windows/Linux/macOS**: Desktop support
  - Core features available
  - Prayer times with manual location
  - Quran reading without audio
  - No notifications or widgets

---

## ⚡ **BREAKING CHANGES**

### **For Existing Users:**

1. **Quran Feature Completely Redesigned**:
   - Old Quran reading interface replaced
   - Bookmarks need to be re-added (incompatible format)
   - Font settings reset to defaults
   - New font download required

2. **Settings Structure Changed**:
   - All settings reorganized into new sections
   - Previous settings preserved but may need reconfiguration
   - Theme settings migrated automatically

3. **Notification System Rebuilt**:
   - All notification preferences reset
   - Need to grant notification permission again (Android 13+)
   - Adhan sounds need to be selected again

4. **Prayer Calculation Method**:
   - Default method may have changed
   - Users should verify and reselect preferred method
   - More accurate calculations may show slightly different times

### **Removed Features:**
- ❌ Old Quran repository implementation
- ❌ Hasanat tracking models (deprecated)
- ❌ Legacy font size selector widgets
- ❌ Old calendar picker widget
- ❌ Enhanced date card (replaced with better version)

---

## 🎓 **USER GUIDANCE**

### **First Launch After Update:**

1. **Grant Permissions**:
   - Allow location access for accurate prayer times
   - Enable notifications for prayer reminders (Android 13+)
   - Approve exact alarm permission for precise timing

2. **Configure Prayers**:
   - Go to Settings → Prayer Calculation
   - Select your preferred calculation method
   - Verify prayer times are correct for your location

3. **Customize Adhan**:
   - Navigate to Settings → Adhan Sounds
   - Select preferred Adhan for each prayer
   - Preview sounds before confirming
   - Adjust volume as needed

4. **Explore Quran Features**:
   - Open Quran tab to see new interface
   - Select preferred font and size
   - Try audio recitation with different reciters
   - Long-press any Ayah to see Tafsir

5. **Add Home Widgets** (Android):
   - Long-press home screen
   - Select Widgets → Wadhakir
   - Choose between Compact or Detailed widget
   - Place on home screen for quick access

---

## 🚀 **WHAT'S NEXT**

### **Planned for Future Versions:**

- 📖 More Tafsir books and translations
- 🎙️ Audio Tafsir (spoken interpretations)
- 📚 Islamic library with Hadith collections
- 🕋 Qibla AR mode with camera overlay
- 📅 Full Islamic calendar with events
- 🤲 Dua collection with audio
- 📊 Prayer statistics and tracking
- 🌙 Ramadan special features
- 🎨 More theme options and customizations
- ☁️ Cloud sync for bookmarks and settings

---

## 🙏 **ACKNOWLEDGMENTS**

### **Special Thanks To:**
- **Quran Library Package**: alheekmah team for the comprehensive Quran package
- **Adhan Dart**: Contributors for accurate prayer time calculations
- **Muezzins**: All the honored Muezzins whose Adhan recordings we use
- **Scholars**: For providing Tafsir As-Sa'di and other interpretations
- **Beta Testers**: Community members who helped test new features
- **Contributors**: All developers who contributed code and suggestions

---

## 📞 **SUPPORT & FEEDBACK**

### **Need Help?**
- 📧 **Email**: Contact through app's About section
- 💬 **Feedback**: Use in-app feedback form
- 🐛 **Report Bugs**: Submit through GitHub issues
- ⭐ **Rate Us**: Leave a review on Play Store/App Store

### **Follow Development:**
- Stay updated on new features
- Join our community discussions
- Get early access to beta versions

---

## 🔐 **SECURITY & PRIVACY**

- ✅ **No Data Collection**: We don't collect or store any personal data
- ✅ **No Analytics**: No tracking or analytics services used
- ✅ **Local Storage**: All data stored locally on your device
- ✅ **No Ads**: Completely ad-free experience
- ✅ **Open Source**: Code available for security review
- ✅ **Secure Permissions**: Only essential permissions requested
- ✅ **No Third-Party Services**: Except for maps and location services

---

## 📅 **RELEASE INFORMATION**

- **Version**: 2.0.0+4
- **Build Number**: 4
- **Previous Version**: 1.1.0+3
- **Release Type**: Major Update
- **Release Date**: December 2024
- **Minimum Android Version**: Android 6.0 (API 21)
- **Minimum iOS Version**: iOS 12.0
- **Flutter SDK**: 3.35.0+
- **Dart SDK**: 3.5.0+

---

## 📝 **INSTALLATION NOTES**

### **Fresh Installation:**
- Download size: ~50 MB
- First launch downloads: ~10 MB (Quran fonts)
- Total app size after setup: ~60-70 MB
- Offline usage: Most features work without internet

### **Update from v1.1.0:**
- Update size: ~30 MB
- Settings will be migrated automatically
- Some features require reconfiguration
- First launch after update may take longer (data migration)

---

## ✨ **SUMMARY**

Wadhakir v2.0.0+4 represents a **massive leap forward** for the app, bringing professional-grade Islamic features that rival dedicated Quran apps, while maintaining the simplicity and beauty users love.

### **Highlights:**
- 📖 **Complete Quran experience** with 28+ reciters, Tafsir, and beautiful Arabic fonts
- 🎨 **Stunning visual design** from splash screen to every UI element
- 🔔 **Never miss a prayer** with advanced notifications and customizable Adhan
- ⚙️ **Complete control** over every aspect of the app through redesigned settings
- 🏠 **Quick access** with home screen widgets
- 🌍 **Your language, your theme** with full localization and theme options
- 💚 **Support development** through easy InstaPay donations

This update took months of development, included 299,000+ lines of code changes, and represents our commitment to providing the best Islamic app experience for our users.

**JazakAllahu Khairan** (May Allah reward you) for using Wadhakir and supporting its development! 🤲

---

**May Allah accept our efforts and make this app a means of benefit for all Muslims. Ameen.** 🌙

---

*Last Updated: December 2024*  
*Version: 2.0.0+4*  
*Document Version: 1.0*
