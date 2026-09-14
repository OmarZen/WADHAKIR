# 🌙 Monthly Islamic Fasting Reminders Feature

## 📖 Background

### What are the Recommended Fasting Days?
This feature covers voluntary (Nafl) fasting days that occur throughout the Hijri calendar:

#### Monthly Fasting Days (Every Hijri Month):
- **Ayyam al-Bid (الأيام البيض)**: The 13th, 14th, and 15th of each Hijri month (white days)
- **9th and 10th of each month**: Following the Sunnah pattern

#### Special Emphasis Days:
- **Tasu'a (تاسوعاء)**: The 9th day of Muharram (first month)
- **Ashura (عاشوراء)**: The 10th day of Muharram (first month)
- **Day of Arafah**: 9th of Dhul Hijjah (for non-pilgrims)

### Religious Significance
- **Highly recommended voluntary fasting** in Islam
- **Ayyam al-Bid**: Prophet Muhammad (PBUH) encouraged fasting these three days every month
- **Ashura fasting** (10th Muharram): Expiates sins of the previous year
- **9th and 10th together**: The Prophet (PBUH) said: *"If I live till the next year, I will fast on the ninth too"* (Muslim 1916)
- **Day of Arafah**: Expiates sins of two years (previous and coming year)

---

## 🎯 Feature Requirements

### Core Functionality
1. **Automatic Detection**
   - Detect Ayyam al-Bid (13th, 14th, 15th) of every Hijri month
   - Detect 9th and 10th of every Hijri month
   - Special emphasis on Muharram 9th (Tasu'a) and 10th (Ashura)
   - Detect Day of Arafah (9th Dhul Hijjah)
   - Use Hijri calendar calculations already in the app

2. **Smart Notifications**
   - Send reminders for upcoming monthly fasting days (1-3 days before)
   - Morning reminders on the fasting day itself
   - Evening reminders (eve of fasting day after Maghrib)
   - Special notifications for Ashura and Arafah with additional emphasis
   - Batch notifications for Ayyam al-Bid (13th-15th)

3. **User Preferences**
   - Enable/disable monthly fasting reminders
   - Choose which days to be reminded about (Ayyam al-Bid, 9th-10th, or both)
   - Choose notification timing (1, 2, or 3 days before)
   - Choose which reminders to receive (eve, morning, both)
   - Silent mode option for notifications
   - Special toggle for Muharram and Dhul Hijjah emphasis

4. **Information Display**
   - Show countdown to next fasting days in the app
   - Monthly fasting calendar view
   - Display educational content about the virtue of each fasting type
   - Show relevant Hadiths for each fasting day
   - Provide fasting guide (intention, timing, breaking fast)

---

## 🏗️ Technical Implementation Plan

### 1. Data Models
**Location**: `lib/data/models/`

Create models:
- `fasting_reminder_settings_model.dart` - User preferences for reminders
- `islamic_fasting_days_model.dart` - Data model for special fasting days

```dart
class FastingReminderSettings {
  bool monthlyFastingRemindersEnabled;
  bool ayyamAlBidEnabled; // 13th, 14th, 15th
  bool ninthTenthEnabled; // 9th and 10th of each month
  bool specialDaysEmphasis; // Muharram & Dhul Hijjah
  int daysBeforeNotification; // 1, 2, or 3
  bool eveReminder;
  bool morningReminder;
  bool silentMode;
  DateTime? lastNotificationSent;
}

class IslamicFastingDay {
  String nameAr;
  String nameEn;
  String descriptionAr;
  String descriptionEn;
  int hijriMonth; // 1-12 (null for monthly recurring)
  int hijriDay; // day of month
  bool isMonthlyRecurring; // true for days that repeat every month
  bool isSpecialDay; // true for Ashura, Arafah, etc.
  List<String> virtues; // Hadiths/benefits
  int rewardLevel; // 1-5 stars
  FastingDayType type; // AYYAM_AL_BID, NINTH_TENTH, SPECIAL
}

enum FastingDayType {
  AYYAM_AL_BID, // 13th, 14th, 15th
  NINTH_TENTH, // 9th and 10th
  SPECIAL, // Ashura, Arafah, etc.
}
```

### 2. Services
**Location**: `lib/features/fasting_reminders/services/`

Create services:
- `hijri_date_calculator_service.dart` - Calculate upcoming Hijri dates
- `fasting_notification_service.dart` - Handle notifications for fasting days
- `fasting_reminder_scheduler.dart` - Schedule notifications in advance

### 3. State Management (Cubit)
**Location**: `lib/features/fasting_reminders/cubit/`

Create Cubit:
- `fasting_reminders_cubit.dart` - Manage fasting reminder state
- `fasting_reminders_state.dart` - State definitions

States:
- `FastingRemindersInitial`
- `FastingRemindersLoading`
- `FastingRemindersLoaded` (with countdown data)
- `FastingRemindersError`

### 4. UI Screens
**Location**: `lib/features/fasting_reminders/views/`

Create screens:
- `fasting_calendar_screen.dart` - Show upcoming fasting days
- `ashura_info_screen.dart` - Detailed info about Tasu'a & Ashura
- `fasting_reminder_settings_screen.dart` - Configure notifications

Create widgets:
- `fasting_day_card_widget.dart` - Display fasting day info
- `countdown_to_ashura_widget.dart` - Show countdown timer
- `hadith_card_widget.dart` - Display related Hadiths
- `fasting_guide_widget.dart` - Show fasting instructions

### 5. Home Screen Integration
**Location**: `lib/features/home/views/widgets/`

Add to home screen:
- Small card/banner when Ashura is approaching (< 7 days)
- Countdown widget during Muharram month
- Quick link to fasting calendar

### 6. Localization
**Location**: `assets/lang/`

Add translations to `ar.json` and `en.json`:
```json
{
  "fasting": {
    "ayyam_al_bid": "الأيام البيض",
    "white_days": "الأيام البيض",
    "tasu_a": "تاسوعاء",
    "ashura": "عاشوراء",
    "arafah": "يوم عرفة",
    "muharram": "محرم",
    "dhul_hijjah": "ذو الحجة",
    "monthly_fasting": "الصيام الشهري",
    "voluntary_fasting": "صيام النافلة",
    "days_until_next_fasting": "متبقي على الصيام القادم",
    "days_until_ayyam_al_bid": "متبقي على الأيام البيض",
    "days_until_ashura": "متبقي على عاشوراء",
    "reminder_title_monthly": "تذكير بالصيام المستحب",
    "reminder_title_ayyam_al_bid": "تذكير بصيام الأيام البيض",
    "reminder_title_ashura": "تذكير بصيام عاشوراء",
    "reminder_body_ayyam_al_bid": "غداً بداية الأيام البيض (13-15)، يُستحب الصيام",
    "reminder_body_ashura": "غداً يوم عاشوراء، يُستحب الصيام",
    "virtue_ayyam_al_bid": "صيام الأيام البيض من السنن المستحبة",
    "virtue_ashura": "صيام عاشوراء يكفر ذنوب سنة ماضية",
    "virtue_arafah": "صيام يوم عرفة يكفر ذنوب سنتين",
    "fasting_guide": "دليل الصيام",
    "enable_reminders": "تفعيل تذكيرات الصيام",
    "enable_ayyam_al_bid": "تفعيل تذكير الأيام البيض",
    "enable_ninth_tenth": "تفعيل تذكير التاسع والعاشر",
    "enable_special_days": "تفعيل تذكير الأيام المميزة",
    "notification_timing": "توقيت الإشعارات",
    "fasting_calendar": "تقويم الصيام",
    "this_month_fasting": "صيام هذا الشهر"
  }
}
```

### 7. Notification Content
Create rich notifications with:
- **For Ayyam al-Bid**: 
  - Title: "🌙 تذكير بصيام الأيام البيض"
  - Body: "غداً بداية الأيام البيض (13-15 {month_name})، يُستحب الصيام"
- **For Ashura**:
  - Title: "🌙 تذكير بصيام عاشوراء وتاسوعاء"
  - Body: Contextual message based on timing
- **For 9th-10th monthly**:
  - Title: "🌙 تذكير بالصيام المستحب"
  - Body: "غداً التاسع/العاشر من {month_name}، يُستحب الصيام"
- Action buttons: "معرفة المزيد" (Learn More), "تم" (Done)
- Deep link to fasting info screen

---

## 📱 User Flow

### First Time Setup (After Feature Launch)
1. User opens app after update
2. Show onboarding dialog explaining new monthly fasting reminders feature
3. Ask user: "Would you like to receive reminders for voluntary fasting days?"
4. Take to settings to configure preferences (Ayyam al-Bid, 9th-10th, special days)
5. Schedule notifications based on preferences

### Throughout Each Hijri Month
1. **7 days before Ayyam al-Bid**: Show countdown card on home screen
2. **3 days before 13th**: Send first reminder notification (if enabled)
3. **Evening before 13th**: Send eve notification
4. **Morning of 13th, 14th, 15th**: Send morning reminders
5. **Similar flow** for 9th and 10th if enabled

### Special Months (Muharram & Dhul Hijjah)
1. **Week before Ashura**: Enhanced notifications and home screen banners
2. **Week before Arafah**: Special countdown and preparation reminders
3. **Additional educational content** for these special days

### Notification Flow
1. User receives notification
2. Tap notification → Opens fasting info screen
3. Screen shows:
   - Countdown to next fasting days
   - Current month's fasting calendar
   - Virtues and Hadiths
   - Fasting guide (intention, times)
   - Related actions (set alarm, prepare suhoor)

---

## 🎨 UI/UX Design Guidelines

### Colors
- **Primary**: Use app's existing theme colors
- **Highlight**: Gold/amber for special days (#FFB74D)
- **Accent**: Teal for countdown (#26A69A)

### Icons
- `Icons.calendar_month` - Calendar view
- `Icons.notifications_active` - Reminders
- `Icons.restaurant_menu` - Fasting
- `Icons.wb_twilight` - Dawn/Dusk times
- `Icons.menu_book` - Hadiths
- `Icons.timer` - Countdown

### Layout
- Card-based design for fasting days
- Circular countdown widget (similar to prayer countdown)
- Bottom sheet for quick fasting guide
- Swipeable cards for multiple fasting days

---

## 📊 Data Sources

### Hijri Calendar Integration
- Use existing `HijriDateTime` from Syncfusion
- Calculate Muharram dates for current and next year
- Store calculated dates locally to avoid recalculation

### Hadith Content
Prepare authentic Hadiths about Ashura:
1. Bukhari 2006 - Prophet's keenness to fast Ashura
2. Muslim 1916 - Fasting on 9th and 10th
3. Related virtues and rewards

---

## ✅ Implementation Checklist

### Phase 1: Core Infrastructure ✅ COMPLETE
- [x] Create data models
- [x] Set up Cubit for state management
- [x] Implement Hijri date calculator service
- [x] Create notification service
- [x] Add localization strings
- [x] Implement repository pattern with clean architecture
- [x] Create use cases for settings management
- [x] Proper JSON serialization with error handling

**Phase 1 Summary:** See [PHASE_1_SUMMARY.md](PHASE_1_SUMMARY.md) for complete details.

### Phase 2: UI Components ✅ COMPLETE
- [x] Design and build fasting calendar screen
- [x] Create fasting info/detail screen  
- [x] Build fasting day card widget
- [x] Design countdown widget for home screen
- [x] Create settings widget for preferences
- [x] Implement proper color coding and themes
- [x] Islamic patterns and visual identity
- [x] Full RTL/LTR support

**Phase 2 Summary:** See [PHASE_2_SUMMARY.md](PHASE_2_SUMMARY.md) for complete details.

### Phase 3: Integration & Testing 🚧 NEXT
- [ ] Implement notification scheduler
- [ ] Set up background notification logic
- [ ] Add notification actions
- [ ] Test notification timing accuracy

### Phase 4: Testing & Polish
- [ ] Test with different Hijri dates
- [ ] Test notifications on different devices
- [ ] Verify localization (Arabic & English)
- [ ] Add analytics tracking
- [ ] Performance optimization

### Phase 5: Documentation
- [ ] User guide for feature
- [ ] Developer documentation
- [ ] Update CHANGELOG.md
- [ ] Create PR with comprehensive description

---

## 🧪 Testing Scenarios

1. **Date Calculation**
   - Verify Muharram 9th and 10th detection
   - Test across Gregorian year boundaries
   - Validate countdown accuracy

2. **Notifications**
   - Test notification timing (1, 2, 3 days before)
   - Verify eve and morning reminders
   - Test notification actions and deep links

3. **User Preferences**
   - Test enable/disable functionality
   - Verify settings persistence
   - Test silent mode

4. **UI/UX**
   - Test on different screen sizes
   - Verify RTL layout for Arabic
   - Test dark/light themes
   - Validate accessibility

---

## 📈 Future Enhancements

- Add reminders for other voluntary fasting days:
  - Mondays and Thursdays (weekly pattern)
  - Six days of Shawwal (after Ramadan)
  - Most of Sha'ban month
- Fasting tracker/journal with history
- Statistics on completed fasts (monthly/yearly)
- Community features (friends fasting together)
- Suhoor time calculator with smart alarm
- Integration with recipe suggestions for suhoor
- Personalized fasting schedule based on user capacity
- Integration with health apps to track fasting benefits
- Ramadan preparation mode (practice fasting)

---

## 🔗 Related Files to Modify

1. **Main Navigation**: `lib/features/home/views/screens/home_screen.dart`
2. **Settings Integration**: `lib/features/settings/views/screens/settings_screen.dart`
3. **Notification Service**: Extend existing notification framework
4. **Hijri Calendar**: Use from `lib/core/utils/date_utils.dart`

---

## 📝 Notes

- This feature should **not** interfere with existing prayer time notifications
- Use existing notification channels appropriately
- Ensure battery optimization doesn't block notifications
- Follow Islamic calendar conventions strictly
- Monthly reminders should be smart (not overwhelming with too many notifications)
- Consider time zones for evening/morning reminders
- Consult with Islamic scholars if needed for accuracy

---

**Branch**: `feature/monthly-fasting-reminders`  
**Estimated Time**: 2-3 weeks  
**Priority**: High (valuable feature for users)  
**Complexity**: Medium-High
