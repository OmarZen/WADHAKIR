# 🌙 Ashura & Tasu'a Fasting Reminders Feature

## 📖 Background

### What are Tasu'a and Ashura?
- **Tasu'a (تاسوعاء)**: The 9th day of Muharram (first month of Islamic calendar)
- **Ashura (عاشوراء)**: The 10th day of Muharram (first month of Islamic calendar)

### Religious Significance
- **Highly recommended fasting days** in Islam
- Prophet Muhammad (PBUH) recommended fasting on both days
- Ashura fasting **expiates sins of the previous year**
- The Prophet (PBUH) said: *"If I live till the next year, I will fast on the ninth too"* (Muslim 1916)
- Muslims fast on **both 9th and 10th** to distinguish from Jewish practice

---

## 🎯 Feature Requirements

### Core Functionality
1. **Automatic Detection**
   - Detect when Muharram 9th (Tasu'a) is approaching (1-3 days before)
   - Detect when Muharram 10th (Ashura) is approaching (1-3 days before)
   - Use Hijri calendar calculations already in the app

2. **Smart Notifications**
   - Send reminder notification 1-3 days before Tasu'a
   - Send reminder notification 1-3 days before Ashura
   - Send reminder on the eve of Tasu'a (Muharram 8th after Maghrib)
   - Send reminder on the eve of Ashura (Muharram 9th after Maghrib)
   - Morning reminder on Tasu'a day itself
   - Morning reminder on Ashura day itself

3. **User Preferences**
   - Enable/disable Ashura fasting reminders
   - Choose notification timing (1, 2, or 3 days before)
   - Choose which reminders to receive (eve, morning, both)
   - Silent mode option for notifications

4. **Information Display**
   - Show countdown to Tasu'a and Ashura in the app
   - Display educational content about the virtue of fasting
   - Show relevant Hadiths about Ashura
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
  bool ashuraRemindersEnabled;
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
  int hijriMonth;
  int hijriDay;
  List<String> virtues; // Hadiths/benefits
  int rewardLevel; // 1-5 stars
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
    "tasu_a": "تاسوعاء",
    "ashura": "عاشوراء",
    "muharram": "محرم",
    "days_until_tasu_a": "متبقي على تاسوعاء",
    "days_until_ashura": "متبقي على عاشوراء",
    "reminder_title": "تذكير بصيام عاشوراء",
    "reminder_body": "غداً يوم عاشوراء، يُستحب الصيام",
    "virtue_description": "صيام عاشوراء يكفر ذنوب سنة ماضية",
    "fasting_guide": "دليل الصيام",
    "enable_reminders": "تفعيل تذكيرات الصيام",
    "notification_timing": "توقيت الإشعارات"
  }
}
```

### 7. Notification Content
Create rich notifications with:
- Title: "🌙 تذكير بصيام عاشوراء وتاسوعاء"
- Body: Contextual message based on timing
- Action buttons: "معرفة المزيد" (Learn More), "تم" (Done)
- Deep link to fasting info screen

---

## 📱 User Flow

### First Time Setup (After Feature Launch)
1. User opens app after update
2. Show onboarding dialog explaining new feature
3. Ask user: "Would you like to receive reminders for Ashura fasting?"
4. Take to settings to configure preferences
5. Schedule notifications based on preferences

### During Muharram Month
1. **7 days before Tasu'a**: Show countdown card on home screen
2. **3 days before**: Send first reminder notification (if enabled)
3. **1 day before**: Send second reminder (eve notification)
4. **Morning of Tasu'a**: Send morning reminder with fasting intention
5. **Repeat** for Ashura (10th Muharram)

### Notification Flow
1. User receives notification
2. Tap notification → Opens Ashura info screen
3. Screen shows:
   - Countdown
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

### Phase 1: Core Infrastructure
- [ ] Create data models
- [ ] Set up Cubit for state management
- [ ] Implement Hijri date calculator service
- [ ] Create notification service
- [ ] Add localization strings

### Phase 2: UI Components
- [ ] Design and build fasting calendar screen
- [ ] Create Ashura info screen
- [ ] Build settings screen for preferences
- [ ] Design countdown widget
- [ ] Create home screen integration

### Phase 3: Notifications
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
  - Ayyam al-Bid (13th, 14th, 15th of each Hijri month)
  - Mondays and Thursdays
  - Six days of Shawwal
  - Arafah Day (9th Dhul Hijjah)
- Fasting tracker/journal
- Statistics on completed fasts
- Community features (friends fasting together)
- Suhoor time calculator with alarm
- Integration with recipe app for suhoor ideas

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
- Consult with Islamic scholars if needed for accuracy

---

**Branch**: `feature/ashura-fasting-reminders`  
**Estimated Time**: 1-2 weeks  
**Priority**: High (valuable feature for users)  
**Complexity**: Medium
