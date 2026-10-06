#!/usr/bin/env bash
# The Claude Code port must not carry Codex runtime files, tool names, or model IDs.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

for path in .codex-plugin agents/openai.yaml scripts/install-codex-agents.sh \
  scripts/resolve-codex-role.sh skills/codex-agent-routing skills/shared/codex-routing.md; do
  [ ! -e "$plugin_root/$path" ] || fail "legacy path remains: $path"
done
if find "$plugin_root/skills" -name openai.yaml | grep -q .; then
  fail "Codex openai.yaml metadata remains in skills"
fi
if find "$plugin_root/agents" -name '*.toml' | grep -q .; then
  fail "Codex TOML role templates remain"
fi
pass "no Codex runtime files"

pattern='spawn_agent|wait_agent|update_plan|fork_turns|gpt-[0-9]|\bastra\b|\bluna\b|\bterra\b|\bcodex\b|openai|resolve-codex|install-codex'
if grep -rniE "$pattern" "$plugin_root/skills" "$plugin_root/agents" "$plugin_root/hooks" \
  "$plugin_root/scripts" "$plugin_root/.claude-plugin" "$plugin_root/package.json"; then
  fail "Codex-only vocabulary remains in shipped runtime files"
fi
pass "no Codex vocabulary in shipped runtime files"
printf 'All legacy-runtime tests passed.\n'
