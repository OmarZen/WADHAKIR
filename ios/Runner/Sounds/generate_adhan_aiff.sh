#!/usr/bin/env bash
#
# Regenerate the iOS notification adhan clips.
#
# iOS UNNotification sounds must be ≤30s, and awesome_notifications' iOS resolver
# (IosAwnCore AudioUtils.getSoundFromResource) looks up the bundle resource with
# a HARDCODED ".aiff" extension — so the clips MUST be .aiff (not .caf/.mp3).
# The Dart side references them as `resource://raw/<name>` which resolves to
# `<name>.aiff` in the Runner bundle.
#
# The generated files are already committed and added to the Runner target's
# "Copy Bundle Resources". Only re-run this if you change the source adhans:
#
#     bash ios/Runner/Sounds/generate_adhan_aiff.sh
#
# Requires ffmpeg (brew install ffmpeg). If you add/remove clips, also update the
# Runner target membership in Xcode (or re-run the add-to-target script).
set -euo pipefail

SRC="android/app/src/main/res/raw"
OUT="ios/Runner/Sounds"
mkdir -p "$OUT"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found. Install it with: brew install ffmpeg" >&2
  exit 1
fi

for f in "$SRC"/adhan_*.mp3; do
  name="$(basename "$f" .mp3)"
  echo "→ $name.aiff"
  # -t 29: cap under the 30s iOS limit. AIFF, 16-bit big-endian PCM.
  #
  # 16kHz MONO is not a quality compromise — it is exactly what the source mp3s
  # already are (16kbps, 16kHz, 1ch). Encoding the .aiff at 44.1kHz stereo would
  # upsample and duplicate a mono 16kHz signal into 4.9MB per clip (63MB across
  # 13) of identical information, paid twice over: once in git history forever,
  # once in every iOS app download. Matching the source costs 0.89MB per clip
  # (~12MB total) and is bit-for-bit as faithful.
  #
  # Keep -ar/-ac in sync with the source mp3s if those are ever re-mastered.
  ffmpeg -y -i "$f" -t 29 -ar 16000 -ac 1 -c:a pcm_s16be -f aiff \
    "$OUT/$name.aiff" -loglevel error
done

echo "Done. Generated $(ls "$OUT"/*.aiff | wc -l | tr -d ' ') .aiff clips in $OUT"
