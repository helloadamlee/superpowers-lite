#!/bin/sh
# Verify the Claude Code plugin: official manifest/skill/agent validation plus the
# focused contract tests. Run from anywhere; exits non-zero on the first failure.
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
plugin_root=$(CDPATH= cd "$script_dir/.." && pwd)
repo_root=$(CDPATH= cd "$plugin_root/.." && pwd)

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

command -v claude >/dev/null 2>&1 || fail "the claude CLI is required (npm install -g @anthropic-ai/claude-code)"
command -v jq >/dev/null 2>&1 || fail "jq is required"
command -v bash >/dev/null 2>&1 || fail "bash is required"

[ -f "$plugin_root/.claude-plugin/plugin.json" ] || fail "plugin manifest is missing"
jq empty "$plugin_root/.claude-plugin/plugin.json"
jq empty "$plugin_root/hooks/hooks.json"
jq empty "$plugin_root/hooks/session-context.json"

for script in review-package sdd-workspace task-brief; do
  [ -x "$plugin_root/scripts/$script" ] || fail "helper script is missing or not executable: $script"
  bash -n "$plugin_root/scripts/$script"
done

# Versions must agree across manifests.
plugin_version=$(jq -r .version "$plugin_root/.claude-plugin/plugin.json")
package_version=$(jq -r .version "$plugin_root/package.json")
[ "$plugin_version" = "$package_version" ] ||
  fail "version drift: plugin.json $plugin_version, package.json $package_version"

# Official validation. --strict turns unrecognized fields and missing metadata into errors.
claude plugin validate --strict "$plugin_root"
if [ -f "$repo_root/.claude-plugin/marketplace.json" ]; then
  claude plugin validate --strict "$repo_root"
  marketplace_source=$(jq -r '.plugins[] | select(.name == "superpowers-lite") | .source' "$repo_root/.claude-plugin/marketplace.json")
  [ "$marketplace_source" = "./claude" ] || fail "marketplace source must be ./claude, found $marketplace_source"
fi

for test_file in "$plugin_root"/tests/claude-native/test-*.sh; do
  [ -f "$test_file" ] || continue
  bash "$test_file"
done
bash "$plugin_root/tests/systematic-debugging/test-find-polluter.sh"

printf 'Claude Code plugin verification passed.\n'
