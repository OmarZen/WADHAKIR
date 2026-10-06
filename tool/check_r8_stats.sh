#!/usr/bin/env bash
#
# Fail the build when R8 leaves too much of the DEX unoptimised for Google Play.
#
# Why this exists: Play Console reads the stats R8 writes into every App Bundle
# (BUNDLE-METADATA/com.android.tools/r8.json) and flags a release whose
# optimisation, obfuscation or shrinking coverage is under 25% — "DEX code
# optimisation is below our threshold", which Play warns may cost the app
# visibility and publishing capabilities. v3.4.1 shipped at 8% in all three
# because android/app/proguard-rules.pro kept io.flutter.**, androidx.**,
# kotlin.** and Material whole. Nothing in CI measured it; Play Console did,
# after the release was live.
#
# Usage:
#   tool/check_r8_stats.sh <min-percent> <label> <path-to-aab-or-r8-metadata>
#
# The path is either an .aab, or the same JSON as R8 writes it during any
# minified build — which is how to measure without the upload key, since
# bundleRelease refuses to run without android/key.properties:
#
#   flutter build apk --release
#   tool/check_r8_stats.sh 25 local \
#     build/app/intermediates/r8_metadata/release/minifyReleaseWithR8/r8-metadata.dat
#
# Each category's coverage is 100 minus R8's `no<Category>Percentage`, which is
# the number Play Console shows. Exits non-zero when any category is under
# <min-percent>, with a GitHub Actions error annotation.

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <min-percent> <label> <path-to-aab-or-r8-metadata>" >&2
  exit 2
fi

min_percent="$1"
label="$2"
path="$3"

# A missing artifact is a failure, not a pass. Gating on a file that silently
# stopped being produced would report green forever.
if [[ ! -f "$path" ]]; then
  echo "::error::$label — artifact not found at $path (did the build step change its output path?)"
  exit 1
fi

# python3 rather than unzip + jq: it is on every runner image and on macOS, and
# reads the zip and the JSON without a second tool.
python3 -I - "$min_percent" "$label" "$path" <<'PY'
import json
import sys
import zipfile

min_percent = float(sys.argv[1])
label = sys.argv[2]
path = sys.argv[3]
is_bundle = path.endswith(".aab")
entry = "BUNDLE-METADATA/com.android.tools/r8.json"
source = f"{path} ({entry})" if is_bundle else path

try:
    if is_bundle:
        with zipfile.ZipFile(path) as bundle:
            stats = json.loads(bundle.read(entry))["stats"]
    else:
        with open(path) as metadata:
            stats = json.load(metadata)["stats"]
except KeyError:
    # No metadata means Play has nothing to read either — and an R8 that
    # stopped running (minify switched off) looks exactly like this.
    print(f"::error::{label} — no R8 stats in {source}. Is isMinifyEnabled still on for release?")
    sys.exit(1)

failed = False
for category, key in (
    ("Optimisation", "noOptimizationPercentage"),
    ("Obfuscation", "noObfuscationPercentage"),
    ("Shrinking", "noShrinkingPercentage"),
):
    coverage = 100.0 - float(stats[key])
    print(f"{label}: {category} {coverage:.2f}% (Play threshold {min_percent:g}%)")
    if coverage < min_percent:
        failed = True
        print(f"::error::{label}: R8 {category.lower()} covers only {coverage:.2f}% of the DEX, under {min_percent:g}%.")

if failed:
    print("::error::A broad -keep rule is the usual cause — see the header of android/app/proguard-rules.pro. "
          "Scope the rule to the classes that need it rather than lowering this threshold.")
    sys.exit(1)

print(f"{label}: R8 coverage is above {min_percent:g}% in every category.")
PY
