#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failures=0

check_target() {
  local source_file="$1"
  local target="$2"
  local clean_target target_path

  case "$target" in
    http://*|https://*|mailto:*|"#"*|"")
      return 0
      ;;
  esac

  clean_target="${target%%#*}"
  clean_target="${clean_target%%\?*}"

  case "$clean_target" in
    /*)
      target_path="${clean_target#/}"
      ;;
    *)
      target_path="$(dirname "$source_file")/$clean_target"
      ;;
  esac

  if [ ! -e "$target_path" ]; then
    printf 'Broken doc link in %s: %s\n' "$source_file" "$target" >&2
    failures=$((failures + 1))
  fi
}

while IFS= read -r source_file; do
  if [ ! -e "$source_file" ]; then
    continue
  fi

  while IFS= read -r target; do
    check_target "$source_file" "$target"
  done < <(
    perl -ne 'while (/(!?)\[[^\]]+\]\(([^)]+)\)/g) { print "$2\n" unless $1 }' "$source_file"
  )
done < <(git ls-files '*.md')

if [ "$failures" -gt 0 ]; then
  exit 1
fi

printf 'Documentation link check passed.\n'
