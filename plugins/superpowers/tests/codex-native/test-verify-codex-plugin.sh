#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
verifier="$repo_root/scripts/verify-codex-plugin.sh"
test -x "$verifier" || {
  printf 'FAIL: verifier is missing or not executable\n' >&2
  exit 1
}
"$verifier"
printf 'Codex package verifier test passed.\n'
