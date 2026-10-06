#!/usr/bin/env bash
# Shared helpers for the Claude-native contract tests.
plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

# frontmatter_field FILE KEY -> value of a top-level scalar key in the YAML frontmatter
frontmatter_field() {
  awk -v key="$2" '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---" { exit }
    infm {
      split($0, kv, ": ")
      if (kv[1] == key) { sub("^" key ": *", ""); print; exit }
    }
  ' "$1"
}
