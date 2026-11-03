#!/bin/sh
set -eu

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
link_root="$(cd "$repo_root/.." && pwd)"
main_root="$(dirname "$(git -C "$repo_root" rev-parse --path-format=absolute --git-common-dir)")"
main_parent="$(cd "$main_root/.." && pwd)"

for sibling in account-av apps-av; do
  target="$main_parent/$sibling"
  link="$link_root/$sibling"
  if [ ! -d "$target/web" ]; then
    echo "setup-worktree: missing sibling checkout $target (apps/web depends on $sibling/web)" >&2
    exit 1
  fi
  if [ "$link_root" = "$main_parent" ]; then
    continue
  fi
  if [ -L "$link" ]; then
    if [ "$(readlink "$link")" != "$target" ]; then
      echo "setup-worktree: $link points elsewhere; remove it and run again" >&2
      exit 1
    fi
  elif [ -e "$link" ]; then
    echo "setup-worktree: $link exists and is not a symlink; remove it and run again" >&2
    exit 1
  else
    ln -s "$target" "$link"
  fi
done

if [ -f "$main_root/.env" ] && [ ! -e "$repo_root/.env" ] && [ "$main_root" != "$repo_root" ]; then
  ln -s "$main_root/.env" "$repo_root/.env"
fi

pnpm install --frozen-lockfile --reporter=silent

echo "Worktree ready: dependencies installed with a frozen lockfile."
