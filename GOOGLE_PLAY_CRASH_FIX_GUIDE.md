# 🔧 Fix Guide: Google Play "App Stability" Rejection

## 📋 Issue Summary
**Rejection Reason:** App crashed during Google Play testing and couldn't be evaluated for policy compliance  
**Version Code:** 9  
**Package:** com.bloom.wadhakir  

## 🔍 Common Causes & Solutions

Based on research and your app configuration, here are the most likely causes and fixes:

---

## ✅ Solution 1: Add Proguard Rules for Release Build (MOST LIKELY FIX)

When you build a release APK/AAB, code obfuscation can cause crashes if certain classes aren't protected.

### Fix:
1. **Create/Update proguard rules:**

Create or update `android/app/proguard-rules.pro`:

```proguard
# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Awesome Notifications
-keep class com.awesome.notifications.** { *; }
-dontwarn com.awesome.notifications.**

# Just Audio
-keep class com.ryanheise.just_audio.** { *; }

# Hive
-keep class com.hivedb.** { *; }
-keep class * extends com.hivedb.** { *; }

# Syncfusion
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# Quran Library
-keep class com.example.quran_library.** { *; }

# Permissions Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# Keep all model classes
-keep class com.bloom.wadhakir.data.models.** { *; }
-keep class com.bloom.wadhakir.domain.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Gson (if using JSON serialization)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
```

2. **Update `android/app/build.gradle.kts` to use proguard:**

---

## ✅ Solution 2: Handle Permission Crashes (HIGH PRIORITY)

Your app requests sensitive permissions (LOCATION, NOTIFICATIONS, SCHEDULE_EXACT_ALARM). If not handled properly, they can cause crashes.

### Fix in your code:

**Check if location permissions are handled with try-catch:**

```dart
// Example: Wrap permission requests in try-catch
Future<void> requestLocationPermission() async {
  try {
    final status = await Permission.location.request();
    if (status.isGranted) {
      // Proceed with location-based features
    } else if (status.isDenied) {
      // Show explanation
    } else if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
    }
  } catch (e) {
    debugPrint('Location permission error: $e');
    // Gracefully handle error - don't crash
  }
}
```

**For SCHEDULE_EXACT_ALARM (Android 14+):**

```dart
// Check if the permission is available before using
if (Platform.isAndroid) {
  try {
    final status = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }
  } catch (e) {
    debugPrint('Alarm permission not supported or error: $e');
    // Use alternative notification scheduling
  }
}
```

---

## ✅ Solution 3: Add Crash Prevention in main.dart

### Add global error handlers:

Update your `lib/main.dart`:

```dart
void main() async {
  // Add these error handlers at the very top of main()
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack Trace: ${details.stack}');
  };

  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error: $error');
    debugPrint('Stack Trace: $stack');
    return true;
  };

  // Wrap everything in try-catch
  try {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    
    // Your existing initialization code...
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('App initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still try to run the app with minimal features
    runApp(ErrorApp(error: e.toString()));
  }
}

// Simple error app in case of catastrophic failure
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('App initialization error. Please reinstall.'),
        ),
      ),
    );
  }
}
```

---

## ✅ Solution 4: Fix Potential Widget Initialization Crash

### Wrap Home Widget initialization in try-catch:

```dart
// In your initialization code
try {
  await HomeWidget.registerBackgroundCallback(backgroundCallback);
  await PrayerTimesHomeWidget.initialize();
  await HijriCalendarHomeWidget.initialize();
} catch (e) {
  debugPrint('Home widget initialization error: $e');
  // Continue without home widgets
}
```

---

## ✅ Solution 5: Update AndroidManifest.xml for Android 14+

Add queries for intents that might cause crashes:

Update `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Add queries for intent handling -->
    <queries>
        <!-- For URL launching -->
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="http" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <!-- For sharing -->
        <intent>
            <action android:name="android.intent.action.SEND" />
            <data android:mimeType="*/*" />
        </intent>
    </queries>

    <!-- Your existing permissions... -->
    
</manifest>
```

---

## ✅ Solution 6: Test on Internal Testing Track First

Before submitting to production:

1. **Upload to Internal Testing:**
   - Go to Play Console → Testing → Internal testing
   - Create new release
   - Upload your AAB
   - Add test users (your email)

2. **Download and test from Play Store:**
   - Install the app from Internal Testing
   - Test all features:
     - Location/Qibla compass
     - Prayer time notifications
     - Audio playback (radio)
     - Widgets
     - Share functionality

3. **Check for crashes:**
   - Use the app for at least 30 minutes
   - Test on different Android versions if possible
   - Check Play Console → Quality → Android vitals for any crashes

---

## ✅ Solution 7: Build Release AAB Correctly

### Proper build command:

```bash
# Clean first
flutter clean

# Get dependencies
flutter pub get

# Build release AAB with obfuscation
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# The AAB will be at: build/app/outputs/bundle/release/app-release.aab
```

**Important:** Use `--obfuscate` and `--split-debug-info` for production builds!

---

## 🧪 Testing Checklist Before Resubmission

- [ ] Test app on real device with release build
- [ ] Test location permission flow
- [ ] Test notification permission flow
- [ ] Test alarm permission (Android 14+)
- [ ] Test audio playback
- [ ] Test widgets installation
- [ ] Test share functionality
- [ ] Check for any error messages in logcat
- [ ] Upload to Internal Testing first
- [ ] Test from Internal Testing track
- [ ] Check Android Vitals for crashes

---

## 📝 Steps to Fix and Resubmit

### Step 1: Apply Proguard Rules
1. Create `android/app/proguard-rules.pro` with the rules above
2. Update `build.gradle.kts` to enable proguard

### Step 2: Add Error Handling
1. Add global error handlers in `main.dart`
2. Wrap permission requests in try-catch
3. Add queries to AndroidManifest.xml

### Step 3: Test Locally
```bash
flutter clean
flutter build apk --release
# Install on real device and test
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Step 4: Build for Play Store
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Step 5: Upload to Internal Testing
- Test thoroughly from Internal Testing track
- Verify no crashes in Android Vitals

### Step 6: Promote to Production
- Once stable in Internal Testing, promote to production

---

## 🎯 Most Likely Fix

Based on common Flutter app rejections, **the #1 most likely cause is missing Proguard rules** causing the release build to crash due to code obfuscation.

**Priority order:**
1. ✅ Add Proguard rules (Solution 1) - **START HERE**
2. ✅ Add error handlers (Solution 3)
3. ✅ Test with Internal Testing track (Solution 6)
4. ✅ Handle permissions properly (Solution 2)

---

## 📞 Need More Help?

If the app still crashes after these fixes:

1. **Check Android Vitals** in Play Console for crash logs
2. **Use Firebase Crashlytics** to get detailed crash reports
3. **Enable logcat** while testing release build:
   ```bash
   adb logcat | grep -i flutter
   ```

---

## 🚀 Quick Fix Script

I can help you implement these fixes. Would you like me to:
1. Create the proguard-rules.pro file
2. Update build.gradle.kts to use proguard
3. Add error handlers to main.dart
4. Update AndroidManifest.xml with queries
