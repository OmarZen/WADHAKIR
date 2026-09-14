# Adhan notification fixes + iOS readiness — implementation notes

This documents what changed for the adhan/notification bugs and iOS support, and
the remaining steps that must be done on the MacBook (Xcode) because they can't
be built/tested off-device.

## 1. Adhan notification fixes (done, Android + iOS-compatible)

**Root problem:** the adhan was played by a Dart audio player triggered from the
`onDisplayed` notification listener on a *silent* channel. That fails when the
app is killed (wrong/no sound), and buffered "displayed" events replayed at app
launch (adhan playing on app open).

**What changed:**

- **Reliable playback — the correct adhan is now baked into the notification
  channel.** There is one Android channel per adhan sound (`adhan_<key>_v1`) with
  the mp3 as the channel `soundSource` (`resource://raw/…`). Android plays it via
  the OS, so the chosen adhan fires reliably even when the app is closed or the
  phone is locked. Files live in `android/app/src/main/res/raw/adhan_*.mp3`
  (ASCII-named copies of the Arabic assets). Catalog + key→resource mapping:
  `lib/core/constants/adhan_sounds.dart`. Channel creation:
  `lib/data/repositories/notification_repository_impl.dart` (`_adhanSoundChannels`).
- **Strong vibration + silent-mode behaviour.** Each adhan channel has
  `enableVibration: true` with `highVibrationPattern`. When the phone is on
  silent/vibrate, Android suppresses the sound and only the strong vibration
  fires — matching the requested "vibrate instead of sound when muted."
- **Stop control.** Every prayer notification has a "إيقاف الأذان / Stop" action
  button; tapping it (or dismissing the notification, or tapping to open the app)
  stops the adhan. See note (2c) for the one remaining piece (hardware volume key
  while fully closed).
- **BUG "adhan plays on app open" fixed.** `onDisplayed`
  (`lib/core/notifications/app_notification_listeners.dart`) now ignores any event
  whose scheduled time isn't within 90s of now (stale replays), de-dupes by id,
  and only plays the in-app full adhan on **iOS while foreground**. On Android the
  channel already plays it.
- **BUG "some prayers don't fire / stop after a day" fixed.** Notifications are
  now scheduled for a **multi-day horizon** (7 days Android / 5 iOS) instead of
  today only, with per-day non-colliding ids
  (`scheduleMultiDayPrayerNotifications`). The wasteful 10-second
  cancel+reschedule churn is gone: `main.dart`'s prayer-times listener has a
  `listenWhen` that ignores countdown re-emits, and the cubit skips a reschedule
  when the plan signature is unchanged (`prayer_times_cubit.dart`).
- **"Default" stays the system beep** (per your choice). Only an explicitly
  chosen adhan plays a full adhan.
- **Persistent "next prayer" notification** is now guarded to Android only.

## 2. Steps you must run on the MacBook

### 2a. iOS adhan clips — DONE ✅ (nothing to do)

iOS custom-adhan notification sounds are fully wired now:
- 13 `.aiff` clips (≤29s) generated in `ios/Runner/Sounds/` — **`.aiff`, not `.caf`**:
  awesome_notifications' iOS resolver hardcodes the `.aiff` extension
  (`IosAwnCore AudioUtils.getSoundFromResource` → `withExtension: "aiff"`), so
  `.caf`/`.mp3` would be silently ignored.
- They're added to the **Runner** target's Copy Bundle Resources and verified in
  the built app (`Runner.app/*.aiff`).
- The Dart side references them as `resource://raw/<key>` (resolves to
  `<key>.aiff` in the bundle) for iOS; on Android the sound still comes from the
  per-sound notification channel.

Only re-run `bash ios/Runner/Sounds/generate_adhan_aiff.sh` (needs `ffmpeg`) if
you change the source adhans; if you add/remove clips, re-add them to the Runner
target in Xcode (File Inspector → Target Membership → Runner).

### 2b. Signing, App Group, icons

Open `ios/Runner.xcworkspace` in Xcode:

1. **Signing** (required — needs your Apple ID): Runner target → Signing &
   Capabilities → check "Automatically manage signing" → select your personal
   Team. This sets `DEVELOPMENT_TEAM`.
2. **App Group** (required for widgets): Runner → Signing & Capabilities → **+
   Capability → App Groups** → add `group.com.bloom.wadhakir`. The entitlements
   file already exists at `ios/Runner/Runner.entitlements`; make sure Runner's
   "Code Signing Entitlements" build setting points to it (Xcode sets this when
   you add the capability).
3. **App icon alpha fix** (App Store rejects icons with transparency):
   ```bash
   dart run flutter_launcher_icons
   ```
4. Build:
   ```bash
   flutter clean && flutter pub get
   flutter precache --ios
   cd ios && pod install && cd ..
   flutter build ios --simulator      # sanity build, no signing
   flutter run                         # simulator, then a real device
   ```

Already done for you: `Info.plist` (location + motion strings, ATS for HTTP
radio, trimmed background modes, encryption flag), localized permission strings
(`ar/en.lproj/InfoPlist.strings`), `Podfile` (min iOS 15 + permission macros),
`Runner.entitlements`, and hiding App-Lock / Floating-Dhikr in Settings on iOS.

### 2c. Native adhan foreground service — OPTIONAL follow-up (Android)

One requested behaviour isn't covered by the channel approach: **stopping the
adhan with the hardware volume buttons while the app is fully closed.** Nothing
of ours runs at that moment (the OS plays the channel sound), so a volume press
only lowers the alarm volume. Today you stop a closed-app adhan by tapping the
notification's **Stop** button, dismissing it, or opening the app. Flip-to-mute
and volume-to-mute work while the app is open.

To get true volume-key stop while closed, we'd add a native Android foreground
service (AlarmManager → BroadcastReceiver → a MediaPlayer service with a
MediaSession + volume ContentObserver + full-screen alert Activity). It's a
sizeable native piece that needs on-device iteration — flagged as a follow-up so
we don't ship untested Kotlin that could break the Android build. Say the word
and it's the next task.

## 3. iOS home-screen widgets (WidgetKit) — extension is BUILT

A WidgetKit app-extension target `WadhakirWidgets` now exists (`ios/WadhakirWidgets/`)
and is embedded in the app. It ships **all 6 SwiftUI widgets** (RTL), matching the
`iOSName`s the Flutter app already passes to `HomeWidget.updateWidget`:

| Widget (kind) | Type | Reads |
|---|---|---|
| `PrayerTimesWidget` | data | `fajr…isha`, `nextPrayerArabic`, `timeUntilNext`, `location`, `hijri_date` |
| `PrayerTimesListWidget` | data | same, vertical list, highlights next prayer |
| `GlassPrayerNextWidget` | image | PNG path in `glass_prayer_next_image` |
| `GlassPrayerDetailWidget` | image | PNG path in `glass_prayer_detail_image` |
| `GlassClockWidget` | live clock | minute timeline + next prayer |
| `HijriCalendarWidget` | data | `hijri_date_display`, `hijri_month_year`, `gregorian_date_display` |

Image widgets load the PNG that `home_widget.renderFlutterWidget` writes into the
shared App Group container (the full file path is stored under the key). Data
widgets read the App Group `UserDefaults`.

**To see it:** run the app once (so it writes data), then long-press the home
screen → **+** → search "Wadhakir" → add the widget.

**How the target was added** (in case you ever need to recreate it): the Xcode
target was created programmatically with the `xcodeproj` gem (scripts were used
once), the "Embed App Extensions" build phase was moved **before** Flutter's
"Thin Binary" script phase to avoid the "Cycle inside Runner" build error, and
the App Group entitlement (`ios/WadhakirWidgets/WadhakirWidgets.entitlements`) was
added. For a **physical device**, add the App Groups capability to the
WadhakirWidgets target in Xcode too (same `group.com.bloom.wadhakir`).

### Original notes (kept for reference)

The 6 portable widgets (Next Prayer, Prayer Detail, Clock, Times list, Times
grid, Hijri calendar) need a **WidgetKit app-extension target** added in Xcode
(File → New → Target → Widget Extension "WadhakirWidgets"), sharing the App Group
above. The Flutter side already writes all the data:

- **Image widgets** (easiest): the app renders PNGs into the shared container
  (`glass_prayer_next_image`, `glass_prayer_detail_image`) — the SwiftUI widget
  just loads and shows them.
- **Data widgets**: read `UserDefaults(suiteName: "group.com.bloom.wadhakir")`
  keys already written by `prayer_times_home_widget.dart` (`fajr…isha`,
  `location`, `gregorian_date`, `day_name`, `hijri_date`, `nextPrayer`,
  `timeUntilNext`, `nextPrayerEpoch`, `nextPrayerArabic`).

This is a native-Swift + Xcode-target task best done with the workspace open and
a device to test on — flagged as a follow-up.

## 3b. Xcode 26 build fixes (already applied)

Your Xcode (26.5 / iOS 26 SDK) is newer than Flutter 3.44.4 fully supports, so the
iOS build hit three issues. All are fixed; noted here so you (and CI / another
machine) understand them:

1. **Flutter tool crash** (`parseOtoolArchitectureSections … Null check`) — caused
   by `path_provider_foundation` shipping an `objective_c` Dart-FFI native asset
   that Flutter couldn't parse under Xcode 26. Fixed by pinning
   `path_provider_foundation: 2.5.1` in `pubspec.yaml` `dependency_overrides`.
2. **`home_widget requires iOS 14`** via Swift Package Manager — Flutter's
   generated SPM package hardcodes iOS 13. Fixed by **disabling SPM**:
   ```bash
   flutter config --no-enable-swift-package-manager
   ```
   ⚠️ This is a **global** flutter setting, NOT stored in the repo. On CI or a
   different machine, run it once before building, or you'll hit the same error.
   (Those 3 plugins don't support SPM anyway, so CocoaPods is the right path.)
3. **`Using bridging headers with module interfaces is unsupported`** — framework
   pods leak `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` into the Runner app, which
   emits a Swift module interface that clashes with the ObjC bridging header on
   Xcode 26. Fixed by forcing `BUILD_LIBRARY_FOR_DISTRIBUTION = NO` (and
   `SWIFT_ENABLE_EXPLICIT_MODULES = NO`) on the Runner target in
   `ios/Flutter/Debug.xcconfig` + `Release.xcconfig`, and on pods via the Podfile.

The proper long-term fix for all three is upgrading Flutter to a version that
supports Xcode 26; these workarounds can be reverted then.

## 3c. Android build fix (AGP 9 + quran_library)

Your Android toolchain (AGP 9.1.0 / Gradle 9.3.1) rejects
`getDefaultProguardFile('proguard-android.txt')`, which `quran_library 4.2.x`
still uses — so `flutter build apk/appbundle` fails while configuring
`:quran_library`, before any app code compiles. This is unrelated to the adhan
changes (it's a dependency + bleeding-edge-AGP mismatch).

Fix: run **`bash android/fix_deps_proguard.sh`** after every `flutter pub get`
(it rewrites the cached dependency to the optimize proguard file). Re-run on CI /
a fresh machine before building. Long-term: report it to `quran_library` or align
AGP. The adhan Dart changes themselves are `flutter analyze`-clean and add only
`res/raw/adhan_*.mp3` resources + Dart — no Gradle/Kotlin changes.

**Second Android env issue on this Mac:** `android/app/build.gradle.kts` sets
`compileSdk = 37`, but only the *preview* platform `android-37.0` is installed,
so Gradle can't find `android-37` and fails at `:app:compileDebugJavaWithJavac`.
Either install the exact platform (`sdkmanager "platforms;android-37"`) or set
`compileSdk = 36` (stable, already installed). Also unrelated to the adhan work.
(With both worked around, the build gets fully past resource processing and
compiles the adhan/notification changes.)

## 4. Distribution reality

iOS apps **cannot** be sideloaded from a website like an Android APK. With a free
Apple ID you can install to **your own devices** (profiles expire after 7 days,
max 3 apps) and use the Simulator freely. **Public "download from a website"
distribution requires the paid Apple Developer Program ($99/yr)** → then the App
Store or TestFlight (TestFlight lets you share an install link with testers).
Everything above makes the app store-ready, so enrolling later is the only
missing piece for public distribution.
