#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$repo_root/scripts/check-public-config-hygiene.sh"
"$repo_root/scripts/check-doc-links.sh"

printf 'Public hygiene checks passed.\n'
