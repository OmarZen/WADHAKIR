#!/usr/bin/env bash
#
# Workaround for an AGP 9 + quran_library incompatibility.
#
# quran_library (latest, 4.2.x) declares
#     getDefaultProguardFile('proguard-android.txt')
# in its android/build.gradle. Android Gradle Plugin 9.x turned that into a HARD
# ERROR ("no longer supported since it includes -dontoptimize"), so `flutter
# build apk/appbundle` fails while *configuring* :quran_library — before any app
# code compiles. There is no way to intercept a dependency's in-script call from
# the app project, so we patch the cached file to use the optimize variant.
#
# `flutter pub get` restores the pub-cache copy, so RE-RUN THIS after every
# `pub get` / on a fresh machine / in CI (before `flutter build`):
#
#     bash android/fix_deps_proguard.sh
#
# Proper long-term fix: report to quran_library to switch to
# 'proguard-android-optimize.txt' (or pin AGP to 8.x once its Gradle 9 support
# lands). Track and remove this script when that happens.
set -euo pipefail

# Honour $PUB_CACHE (CI runners often relocate the cache) and fall back to the
# default location. The glob covers quran_library-* rather than a pinned version
# on purpose: a hardcoded `quran_library-4.2.0` path silently stopped matching
# the moment the constraint moved to ^4.2.1, and a no-op patch step looks
# identical to a working one until Gradle fails.
PUB_CACHE_DIR="${PUB_CACHE:-$HOME/.pub-cache}"

found=0
for gradle in "$PUB_CACHE_DIR"/hosted/*/quran_library-*/android/build.gradle; do
  [ -f "$gradle" ] || continue
  if grep -q "getDefaultProguardFile('proguard-android.txt')" "$gradle"; then
    sed -i.orig \
      "s/getDefaultProguardFile('proguard-android.txt')/getDefaultProguardFile('proguard-android-optimize.txt')/" \
      "$gradle"
    echo "✓ patched $gradle"
    found=1
  else
    echo "• already patched (or not present): $gradle"
    found=1
  fi
done

[ "$found" = 1 ] || echo "No quran_library found in pub-cache — run 'flutter pub get' first."
