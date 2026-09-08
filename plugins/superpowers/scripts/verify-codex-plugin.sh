#!/bin/sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd "$script_dir/.." && pwd)
codex_root=${CODEX_HOME-}
user_home=${HOME-}
if [ -z "$codex_root" ]; then
  codex_root=$user_home/.codex
fi
validator_root=${CODEX_VALIDATOR_ROOT-}
if [ -z "$validator_root" ]; then
  validator_root=$codex_root/skills/.system
fi
skill_validator=$validator_root/skill-creator/scripts/quick_validate.py
plugin_validator=$validator_root/plugin-creator/scripts/validate_plugin.py

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"
[ -f "$repo_root/.codex-plugin/plugin.json" ] || fail "Codex manifest is missing"
[ -f "$skill_validator" ] || fail "skill validator is missing: $skill_validator"
[ -f "$plugin_validator" ] || fail "plugin validator is missing: $plugin_validator"

jq empty "$repo_root/.codex-plugin/plugin.json"
[ -x "$repo_root/scripts/install-codex-agents.sh" ] || fail "agent installer is missing"
[ -x "$repo_root/scripts/resolve-codex-role.sh" ] || fail "role resolver is missing"
[ -x "$repo_root/scripts/sdd-workspace" ] || fail "sdd-workspace wrapper is missing"
[ -x "$repo_root/scripts/task-brief" ] || fail "task-brief wrapper is missing"
[ -x "$repo_root/scripts/review-package" ] || fail "review-package command is missing"

for runtime_file in \
  "$repo_root/scripts/install-codex-agents.ps1" \
  "$repo_root/scripts/resolve-codex-role.ps1" \
  "$repo_root/scripts/verify-codex-plugin.ps1"; do
  [ -f "$runtime_file" ] || fail "PowerShell runtime script is missing: $runtime_file"
done

for test_file in \
  "$repo_root/tests/codex-native/test-install-codex-agents.ps1" \
  "$repo_root/tests/codex-native/test-routing-contract.ps1" \
  "$repo_root/tests/codex-native/test-skill-routing-contract.ps1" \
  "$repo_root/tests/codex-native/test-no-legacy-runtime.ps1"; do
  [ -f "$test_file" ] || fail "PowerShell focused test is missing: $test_file"
done

for test_file in \
  "$repo_root/tests/codex-native/test-install-codex-agents.sh" \
  "$repo_root/tests/codex-native/test-routing-contract.sh" \
  "$repo_root/tests/codex-native/test-skill-routing-contract.sh" \
  "$repo_root/tests/codex-native/test-no-legacy-runtime.sh"; do
  [ -x "$test_file" ] || fail "focused test is missing or not executable: $test_file"
  bash "$test_file"
done

workflow=$repo_root/../../.github/workflows/verify.yml
[ -f "$workflow" ] || fail "verification workflow is missing: $workflow"
for job_id in linux windows-powershell-5 windows-powershell-7; do
  grep -q "^  $job_id:\$" "$workflow" ||
    fail "verification workflow is missing job: $job_id"
done

for skill_file in "$repo_root"/skills/*/SKILL.md; do
  [ -f "$skill_file" ] || continue
  skill_dir=$(dirname "$skill_file")
  python3 "$skill_validator" "$skill_dir"
done

python3 "$plugin_validator" "$repo_root"

forbidden_pattern='\b(hai''ku|son''net|op''us|fa''ble|anthro''pic|clau''de|open''code|gem''ini)\b'
if rg -n -i "$forbidden_pattern" \
  "$repo_root/.codex-plugin" "$repo_root/skills" \
  "$repo_root/scripts/install-codex-agents.sh" \
  "$repo_root/scripts/install-codex-agents.ps1" \
  "$repo_root/scripts/resolve-codex-role.sh" \
  "$repo_root/scripts/resolve-codex-role.ps1" \
  "$repo_root/scripts/review-package" \
  "$repo_root/scripts/verify-codex-plugin.sh" \
  "$repo_root/scripts/verify-codex-plugin.ps1" \
  "$repo_root/README.md" "$repo_root/package.json"; then
  fail "legacy host or model identifier remains in shipped runtime files"
fi

printf 'Codex plugin verification passed.\n'
