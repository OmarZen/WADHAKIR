#!/usr/bin/env bash
#
# Stops quran_library from loading a recitation over the network on every
# app start.
#
# QuranLibrary.init() ends with `AudioCtrl.instance;`, and AudioCtrl.onInit
# calls `lastAudioSource()`, which hands just_audio the last-played surah's URL
# with preloading on. ExoPlayer then buffers up to about a minute of
# recitation the user never asked for, on every launch, Quran tab opened or
# not: data and battery for nothing, and with no connection an
# `UnknownHostException` in the log. Nothing outside the package can switch it
# off: init() has no option for it and 5.0.1 is the latest release.
#
# Every real play path in the package sets its own source before playing
# (the last-surah button, choosing a surah, playAyah, playSurah), so the
# startup load is only needed by nothing. The patch keeps the rest of that
# startup work, restoring the last surah and position and publishing the media
# item, and drops only the player load.
#
# Like android/fix_deps_proguard.sh (which runs this), it edits the pub-cache
# copy, so it has to run after every `flutter pub get`, on a fresh machine and
# in CI, before `flutter build`. Remove it once quran_library stops preloading
# at startup.
set -euo pipefail

PUB_CACHE_DIR="${PUB_CACHE:-$HOME/.pub-cache}"
# Pinned on purpose, unlike the proguard patch: this rewrites Dart source, and
# a new release may have moved or fixed the call. A version that does not
# match fails loudly instead of being patched blind or skipped in silence.
EXPECTED_VERSION="5.0.1"
MARKER="wadhakir-patch: no audio preload at startup"

found=0
for dir in "$PUB_CACHE_DIR"/hosted/*/quran_library-*; do
  [ -d "$dir" ] || continue
  version="${dir##*/quran_library-}"
  if [ "$version" != "$EXPECTED_VERSION" ]; then
    echo "• skipping quran_library $version (this patch is for $EXPECTED_VERSION)"
    continue
  fi
  found=1
  file="$dir/lib/src/audio/controller/audio_ctrl.dart"
  if grep -q "$MARKER" "$file"; then
    echo "• already patched: $file"
    continue
  fi
  calls=$(grep -c "^[[:space:]]*await lastAudioSource();$" "$file" || true)
  if [ "$calls" != "3" ]; then
    echo "✗ expected 3 startup lastAudioSource() calls in $file, found $calls." >&2
    echo "  quran_library changed; re-check the patch before building." >&2
    exit 1
  fi
  perl -0pi.orig -e \
    's/^([ \t]*)await lastAudioSource\(\);$/$1\/\/ '"$MARKER"'\n$1loadLastSurahAndPosition();\n$1AudioHandler.instance.mediaItem.add(mediaItem);/mg' \
    "$file"
  echo "✓ patched $file"
done

if [ "$found" = 0 ]; then
  echo "✗ quran_library $EXPECTED_VERSION not found in $PUB_CACHE_DIR — run 'flutter pub get' first," >&2
  echo "  or update this patch if the dependency moved." >&2
  exit 1
fi
