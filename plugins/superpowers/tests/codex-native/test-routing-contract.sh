#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$script_dir/../.." && pwd)
resolver="$repo_root/scripts/resolve-codex-role.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_equals() {
  actual=$1
  expected=$2
  description=$3
  test "$actual" = "$expected" || fail "$description: expected $expected, got $actual"
  printf 'PASS: %s\n' "$description"
}

assert_fails() {
  description=$1
  shift
  if "$@" >/dev/null 2>&1; then
    fail "$description unexpectedly succeeded"
  fi
  printf 'PASS: %s\n' "$description"
}

test -x "$resolver" || fail "resolver is missing or not executable"
assert_equals "$("$resolver" mechanical)" superpowers_luna_implementer "mechanical tier"
assert_equals "$("$resolver" standard)" superpowers_terra_implementer "standard tier"
assert_equals "$("$resolver" frontier)" superpowers_astra_implementer "frontier tier"
assert_equals "$("$resolver" review)" superpowers_astra_reviewer "review tier"
assert_fails "unknown tier is rejected" "$resolver" unknown
assert_fails "mixed-case tier is rejected" "$resolver" Mechanical
assert_fails "missing tier is rejected" "$resolver"
assert_fails "extra argument is rejected" "$resolver" standard extra
printf 'All Codex routing contract tests passed.\n'
