#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failures=0

asset_pattern='(AppIcon|Launch|Splash|splash|appicon|icon|monogram|avi|Avi|AV)'
file_pattern='\.(png|jpg|jpeg|webp|heic|svg|pdf|imageset|appiconset|colorset|xcassets)$'

while IFS= read -r path; do
  if [[ "$path" =~ $file_pattern ]] && [[ "$path" =~ $asset_pattern ]]; then
    printf 'Canonical asset approval required before tracking: %s\n' "$path" >&2
    failures=$((failures + 1))
  fi
done < <(git ls-files apps docs)

if [ "$failures" -gt 0 ]; then
  cat >&2 <<'MSG'
Final icon, splash, AV monogram, and Avi artwork must come from approved
canonical assets. Do not commit generated or approximate brand artwork.
MSG
  exit 1
fi

printf 'Canonical asset gate passed.\n'
