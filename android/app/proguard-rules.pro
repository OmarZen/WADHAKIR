# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Awesome Notifications (real Android package is me.carda.*; the old
# com.awesome.notifications rule matched nothing). Also keep any notification
# broadcast receivers/services so scheduled adhan/fasting/wird alarms survive
# release minification and still fire after the device wakes/reboots.
-keep class me.carda.awesome_notifications.** { *; }
-dontwarn me.carda.awesome_notifications.**
-keep public class * extends android.content.BroadcastReceiver { *; }
-keep public class * extends android.app.Service { *; }

# Just Audio & Audio Session
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audio_session.** { *; }

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

# Geolocator & Geocoding
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }

# Flutter Compass
-keep class com.hemanthraj.fluttercompass.** { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Package Info Plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
# Google Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# SQLite
-keep class com.tekartik.sqflite.** { *; }

# Volume Controller
-keep class com.yosemiteyss.flutter_volume_controller.** { *; }

# Sensors Plus
-keep class dev.fluttercommunity.plus.sensors.** { *; }

# HTTP
-keep class io.flutter.plugins.http.** { *; }

# Cached Network Image
-keep class com.github.danielgindi.PowerFileExplorer.** { *; }

# Keep all model classes (adjust package name if different)
-keep class com.bloom.wadhakir.data.models.** { *; }
-keep class com.bloom.wadhakir.domain.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Gson (for JSON serialization)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep generic signature
-keepattributes Signature

# Keep Parcelables
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Android X
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Material Components
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
