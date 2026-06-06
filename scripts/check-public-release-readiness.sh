#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$repo_root/scripts/check-public-hygiene.sh"
"$repo_root/scripts/check-canonical-asset-gate.sh"

printf 'Public release readiness checks passed.\n'
