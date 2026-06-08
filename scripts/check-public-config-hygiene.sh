#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tracked_files() {
  while IFS= read -r -d '' path; do
    if [[ "$path" != "scripts/check-public-config-hygiene.sh" && -f "$path" ]]; then
      printf '%s\0' "$path"
    fi
  done < <(git ls-files -z)
}

for forbidden_path in \
  ".env" \
  ".env.local" \
  ".env.example" \
  "apps/ios/Config/Local.xcconfig" \
  "apps/ios/Config/Local.xcconfig.example"
do
  if git ls-files --error-unmatch "$forbidden_path" >/dev/null 2>&1; then
    printf 'Forbidden tracked local config artifact: %s\n' "$forbidden_path" >&2
    exit 1
  fi
done

content_pattern='sk_(live|test)_[A-Za-z0-9_]+|CLERK_SECRET_KEY=|AVALSYS_APPLE_DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*[A-Z0-9]{10}|DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*[A-Z0-9]{10}|127\.0\.0\.1:8788'

if tracked_files | xargs -0 grep -E -n -I -- "$content_pattern"; then
  printf 'Forbidden config/secrets pattern found in tracked files.\n' >&2
  exit 1
fi

printf 'Public config hygiene check passed.\n'
