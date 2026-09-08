#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
require_text() {
  file=$1
  text=$2
  grep -Fq "$text" "$file" || fail "missing '$text' in $file"
}
reject_text() {
  file=$1
  text=$2
  if grep -Fq "$text" "$file"; then
    fail "unexpected '$text' in $file"
  fi
}
test_review_package_worktree_state() (
  fixture=$(mktemp -d)
  trap 'rm -rf "$fixture"' EXIT
  git -C "$fixture" init -q
  git -C "$fixture" config user.email test@example.com
  git -C "$fixture" config user.name "Contract Test"
  mkdir -p "$fixture/docs"
  printf 'plan\n' > "$fixture/docs/plan.md"
  printf 'original\n' > "$fixture/tracked.txt"
  git -C "$fixture" add docs/plan.md tracked.txt
  git -C "$fixture" commit -qm baseline
  base=$(git -C "$fixture" rev-parse HEAD)

  printf 'committed content\n' > "$fixture/committed.txt"
  git -C "$fixture" add committed.txt
  git -C "$fixture" commit -qm committed-change
  head=$(git -C "$fixture" rev-parse HEAD)

  printf 'staged content\n' > "$fixture/staged.txt"
  git -C "$fixture" add staged.txt
  printf 'unstaged content\n' >> "$fixture/tracked.txt"
  printf 'untracked content\n' > "$fixture/untracked.txt"

  output=$(mktemp)
  trap 'rm -rf "$fixture"; rm -f "$output"' EXIT
  (
    cd "$fixture"
    "$repo_root/scripts/review-package" \
      docs/plan.md "$base" "$head" "$output" >/dev/null
  )

  grep -Fq 'committed content' "$output" || fail "review package omitted committed changes"
  grep -Fq 'staged content' "$output" || fail "review package omitted staged changes"
  grep -Fq 'unstaged content' "$output" || fail "review package omitted unstaged changes"
  grep -Fq 'untracked content' "$output" || fail "review package omitted untracked files"
)
test_plugin_wrappers_from_consumer_worktree() (
  fixture=$(mktemp -d)
  trap 'rm -rf "$fixture"' EXIT
  git -C "$fixture" init -q
  mkdir -p "$fixture/docs"
  plan="$fixture/docs/plan.md"
  printf '# Plan\n\n## Task 1: Verify wrappers\n\nRun the helper.\n' > "$plan"

  workspace=$(cd "$fixture" && "$repo_root/scripts/sdd-workspace" "$plan")
  test "$workspace" = "$fixture/.superpowers/sdd/plan" ||
    fail "sdd-workspace wrapper returned unexpected path: $workspace"

  output=$(cd "$fixture" && "$repo_root/scripts/task-brief" "$plan" 1)
  printf '%s\n' "$output" | grep -Fq "wrote $workspace/task-1-brief.md" ||
    fail "task-brief wrapper returned unexpected output: $output"
  grep -Fq '## Task 1: Verify wrappers' "$workspace/task-1-brief.md" ||
    fail "task-brief wrapper did not extract the requested task"
)
files="
$repo_root/skills/shared/codex-routing.md
$repo_root/skills/shared/task-format-reference.md
$repo_root/skills/brainstorming/SKILL.md
$repo_root/skills/brainstorming/spec-document-reviewer-prompt.md
$repo_root/skills/subagent-driven-development/SKILL.md
$repo_root/skills/subagent-driven-development/implementer-prompt.md
$repo_root/skills/subagent-driven-development/spec-reviewer-prompt.md
$repo_root/skills/subagent-driven-development/code-quality-reviewer-prompt.md
$repo_root/skills/subagent-driven-development/task-reviewer-prompt.md
$repo_root/skills/subagent-driven-development/re-review-prompt.md
$repo_root/skills/dispatching-parallel-agents/SKILL.md
$repo_root/skills/codex-agent-routing/SKILL.md
$repo_root/skills/executing-plans/SKILL.md
$repo_root/skills/requesting-code-review/SKILL.md
$repo_root/skills/requesting-code-review/code-reviewer.md
$repo_root/skills/test-driven-development/SKILL.md
$repo_root/skills/using-git-worktrees/SKILL.md
$repo_root/skills/finishing-a-development-branch/SKILL.md
$repo_root/skills/using-superpowers/SKILL.md
$repo_root/skills/using-superpowers/references/codex-tools.md
$repo_root/skills/writing-plans/SKILL.md
$repo_root/skills/writing-plans/plan-document-reviewer-prompt.md
$repo_root/skills/specifying-gates/SKILL.md
"
for file in $files; do
  test -f "$file" || fail "missing skill file: $file"
done
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" superpowers_luna_implementer
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" superpowers_terra_implementer
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" superpowers_astra_implementer
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" superpowers_astra_reviewer
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" spawn_agent
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" "fork_turns: none"
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" "never silently substitute"
require_text "$repo_root/skills/shared/codex-routing.md" "## Host Capability Gate"
require_text "$repo_root/skills/shared/codex-routing.md" "host's callable tool list"
require_text "$repo_root/skills/shared/codex-routing.md" "single-agent mode"
require_text "$repo_root/skills/shared/codex-routing.md" "must not claim"
require_text "$repo_root/skills/shared/codex-routing.md" install-codex-agents.ps1
require_text "$repo_root/skills/shared/codex-routing.md" resolve-codex-role.ps1
require_text "$repo_root/skills/shared/codex-routing.md" "current platform"
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" "requires routed mode"
require_text "$repo_root/skills/dispatching-parallel-agents/SKILL.md" "single-agent mode"
require_text "$repo_root/skills/writing-plans/SKILL.md" modelTier
require_text "$repo_root/skills/executing-plans/SKILL.md" spawn_agent
require_text "$repo_root/skills/executing-plans/SKILL.md" "single-agent mode"
require_text "$repo_root/skills/codex-agent-routing/SKILL.md" "host's callable tool list"
require_text "$repo_root/skills/requesting-code-review/SKILL.md" "superpowers_astra_reviewer"
require_text "$repo_root/skills/requesting-code-review/SKILL.md" "independent review unavailable"
require_text "$repo_root/skills/using-superpowers/SKILL.md" "host capability gate"
require_text "$repo_root/skills/using-superpowers/references/codex-tools.md" "single-agent mode"
require_text "$repo_root/skills/using-superpowers/SKILL.md" "Direct"
require_text "$repo_root/skills/using-superpowers/SKILL.md" "controller implements directly"
require_text "$repo_root/skills/brainstorming/SKILL.md" "No redundant approval"
require_text "$repo_root/skills/brainstorming/SKILL.md" "No mandatory document, commit, task tracker, or separate spec review"
require_text "$repo_root/skills/writing-plans/SKILL.md" "Controller execution is the normal default"
require_text "$repo_root/skills/writing-plans/SKILL.md" "highRiskBoundary"
require_text "$repo_root/skills/requesting-code-review/SKILL.md" "Independent review is a risk control, not a ritual"
require_text "$repo_root/skills/requesting-code-review/SKILL.md" "Mechanical/trivial"
require_text "$repo_root/skills/test-driven-development/SKILL.md" "Test behavior, not every new function or method"
require_text "$repo_root/skills/test-driven-development/SKILL.md" "Refactoring is optional cleanup"
require_text "$repo_root/skills/using-git-worktrees/SKILL.md" "Do not create a worktree merely because a plan exists"
require_text "$repo_root/skills/using-git-worktrees/SKILL.md" "Do not automatically install"
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" "Per-task independent review is REQUIRED only"
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" "exactly one fresh independent whole-diff review"
require_text "$repo_root/skills/shared/codex-routing.md" "Ordinary delegated tasks complete from implementer evidence plus controller"
require_text "$repo_root/skills/shared/codex-routing.md" "reruns only evidence"
require_text "$repo_root/skills/shared/task-format-reference.md" "highRiskBoundary: true"
require_text "$repo_root/skills/shared/task-format-reference.md" "Ordinary tasks"
require_text "$repo_root/skills/writing-plans/SKILL.md" "requires one task-scoped independent review"
require_text "$repo_root/skills/requesting-code-review/SKILL.md" "Required task-scoped review"
require_text "$repo_root/skills/subagent-driven-development/SKILL.md" "includes the committed range, index, working tree, and untracked files"
require_text "$repo_root/skills/subagent-driven-development/implementer-prompt.md" "[BRIEF_FILE]"
require_text "$repo_root/skills/subagent-driven-development/implementer-prompt.md" "[REPORT_FILE]"
require_text "$repo_root/skills/subagent-driven-development/implementer-prompt.md" "Write your complete implementation and evidence report"
require_text "$repo_root/skills/dispatching-parallel-agents/SKILL.md" "superpowers_terra_implementer"
require_text "$repo_root/skills/dispatching-parallel-agents/SKILL.md" "fork_turns: none"
reject_text "$repo_root/skills/dispatching-parallel-agents/SKILL.md" "Subagent (general-purpose)"
require_text "$repo_root/skills/finishing-a-development-branch/SKILL.md" "is not ownership proof"
require_text "$repo_root/skills/finishing-a-development-branch/SKILL.md" "mandatory cleanup helper"
require_text "$repo_root/skills/finishing-a-development-branch/SKILL.md" 'Never use location, apparent staleness, or a broad'
for reviewer_prompt in \
  "$repo_root/skills/brainstorming/spec-document-reviewer-prompt.md" \
  "$repo_root/skills/writing-plans/plan-document-reviewer-prompt.md" \
  "$repo_root/skills/subagent-driven-development/spec-reviewer-prompt.md" \
  "$repo_root/skills/subagent-driven-development/code-quality-reviewer-prompt.md" \
  "$repo_root/skills/subagent-driven-development/task-reviewer-prompt.md" \
  "$repo_root/skills/subagent-driven-development/re-review-prompt.md" \
  "$repo_root/skills/requesting-code-review/code-reviewer.md"; do
  require_text "$reviewer_prompt" "superpowers_astra_reviewer"
  require_text "$reviewer_prompt" 'Verdict: ship | fix-first | rethink'
done
require_text "$repo_root/skills/requesting-code-review/code-reviewer.md" "Do not create or enter worktrees"
require_text "$repo_root/skills/executing-plans/SKILL.md" "A written plan does not make a worktree mandatory"
require_text "$repo_root/skills/specifying-gates/SKILL.md" "Do not impose one-question-at-a-time ceremony"
reject_text "$repo_root/skills/subagent-driven-development/SKILL.md" "rounds 1-3"
reject_text "$repo_root/skills/subagent-driven-development/SKILL.md" "Never skip the task review"
reject_text "$repo_root/skills/test-driven-development/SKILL.md" "Every new function/method has a test"
reject_text "$repo_root/skills/specifying-gates/SKILL.md" "one question at a time per the brainstorming skill's rule"
require_text "$repo_root/skills/subagent-driven-development/implementer-prompt.md" "You Do Not Dispatch Subagents"
require_text "$repo_root/skills/subagent-driven-development/task-reviewer-prompt.md" "You Do Not Dispatch Subagents"
require_text "$repo_root/skills/subagent-driven-development/re-review-prompt.md" "You Do Not Dispatch Subagents"
require_text "$repo_root/skills/requesting-code-review/code-reviewer.md" "You Do Not Dispatch Subagents"
for role in \
  "$repo_root/agents/superpowers-luna-implementer.toml" \
  "$repo_root/agents/superpowers-terra-implementer.toml" \
  "$repo_root/agents/superpowers-astra-implementer.toml" \
  "$repo_root/agents/superpowers-astra-reviewer.toml"; do
  require_text "$role" "never spawn"
done
require_text "$repo_root/agents/superpowers-astra-implementer.toml" 'model = "gpt-6-astra"'
require_text "$repo_root/agents/superpowers-astra-reviewer.toml" 'model = "gpt-6-astra"'
require_text "$repo_root/agents/superpowers-astra-implementer.toml" 'name = "superpowers_astra_implementer"'
require_text "$repo_root/agents/superpowers-astra-reviewer.toml" 'name = "superpowers_astra_reviewer"'
require_text "$repo_root/agents/superpowers-astra-implementer.toml" 'model_reasoning_effort = "high"'
require_text "$repo_root/agents/superpowers-astra-reviewer.toml" 'model_reasoning_effort = "high"'
require_text "$repo_root/agents/superpowers-astra-reviewer.toml" 'sandbox_mode = "read-only"'
test -x "$repo_root/scripts/sdd-workspace" || fail "sdd-workspace wrapper is missing or not executable"
test -x "$repo_root/scripts/task-brief" || fail "task-brief wrapper is missing or not executable"
require_text "$repo_root/skills/shared/codex-routing.md" 'Resolve every `scripts/...` path'
require_text "$repo_root/skills/shared/codex-routing.md" "plugin root"
test_plugin_wrappers_from_consumer_worktree
test_review_package_worktree_state
printf '%s\n' "$files" | while IFS= read -r file; do
  test -n "$file" || continue
  if grep -Eiq '\b(haiku|sonnet|opus|fable|anthropic)\b' "$file"; then
    fail "legacy model alias remains in $file"
  fi
done
printf 'All Codex skill routing contract tests passed.\n'
