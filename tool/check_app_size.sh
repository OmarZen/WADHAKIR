#!/usr/bin/env bash
#
# Fail the build when a shipped artifact outgrows its size budget.
#
# Why this exists: Google Play caps the compressed download at 200 MB, and
# until R3 there was no size gate anywhere in CI. The failure surfaced at Play
# Console upload — *after* the tag was pushed and the GitHub release was
# already published, which is the most expensive moment to discover it.
#
# Usage:
#   tool/check_app_size.sh <budget-mb> <label> <path>
#
# Exits non-zero when the artifact is over budget, and prints a GitHub Actions
# error annotation so the failure lands on the workflow summary rather than
# only in the log.

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <budget-mb> <label> <path>" >&2
  exit 2
fi

budget_mb="$1"
label="$2"
path="$3"

# A missing artifact is a failure, not a pass. Gating on a file that silently
# stopped being produced would report green forever.
if [[ ! -f "$path" ]]; then
  echo "::error::$label — artifact not found at $path (did the build step change its output path?)"
  exit 1
fi

# BSD stat (macOS, for running this locally) vs GNU stat (ubuntu-latest).
if stat -f%z "$path" >/dev/null 2>&1; then
  bytes=$(stat -f%z "$path")
else
  bytes=$(stat -c%s "$path")
fi

# Decimal MB (10^6), NOT MiB. This matches what `flutter build` prints and what
# Google Play means by its 200 MB download cap — so the number this gate reports
# is the same number as the build log above it and the Play Console below it.
# Using MiB here would make a 131.1 MB APK read as 125.0 MB and quietly move the
# budget by 5%.
readonly MB=1000000
budget_bytes=$((budget_mb * MB))
# Two decimal places without bc, which is not installed on every runner image.
size_mb=$(awk -v b="$bytes" -v m="$MB" 'BEGIN { printf "%.2f", b / m }')
headroom_mb=$(awk -v b="$bytes" -v c="$budget_bytes" -v m="$MB" 'BEGIN { printf "%.2f", (c - b) / m }')

echo "$label: ${size_mb} MB (budget ${budget_mb} MB)"

if (( bytes > budget_bytes )); then
  echo "::error::$label is ${size_mb} MB, over its ${budget_mb} MB budget by ${headroom_mb#-} MB."
  echo "::error::Either shrink the artifact or raise the budget deliberately in the workflow — do not raise it to make a red build green."
  exit 1
fi

# Warn inside the last 5% so the budget gets raised deliberately in a PR rather
# than discovered by a release that fails the gate.
#
# 95%, not 90%: the arm64 APK sits at 131.1 MB against a 140 MB budget, and a
# 90% threshold would fire on every single build. A warning that is always
# present is a warning nobody reads.
warn_bytes=$((budget_bytes * 95 / 100))
if (( bytes > warn_bytes )); then
  echo "::warning::$label is ${size_mb} MB — only ${headroom_mb} MB under its ${budget_mb} MB budget."
fi

echo "$label is within budget (${headroom_mb} MB of headroom)."
