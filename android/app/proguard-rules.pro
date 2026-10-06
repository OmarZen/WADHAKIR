# R8 rules for the app module.
#
# There are deliberately no keep rules in this file. Read this before adding one.
#
# Every library in the build ships the R8 rules it needs inside its own AAR —
# AndroidX (WorkManager keeps worker names, androidx.startup its initializers),
# Kotlin, media3, CameraX, package:jni, and awesome_notifications, whose
# `-keep public class me.carda.** { *; }` covers its reflection and stored
# schedules — and Flutter's Gradle plugin adds flutter_proguard_rules.pro.
# Everything declared in AndroidManifest.xml (activities, services, receivers,
# the eight widget providers that home_widget looks up by name) keeps its name
# through the rules AAPT generates from the manifest. GeneratedPluginRegistrant
# is @Keep. An audit of the app's Kotlin and every Android plugin in the build
# (v3.4.2, October 2026) found no reflective or by-name lookup those do not
# already cover.
#
# This file used to keep io.flutter.**, androidx.**, kotlin.**,
# com.google.android.material.**, com.google.gson.**, every Service and
# BroadcastReceiver, and a dozen plugin packages, all with { *; }. R8 could
# then touch only 9% of the DEX, and Play Console flagged v3.4.1 with "DEX code
# optimisation is below our threshold": optimisation, obfuscation and shrinking
# all at 8%, against a 25% floor that Play enforces from February 2027 with
# reduced visibility and publishing capabilities (Android Developers Blog,
# 2026-08: android-developers.googleblog.com/2026/08/app-quality-memory-
# optimization-secure-onboarding.html). The same keeps held on to Material's
# BottomSheetDialog/SheetDialog and androidx's EdgeToEdge classes — unused, yet
# reported by Play as deprecated edge-to-edge API use. Removing them took
# coverage from 8% to about 91% and the DEX from 24 MB to 4.5 MB.
#
# The only Window.setStatusBarColor/setNavigationBarColor calls left are the
# Flutter embedding's own (FlutterActivity.onCreate and
# PlatformPlugin.setSystemChromeSystemUIOverlayStyle), both behind an
# SDK_INT < 35 check. R8 now renames them, so a Play report may show them as
# short names such as "pp0.onCreate" or "l8.o" (they change per build); look
# them up in that build's mapping.txt before chasing them.
#
# If something genuinely needs a rule:
#  - keep the specific class or member, never a whole package with { *; };
#  - prefer -keepnames, -keepclassmembers or -keep,allowobfuscation over -keep;
#  - write down next to it what looks it up by name, with file and line.
#
# Measure the effect. R8 writes the numbers Play reads on every minified build
# (and into the .aab); this needs no upload key:
#     flutter build apk --release
#     bash tool/check_r8_stats.sh 25 local \
#       build/app/intermediates/r8_metadata/release/minifyReleaseWithR8/r8-metadata.dat
# The tagged release workflow runs the same check on the .aab and fails below 25%.
