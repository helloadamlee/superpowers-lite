#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
assert_absent() {
  path=$1
  test ! -e "$repo_root/$path" || fail "legacy path remains: $path"
  printf 'PASS: absent %s\n' "$path"
}
assert_contains() {
  file=$1
  text=$2
  grep -Fq "$text" "$repo_root/$file" || fail "missing '$text' in $file"
}
assert_absent .claude-plugin
assert_absent hooks
assert_absent commands
assert_absent CLAUDE.md
assert_absent GEMINI.md
assert_absent docs/README.opencode.md
assert_absent docs/windows
assert_contains skills/codex-agent-routing/SKILL.md install-codex-agents.sh
assert_contains skills/codex-agent-routing/SKILL.md "Restore access"
printf 'All Codex runtime cleanup tests passed.\n'
