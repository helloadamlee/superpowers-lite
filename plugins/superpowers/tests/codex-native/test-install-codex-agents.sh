#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$script_dir/../.." && pwd)
installer="$repo_root/scripts/install-codex-agents.sh"
fixture=$(mktemp -d "${TMPDIR:-/tmp}/superpowers-agent-test.XXXXXX")

cleanup() {
  rm -rf "$fixture"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

assert_file() {
  test -f "$1" || fail "missing file: $1"
}

assert_same() {
  cmp -s "$1" "$2" || fail "files differ: $1 and $2"
}

assert_refuses() {
  if "$@" >/dev/null 2>&1; then
    fail "command unexpectedly succeeded: $*"
  fi
}

test -x "$installer" || fail "installer is missing or not executable"

clean_target="$fixture/clean"
"$installer" --target-dir "$clean_target"
for role in \
  superpowers-luna-implementer.toml \
  superpowers-terra-implementer.toml \
  superpowers-astra-implementer.toml \
  superpowers-astra-reviewer.toml; do
  assert_file "$clean_target/$role"
  assert_same "$repo_root/agents/$role" "$clean_target/$role"
done
pass "clean installation writes all exact role templates"

before=$(find "$clean_target" -maxdepth 1 -type f -printf '%f %s\n' | sort)
"$installer" --target-dir "$clean_target" --check
after=$(find "$clean_target" -maxdepth 1 -type f -printf '%f %s\n' | sort)
test "$before" = "$after" || fail "check mode changed the target"
pass "check mode is non-mutating"

modified_target="$fixture/modified"
"$installer" --target-dir "$modified_target"
printf '\nmodified\n' >> "$modified_target/superpowers-terra-implementer.toml"
assert_refuses "$installer" --target-dir "$modified_target"
pass "modified destination is rejected"

unsafe_target="$fixture/unsafe"
mkdir -p "$unsafe_target"
ln -s "$clean_target/superpowers-astra-reviewer.toml" "$unsafe_target/superpowers-astra-reviewer.toml"
assert_refuses "$installer" --target-dir "$unsafe_target"
pass "symlink destination is rejected"

missing_check_target="$fixture/missing-check"
assert_refuses "$installer" --target-dir "$missing_check_target" --check
test ! -e "$missing_check_target" || fail "check mode created a missing target"
pass "check mode rejects a missing target without creating it"

printf 'All Codex agent installer tests passed.\n'
