#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

checks=(
  "Video Credits"
  "source image"
  "Moments AV"
  "MomentsAV"
  "momentsav"
  "Guide and voice"
  "optional voice line"
  "short voice line"
  "who speaks"
  "quién habla"
  "wer spricht"
  "spoken exactly"
  "exact spoken text"
)

paths=(
  "apps/ios/AnimateAV/Resources"
  "docs"
  "README.md"
  "SUPPORT.md"
)

for phrase in "${checks[@]}"; do
  if git -C "$repo_root" grep -n -F "$phrase" -- "${paths[@]}" >/tmp/animate-public-copy-hygiene.txt; then
    printf 'Forbidden public Animate AV copy phrase: %s\n' "$phrase" >&2
    cat /tmp/animate-public-copy-hygiene.txt >&2
    exit 1
  fi
done

rm -f /tmp/animate-public-copy-hygiene.txt
printf 'Public copy hygiene check passed.\n'
